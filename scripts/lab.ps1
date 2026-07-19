[CmdletBinding()]
param(
    [ValidateSet('Up', 'Down', 'Assess', 'BuildBundle', 'VerifyBundle', 'Patch', 'Test', 'Doctor', 'Status')]
    [string]$Action = 'Assess',
    [switch]$Apply
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$WindowsPosixPath = $ProjectRoot.Replace('\', '/')
$WslProjectRoot = (wsl -d Ubuntu -- wslpath -a $WindowsPosixPath).Trim()
$ApplyValue = if ($Apply) { 'true' } else { 'false' }

if (-not $WslProjectRoot) {
    throw 'Could not translate the project path into a WSL path.'
}

wsl -d Ubuntu -- bash -lc "cd '$WslProjectRoot' && ./scripts/lab.sh '$Action' '$ApplyValue'"
if ($LASTEXITCODE -ne 0) {
    throw "Lab action '$Action' failed with exit code $LASTEXITCODE."
}
