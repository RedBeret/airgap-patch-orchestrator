[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$WindowsPosixPath = $ProjectRoot.Replace('\', '/')
$WslProjectRoot = (wsl -d Ubuntu -- wslpath -a $WindowsPosixPath).Trim()

if (-not $WslProjectRoot) {
    throw 'Could not translate the project path into a WSL path.'
}

if (-not (Test-Path (Join-Path $ProjectRoot 'lab/ssh/id_ed25519'))) {
    wsl -d Ubuntu -- bash -lc "mkdir -p '$WslProjectRoot/lab/ssh' && ssh-keygen -q -t ed25519 -N '' -f '$WslProjectRoot/lab/ssh/id_ed25519' && cp '$WslProjectRoot/lab/ssh/id_ed25519.pub' '$WslProjectRoot/lab/ssh/authorized_keys'"
}

wsl -d Ubuntu -- bash -lc "cd '$WslProjectRoot' && python3 -m venv .venv && .venv/bin/python -m pip install --upgrade pip && .venv/bin/pip install -r requirements-dev.txt -e ."
if ($LASTEXITCODE -ne 0) {
    throw "WSL dependency installation failed with exit code $LASTEXITCODE."
}

Write-Host 'Bootstrap complete. Run: pwsh ./scripts/lab.ps1 -Action Up'
