#Requires -Module Pester

param ([switch] $Cover)

if ($Cover) {
  $src = Get-ChildItem $PSScriptRoot\..\cd-extras\ -Recurse -File -Include *.ps1
  Invoke-Pester $PSScriptRoot\cd-extras.Tests.ps1 -CodeCoverage $src
} else {
  Invoke-Pester $PSScriptRoot\cd-extras.Tests.ps1
}