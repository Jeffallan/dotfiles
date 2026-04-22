# Syncthing CLI & API Cheatsheet

Commands for managing Syncthing from the terminal. Works on any device with the Syncthing CLI or curl.

## API Key

All API calls require the API key. Get it from the CLI (never hardcode it):

```bash
# Store in a variable for the session
API_KEY=$(syncthing cli config gui apikey get)
```

## System

```bash
# System status (uptime, version, device ID)
curl -s -H "X-API-Key:$API_KEY" 'http://127.0.0.1:8384/rest/system/status' | python3 -m json.tool

# Health check (no auth required)
curl -s 'http://127.0.0.1:8384/rest/noauth/health'

# Restart syncthing
curl -s -X POST -H "X-API-Key:$API_KEY" 'http://127.0.0.1:8384/rest/system/restart'

# Shutdown syncthing
curl -s -X POST -H "X-API-Key:$API_KEY" 'http://127.0.0.1:8384/rest/system/shutdown'
```

## Connections

```bash
# Show all device connections (connected, paused, bytes transferred)
curl -s -H "X-API-Key:$API_KEY" 'http://127.0.0.1:8384/rest/system/connections' | python3 -m json.tool

# Quick connection summary
curl -s -H "X-API-Key:$API_KEY" 'http://127.0.0.1:8384/rest/system/connections' | \
  python3 -c "import sys,json; d=json.load(sys.stdin)
for did,c in d['connections'].items():
  print(f'{did[:7]} connected={c[\"connected\"]} paused={c[\"paused\"]} in={c[\"inBytesTotal\"]:,} out={c[\"outBytesTotal\"]:,}')"
```

## Folders

```bash
# List all folder IDs
syncthing cli config folders list

# Get full folder config
curl -s -H "X-API-Key:$API_KEY" 'http://127.0.0.1:8384/rest/config/folders' | python3 -m json.tool

# Folder sync status (state, errors, need counts)
curl -s -H "X-API-Key:$API_KEY" 'http://127.0.0.1:8384/rest/db/status?folder=FOLDER_ID' | python3 -m json.tool

# Quick folder status summary
curl -s -H "X-API-Key:$API_KEY" 'http://127.0.0.1:8384/rest/db/status?folder=FOLDER_ID' | \
  python3 -c "import sys,json; d=json.load(sys.stdin)
print(f'State: {d[\"state\"]}')
print(f'Error: {d[\"error\"]}')
print(f'Files: {d[\"inSyncFiles\"]}/{d[\"globalFiles\"]}')
print(f'Need: {d[\"needFiles\"]} files, {d[\"needBytes\"]:,} bytes')"

# Trigger folder rescan
curl -s -X POST -H "X-API-Key:$API_KEY" 'http://127.0.0.1:8384/rest/db/scan?folder=FOLDER_ID'

# List out-of-sync items
curl -s -H "X-API-Key:$API_KEY" 'http://127.0.0.1:8384/rest/db/need?folder=FOLDER_ID' | python3 -m json.tool

# Browse folder contents (as syncthing sees them)
curl -s -H "X-API-Key:$API_KEY" 'http://127.0.0.1:8384/rest/db/browse?folder=FOLDER_ID' | python3 -m json.tool
```

## Devices

```bash
# List all device IDs
syncthing cli config devices list

# Get device config
curl -s -H "X-API-Key:$API_KEY" 'http://127.0.0.1:8384/rest/config/devices' | python3 -m json.tool

# Pause a device
syncthing cli config devices DEVICE_ID paused set true

# Unpause a device
syncthing cli config devices DEVICE_ID paused set false

# Get device stats (last seen, etc)
curl -s -H "X-API-Key:$API_KEY" 'http://127.0.0.1:8384/rest/stats/device' | python3 -m json.tool
```

## Folder Type Changes

```bash
# Set folder to Send Only
curl -s -X PATCH -H "X-API-Key:$API_KEY" -H "Content-Type: application/json" \
  -d '{"type":"sendonly"}' 'http://127.0.0.1:8384/rest/config/folders/FOLDER_ID'

# Set folder to Receive Only
curl -s -X PATCH -H "X-API-Key:$API_KEY" -H "Content-Type: application/json" \
  -d '{"type":"receiveonly"}' 'http://127.0.0.1:8384/rest/config/folders/FOLDER_ID'

# Set folder to Send & Receive
curl -s -X PATCH -H "X-API-Key:$API_KEY" -H "Content-Type: application/json" \
  -d '{"type":"sendreceive"}' 'http://127.0.0.1:8384/rest/config/folders/FOLDER_ID'
```

## Ignore Patterns

```bash
# Get current ignore patterns for a folder
curl -s -H "X-API-Key:$API_KEY" 'http://127.0.0.1:8384/rest/db/ignores?folder=FOLDER_ID' | python3 -m json.tool

# Set ignore patterns (replaces all existing)
curl -s -X POST -H "X-API-Key:$API_KEY" -H "Content-Type: application/json" \
  -d '{"ignore":["node_modules/","dist/","build/"]}' \
  'http://127.0.0.1:8384/rest/db/ignores?folder=FOLDER_ID'
```

## Events & Logs

```bash
# Recent events
curl -s -H "X-API-Key:$API_KEY" 'http://127.0.0.1:8384/rest/events?limit=10' | python3 -m json.tool

# Recent log messages
curl -s -H "X-API-Key:$API_KEY" 'http://127.0.0.1:8384/rest/system/log' | python3 -m json.tool

# Errors only
curl -s -H "X-API-Key:$API_KEY" 'http://127.0.0.1:8384/rest/system/error' | python3 -m json.tool

# Clear errors
curl -s -X POST -H "X-API-Key:$API_KEY" 'http://127.0.0.1:8384/rest/system/error/clear'
```

## Monitoring One-Liners

```bash
# Watch sync progress (poll every 5s)
while true; do
  curl -s -H "X-API-Key:$API_KEY" 'http://127.0.0.1:8384/rest/db/status?folder=FOLDER_ID' | \
    python3 -c "import sys,json; d=json.load(sys.stdin); print(f'{d[\"state\"]} | {d[\"inSyncFiles\"]}/{d[\"globalFiles\"]} files | need {d[\"needFiles\"]} ({d[\"needBytes\"]:,} bytes) | err: {d[\"error\"] or \"none\"}')"
  sleep 5
done

# Watch data flow (poll every 5s)
while true; do
  curl -s -H "X-API-Key:$API_KEY" 'http://127.0.0.1:8384/rest/system/connections' | \
    python3 -c "import sys,json; d=json.load(sys.stdin)
for did,c in d['connections'].items():
  status = 'PAUSED' if c['paused'] else ('UP' if c['connected'] else 'DOWN')
  print(f'{did[:7]} [{status}] in={c[\"inBytesTotal\"]:,} out={c[\"outBytesTotal\"]:,}')"
  echo "---"
  sleep 5
done
```

## Local IDs Reference

Look up your folder and device IDs with:

```bash
syncthing cli config folders list
syncthing cli config devices list
```

Keep a personal copy of the resulting tables in a gitignored file (the `*.local`
pattern in this repo's `.gitignore` covers it):

```
syncthing/IDS.local.md
```

Reference those values when running the commands above (e.g. by exporting
`WORK_FOLDER_ID`, `HUB_DEVICE_ID`, etc. in your shell rc).

## Notes

- A headless server's Syncthing API may only be reachable from inside its container/host or via a local web UI — confirm reachability before running these commands remotely.
- Replace `127.0.0.1:8384` with the appropriate address when running against Syncthing on a different host.
- The `syncthing cli` binary only works where Syncthing is installed natively (e.g. macOS via Homebrew). In container/appliance setups, use `curl` against the local API or the web UI.
