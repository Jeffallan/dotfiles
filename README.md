# Dotfiles

Personal dotfiles and shell configurations.

## ZSH Configuration

Clean oh-my-zsh setup with public/private configuration split.

### Features

- Public `.zshrc` with oh-my-zsh framework configuration
- Private `.zshrc.local` for machine-specific settings (not tracked in git)
- Parrot theme with full path display
- Plugin support (git, zsh-autosuggestions)

### Installation

```bash
# Clone this repo
git clone <your-repo-url> ~/dotfiles

# Create symlinks
ln -s ~/dotfiles/zsh/.zshrc ~/.zshrc
ln -s ~/dotfiles/zsh/themes/parrot.zsh-theme ~/.oh-my-zsh/custom/themes/parrot.zsh-theme

# Create your local configuration
touch ~/.zshrc.local
# Add machine-specific configs (PATH, tool configurations, etc.) to ~/.zshrc.local
```

## Parrot ZSH Theme

A customized version of the Parrot ZSH theme with full path display.

### Features

- Clean, two-line prompt with decorative box-style design
- Git, SVN, and Mercurial repository status indicators
- Python virtualenv display
- Exit code display on errors
- Full working directory path (modified from original)

### Installation

```bash
# Clone this repo
git clone <your-repo-url> ~/dotfiles

# Create symlink to oh-my-zsh custom themes
ln -s ~/dotfiles/zsh/themes/parrot.zsh-theme ~/.oh-my-zsh/custom/themes/parrot.zsh-theme

# Set theme in ~/.zshrc
ZSH_THEME="parrot"
```

### Attribution

- **Original YS Theme**: Yad Smood (2013)
- **Parrot Theme**: TOURE A. KARIM (Feb 2022) - [trabdlkarim/parrot-zsh-theme](https://github.com/trabdlkarim/parrot-zsh-theme)
- **Modified**: Changed from `%c` (current directory name) to `%~` (full path from home)

## Claude Code Configuration

Personal Claude Code instructions for consistent AI-assisted development practices.

### Features

- Verification discipline (no completion claims without evidence)
- Systematic debugging process (root cause before fixes)
- Testing mandate (RED-GREEN-REFACTOR)
- Communication standards (no agreement theater)
- Code review standards (spec compliance first)

### Installation

```bash
# Create Claude config directory if needed
mkdir -p ~/.claude

# Create symlink
ln -s ~/dotfiles/claude/CLAUDE.md ~/.claude/CLAUDE.md
```

### Attribution

Behavioral patterns adapted from [obra/superpowers](https://github.com/obra/superpowers) by Jesse Vincent (@obra), MIT License.

## License

MIT License - See LICENSE file

This modification maintains the MIT License from the original Parrot theme.
