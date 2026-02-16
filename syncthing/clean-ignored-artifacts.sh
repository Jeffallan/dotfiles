#!/bin/bash
# Remove files and directories matching .stignore patterns from a synced folder
# Usage: ./clean-ignored-artifacts.sh [folder_path]
#   Defaults to ~/work if no argument given

set -euo pipefail

FOLDER="${1:-$HOME/work}"
STIGNORE="$FOLDER/.stignore"

if [ ! -f "$STIGNORE" ]; then
  # Follow symlinks
  STIGNORE="$(readlink -f "$STIGNORE" 2>/dev/null || true)"
  if [ ! -f "$STIGNORE" ]; then
    echo "Error: No .stignore found in $FOLDER"
    exit 1
  fi
fi

echo "Folder:    $FOLDER"
echo "Stignore:  $STIGNORE"
echo ""

dir_patterns=()
file_patterns=()

while IFS= read -r line; do
  # Skip comments, blank lines, and syncthing directives like (?d)
  line="$(echo "$line" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')"
  [[ -z "$line" ]] && continue
  [[ "$line" =~ ^# ]] && continue
  [[ "$line" =~ ^// ]] && continue

  # Strip syncthing prefixes like (?d), (?i), etc.
  line="$(echo "$line" | sed 's/^(![^)]*)//' | sed 's/^(\?[^)]*)//')"

  # Directory patterns end with /
  if [[ "$line" == */ ]]; then
    dir_patterns+=("${line%/}")
  else
    file_patterns+=("$line")
  fi
done < "$STIGNORE"

found=()

# Find matching directories
for pat in "${dir_patterns[@]}"; do
  while IFS= read -r match; do
    [ -n "$match" ] && found+=("$match")
  done < <(find "$FOLDER" -type d -name "$pat" 2>/dev/null)
done

# Find matching files
for pat in "${file_patterns[@]}"; do
  while IFS= read -r match; do
    [ -n "$match" ] && found+=("$match")
  done < <(find "$FOLDER" -type f -name "$pat" 2>/dev/null)
done

if [ ${#found[@]} -eq 0 ]; then
  echo "No ignored artifacts found."
  exit 0
fi

echo "Found ${#found[@]} items to remove:"
echo ""
for item in "${found[@]}"; do
  size=$(du -sh "$item" 2>/dev/null | cut -f1)
  echo "  [$size]  ${item#$FOLDER/}"
done

echo ""
read -p "Remove all? [y/N] " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
  for item in "${found[@]}"; do
    rm -rf "$item"
    echo "Removed: ${item#$FOLDER/}"
  done
  echo ""
  echo "Done. Syncthing should clear errors on next scan."
else
  echo "Aborted."
fi
