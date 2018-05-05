#Requires -Module Pester

$src = Get-ChildItem $PSScriptRoot\..\cd-extras\ -Recurse -File -Include *.ps1
Invoke-Pester $PSScriptRoot\cd-extras.Tests.ps1 -CodeCoverage $src