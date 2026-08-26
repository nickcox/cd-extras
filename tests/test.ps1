#Requires -Modules @{ ModuleName = 'Pester'; RequiredVersion = '5.7.1' }

param(
  [switch] $Cover,
  [switch] $EnableExit,
  [Alias('OutputFile')]
  [string] $TestResultOutputPath,
  [Alias('CodeCoverageOutputFile')]
  [string] $CoverageOutputPath,
  [ValidateSet('None', 'Normal', 'Detailed', 'Diagnostic')]
  [string] $Verbosity = 'Normal',
  [string[]] $Path = $PSScriptRoot
)

$configuration = New-PesterConfiguration
$configuration.Run.Path = $Path
$configuration.Run.Throw = $EnableExit.IsPresent
$configuration.Output.Verbosity = $Verbosity

if ($TestResultOutputPath) {
  $configuration.TestResult.Enabled = $true
  $configuration.TestResult.OutputPath = $TestResultOutputPath
  $configuration.TestResult.OutputFormat = 'NUnitXml'
}

if ($Cover) {
  $moduleRoot = "$PSScriptRoot/../cd-extras"
  $configuration.CodeCoverage.Enabled = $Cover.IsPresent
  $configuration.CodeCoverage.Path = @("$moduleRoot/public/*-*.ps1", "$moduleRoot/private/*.ps1")
  $configuration.CodeCoverage.OutputFormat = 'JaCoCo'
  if ($CoverageOutputPath) { $configuration.CodeCoverage.OutputPath = $CoverageOutputPath }
}

Invoke-Pester -Configuration $configuration
