# Syncthing Rebuild Playbook

Step-by-step guide for rebuilding `~/work` sync from scratch after corruption, server outage, or misconfigured sync. Assumes a hub-and-spoke topology with one source-of-truth device, one hub server, and one or more receiving devices.

## Prerequisites

- All Syncthing instances paused on all devices
- Know which device has the cleanest `~/work` state (usually the one you've been actively using and which is configured as the source of truth)
- Know your folder IDs and device IDs (`syncthing cli config folders list` / `devices list`)

## Phase 1: Backup (on each device)

### 1.1 Backup shell config (critical)

~/.zshrc is a symlink into ~/work/dotfiles. If you move ~/work, your shell breaks.

```bash
cp ~/work/dotfiles/zsh/.zshrc ~/.zshrc.bak
```

### 1.2 Check for symlinks

```bash
find ~/work -maxdepth 3 -type l
find ~ -maxdepth 1 -type l
```

Known symlinks:
- `~/.zshrc` -> `~/work/dotfiles/zsh/.zshrc`
- `~/work/.stignore` -> `~/work/dotfiles/syncthing/.stignore`

### 1.3 Check for unsynced local-only files

Look for non-git config files, .env files, anything that won't come back from a clone:

```bash
find ~/work -not -path '*/.git/*' -not -path '*/node_modules/*' -name ".env*" -type f
find ~/work -not -path '*/.git/*' -not -path '*/node_modules/*' -name ".*" -type f | grep -v .DS_Store
```

### 1.4 Check for sync conflict files

```bash
find ~/work -name "*.sync-conflict-*"
```

### 1.5 Check git repos for unpushed work

```bash
for dir in $(find ~/work -name .git -type d -maxdepth 4); do
  repo=$(dirname "$dir")
  echo "=== $repo ==="
  git -C "$repo" status --short
  git -C "$repo" log --oneline @{upstream}..HEAD 2>/dev/null || echo "(no upstream)"
done
```

## Phase 2: Clear the sync target

### 2.1 On client devices (regular filesystem)

```bash
mv ~/work ~/old-work
mkdir ~/work
```

### 2.2 On the hub server

If the sync target sits on a regular filesystem, use the same `mv` approach as
above (substituting the actual sync path). If it sits on something that can't
be moved with `mv` (e.g. a ZFS mountpoint, a dedicated mountpoint, a container
volume), see your homelab notes for the platform-specific procedure — the
general shape is "stash existing contents, leave the mountpoint in place,
recreate empty".

### 2.3 Create Syncthing folder marker

Syncthing requires `.stfolder` to exist in the sync root or it will error with
"folder marker missing". Create one on every device after clearing:

```bash
mkdir <sync-root>/.stfolder
```

## Phase 3: Rebuild on the source-of-truth device

### 3.1 Copy dotfiles first

```bash
cp -a ~/old-work/dotfiles ~/work/dotfiles
```

### 3.2 Recreate symlinks

```bash
ln -sf ~/work/dotfiles/zsh/.zshrc ~/.zshrc
ln -sf ~/work/dotfiles/syncthing/.stignore ~/work/.stignore
```

### 3.3 Verify shell works

```bash
source ~/.zshrc
```

### 3.4 Recreate directory structure

Recreate whatever top-level subdirectories you organize work into:

```bash
mkdir -p ~/work/<subdir-1> ~/work/<subdir-2> ...
```

### 3.5 Re-clone git repos

Clone each repo into its correct location. Fetch all remote branches:

```bash
git clone <url> ~/work/path/to/repo
cd ~/work/path/to/repo
git fetch --all
git branch -r | grep -v '\->' | while read remote; do
  git branch --track "${remote#origin/}" "$remote" 2>/dev/null
done
git fetch --all
```

### 3.6 Restore non-git files

Copy back any .env files or local configs from old-work:

```bash
# Example: find and copy .env files
find ~/old-work -name ".env*" -not -path '*/.git/*' -not -path '*/node_modules/*'
# Then manually cp each one to the corresponding location in ~/work
```

## Phase 4: Sync to the hub (one device at a time)

### 4.1 Verify the hub's sync target

Confirm the sync target on the hub is on a persistent volume. A non-persistent
mount (e.g. an ephemeral container volume) means data loss on restart. This is
the failure mode that motivated this playbook.

### 4.2 Set ignore patterns on the hub

Paste the contents of `.stignore` into the hub's Syncthing UI ignore-patterns
editor for the work folder. Verify it matches the source-of-truth file.

### 4.3 Configure folder types

- Source-of-truth device: **Send Only**
- Hub: **Receive Only**

### 4.4 Unpause source ↔ hub connection

On the source-of-truth device:
```bash
syncthing cli config devices <HUB-DEVICE-ID> paused set false
```

### 4.5 Monitor sync progress

Set `WORK_FOLDER_ID` to your work folder's ID first (see
`syncthing cli config folders list`):

```bash
# Check folder status
curl -s -H "X-API-Key:$(syncthing cli config gui apikey get)" \
  "http://127.0.0.1:8384/rest/db/status?folder=${WORK_FOLDER_ID}" | python3 -m json.tool

# Watch connection throughput
curl -s -H "X-API-Key:$(syncthing cli config gui apikey get)" \
  'http://127.0.0.1:8384/rest/system/connections' | python3 -m json.tool
```

### 4.6 Wait for "Up to Date" on both sides before proceeding

## Phase 5: Sync to remaining receiving devices

### 5.1 On each receiving device, repeat Phase 2 and Phase 3

- `mv ~/work ~/old-work && mkdir ~/work`
- Copy dotfiles, recreate symlinks, re-clone repos
- Create `.stfolder`

### 5.2 Unpause hub ↔ device connection

Do this from the hub's Syncthing UI. Keep the receiving device as **Receive
Only** until the first sync completes.

### 5.3 Wait for full sync, then switch to normal mode

Once all devices show "Up to Date", switch folder types back to your normal
config if desired.

## Phase 6: Cleanup

Once everything is confirmed working:

```bash
# On each device, after verifying sync is complete:
rm -rf ~/old-work

# On the hub, if its sync target is on a non-standard filesystem (e.g. ZFS,
# btrfs, container volume), use the platform-specific destroy command instead.

# Remove shell backup:
rm ~/.zshrc.bak
```

## Troubleshooting

### "folder marker missing"
Create `.stfolder` in the sync target and trigger a rescan.

### "Device or resource busy" on the hub
The sync target may be a mountpoint that can't be removed by `rm`. Stop the
Syncthing process/container first, then use the filesystem-appropriate command
to clear it (see your platform notes).

### `.stignore` not propagating
Paste ignore patterns manually into the Syncthing UI on each device. Don't
rely on file sync for the ignore file itself.

### Sync stuck at 99%
Check for symlinks or special files that can't sync. Look at the "Out of Sync
Items" count in the UI for details.
