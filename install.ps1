# install.ps1 — Bootstrap Neovim config on Windows
# Usage: .\install.ps1 [-WhatIf]
# Requirements: PowerShell 7+ recommended (pwsh), or PowerShell 5.1 with remoteSigned policy

param(
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"

# Colors
function Write-Info { Write-Host "[INFO]   " -NoNewline -ForegroundColor Cyan; Write-Host $args[0] }
function Write-Ok    { Write-Host "[OK]     " -NoNewline -ForegroundColor Green; Write-Host $args[0] }
function Write-Warn { Write-Host "[WARN]   " -NoNewline -ForegroundColor Yellow; Write-Host $args[0] }
function Write-Err  { Write-Host "[ERR]    " -NoNewline -ForegroundColor Red; Write-Host $args[0] }

function Run {
    param([string]$Cmd)
    if ($WhatIf) {
        Write-Host "  (WhatIf) $Cmd" -ForegroundColor Gray
    } else {
        Write-Debug "Running: $Cmd"
        Invoke-Expression $Cmd
    }
}

$DOTFILES_DIR = $PSScriptRoot
if (-not $DOTFILES_DIR) {
    $DOTFILES_DIR = Get-Location
}

Write-Host ""
Write-Host "══ Windows Setup ═══════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""

# Check if running as Administrator (needed for some installs)
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Detect package manager
$pkgMgr = $null
if (Get-Command winget -ErrorAction SilentlyContinue) {
    $pkgMgr = "winget"
} elseif (Get-Command choco -ErrorAction SilentlyContinue) {
    $pkgMgr = "choco"
} else {
    Write-Warn "No package manager found (winget/choco). Install dependencies manually."
}

# Install if missing helper
function Install-IfMissing {
    param([string]$Cmd, [string]$Pkg, [string]$WingetId, [string]$ChocoId)
    if (Get-Command $Cmd -ErrorAction SilentlyContinue) {
        Write-Ok "$Cmd already installed"
        return
    }

    Write-Info "Installing $Cmd..."
    if ($pkgMgr -eq "winget" -and $WingetId) {
        Run "winget install --id $WingetId --silent --accept-package-agreements --accept-source-agreements"
    } elseif ($pkgMgr -eq "choco" -and $ChocoId) {
        Run "choco install $ChocoId -y"
    } else {
        Write-Warn "  $Cmd not found. Install manually if needed."
    }
}

# Core dependencies
Write-Host "══ Core Dependencies ═══════════════════════════════════════════════" -ForegroundColor Magenta

# Git
Install-IfMissing -Cmd "git" -WingetId "Git.Git" -ChocoId "git"

# Curl (usually comes with Windows)
if (Get-Command curl -ErrorAction SilentlyContinue) {
    Write-Ok "curl available"
} else {
    Write-Warn "curl not found"
}

# Neovim
Write-Host ""
Write-Host "══ Neovim ═══════════════════════════════════════════════════════" -ForegroundColor Magenta

if (Get-Command nvim -ErrorAction SilentlyContinue) {
    $nvimVer = (nvim --version | Select-Object -First 1)
    Write-Ok "Neovim already installed — $nvimVer"
} else {
    Write-Info "Installing Neovim..."
    if ($pkgMgr -eq "winget") {
        Run "winget install --id Neovim.Neovim --silent --accept-package-agreements --accept-source-agreements"
    } elseif ($pkgMgr -eq "choco") {
        Run "choco install neovim -y"
    } else {
        Write-Warn "Install Neovim manually from https://github.com/neovim/neovim/releases"
    }
}

# Node.js
Write-Host ""
Write-Host "══ Node.js ═══════════════════════════════════════════════════════" -ForegroundColor Magenta

if (Get-Command node -ErrorAction SilentlyContinue) {
    Write-Ok "Node.js $(node --version) already installed"
} else {
    Write-Info "Installing Node.js..."
    if ($pkgMgr -eq "winget") {
        Run "winget install OpenJS.NodeJS.LTS --silent --accept-package-agreements --accept-source-agreements"
    } elseif ($pkgMgr -eq "choco") {
        Run "choco install nodejs-lts -y"
    } else {
        Write-Warn "Install Node.js manually from https://nodejs.org"
    }
}

# tree-sitter CLI (for nvim-treesitter)
Write-Host ""
Write-Host "══ tree-sitter CLI ═══════════════════════════════════════════════" -ForegroundColor Magenta

if (Get-Command tree-sitter -ErrorAction SilentlyContinue) {
    Write-Ok "tree-sitter CLI already installed"
} else {
    Write-Info "Installing tree-sitter CLI..."
    if (Get-Command npm -ErrorAction SilentlyContinue) {
        Run "npm install -g tree-sitter-cli"
    } else {
        Write-Warn "npm not found. Install Node.js first, then: npm install -g tree-sitter-cli"
    }
}

# ripgrep (for Telescope live_grep)
Write-Host ""
Write-Host "══ ripgrep ═══════════════════════════════════════════════" -ForegroundColor Magenta

if (Get-Command rg -ErrorAction SilentlyContinue) {
    Write-Ok "ripgrep already installed"
} else {
    Write-Info "Installing ripgrep..."
    if ($pkgMgr -eq "winget") {
        Run "winget install --id BurntSushi.ripgrep.MSVC --silent --accept-package-agreements --accept-source-agreements"
    } elseif ($pkgMgr -eq "choco") {
        Run "choco install ripgrep -y"
    }
}

# fd (for Telescope file finder)
Write-Host ""
Write-Host "══ fd (Telescope) ═══════════════════════════════════════════════" -ForegroundColor Magenta

if (Get-Command fd -ErrorAction SilentlyContinue) {
    Write-Ok "fd already installed"
} else {
    Write-Info "Installing fd..."
    if ($pkgMgr -eq "winget") {
        Run "winget install --id sharkdp.fd --silent --accept-package-agreements --accept-source-agreements"
    } elseif ($pkgMgr -eq "choco") {
        Run "choco install fd -y"
    }
}

# Symlink dotfiles
Write-Host ""
Write-Host "══ Symlinking Config ═══════════════════════════════════════════════" -ForegroundColor Magenta

$targetDir = "$env:USERPROFILE\AppData\Local\nvim"
$sourceDir = $DOTFILES_DIR

if (Test-Path $targetDir) {
    if ((Get-Item $targetDir).LinkType -eq "SymbolicLink") {
        Write-Ok "$targetDir already linked"
    } else {
        $bak = "$targetDir.bak.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Write-Warn "Backing up existing $targetDir -> $bak"
        if (-not $WhatIf) {
            Move-Item $targetDir $bak
        }
        Run "New-Item -ItemType SymbolicLink -Path $targetDir -Target $sourceDir"
        Write-Ok "Linked $sourceDir -> $targetDir"
    }
} else {
    Run "New-Item -ItemType SymbolicLink -Path $targetDir -Target $sourceDir"
    Write-Ok "Linked $sourceDir -> $targetDir"
}

# Refresh environment for newly installed tools
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# First-run nvim setup
Write-Host ""
Write-Host "══ Neovim Plugin Bootstrap ═══════════════════════════════════════════════" -ForegroundColor Magenta

if (Get-Command nvim -ErrorAction SilentlyContinue -and -not $WhatIf) {
    Write-Info "Running headless Neovim to install lazy.nvim plugins..."
    Run "nvim --headless `"+Lazy! sync`" +qa 2>&1 | Select-Object -Last 5"
    Write-Ok "Plugins installed"

    Write-Info "Installing treesitter parsers (this may take a minute)..."
    Run "nvim --headless `"+TSUpdate`" +qa 2>&1 | Select-Object -Last 5"
    Write-Ok "Treesitter parsers installed"
} elseif ($WhatIf) {
    Write-Warn "(WhatIf) Skipping nvim bootstrap"
}

# Done
Write-Host ""
Write-Host "══════════════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "  All done! Your Neovim config is installed." -ForegroundColor Green
Write-Host ""
Write-Host "  Next steps:"
Write-Host "    • Open nvim and wait for LSP servers to install via Mason"
Write-Host "    • Run :TSUpdate in nvim if parsers don't work"
Write-Host ""
Write-Host "  Keymaps added by this config:"
Write-Host "    <leader>oc   — Toggle OpenCode floating terminal"
Write-Host "    <leader>mr   — Toggle in-buffer Markdown render"
Write-Host "    <leader>mp   — Open Markdown browser preview"
Write-Host "    <leader>xd   — Toggle LSP diagnostics"
Write-Host "    <C-n>        — Toggle Neo-tree file explorer"
Write-Host "    <C-p>        — Telescope file picker"
Write-Host "    <leader>fg   — Telescope live grep"
Write-Host ""
