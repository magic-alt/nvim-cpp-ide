Param(
  [switch]$Local,
  [switch]$FirstLaunchOnly,
  [switch]$SkipFirstLaunch,
  [switch]$NoBackup,
  [string]$Repo = "magic-alt/nvim-cpp-ide",
  [string]$SourcePath
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$destNvim = Join-Path $env:LOCALAPPDATA "nvim"
$initLuaPath = Join-Path $destNvim "init.lua"
$scriptRoot = $PSScriptRoot
if (-not $scriptRoot -and $MyInvocation.MyCommand.Path) {
  $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
}

function Write-Header {
  Write-Host "Neovim C/C++ IDE Installer (Lua Edition, Neovim 0.11+)" -ForegroundColor Cyan
  Write-Host ""
}

function Ensure-Git {
  if ($script:GitExe) { return $script:GitExe }

  $candidates = @(
    "C:\Program Files\Git\cmd\git.exe",
    "C:\Program Files (x86)\Git\cmd\git.exe",
    (Join-Path $env:LOCALAPPDATA "Programs\Git\cmd\git.exe"),
    "git"
  )

  foreach ($candidate in $candidates) {
    try {
      $null = & $candidate --version 2>&1
      if ($LASTEXITCODE -eq 0) {
        $script:GitExe = $candidate
        return $script:GitExe
      }
    } catch {
      continue
    }
  }

  throw "Git not found. Install it first: winget install Git.Git"
}

function Invoke-NativeCapture {
  param(
    [Parameter(Mandatory = $true)][string]$FilePath,
    [Parameter(Mandatory = $true)][string[]]$ArgumentList
  )

  # Windows PowerShell 5.1 turns redirected native stderr into ErrorRecord objects.
  # With the installer's global ErrorActionPreference=Stop, normal tools such as
  # `git clone` can therefore terminate the script merely for writing progress to
  # stderr. Capture native output under Continue and make the process exit code
  # the authoritative success/failure signal instead.
  $previousErrorActionPreference = $ErrorActionPreference
  try {
    $ErrorActionPreference = "Continue"
    $output = @(& $FilePath @ArgumentList 2>&1)
    $exitCode = $LASTEXITCODE
  } finally {
    $ErrorActionPreference = $previousErrorActionPreference
  }

  return [PSCustomObject]@{
    ExitCode = $exitCode
    Output = @($output | ForEach-Object { $_.ToString() })
  }
}

function Backup-NvimConfig {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return }

  $backup = "$Path.bak.$([DateTime]::Now.ToString('yyyyMMdd-HHmmss'))"
  Rename-Item $Path $backup
  Write-Host "  Backup: $backup" -ForegroundColor Yellow
}

function Copy-ModularConfig {
  param([string]$SourceRoot, [string]$Destination)

  $initSource = Join-Path $SourceRoot "init.lua"
  $luaSource = Join-Path $SourceRoot "lua"

  if (-not (Test-Path $initSource)) {
    throw "init.lua not found at: $SourceRoot"
  }
  if (-not (Test-Path $luaSource)) {
    throw "lua module tree not found at: $luaSource"
  }

  New-Item -ItemType Directory -Force -Path $Destination | Out-Null
  Copy-Item -Force $initSource (Join-Path $Destination "init.lua")
  Copy-Item -Recurse -Force $luaSource (Join-Path $Destination "lua")

  Write-Host "  Installed init.lua + lua/ modules to $Destination" -ForegroundColor Green
}

function Install-FromLocal {
  param([string]$SourceRoot, [string]$Destination)
  if (-not $SourceRoot) {
    throw "Local mode requires -SourcePath or execution from a saved repository script."
  }
  Copy-ModularConfig -SourceRoot $SourceRoot -Destination $Destination
}

function Install-FromRemote {
  param([string]$RepoName, [string]$Destination, [string]$GitExe)

  $tmp = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
  try {
    Write-Host "  Cloning https://github.com/$RepoName.git" -ForegroundColor DarkGray
    $clone = Invoke-NativeCapture -FilePath $GitExe -ArgumentList @(
      "clone",
      "--depth",
      "1",
      "https://github.com/$RepoName.git",
      $tmp
    )
    if ($clone.ExitCode -ne 0) {
      $details = ($clone.Output | Select-Object -Last 20) -join [Environment]::NewLine
      if ($details) {
        throw "Git clone failed (exit code: $($clone.ExitCode))`n$details"
      }
      throw "Git clone failed (exit code: $($clone.ExitCode))"
    }
    Copy-ModularConfig -SourceRoot $tmp -Destination $Destination
  } finally {
    Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
  }
}

function Invoke-FirstLaunch {
  param([string]$InitPath)

  if (-not (Test-Path $InitPath)) {
    throw "init.lua not found at: $InitPath"
  }

  $nvim = Get-Command nvim -ErrorAction SilentlyContinue
  if (-not $nvim) {
    throw "Neovim not found in PATH. Install Neovim 0.11+ and rerun with -FirstLaunchOnly."
  }

  $versionLine = (& $nvim.Source --version | Select-Object -First 1)
  Write-Host "  $versionLine" -ForegroundColor DarkGray

  Write-Host "  Synchronizing lazy.nvim plugins..." -ForegroundColor Cyan
  & $nvim.Source --headless "+Lazy! sync" +qa
  if ($LASTEXITCODE -ne 0) {
    throw "Neovim plugin synchronization failed (exit code: $LASTEXITCODE)"
  }

  Write-Host "  Plugin synchronization complete" -ForegroundColor Green
  Write-Host ""
  Write-Host "Profiles:" -ForegroundColor Cyan
  Write-Host "  cpp     default full C/C++ IDE"
  Write-Host "  minimal lightweight editor"
  Write-Host "  agent   cpp + provider-neutral agent foundation"
  Write-Host ""
  Write-Host "Optional tools: :MasonInstall clangd lua-language-server clang-format stylua" -ForegroundColor DarkGray
}

if ($FirstLaunchOnly -and $SkipFirstLaunch) {
  throw "-FirstLaunchOnly cannot be combined with -SkipFirstLaunch"
}

Write-Header

if (-not $FirstLaunchOnly) {
  if (-not $NoBackup) {
    Backup-NvimConfig -Path $destNvim
  } elseif (Test-Path $destNvim) {
    Remove-Item -Recurse -Force $destNvim
  }

  if ($Local) {
    $resolvedSource = if ($SourcePath) { $SourcePath } else { $scriptRoot }
    Install-FromLocal -SourceRoot $resolvedSource -Destination $destNvim
  } else {
    $git = Ensure-Git
    Install-FromRemote -RepoName $Repo -Destination $destNvim -GitExe $git
  }
}

if (-not $SkipFirstLaunch) {
  Invoke-FirstLaunch -InitPath $initLuaPath
}

Write-Host "All done." -ForegroundColor Green
