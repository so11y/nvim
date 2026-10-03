param([Parameter(Mandatory=$true)][string]$DataRoot)
$ErrorActionPreference = 'Stop'
$configRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$lock = Get-Content -LiteralPath (Join-Path $configRoot 'tools.lock.json') -Raw | ConvertFrom-Json
$patch = Join-Path $configRoot 'patches\efm-windows-command.patch'
if ((Get-FileHash -LiteralPath $patch -Algorithm SHA256).Hash.ToLowerInvariant() -ne $lock.efm_patch.patch_sha256) { throw 'EFM patch checksum mismatch' }
$binary = Join-Path $DataRoot "mason\packages\efm\efm-langserver_$($lock.mason.efm)_windows_amd64\efm-langserver.exe"
if ((Test-Path -LiteralPath $binary) -and (Get-FileHash -LiteralPath $binary -Algorithm SHA256).Hash.ToLowerInvariant() -eq $lock.efm_patch.binary_sha256) { exit 0 }
$go = Join-Path $DataRoot "tools\$($lock.efm_patch.compiler.version)\go\bin\go.exe"
if (-not (Test-Path -LiteralPath $go)) { throw 'Install the compiler pinned in tools.lock.json before rebuilding EFM' }
$buildRoot = Join-Path ([IO.Path]::GetTempPath()) ('nvim-efm-build-' + [guid]::NewGuid().ToString('N'))
& git clone --depth 1 --branch $lock.mason.efm https://github.com/mattn/efm-langserver.git $buildRoot
if ($LASTEXITCODE -ne 0) { throw 'EFM clone failed' }
$sourceCommit = & git -C $buildRoot rev-parse HEAD
if ($sourceCommit.Trim() -ne $lock.efm_patch.source_commit) { throw 'EFM source revision mismatch' }
& git -C $buildRoot apply $patch
if ($LASTEXITCODE -ne 0) { throw 'EFM patch failed' }
Push-Location -LiteralPath $buildRoot
try {
    & $go build -trimpath -buildvcs=false '-ldflags=-s -w -X main.revision=740a66b+windows-command-errors' -o (Join-Path $buildRoot 'efm-langserver.exe') .
    if ($LASTEXITCODE -ne 0) { throw 'EFM build failed' }
    $built = Join-Path $buildRoot 'efm-langserver.exe'
    if ((Get-FileHash -LiteralPath $built -Algorithm SHA256).Hash.ToLowerInvariant() -ne $lock.efm_patch.binary_sha256) { throw 'Built EFM checksum mismatch' }
    Copy-Item -LiteralPath $built -Destination $binary -Force
} finally { Pop-Location }
