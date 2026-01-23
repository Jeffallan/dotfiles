#!/usr/bin/env bash

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where this script is located
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Dotfiles Installation Script             ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Dotfiles location:${NC} $DOTFILES_DIR"
echo -e "${BLUE}Backup location:${NC} $BACKUP_DIR"
echo ""

# Function to create backup
create_backup() {
    local file=$1
    local backup_path="$BACKUP_DIR/$(dirname "$file")"

    mkdir -p "$backup_path"
    cp -P "$file" "$backup_path/"
    echo -e "${GREEN}  ✓ Backup created${NC}"
}

# Function to create symlink
create_symlink() {
    local target=$1
    local link=$2

    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$link")"

    # Remove existing file/link
    rm -rf "$link"

    # Create symlink
    ln -s "$target" "$link"
    echo -e "${GREEN}  ✓ Symlink created${NC}"
}

# Function to process a file
process_file() {
    local source=$1
    local target=$2
    local description=$3

    echo ""
    echo -e "${BLUE}Processing:${NC} $description"
    echo -e "  Source: $source"
    echo -e "  Target: $target"

    # Check if target is already a symlink to our dotfiles
    if [ -L "$target" ]; then
        local link_target=$(readlink "$target")
        if [ "$link_target" = "$source" ]; then
            echo -e "${GREEN}  ✓ Already linked correctly${NC}"
            return
        else
            echo -e "${YELLOW}  ⚠ Existing symlink points to: $link_target${NC}"
        fi
    elif [ -e "$target" ]; then
        echo -e "${YELLOW}  ⚠ File exists${NC}"
    else
        echo -e "${YELLOW}  ⚠ File does not exist${NC}"
    fi

    # Prompt user
    read -p "$(echo -e ${BLUE}Do you want to link this file? [y/N/s=skip]:${NC} )" -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Backup existing file if it exists and is not a symlink to our repo
        if [ -e "$target" ]; then
            create_backup "$target"
        fi
        create_symlink "$source" "$target"
    elif [[ $REPLY =~ ^[Ss]$ ]]; then
        echo -e "${YELLOW}  ⊘ Skipped${NC}"
    else
        echo -e "${YELLOW}  ⊘ Skipped${NC}"
    fi
}

# Files to symlink (source|target pairs)
FILES=(
    "$DOTFILES_DIR/zsh/.zshrc|$HOME/.zshrc"
    "$DOTFILES_DIR/zsh/themes/parrot.zsh-theme|$HOME/.oh-my-zsh/custom/themes/parrot.zsh-theme"
    "$DOTFILES_DIR/claude/CLAUDE.md|$HOME/.claude/CLAUDE.md"
)

# Process each file
for entry in "${FILES[@]}"; do
    IFS='|' read -r source target <<< "$entry"
    description=$(basename "$target")
    process_file "$source" "$target" "$description"
done

# Handle .zshrc.local specially
echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     .zshrc.local Configuration                ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
echo ""

if [ -f "$HOME/.zshrc.local" ]; then
    echo -e "${GREEN}✓ .zshrc.local already exists${NC}"
    echo -e "  Location: $HOME/.zshrc.local"
else
    echo -e "${YELLOW}⚠ .zshrc.local does not exist${NC}"
    read -p "$(echo -e ${BLUE}Create .zshrc.local from template? [Y/n]:${NC} )" -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo -e "${YELLOW}  ⊘ Skipped${NC}"
    else
        cp "$DOTFILES_DIR/zsh/.zshrc.local.template" "$HOME/.zshrc.local"
        echo -e "${GREEN}  ✓ Created $HOME/.zshrc.local from template${NC}"
        echo -e "${YELLOW}  ⚠ Remember to uncomment and configure required settings (especially NVM)${NC}"
    fi
fi

# Handle Syncthing .stignore
echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Syncthing .stignore Configuration         ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
echo ""

# Ask for sync folder location
read -p "$(echo -e ${BLUE}Enter your Syncthing work folder path [default: ~/work]:${NC} )" SYNC_FOLDER
SYNC_FOLDER=${SYNC_FOLDER:-$HOME/work}

# Expand tilde
SYNC_FOLDER="${SYNC_FOLDER/#\~/$HOME}"

if [ -d "$SYNC_FOLDER" ]; then
    if [ -L "$SYNC_FOLDER/.stignore" ]; then
        LINK_TARGET=$(readlink "$SYNC_FOLDER/.stignore")
        if [ "$LINK_TARGET" = "$DOTFILES_DIR/syncthing/.stignore" ]; then
            echo -e "${GREEN}✓ .stignore already linked correctly${NC}"
            echo -e "  Location: $SYNC_FOLDER/.stignore → $DOTFILES_DIR/syncthing/.stignore"
        else
            echo -e "${YELLOW}⚠ .stignore exists but points to: $LINK_TARGET${NC}"
            read -p "$(echo -e ${BLUE}Update symlink? [Y/n]:${NC} )" -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                rm "$SYNC_FOLDER/.stignore"
                ln -s "$DOTFILES_DIR/syncthing/.stignore" "$SYNC_FOLDER/.stignore"
                echo -e "${GREEN}  ✓ Updated symlink${NC}"
            fi
        fi
    elif [ -f "$SYNC_FOLDER/.stignore" ]; then
        echo -e "${YELLOW}⚠ .stignore file exists (not a symlink)${NC}"
        read -p "$(echo -e ${BLUE}Replace with symlink? [y/N]:${NC} )" -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if [ -d "$BACKUP_DIR" ]; then
                cp "$SYNC_FOLDER/.stignore" "$BACKUP_DIR/.stignore"
                echo -e "${GREEN}  ✓ Backed up existing .stignore${NC}"
            fi
            rm "$SYNC_FOLDER/.stignore"
            ln -s "$DOTFILES_DIR/syncthing/.stignore" "$SYNC_FOLDER/.stignore"
            echo -e "${GREEN}  ✓ Created symlink${NC}"
        else
            echo -e "${YELLOW}  ⊘ Skipped${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ .stignore does not exist${NC}"
        read -p "$(echo -e ${BLUE}Create symlink? [Y/n]:${NC} )" -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            ln -s "$DOTFILES_DIR/syncthing/.stignore" "$SYNC_FOLDER/.stignore"
            echo -e "${GREEN}  ✓ Created symlink${NC}"
            echo -e "${YELLOW}  ⚠ Restart Syncthing or rescan folder for changes to take effect${NC}"
        else
            echo -e "${YELLOW}  ⊘ Skipped${NC}"
        fi
    fi
else
    echo -e "${YELLOW}⚠ Sync folder not found: $SYNC_FOLDER${NC}"
    echo -e "  Create the folder and run this script again, or manually create symlink:"
    echo -e "  ln -s $DOTFILES_DIR/syncthing/.stignore $SYNC_FOLDER/.stignore"
fi

# Summary
echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Installation Complete                     ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════╝${NC}"
echo ""

if [ -d "$BACKUP_DIR" ]; then
    echo -e "${GREEN}✓ Backups saved to:${NC} $BACKUP_DIR"
fi

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo -e "  1. Edit ~/.zshrc.local and uncomment required configurations"
echo -e "  2. Restart your shell or run: source ~/.zshrc"
echo -e "  3. If Syncthing is running, rescan folder or restart to apply .stignore"
echo ""
