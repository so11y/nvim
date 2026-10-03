param([string]$Destination = (Join-Path ([IO.Path]::GetTempPath()) ('nvim-verification-' + [guid]::NewGuid().ToString('N'))))
$ErrorActionPreference = 'Stop'
if (Test-Path -LiteralPath $Destination) { throw 'Use a new directory so verification cannot change an existing project' }
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'fixtures') -Destination $Destination -Recurse
$configRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..'))
$appName = Split-Path -Leaf $configRoot
$lock = Get-Content -LiteralPath (Join-Path $configRoot 'tools.lock.json') -Raw | ConvertFrom-Json
$node = Join-Path $env:LOCALAPPDATA "$appName-data\tools\node-v$($lock.node)-win-x64"
$env:Path = $node + ';' + $env:Path
& (Join-Path $node 'npm.cmd') ci --prefix (Join-Path $Destination 'alpha') --no-audit --no-fund
if ($LASTEXITCODE -ne 0) { throw 'Fixture dependency installation failed' }
New-Item -ItemType Junction -Path (Join-Path $Destination 'beta\node_modules') -Target (Join-Path $Destination 'alpha\node_modules') | Out-Null
Write-Output "Set NVIM_TEST_ROOT=$Destination when running check-ui.mjs."
