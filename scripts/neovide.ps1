$ErrorActionPreference = 'Stop'
$configRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$lock = Get-Content -LiteralPath (Join-Path $configRoot 'tools.lock.json') -Raw | ConvertFrom-Json
$env:NVIM_APPNAME = Split-Path -Leaf $configRoot
$editor = 'C:\tools\neovim\nvim-v' + $lock.neovim + '\nvim-win64\bin\nvim.exe'
$gui = 'C:\tools\neovide\v' + $lock.neovide + '\neovide.exe'
& $gui --neovim-bin $editor @args
exit $LASTEXITCODE
