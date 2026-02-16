# Syncthing Configuration

## .stignore File

Multi-language development ignore patterns for Syncthing.

### Installation

```bash
# Copy to your synced folder
cp .stignore ~/path/to/your/synced/folder/.stignore

# Or symlink for automatic updates
ln -s ~/dotfiles/syncthing/.stignore ~/path/to/your/synced/folder/.stignore
```

### What's Excluded

**Build artifacts and dependencies:**
- `node_modules/` (Node.js)
- `venv/`, `__pycache__/` (Python)
- `target/` (Rust)
- `vendor/` (Go)
- `build/`, `dist/`, `.next/`, `.expo/` (Various frameworks)

**IDE and OS files:**
- `.vscode/`, `.idea/` (IDEs)
- `.DS_Store`, `Thumbs.db` (OS)

**Live database files:**
- `*.db`, `*.sqlite` (Use SQL dumps instead)

### What's Included (Synced)

**✅ Secrets (for dev environments):**
- `.env` files
- `.key`, `.pem`, `.crt` files
- **⚠️ WARNING:** Only sync development secrets, never production!

**✅ Docker overrides:**
- `docker-compose.override.yml` (for consistent dev environments)

**✅ Lock files:**
- `package-lock.json`, `yarn.lock`, `poetry.lock`, etc.
- Recommended for reproducible builds

### Rationale

**Why exclude node_modules?**
- 100K-300K+ tiny files per project
- Sync takes hours instead of minutes
- `npm install` is faster than syncing
- Cross-platform binary compatibility issues
- High CPU/disk I/O overhead

**Why exclude databases?**
- Risk of corruption if accessed simultaneously
- Lock file conflicts
- Better approach: Sync SQL dumps or seed scripts

**Why include secrets?**
- Consistent dev environment across machines
- Convenience for development workflow
- You own the infrastructure (NAS)
- Use `.env` for dev, proper secrets management for production

### Best Practices

1. **Initial setup:** Let first sync complete before applying .stignore
2. **After applying:** Run `npm install`, `pip install`, etc. on each machine
3. **Database state:** Use migrations and seed scripts instead of syncing live DBs
4. **Production secrets:** Never sync production credentials

### Performance Impact

**Without .stignore:**
- 300K+ files
- 8-24 hour initial sync
- Constant background syncing
- High CPU/battery usage

**With .stignore:**
- 5K-10K source files
- 10-30 minute initial sync
- Minimal background activity
- Low resource usage

### Cleaning Up Ignored Artifacts

When Syncthing reports errors like "directory has been deleted on a remote device but contains ignored files", use the cleanup script to remove locally-ignored build artifacts that are blocking directory deletions.

```bash
# Clean ~/work (default)
./clean-ignored-artifacts.sh

# Clean a different synced folder
./clean-ignored-artifacts.sh ~/note-sync
```

The script reads patterns from the folder's `.stignore`, finds matching files and directories, shows them with sizes, and asks for confirmation before deleting. It can be run from any directory.

### Customization

Edit the file to match your workflow:
- Uncomment lock file exclusions if you prefer platform-specific dependencies
- Add project-specific patterns
- Adjust based on your security requirements
