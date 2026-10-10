param([Parameter(Mandatory=$true)][string]$BackupRoot)
$ErrorActionPreference = 'Stop'
$configRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$lock = Get-Content -LiteralPath (Join-Path $configRoot 'tools.lock.json') -Raw | ConvertFrom-Json
$appName = Split-Path -Leaf $configRoot
$editorBin = 'C:\tools\neovim\nvim-v' + $lock.neovim + '\nvim-win64\bin'
if (-not (Test-Path -LiteralPath (Join-Path $editorBin 'nvim.exe'))) { throw 'Install the pinned Neovim before activation' }
New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
$activationBackup = Join-Path $BackupRoot 'activation.json'
if (Test-Path -LiteralPath $activationBackup) { throw 'Activation backup already exists; choose a fresh backup directory' }
$userEnvironment = @{}
foreach ($name in @('Path', 'NVIM_APPNAME', 'NEOVIM_BIN')) { $userEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'User') }
$profileFile = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'WindowsPowerShell\profile.ps1'
$profileExisted = Test-Path -LiteralPath $profileFile
if ($profileExisted) { Copy-Item -LiteralPath $profileFile -Destination (Join-Path $BackupRoot 'profile.ps1') }
$settingsFile = Join-Path $env:APPDATA 'Code\User\settings.json'
Copy-Item -LiteralPath $settingsFile -Destination (Join-Path $BackupRoot 'vscode-settings.json')
@{ User = $userEnvironment; Profile = $profileFile; ProfileExisted = $profileExisted; Settings = $settingsFile } | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $activationBackup -Encoding UTF8
$oldBin = 'C:\tools\neovim\nvim-win64\bin'
$entries = $userEnvironment.Path.Split(';') | Where-Object { $_.TrimEnd('\') -ine $oldBin -and $_.TrimEnd('\') -ine $editorBin }
[Environment]::SetEnvironmentVariable('Path', (@($editorBin) + $entries) -join ';', 'User')
[Environment]::SetEnvironmentVariable('NVIM_APPNAME', $appName, 'User')
[Environment]::SetEnvironmentVariable('NEOVIM_BIN', (Join-Path $editorBin 'nvim.exe'), 'User')
$profileText = if ($profileExisted) { [IO.File]::ReadAllText($profileFile) } else { '' }
$profileText = [regex]::Replace($profileText, '(?ms)^# BEGIN Neovim upgrade\r?\n.*?^# END Neovim upgrade\r?\n?', '')
$nvimLauncher = (Join-Path $PSScriptRoot 'nvim.ps1').Replace("'", "''")
$guiLauncher = (Join-Path $PSScriptRoot 'neovide.ps1').Replace("'", "''")
$profileText += "
# BEGIN Neovim upgrade
function global:nvim { & '$nvimLauncher' @args }
function global:neovide { & '$guiLauncher' @args }
# END Neovim upgrade
"
New-Item -ItemType Directory -Path (Split-Path -Parent $profileFile) -Force | Out-Null
[IO.File]::WriteAllText($profileFile, $profileText, (New-Object Text.UTF8Encoding($true)))
$env:NVIM_APPNAME = $appName
$env:NEOVIM_BIN = Join-Path $editorBin 'nvim.exe'
$env:Path = $editorBin + ';' + $env:Path
& (Join-Path $PSScriptRoot 'notify-environment.ps1')
Write-Output "Activated $appName; existing editor sessions are preserved. For VSCode, set vscode-neovim.neovimExecutablePaths.win32 to the pinned nvim.exe and vscode-neovim.NVIM_APPNAME to $appName."
