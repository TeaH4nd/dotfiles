#!/usr/bin/env bash
set -euo pipefail

export DOTFILES_DIR
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Color support ───────────────────────────────────────────────────────────

USE_COLOR=true

setup_colors() {
    if [[ "$USE_COLOR" == true ]] && [[ -t 1 ]] && [[ "${TERM:-dumb}" != "dumb" ]]; then
        RED='\033[0;31m'
        GREEN='\033[0;32m'
        YELLOW='\033[0;33m'
        BLUE='\033[0;34m'
        MAGENTA='\033[0;35m'
        CYAN='\033[0;36m'
        BOLD='\033[1m'
        DIM='\033[2m'
        REVERSE='\033[7m'
        RESET='\033[0m'
    else
        RED='' GREEN='' YELLOW='' BLUE='' MAGENTA='' CYAN=''
        BOLD='' DIM='' REVERSE='' RESET=''
    fi
}

# ─── TUI helpers ─────────────────────────────────────────────────────────────

banner() {
    echo
    echo -e "${CYAN}${BOLD}"
    echo '    ╔══════════════════════════════════════╗'
    echo '    ║         ·  D O T F I L E S  ·        ║'
    echo '    ║           setup & installer          ║'
    echo '    ╚══════════════════════════════════════╝'
    echo -e "${RESET}"
}

header() {
    local title="$1"
    local width=40
    local pad=$(( (width - ${#title} - 2) / 2 ))
    local line=""
    for ((i = 0; i < pad; i++)); do line+="═"; done
    echo
    echo -e "${BOLD}${BLUE}  ${line} ${title} ${line}${RESET}"
}

info()    { echo -e "  ${BLUE}ℹ${RESET}  $*"; }
success() { echo -e "  ${GREEN}✓${RESET}  $*"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET}  $*"; }
error()   { echo -e "  ${RED}✗${RESET}  $*"; }

spinner() {
    local msg="$1"
    shift
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local log
    log=$(mktemp)

    "$@" >"$log" 2>&1 &
    local pid=$!
    local i=0

    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${CYAN}%s${RESET}  %s" "${frames[i++ % ${#frames[@]}]}" "$msg"
        sleep 0.08
    done

    wait "$pid"
    local exit_code=$?
    printf "\r"

    if [[ $exit_code -eq 0 ]]; then
        success "$msg"
    else
        error "$msg"
        if [[ -s "$log" ]]; then
            echo -e "    ${DIM}$(head -5 "$log")${RESET}"
        fi
    fi

    rm -f "$log"
    return $exit_code
}

# ─── Checkbox menu ───────────────────────────────────────────────────────────

# checkbox_menu LABEL_ARRAY RESULT_ARRAY
# Presents an interactive checkbox list. Writes selected indices into RESULT_ARRAY.
# Controls: ↑/↓ navigate, Space toggles, a selects all, n deselects all, Enter confirms.
checkbox_menu() {
    local -n _labels=$1
    local -n _result=$2
    local count=${#_labels[@]}
    local cursor=0
    local -a checked
    for ((i = 0; i < count; i++)); do checked[i]=0; done

    # Hide cursor
    printf '\033[?25l'
    # Ensure cursor is restored on exit/interrupt
    trap 'printf "\033[?25h"' RETURN

    # Draw initial list
    _draw_menu() {
        for ((i = 0; i < count; i++)); do
            local marker="  "
            [[ $i -eq $cursor ]] && marker="${CYAN}❯${RESET} " || marker="  "

            local box="[ ]"
            [[ ${checked[i]} -eq 1 ]] && box="${GREEN}[x]${RESET}" || box="${DIM}[ ]${RESET}"

            local label="${_labels[i]}"
            if [[ $i -eq $cursor ]]; then
                echo -e "${marker}${box} ${BOLD}${label}${RESET}"
            else
                echo -e "${marker}${box} ${label}"
            fi
        done
        echo
        echo -e "  ${DIM}[↑/↓] navigate · [space] toggle · [a] all · [n] none · [enter] confirm${RESET}"
    }

    # Move cursor up to redraw
    _clear_menu() {
        # count lines + 1 blank + 1 help line
        for ((i = 0; i < count + 2; i++)); do
            printf '\033[A\033[2K'
        done
    }

    _draw_menu

    while true; do
        local key
        IFS= read -rsn1 key

        case "$key" in
            $'\x1b')
                read -rsn2 -t 0.01 key
                case "$key" in
                    '[A') # Up
                        ((cursor > 0)) && ((cursor--)) || true
                        ;;
                    '[B') # Down
                        ((cursor < count - 1)) && ((cursor++)) || true
                        ;;
                esac
                ;;
            ' ') # Space — toggle
                if [[ ${checked[cursor]} -eq 0 ]]; then
                    checked[cursor]=1
                else
                    checked[cursor]=0
                fi
                ;;
            'a'|'A') # Select all
                for ((i = 0; i < count; i++)); do checked[i]=1; done
                ;;
            'n'|'N') # Deselect all
                for ((i = 0; i < count; i++)); do checked[i]=0; done
                ;;
            '') # Enter — confirm
                break
                ;;
        esac

        _clear_menu
        _draw_menu
    done

    # Show cursor
    printf '\033[?25h'

    # Build result array
    _result=()
    for ((i = 0; i < count; i++)); do
        [[ ${checked[i]} -eq 1 ]] && _result+=("$i") || true
    done
}

# ─── Component functions ─────────────────────────────────────────────────────

COMPONENT_NAMES=(
    "Update dotfiles"
    "Install Vim"
    "Vim color scheme"
    "Install Vundle"
    "Install Tmux"
    "Install TPM"
    "Symlink dotfiles"
)

# Status tracking: skipped / installed / already_present / failed
declare -A STATUS

do_update_dotfiles() {
    header "Update Dotfiles"
    if command -v git &>/dev/null && [[ -d "$DOTFILES_DIR/.git" ]]; then
        if spinner "Pulling latest changes" \
            git --work-tree="$DOTFILES_DIR" --git-dir="$DOTFILES_DIR/.git" pull --ff-only; then
            STATUS["Update dotfiles"]="updated"
        else
            STATUS["Update dotfiles"]="failed"
        fi
    else
        warn "Not a git repository or git not found — skipping"
        STATUS["Update dotfiles"]="failed"
    fi
}

do_install_vim() {
    header "Vim"
    if command -v vim &>/dev/null; then
        success "Vim is already installed"
        STATUS["Install Vim"]="already_present"
    else
        info "Installing Vim..."
        if sudo apt install -y vim; then
            success "Vim installed"
            STATUS["Install Vim"]="installed"
        else
            error "Failed to install Vim"
            STATUS["Install Vim"]="failed"
        fi
    fi
}

do_vim_colorscheme() {
    header "Vim Color Scheme"
    mkdir -p "$HOME/.vim/colors"
    if cp "$DOTFILES_DIR/colors/"* "$HOME/.vim/colors/" 2>/dev/null; then
        success "Color scheme copied to ~/.vim/colors/"
        STATUS["Vim color scheme"]="installed"
    else
        error "Failed to copy color scheme"
        STATUS["Vim color scheme"]="failed"
    fi
}

do_install_vundle() {
    header "Vundle"
    if [[ -d "$HOME/.vim/bundle/Vundle.vim" ]]; then
        success "Vundle is already installed"
        STATUS["Install Vundle"]="already_present"
    else
        if spinner "Cloning Vundle" \
            git clone https://github.com/VundleVim/Vundle.vim.git "$HOME/.vim/bundle/Vundle.vim"; then
            STATUS["Install Vundle"]="installed"
        else
            STATUS["Install Vundle"]="failed"
        fi
    fi
}

do_install_tmux() {
    header "Tmux"
    if command -v tmux &>/dev/null; then
        success "Tmux is already installed"
        STATUS["Install Tmux"]="already_present"
    else
        info "Installing Tmux..."
        if sudo apt install -y tmux; then
            success "Tmux installed"
            STATUS["Install Tmux"]="installed"
        else
            error "Failed to install Tmux"
            STATUS["Install Tmux"]="failed"
        fi
    fi
}

do_install_tpm() {
    header "TPM (Tmux Plugin Manager)"
    if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
        success "TPM is already installed"
        STATUS["Install TPM"]="already_present"
    else
        if spinner "Cloning TPM" \
            git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"; then
            STATUS["Install TPM"]="installed"
        else
            STATUS["Install TPM"]="failed"
        fi
    fi
}

do_symlink_dotfiles() {
    header "Symlink Dotfiles"
    local files=(.bashrc .vimrc .tmux.conf)
    local all_ok=true
    for f in "${files[@]}"; do
        if [[ -f "$DOTFILES_DIR/$f" ]]; then
            ln -sf "$DOTFILES_DIR/$f" "$HOME/$f"
            success "$f → ~/$f"
        else
            warn "$f not found in dotfiles repo — skipping"
            all_ok=false
        fi
    done
    if [[ "$all_ok" == true ]]; then
        STATUS["Symlink dotfiles"]="installed"
    else
        STATUS["Symlink dotfiles"]="partial"
    fi
}

# Map indices to functions
COMPONENT_FUNCS=(
    do_update_dotfiles
    do_install_vim
    do_vim_colorscheme
    do_install_vundle
    do_install_tmux
    do_install_tpm
    do_symlink_dotfiles
)

# ─── Summary ─────────────────────────────────────────────────────────────────

print_summary() {
    header "Summary"
    echo

    for name in "${COMPONENT_NAMES[@]}"; do
        local status="${STATUS[$name]:-skipped}"
        local icon color label
        case "$status" in
            installed)      icon="✓"; color="$GREEN";  label="Installed";;
            updated)        icon="✓"; color="$GREEN";  label="Updated";;
            already_present) icon="·"; color="$CYAN";  label="Already present";;
            partial)        icon="⚠"; color="$YELLOW"; label="Partial";;
            failed)         icon="✗"; color="$RED";    label="Failed";;
            skipped)        icon="–"; color="$DIM";    label="Skipped";;
        esac
        printf "  ${color}%s${RESET}  %-25s ${color}%s${RESET}\n" "$icon" "$name" "$label"
    done
    echo
}

# ─── CLI parsing ─────────────────────────────────────────────────────────────

RUN_ALL=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --all)      RUN_ALL=true ;;
        --no-color) USE_COLOR=false ;;
        -h|--help)
            echo "Usage: $(basename "$0") [OPTIONS]"
            echo
            echo "Options:"
            echo "  --all        Install everything (skip selection menu)"
            echo "  --no-color   Disable colored output"
            echo "  -h, --help   Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
    shift
done

# ─── Main ────────────────────────────────────────────────────────────────────

setup_colors
banner

if [[ "$RUN_ALL" == true ]]; then
    info "Running all components (--all)"
    selected=()
    for ((i = 0; i < ${#COMPONENT_NAMES[@]}; i++)); do selected+=("$i"); done
else
    echo -e "  ${BOLD}Select components to set up:${RESET}"
    echo
    checkbox_menu COMPONENT_NAMES selected
fi

if [[ ${#selected[@]} -eq 0 ]]; then
    warn "Nothing selected — exiting."
    exit 0
fi

for idx in "${selected[@]}"; do
    ${COMPONENT_FUNCS[$idx]}
done

print_summary

