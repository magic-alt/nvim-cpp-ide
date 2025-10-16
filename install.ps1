# install.ps1 - Neovim/Vim C/C++ IDE Installer for Windows
Param(
  [string]$Repo = "magic-alt/nvim-cpp-ide"
)

$ErrorActionPreference = "Stop"

$destNvim = "$HOME\AppData\Local\nvim"
$destVim1 = "$HOME\vimfiles\my_configs.vim"      # gVim
$destVim2 = "$HOME\.vim\my_configs.vim"          # WSL/MinGW

Write-Host "[1/4] Backup old configs..." -ForegroundColor Cyan
if (Test-Path $destNvim) { 
    $backupName = "$destNvim.bak.$([DateTime]::Now.ToString('yyyyMMdd-HHmmss'))"
    Write-Host "  Backing up existing config to: $backupName" -ForegroundColor Yellow
    Rename-Item $destNvim $backupName
}

Write-Host "[2/4] Clone repo..." -ForegroundColor Cyan
$tmp = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
try {
    git clone --depth 1 "https://github.com/$Repo.git" $tmp 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Git clone failed. Please ensure git is installed and you have internet connection."
    }
} catch {
    Write-Error "Failed to clone repository: $_"
    exit 1
}

Write-Host "[3/4] Install config.vim..." -ForegroundColor Cyan
$configSource = Join-Path $tmp "config.vim"
if (-not (Test-Path $configSource)) {
    Write-Error "config.vim not found in repository!"
    exit 1
}

# Install for Neovim
New-Item -ItemType Directory -Force -Path $destNvim | Out-Null
Copy-Item -Force $configSource "$destNvim\init.vim"
Write-Host "  Installed to: $destNvim\init.vim" -ForegroundColor Green

# Install for gVim (optional)
try {
    New-Item -ItemType Directory -Force -Path (Split-Path $destVim1) -ErrorAction SilentlyContinue | Out-Null
    Copy-Item -Force $configSource $destVim1 -ErrorAction SilentlyContinue
    Write-Host "  Installed to: $destVim1" -ForegroundColor Green
} catch {
    Write-Host "  Skipped gVim location (optional)" -ForegroundColor DarkGray
}

# Install for WSL/MinGW Vim (optional)
try {
    New-Item -ItemType Directory -Force -Path (Split-Path $destVim2) -ErrorAction SilentlyContinue | Out-Null
    Copy-Item -Force $configSource $destVim2 -ErrorAction SilentlyContinue
    Write-Host "  Installed to: $destVim2" -ForegroundColor Green
} catch {
    Write-Host "  Skipped WSL/MinGW location (optional)" -ForegroundColor DarkGray
}

# Cleanup
Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue

Write-Host "[4/4] Done! Open nvim/vim to bootstrap plugins." -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Run: nvim (or vim)" -ForegroundColor White
Write-Host "  2. Wait for plugins to install automatically" -ForegroundColor White
Write-Host "  3. Restart nvim/vim after plugin installation completes" -ForegroundColor White