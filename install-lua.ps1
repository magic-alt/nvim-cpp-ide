# install-lua.ps1 - Neovim C/C++ IDE Installer (Lua version) for Windows
Param(
  [string]$Repo = "magic-alt/nvim-cpp-ide"
)

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'  # Speed up web requests

$destNvim = "$HOME\AppData\Local\nvim"

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Neovim C/C++ IDE Installer (Lua + LSP Edition)               ║" -ForegroundColor Cyan
Write-Host "║  Modern configuration with lazy.nvim, LSP, and nvim-cmp       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/4] Backup old configs..." -ForegroundColor Cyan
if (Test-Path $destNvim) { 
    $backupName = "$destNvim.bak.$([DateTime]::Now.ToString('yyyyMMdd-HHmmss'))"
    Write-Host "  Backing up existing config to:" -ForegroundColor Yellow
    Write-Host "  $backupName" -ForegroundColor DarkYellow
    Rename-Item $destNvim $backupName
    Write-Host "  ✓ Backup created" -ForegroundColor Green
}

Write-Host "[2/4] Clone repo..." -ForegroundColor Cyan
$tmp = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())

# Find working Git installation
$gitExe = $null
$gitPaths = @(
    "C:\Program Files\Git\cmd\git.exe",
    "C:\Program Files (x86)\Git\cmd\git.exe",
    "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe",
    "git"  # Try PATH
)

foreach ($gitPath in $gitPaths) {
    try {
        $testGit = if ($gitPath -eq "git") { "git" } else { $gitPath }
        $null = & $testGit --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $gitExe = $testGit
            if ($gitPath -ne "git") {
                Write-Host "  Using: $gitPath" -ForegroundColor DarkGray
            }
            break
        }
    } catch {
        continue
    }
}

if (-not $gitExe) {
    Write-Error "Git not found. Please install Git: winget install Git.Git"
    exit 1
}

try {
    Write-Host "  Cloning repository..." -ForegroundColor DarkGray
    $cloneArgs = @("clone", "--depth", "1", "https://github.com/$Repo.git", $tmp)
    
    if ($gitExe -eq "git") {
        & git $cloneArgs 2>&1 | Out-Null
    } else {
        & $gitExe $cloneArgs 2>&1 | Out-Null
    }
    
    if ($LASTEXITCODE -ne 0) {
        throw "Git clone failed (exit code: $LASTEXITCODE)"
    }
    
    Write-Host "  ✓ Clone successful" -ForegroundColor Green
} catch {
    Write-Error "Failed to clone repository: $_"
    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "  • Ensure Git is installed: winget install Git.Git" -ForegroundColor White
    Write-Host "  • Check internet connection" -ForegroundColor White
    Write-Host "  • Try: git config --global http.sslVerify true" -ForegroundColor White
    exit 1
}

Write-Host "[3/4] Install init.lua..." -ForegroundColor Cyan
$luaSource = Join-Path $tmp "init.lua"
if (-not (Test-Path $luaSource)) {
    Write-Error "init.lua not found in repository!"
    exit 1
}

# Install for Neovim
New-Item -ItemType Directory -Force -Path $destNvim | Out-Null
Copy-Item -Force $luaSource "$destNvim\init.lua"
Write-Host "  ✓ Installed to: $destNvim\init.lua" -ForegroundColor Green

# Cleanup
Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue

Write-Host "[4/4] Installation complete!" -ForegroundColor Green
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║  Next Steps:                                                   ║" -ForegroundColor Yellow
Write-Host "╠════════════════════════════════════════════════════════════════╣" -ForegroundColor Yellow
Write-Host "║  1. Run: nvim                                                  ║" -ForegroundColor White
Write-Host "║     First launch will auto-install plugins (wait ~2 minutes)  ║" -ForegroundColor DarkGray
Write-Host "║                                                                ║" -ForegroundColor White
Write-Host "║  2. Install LSP servers (in Neovim):                          ║" -ForegroundColor White
Write-Host "║     :Mason                                                     ║" -ForegroundColor Cyan
Write-Host "║     Then press 'i' on:                                        ║" -ForegroundColor DarkGray
Write-Host "║       - clangd (C/C++)                                        ║" -ForegroundColor DarkGray
Write-Host "║       - lua-language-server (Lua)                            ║" -ForegroundColor DarkGray
Write-Host "║       - clang-format (formatting)                            ║" -ForegroundColor DarkGray
Write-Host "║                                                                ║" -ForegroundColor White
Write-Host "║  3. Check health: :checkhealth                                ║" -ForegroundColor White
Write-Host "║                                                                ║" -ForegroundColor White
Write-Host "║  4. Learn keybindings: Press <Space> in normal mode           ║" -ForegroundColor White
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
Write-Host ""
Write-Host "📖 Read LUA_MIGRATION_GUIDE.md for detailed migration guide!" -ForegroundColor Magenta
Write-Host ""
