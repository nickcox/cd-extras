[CmdletBinding()]
Param(
  [string]$Version = $null,
  [string]$NuGetApiKey = $env:PSNugetKey,
  [switch]$Confirm = $false,
  [switch]$WhatIf = $false
)

Copy-Item $PSScriptRoot/readme.md $PSScriptRoot/cd-extras/about_Cd-Extras.help.txt
$manifest = Import-PowerShellDataFile "$PSScriptRoot/cd-extras/cd-extras.psd1"

If ([String]::IsNullOrEmpty($Version)) {
  $Version = $manifest.ModuleVersion
}
Else {
  If ($Version[0] -Eq 'v') {
    $Version = [regex]::Replace($Version, '^v', "")
  }
}

$outputDirectory = "$PSScriptRoot/out/$Version"
$null = Remove-Item -Force -Recurse $outputDirectory -ErrorAction Ignore
$null = New-Item -Type Directory $outputDirectory
$null = Copy-Item -Recurse "$PSScriptRoot/cd-extras" "$outputDirectory/cd-extras"
$releaseNotes = (Get-Content -Raw CHANGELOG.md).Split('##') | select -Skip 1 -f 1 | % { $_.Trim() }

If ($manifest.ModuleVersion -ne $Version) {
  Write-Warning "Version $Version specified on commandline, but manifest contains $($manifest.ModuleVersion)."
  Write-Warning "Preferring $Version from commandline."

  Update-ModuleManifest -Path "$outputDirectory/cd-extras/cd-extras.psd1" -ModuleVersion $Version
  Update-ModuleManifest -Path "$outputDirectory/cd-extras/cd-extras.psd1" -ReleaseNotes $releaseNotes
}

$publishParameters = @{
  Path        = "$outputDirectory/cd-extras"
  NuGetApiKey = $NugetAPIKey
  Repository  = "PSGallery"
  WhatIf      = $WhatIf
}

Publish-Module -Confirm:$Confirm @publishParameters