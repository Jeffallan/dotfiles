# Dotfiles

Personal dotfiles and shell configurations.

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
git clone <your-repo-url> ~/work/dotfiles

# Create symlink to oh-my-zsh custom themes
ln -s ~/work/dotfiles/zsh/themes/parrot.zsh-theme ~/.oh-my-zsh/custom/themes/parrot.zsh-theme

# Set theme in ~/.zshrc
ZSH_THEME="parrot"
```

### Attribution

- **Original YS Theme**: Yad Smood (2013)
- **Parrot Theme**: TOURE A. KARIM (Feb 2022) - [trabdlkarim/parrot-zsh-theme](https://github.com/trabdlkarim/parrot-zsh-theme)
- **Modified**: Changed from `%c` (current directory name) to `%~` (full path from home)

### License

MIT License - See LICENSE file

This modification maintains the MIT License from the original Parrot theme.
