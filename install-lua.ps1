Param(
  [switch]$Local,
  [switch]$FirstLaunchOnly,
  [switch]$SkipFirstLaunch,
  [switch]$NoBackup,
  [string]$Repo = "magic-alt/nvim-cpp-ide",
  [string]$SourcePath
)

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

$destNvim = "$HOME\AppData\Local\nvim"
$initLuaPath = "$destNvim\init.lua"
$scriptRoot = $PSScriptRoot
if (-not $scriptRoot -and $MyInvocation.MyCommand.Path) {
  $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Write-Header {
  Write-Host "╔════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
  Write-Host "║  Neovim C/C++ IDE Installer (Lua Edition, Neovim 0.11+)       ║" -ForegroundColor Cyan
  Write-Host "╚════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
  Write-Host ""
}

function Ensure-Git {
  if ($script:GitExe) { return $script:GitExe }

  $gitPaths = @(
    "C:\\Program Files\\Git\\cmd\\git.exe",
    "C:\\Program Files (x86)\\Git\\cmd\\git.exe",
    "$env:LOCALAPPDATA\\Programs\\Git\\cmd\\git.exe",
    "git"
  )

  foreach ($gitCandidate in $gitPaths) {
    try {
      $testGit = if ($gitCandidate -eq "git") { "git" } else { $gitCandidate }
      $null = & $testGit --version 2>&1
      if ($LASTEXITCODE -eq 0) {
        $script:GitExe = $testGit
        if ($gitCandidate -ne "git") {
          Write-Host "  Using Git at: $gitCandidate" -ForegroundColor DarkGray
        }
        return $script:GitExe
      }
    } catch {
      continue
    }
  }

  throw "Git not found. Install it first: winget install Git.Git"
}

function Backup-NvimConfig {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return }

  $backupName = "$Path.bak.$([DateTime]::Now.ToString('yyyyMMdd-HHmmss'))"
  Write-Host "  Backing up existing config to:" -ForegroundColor Yellow
  Write-Host "  $backupName" -ForegroundColor DarkYellow
  Rename-Item $Path $backupName
  Write-Host "  ✓ Backup created" -ForegroundColor Green
}

function Install-FromLocal {
  param([string]$SourceRoot, [string]$Destination)

  if (-not $SourceRoot) {
    throw "Local mode requires -SourcePath or running from a saved script file."
  }

  $initSource = Join-Path $SourceRoot "init.lua"
  if (-not (Test-Path $initSource)) {
    throw "init.lua not found at: $SourceRoot"
  }

  New-Item -ItemType Directory -Force -Path $Destination | Out-Null
  Copy-Item -Force $initSource (Join-Path $Destination "init.lua")
  Write-Host "  ✓ Copied init.lua from $SourceRoot" -ForegroundColor Green
}

function Install-FromRemote {
  param([string]$RepoName, [string]$Destination, [string]$GitExe)

  $tmp = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
  Write-Host "[2/3] Clone repo..." -ForegroundColor Cyan

  try {
    Write-Host "  Cloning https://github.com/$RepoName.git" -ForegroundColor DarkGray
    $cloneArgs = @("clone", "--depth", "1", "https://github.com/$RepoName.git", $tmp)

    if ($GitExe -eq "git") {
      & git $cloneArgs 2>&1 | Out-Null
    } else {
      & $GitExe $cloneArgs 2>&1 | Out-Null
    }

    if ($LASTEXITCODE -ne 0) {
      throw "Git clone failed (exit code: $LASTEXITCODE)"
    }

    $initSource = Join-Path $tmp "init.lua"
    if (-not (Test-Path $initSource)) {
      throw "init.lua not found in repository!"
    }

    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    Copy-Item -Force $initSource (Join-Path $Destination "init.lua")
    Write-Host "  ✓ Installed to: $Destination\init.lua" -ForegroundColor Green
  } finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
  }
}

function Invoke-FirstLaunch {
  param([string]$InitPath, [string]$GitExe)

  Write-Host "[First Launch] Preparing environment..." -ForegroundColor Cyan

  if (-not (Test-Path $InitPath)) {
    throw "init.lua not found at: $InitPath"
  }
  Write-Host "  ✓ Found init.lua" -ForegroundColor Green

  $nvimCmd = Get-Command nvim -ErrorAction SilentlyContinue
  if (-not $nvimCmd) {
    throw "Neovim (nvim) not found in PATH. Install Neovim 0.11+ and rerun with -FirstLaunchOnly."
  }

  $nvimData = "$env:LOCALAPPDATA\nvim-data"
  $lazyPath = "$nvimData\lazy\lazy.nvim"

  if (-not (Test-Path $lazyPath)) {
    Write-Host "  Installing lazy.nvim plugin manager..." -ForegroundColor Cyan
    New-Item -ItemType Directory -Force -Path (Split-Path $lazyPath) | Out-Null

    $cloneArgs = @("clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", $lazyPath)
    try {
      if ($GitExe -eq "git") {
        & git $cloneArgs 2>&1 | Out-Null
      } else {
        & $GitExe $cloneArgs 2>&1 | Out-Null
      }
      if ($LASTEXITCODE -ne 0) {
        throw "lazy.nvim clone failed (exit code: $LASTEXITCODE)"
      }
      Write-Host "  ✓ lazy.nvim installed" -ForegroundColor Green
    } catch {
      throw "无法安装 lazy.nvim：$_"
    }
  } else {
    Write-Host "  ✓ lazy.nvim already present" -ForegroundColor Green
  }

  Write-Host "  Synchronizing plugins (Lazy! sync)..." -ForegroundColor Cyan
  try {
    $syncOutput = & $nvimCmd.Source --headless "+Lazy! sync" +qa 2>&1
    if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) {
      Write-Host "  ✓ Plugin sync completed" -ForegroundColor Green
    } else {
      Write-Host "  ⚠️  Sync completed with warnings (exit code: $LASTEXITCODE)" -ForegroundColor Yellow
      if ($syncOutput) {
        Write-Host $syncOutput -ForegroundColor DarkYellow
      }
    }
  } catch {
    Write-Host "  ⚠️  Failed to run Lazy sync" -ForegroundColor Yellow
    Write-Host $_.Exception.Message -ForegroundColor DarkYellow
  }

  $pluginRoot = "$nvimData\lazy"
  $pluginDirs = Get-ChildItem -Path $pluginRoot -Directory -ErrorAction SilentlyContinue
  if ($pluginDirs) {
    Write-Host "  ✓ Detected $($pluginDirs.Count) plugins" -ForegroundColor Green
    $pluginDirs | Select-Object -First 10 | ForEach-Object {
      Write-Host "    - $($_.Name)" -ForegroundColor DarkGray
    }
    if ($pluginDirs.Count -gt 10) {
      Write-Host "    ... and $($pluginDirs.Count - 10) more" -ForegroundColor DarkGray
    }
  } else {
    Write-Host "  ⚠️  No plugins detected under $pluginRoot" -ForegroundColor Yellow
  }

  Write-Host ""
  Write-Host "Next steps:" -ForegroundColor Cyan
  Write-Host "  1. Launch Neovim: nvim" -ForegroundColor White
  Write-Host "  2. Install recommended LSP servers (in Neovim):" -ForegroundColor White
  Write-Host "     :MasonInstall clangd lua-language-server clang-format stylua" -ForegroundColor DarkGray
  Write-Host "  3. Run health checks: :checkhealth" -ForegroundColor White
  Write-Host "  4. Explore keybindings: press <Space> (which-key)" -ForegroundColor White
}

if ($FirstLaunchOnly -and $SkipFirstLaunch) {
  throw "-FirstLaunchOnly cannot be combined with -SkipFirstLaunch"
}

Write-Header

if (-not $FirstLaunchOnly) {
  Write-Host "[1/3] Backup old configs..." -ForegroundColor Cyan
  if (-not $NoBackup) {
    Backup-NvimConfig -Path $destNvim
  } elseif (-not (Test-Path $destNvim)) {
    Write-Host "  No existing config found" -ForegroundColor DarkGray
  } else {
    Write-Host "  Skipping backup as requested" -ForegroundColor Yellow
    Remove-Item -Recurse -Force $destNvim
  }

  if ($Local) {
    Write-Host "[2/3] Install init.lua from local path..." -ForegroundColor Cyan
    $resolvedSource = if ($SourcePath) { $SourcePath } else { $scriptRoot }
    Install-FromLocal -SourceRoot $resolvedSource -Destination $destNvim
  } else {
    $gitExe = Ensure-Git
    Install-FromRemote -RepoName $Repo -Destination $destNvim -GitExe $gitExe
  }

  Write-Host "[3/3] Installation complete" -ForegroundColor Green
  Write-Host ""
}

if ($SkipFirstLaunch) {
  Write-Host "Skipping first-launch bootstrap as requested (-SkipFirstLaunch)." -ForegroundColor Yellow
} else {
  $gitExeForBootstrap = Ensure-Git
  Invoke-FirstLaunch -InitPath $initLuaPath -GitExe $gitExeForBootstrap
}

Write-Host ""
Write-Host "All done!" -ForegroundColor Green
