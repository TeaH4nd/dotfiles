#!/usr/bin/env bash

export DOTFILES_DIR
DOTFILES_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

PATH="$DOTFILES_DIR/bin:$PATH"

## Update dotfiles itself
echo -n Updating dotfiles... 
if command -v git &>/dev/null && [ -d "$DOTFILES_DIR/.git" ]
then 
    git --work-tree="$DOTFILES_DIR" --git-dir="$DOTFILES_DIR/.git" pull origin main; 
    echo Updated!
fi
echo

## Verify if vim is installed
echo -n Verifying if vim is installed... 
if ! command -v vim &>/dev/null
then
    sudo apt install vim
else
    echo Vim is installed!
fi
echo

## Verify if stow is installed
echo -n Verifying if stow is installed...
if ! command -v stow &>/dev/null
then
    sudo apt install stow
else
    echo stow is installed!
fi
echo

## Stow dotfiles packages
echo Stowing dotfiles...
cd "$DOTFILES_DIR"
stow -v -t "$HOME" bash vim

true