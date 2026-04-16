#!/usr/bin/env bash
#
# Best bashrc in history
#
# Author: TeaH4nd
# Date: 15/04/2026
# License: MIT

# If not running interactively, don't do anything
[[ -n $PS1 ]] || return

# Set environment
export EDITOR='vim'
export GREP_COLOR='1;36'
export HISTCONTROL='ignoreboth'
export HISTSIZE=5000
export HISTFILESIZE=5000
export LSCOLORS='ExGxbEaECxxEhEhBaDaCaD'
export PAGER='less'
export VISUAL='vim'

# Support colors in less
export LESS_TERMCAP_mb=$(tput bold; tput setaf 1)
export LESS_TERMCAP_md=$(tput bold; tput setaf 1)
export LESS_TERMCAP_me=$(tput sgr0)
export LESS_TERMCAP_se=$(tput sgr0)
export LESS_TERMCAP_so=$(tput bold; tput setaf 3; tput setab 4)
export LESS_TERMCAP_ue=$(tput sgr0)
export LESS_TERMCAP_us=$(tput smul; tput bold; tput setaf 2)
export LESS_TERMCAP_mr=$(tput rev)
export LESS_TERMCAP_mh=$(tput dim)
export LESS_TERMCAP_ZN=$(tput ssubm)
export LESS_TERMCAP_ZV=$(tput rsubm)
export LESS_TERMCAP_ZO=$(tput ssupm)
export LESS_TERMCAP_ZW=$(tput rsupm)

# Shell Options
# Attempt spelling correction on each directory component of an argument to cd. Allowed in interactive shells only.
shopt -s cdspell
# Check the window size after each command, and update LINES and COLUMNS if the size has changed.
shopt -s checkwinsize
# If set, the extended pattern matching features described above under Pathname Expansion are enabled.
shopt -s extglob
# append to the history file, don't overwrite it
shopt -s histappend

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# colored GCC warnings and errors
export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Gruvbox-like prompt colors
BOLD=$(tput bold)
RESET=$(tput sgr0)
RED=$(tput setaf 124)
WHITE=$(tput setaf 15)
BLUE=$(tput setaf 24)
YELLOW=$(tput setaf 208)
ORANGE=$(tput setaf 202)
D_ORANGE=$(tput setaf 130)
TEXT=$(tput setaf 215)

# Track command execution time
trap '_command_start_time=$(date +%s%N)' DEBUG

# Construct the prompt in modular sections
_update_ps1() {
    local ret=$?
    
    # Exit code of last process
    local ps1_exit=""
    if (( ret != 0 )); then
        ps1_exit="\[$RED\]($ret) \[$RESET\]"
    fi
    
    # Username
    local ps1_user="\[$BOLD\]\[$RED\]\u\[$RESET\] - "
    
    # Hostname
    local ps1_host="\[$ORANGE\]\h \[$RESET\]"
    
    # Current working directory
    local ps1_cwd="\[$BLUE\]\w\[$RESET\]"
    
    # Git branch display
    local ps1_git=""
    local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [[ -n $branch ]]; then
        ps1_git=" \[$YELLOW\](\[$ORANGE\]git:$branch\[$YELLOW\])\[$RESET\]"
    fi
    
    # Execution time
    local current_time=$(date +%s%N)
    local elapsed_ms=$(( (current_time - _command_start_time) / 1000000 ))
    local ps1_time=""
    if [ $elapsed_ms -gt 0 ]; then
        ps1_time=" \[$D_ORANGE\][\[$RESET\]${elapsed_ms}ms\[$D_ORANGE\]]\[$RESET\]"
    fi
    
    # Prompt character
    local ps1_char="\n\[$D_ORANGE\]λ \[$RESET\]"
    
    export PS1="${ps1_exit}${ps1_user}${ps1_host}${ps1_cwd}${ps1_git}${ps1_time}${ps1_char}"
}

export PROMPT_COMMAND="_update_ps1"

# Run nerdfetch if available
# https://github.com/thatonecalculator/nerdfetch
command -v nerdfetch &>/dev/null && nerdfetch
echo

# Source local bashrc if it exists
if [ -f "$HOME/.bashrc_local" ]; then
    # Redirect stderr to /dev/null to avoid errors if the file doesn't exist
    source "$HOME/.bashrc_local" 2>/dev/null
fi
true