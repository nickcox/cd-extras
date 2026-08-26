param ([switch] $Cover)

if ($Cover) {
  $ex = "$PSScriptRoot/../cd-extras"
  Invoke-Pester $PSScriptRoot -CodeCoverage "$ex/public/*-*.ps1", "$ex/private/*.ps1" @args
}
else {
  Invoke-Pester $PSScriptRoot @args
}
