#!/usr/bin/env bash

export DOTFILES_DIR
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

PATH="$DOTFILES_DIR/bin:$PATH"

## Update dotfiles itself
echo -n "Updating dotfiles... "
if command -v git &>/dev/null && [ -d "$DOTFILES_DIR/.git" ]
then 
    git --work-tree="$DOTFILES_DIR" --git-dir="$DOTFILES_DIR/.git" pull origin main; 
    echo "Updated!"
fi
echo

## Verify if vim is installed
echo -n "Verifying if vim is installed... "
if ! command -v vim &>/dev/null
then
    sudo apt install vim
else
    echo "Vim is installed!"
fi
echo

## Verify if stow is installed
echo -n "Verifying if stow is installed... "
if ! command -v stow &>/dev/null
then
    sudo apt install stow
else
    echo "Stow is installed!"
fi
echo

## Backup and Cleanup of conflicting files
echo "Checking for existing files to backup..."
# List of packages to be processed by stow
PACKAGES=("bash" "vim")

for pkg in "${PACKAGES[@]}"; do
    # List files inside the package directory (e.g., dotfiles/bash/)
    # 'find' is used to retrieve only the relative filenames
    files=$(find "$DOTFILES_DIR/$pkg" -maxdepth 1 -not -path "$DOTFILES_DIR/$pkg" -printf "%f\n")
    
    for file in $files; do
        target="$HOME/$file"
        # If the file exists and is NOT a symbolic link, move it to backup
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            echo "Found real file: $file. Moving to $BACKUP_DIR"
            mkdir -p "$BACKUP_DIR"
            mv "$target" "$BACKUP_DIR/"
        fi
    done
done

## Stow dotfiles packages
echo "Stowing dotfiles..."
cd "$DOTFILES_DIR"
stow -v -t "$HOME" bash vim

echo "Done!"