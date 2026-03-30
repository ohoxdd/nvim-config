#!/usr/bin/env bash
# install.sh — Bootstrap dotfiles on a fresh machine (Linux, macOS, WSL)
# Usage:  bash install.sh [--dry-run]
set -euo pipefail

# ── Colour helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${BLUE}[INFO]${RESET}  $*"; }
ok()      { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
err()     { echo -e "${RED}[ERR]${RESET}   $*" >&2; }
section() { echo -e "\n${BOLD}══ $* ══${RESET}"; }

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true && warn "Dry-run mode — no changes will be made."

run() {
    if $DRY_RUN; then echo "  (dry) $*"; else eval "$@"; fi
}

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Detect OS / environment ───────────────────────────────────────────────────
section "Environment detection"
OS="linux"
PKG_MGR=""

if [[ "$(uname)" == "Darwin" ]]; then
    OS="macos"
elif grep -qi microsoft /proc/version 2>/dev/null; then
    OS="wsl"
    info "WSL detected"
fi

info "OS: $OS"

if [[ "$OS" == "macos" ]]; then
    if ! command -v brew &>/dev/null; then
        warn "Homebrew not found — installing..."
        run '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    fi
    PKG_MGR="brew install"
else
    if command -v apt-get &>/dev/null; then
        run "sudo apt-get update -qq"
        PKG_MGR="sudo apt-get install -y"
    elif command -v pacman &>/dev/null; then
        PKG_MGR="sudo pacman -S --noconfirm"
    elif command -v dnf &>/dev/null; then
        PKG_MGR="sudo dnf install -y"
    else
        err "No supported package manager found (apt/pacman/dnf). Install dependencies manually."
        exit 1
    fi
fi
ok "Package manager: ${PKG_MGR%% *}"

# ── Install core dependencies ─────────────────────────────────────────────────
section "Core dependencies"

install_if_missing() {
    local cmd="$1"; shift
    if ! command -v "$cmd" &>/dev/null; then
        info "Installing $cmd..."
        run "$PKG_MGR $*"
    else
        ok "$cmd already installed ($(command -v "$cmd"))"
    fi
}

install_if_missing git    git
install_if_missing curl   curl
install_if_missing unzip  unzip
install_if_missing tar    tar

# Neovim — prefer latest stable
section "Neovim"
if ! command -v nvim &>/dev/null; then
    info "Installing Neovim..."
    if [[ "$OS" == "macos" ]]; then
        run "brew install neovim"
    elif [[ "$OS" == "wsl" ]] || [[ "$OS" == "linux" ]]; then
        # Use the AppImage for a version-independent install on Linux/WSL
        NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
        run "curl -L '$NVIM_URL' -o /tmp/nvim.tar.gz"
        run "sudo tar -C /opt -xzf /tmp/nvim.tar.gz"
        run "sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim"
        run "rm /tmp/nvim.tar.gz"
    fi
else
    NVIM_VER=$(nvim --version | head -1)
    ok "Neovim already installed — $NVIM_VER"
fi

# Node.js (needed by many LSPs and markdown-preview)
section "Node.js"
if ! command -v node &>/dev/null; then
    info "Installing Node.js via nvm..."
    run 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash'
    # Source nvm so we can use it immediately
    export NVM_DIR="$HOME/.nvm"
    # shellcheck disable=SC1090
    [ -s "$NVM_DIR/nvm.sh" ] && run ". '$NVM_DIR/nvm.sh'"
    run "nvm install --lts"
else
    ok "Node.js $(node --version) already installed"
fi

# ripgrep (for Telescope live_grep)
install_if_missing rg ripgrep

# fd (for Telescope file finder — much faster than find)
if [[ "$OS" == "macos" ]]; then
    install_if_missing fd fd
else
    install_if_missing fdfind fd-find || install_if_missing fd fd
fi

# Optional: OpenCode
section "OpenCode (optional)"
if ! command -v opencode &>/dev/null; then
    warn "opencode not found. Install from https://opencode.ai when ready."
    warn "After installing, <leader>oc in nvim will open it automatically."
else
    ok "opencode $(opencode --version 2>/dev/null || echo '') found"
fi

# ── Java tools (optional) ─────────────────────────────────────────────────────
section "Java (optional)"
if ! command -v java &>/dev/null; then
    warn "Java not found. Install a JDK if you need Java support:"
    if [[ "$OS" == "macos" ]]; then
        warn "  brew install temurin  (via Homebrew Cask)"
    else
        warn "  sudo apt install default-jdk  (or your distro equivalent)"
    fi
else
    ok "Java $(java -version 2>&1 | head -1)"
fi

# ── Symlink dotfiles ──────────────────────────────────────────────────────────
section "Symlinking dotfiles"

symlink() {
    local src="$1"
    local dst="$2"
    local dst_dir
    dst_dir="$(dirname "$dst")"

    if [[ ! -d "$dst_dir" ]]; then
        run "mkdir -p '$dst_dir'"
    fi

    if [[ -e "$dst" && ! -L "$dst" ]]; then
        local bak="${dst}.bak.$(date +%Y%m%d_%H%M%S)"
        warn "Backing up existing $dst → $bak"
        run "mv '$dst' '$bak'"
    fi

    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
        ok "$dst already linked"
    else
        run "ln -sf '$src' '$dst'"
        ok "Linked $src → $dst"
    fi
}

# nvim
symlink "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

# Add more symlinks here as your dotfiles grow, e.g.:
# symlink "$DOTFILES_DIR/kitty"    "$HOME/.config/kitty"
# symlink "$DOTFILES_DIR/tmux"     "$HOME/.config/tmux"
# symlink "$DOTFILES_DIR/.zshrc"   "$HOME/.zshrc"

# ── First-run nvim setup ──────────────────────────────────────────────────────
section "Neovim plugin bootstrap"
if command -v nvim &>/dev/null && ! $DRY_RUN; then
    info "Running headless Neovim to install lazy.nvim plugins..."
    # +qa exits after lazy finishes
    nvim --headless "+Lazy! sync" +qa 2>&1 | tail -5 || true
    ok "Plugins installed"
else
    $DRY_RUN && warn "(dry) Skipping nvim headless bootstrap"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
section "All done"
echo -e "${GREEN}${BOLD}Dotfiles installed successfully!${RESET}"
echo ""
echo "  • Open nvim and wait for LSP servers to install via Mason."
echo "  • If on WSL, add to your ~/.bashrc / ~/.zshrc:"
echo "      export DISPLAY=:0   # only needed for GUI-forwarded apps"
echo ""
echo "  Keymaps added by this config:"
echo "    <leader>oc   — Toggle OpenCode floating terminal"
echo "    <leader>mr   — Toggle in-buffer Markdown render"
echo "    <leader>mp   — Open Markdown browser preview"
echo "    <leader>xd   — Toggle LSP diagnostics"
echo "    <C-n>        — Toggle Neo-tree file explorer"
echo "    <C-p>        — Telescope file picker"
echo "    <leader>fg   — Telescope live grep"
