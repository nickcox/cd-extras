[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string] $ModulePath,
  [string] $ApprovedExportsPath = (Join-Path $PSScriptRoot 'approved-exports.psd1')
)

$ErrorActionPreference = 'Stop'

function Assert-ExactList($Actual, $Expected, $Description) {
  $actualList = @($Actual | Sort-Object)
  $expectedList = @($Expected | Sort-Object)
  $difference = @(Compare-Object -ReferenceObject $expectedList -DifferenceObject $actualList)

  if ($difference) {
    $details = $difference | ForEach-Object { "$($_.SideIndicator) $($_.InputObject)" }
    throw "$Description does not match the approved list: $($details -join ', ')"
  }
}

$manifest = Test-ModuleManifest -Path $ModulePath
$approved = Import-PowerShellDataFile -Path $ApprovedExportsPath
$moduleRoot = Split-Path -Parent $manifest.Path
Assert-ExactList $manifest.ExportedFunctions.Keys $approved.Functions 'Manifest functions'
Assert-ExactList $manifest.ExportedAliases.Keys $approved.Aliases 'Manifest aliases'
Assert-ExactList $manifest.ExportedVariables.Keys $approved.Variables 'Manifest variables'
$previousLocation = Get-Location
$previousCdAlias = (Get-Alias -Name cd -ErrorAction Stop).Definition
$originalCommandNotFoundAction = $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction
$commandNotFoundSentinel = { param($CommandName, $CommandLookupEventArgs) }
$ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = $commandNotFoundSentinel
$previousCommandNotFoundAction = $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction
$smokeRoot = Join-Path ([IO.Path]::GetTempPath()) "cd-extras-smoke-$([guid]::NewGuid())"
$module = $null
$removalFailure = $null

try {
  $module = @(Import-Module -Name $manifest.Path -Force -PassThru) |
  Where-Object Name -eq 'cd-extras'

  Assert-ExactList $module.ExportedFunctions.Keys $approved.Functions 'Exported functions'
  Assert-ExactList $module.ExportedAliases.Keys $approved.Aliases 'Exported aliases'
  foreach ($variableName in $approved.Variables) {
    if (!(Get-Variable -Name $variableName -Scope Global -ErrorAction Ignore)) {
      throw "Exported variable $variableName is not available in the global scope."
    }
  }

  foreach ($commandName in $approved.Functions) {
    $help = Get-Help -Name $commandName
    if ([string]::IsNullOrWhiteSpace($help.Synopsis)) {
      throw "$commandName does not have synopsis help."
    }
  }

  foreach ($publicScript in Get-ChildItem -LiteralPath (Join-Path $moduleRoot 'public') -Filter '*.ps1') {
    $content = Get-Content -Raw -LiteralPath $publicScript.FullName
    $linkBlocks = [regex]::Matches($content, '(?ms)^\.LINK\s*\r?\n(?<links>.*?)(?=^\.[A-Z]+|^#>|\z)')
    foreach ($linkBlock in $linkBlocks) {
      foreach ($link in @($linkBlock.Groups['links'].Value -split '\r?\n')) {
        $target = $link.Trim()
        if (!$target -or $target -match 'https?://') { continue }
        if (!(Get-Command -Name $target -ErrorAction Ignore) -and !(Get-Help -Name $target -ErrorAction Ignore)) {
          throw "$($publicScript.Name) contains an unresolved help link: $target"
        }
      }
    }
  }

  $firstDirectory = New-Item -ItemType Directory -Path (Join-Path $smokeRoot 'first') -Force
  $secondDirectory = New-Item -ItemType Directory -Path (Join-Path $smokeRoot 'second') -Force

  Set-CdExtrasOption -Options @{ AUTO_CD = $true; FrecentProvider = $null }
  if ([object]::ReferenceEquals(
      $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction,
      $previousCommandNotFoundAction
    )) {
    throw 'AUTO_CD did not install its command-not-found handler.'
  }

  cd $firstDirectory.FullName
  cd $secondDirectory.FullName
  cdr -n 1
  if ($PWD.Path -ne $firstDirectory.FullName) { throw 'cdr did not select the expected recent directory.' }
  cdf -n 1
  if ($PWD.Path -ne $secondDirectory.FullName) { throw 'cdf did not select the expected frecent directory.' }

  mark $smokeRoot
  if ($smokeRoot -notin @(Get-Bookmark)) { throw 'mark did not create the expected bookmark.' }
  $null = getocd
}
finally {
  Microsoft.PowerShell.Management\Set-Location -LiteralPath $previousLocation.Path
  if ($module) { Remove-Module -ModuleInfo $module -Force }

  if ((Get-Alias -Name cd -ErrorAction Stop).Definition -ne $previousCdAlias) {
    $removalFailure = 'Removing cd-extras did not restore the previous cd alias.'
  }
  elseif (![object]::ReferenceEquals(
      $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction,
      $previousCommandNotFoundAction
    )) {
    $removalFailure = 'Removing cd-extras did not restore the previous command-not-found handler.'
  }

  $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = $originalCommandNotFoundAction
  Remove-Item -LiteralPath $smokeRoot -Recurse -Force -ErrorAction Ignore
}

if ($removalFailure) { throw $removalFailure }
