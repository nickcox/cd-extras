#Requires -Modules @{ ModuleName = 'PSScriptAnalyzer'; RequiredVersion = '1.24.0' }

[CmdletBinding()]
param(
  [string] $RepositoryRoot = (Resolve-Path "$PSScriptRoot/..").Path
)

$ErrorActionPreference = 'Stop'
$settingsPath = Join-Path $RepositoryRoot 'PSScriptAnalyzerSettings.psd1'
$targets = @(
  (Join-Path $RepositoryRoot 'cd-extras')
  (Join-Path $RepositoryRoot 'tests')
  (Join-Path $RepositoryRoot 'publishme.ps1')
)
$findings = @()

foreach ($target in $targets) {
  $findings += @(Invoke-ScriptAnalyzer -Path $target -Settings $settingsPath -Recurse)
}

if ($findings) {
  $findings |
  Sort-Object Severity, ScriptName, Line |
  ForEach-Object {
    "$($_.Severity): $($_.RuleName) in $($_.ScriptName):$($_.Line) - $($_.Message)"
  }
}

$failures = @($findings | Where-Object Severity -in 'Error', 'Warning')
if ($failures) {
  throw "PSScriptAnalyzer found $($failures.Count) error or warning findings."
}

$manifestPath = Join-Path $RepositoryRoot 'cd-extras/cd-extras.psd1'
$null = Test-ModuleManifest -Path $manifestPath
