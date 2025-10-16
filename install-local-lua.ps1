# install-local-lua.ps1 - Local test installer (Lua version)
$ErrorActionPreference = "Stop"

$destNvim = "$HOME\AppData\Local\nvim"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Neovim C/C++ IDE Local Installer (Lua Edition)               ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/3] Backup old configs..." -ForegroundColor Cyan
if (Test-Path $destNvim) { 
    $backupName = "$destNvim.bak.$([DateTime]::Now.ToString('yyyyMMdd-HHmmss'))"
    Write-Host "  Backing up to: $backupName" -ForegroundColor Yellow
    Rename-Item $destNvim $backupName
    Write-Host "  ✓ Backup created" -ForegroundColor Green
}

Write-Host "[2/3] Install init.lua..." -ForegroundColor Cyan
$luaSource = Join-Path $scriptPath "init.lua"
if (-not (Test-Path $luaSource)) {
    Write-Error "init.lua not found in: $scriptPath"
    exit 1
}

New-Item -ItemType Directory -Force -Path $destNvim | Out-Null
Copy-Item -Force $luaSource "$destNvim\init.lua"
Write-Host "  ✓ Installed: $destNvim\init.lua" -ForegroundColor Green

Write-Host "[3/3] Done!" -ForegroundColor Green
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
Write-Host "║  ⚠️  重要: 首次启动需要额外设置！                            ║" -ForegroundColor Yellow
Write-Host "╠════════════════════════════════════════════════════════════════╣" -ForegroundColor Yellow
Write-Host "║  请运行首次启动助手来完成插件安装:                          ║" -ForegroundColor White
Write-Host "║                                                                ║" -ForegroundColor White
Write-Host "║  .\first-launch.ps1                                            ║" -ForegroundColor Cyan
Write-Host "║                                                                ║" -ForegroundColor White
Write-Host "║  这将自动安装 lazy.nvim 和所有插件 (~2-5 分钟)              ║" -ForegroundColor DarkGray
Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
Write-Host ""
Write-Host "或者手动启动 Neovim (需要等待插件自动安装):" -ForegroundColor DarkGray
Write-Host "  nvim" -ForegroundColor DarkGray
Write-Host ""
Write-Host "📖 详细指南: FIRST_LAUNCH_GUIDE.md" -ForegroundColor Magenta
