param([Parameter(Mandatory=$true)][string]$BackupRoot)
$ErrorActionPreference = 'Stop'
$backup = Get-Content -LiteralPath (Join-Path $BackupRoot 'activation.json') -Raw | ConvertFrom-Json
foreach ($name in @('Path', 'NVIM_APPNAME', 'NEOVIM_BIN')) {
    [Environment]::SetEnvironmentVariable($name, $backup.User.$name, 'User')
}
if ($backup.ProfileExisted) {
    Copy-Item -LiteralPath (Join-Path $BackupRoot 'profile.ps1') -Destination $backup.Profile -Force
} else {
    Remove-Item -LiteralPath $backup.Profile
}
Copy-Item -LiteralPath (Join-Path $BackupRoot 'vscode-settings.json') -Destination $backup.Settings -Force
& (Join-Path $PSScriptRoot 'notify-environment.ps1')
Write-Output 'Restored the saved user environment, PowerShell profile and VSCode settings. After saving your files, close and reopen the terminal and VSCode so their process environments are refreshed.'
Write-Output 'This rollback restores the prior Neovim 0.12.5 launcher environment. It does not replace the current master configuration or data junction; Neovim 0.11.5 assets have been removed.'
