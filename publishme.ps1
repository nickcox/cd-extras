[CmdletBinding()]
param(
  [string] $Version,
  [string] $OutputDirectory = (Join-Path $PSScriptRoot 'out'),
  [switch] $Publish,
  [string] $NuGetApiKey = $env:PSNugetKey,
  [switch] $Confirm,
  [switch] $WhatIf
)

$ErrorActionPreference = 'Stop'
$sourceManifestPath = Join-Path $PSScriptRoot 'cd-extras/cd-extras.psd1'
$sourceManifest = Test-ModuleManifest -Path $sourceManifestPath
$changelog = Get-Content -Raw (Join-Path $PSScriptRoot 'CHANGELOG.md')
$release = [regex]::Match(
  $changelog,
  '(?ms)^## \[(?<version>[^]]+)\]\s*\r?\n(?<notes>.*?)(?=^## \[|\z)'
)

if (!$release.Success) { throw 'CHANGELOG.md does not contain a release section.' }

$changelogVersion = $release.Groups['version'].Value
$releaseNotes = $release.Groups['notes'].Value.Trim()
if ($changelogVersion -ne $sourceManifest.Version.ToString()) {
  throw "CHANGELOG.md begins with version $changelogVersion, but the manifest contains $($sourceManifest.Version)."
}

if ([string]::IsNullOrWhiteSpace($Version)) { $Version = $changelogVersion }
$Version = $Version -replace '^v', ''
$versionMatch = [regex]::Match($Version, '^(?<base>\d+\.\d+\.\d+)(?:-(?<prerelease>[0-9A-Za-z.-]+))?$')
if (!$versionMatch.Success) { throw "Version '$Version' is not a valid module version." }

$baseVersion = $versionMatch.Groups['base'].Value
$prerelease = $versionMatch.Groups['prerelease'].Value

if ($Publish) {
  if ($baseVersion -ne $sourceManifest.Version.ToString()) {
    throw "Publish version $baseVersion does not match manifest version $($sourceManifest.Version)."
  }

  $expectedTag = "v$Version"
  $actualTag = &git -C $PSScriptRoot describe --tags --exact-match HEAD 2>$null
  if ($LASTEXITCODE -ne 0 -or $actualTag -ne $expectedTag) {
    throw "Publishing version $Version requires HEAD to have the exact tag '$expectedTag'."
  }

  if ([string]::IsNullOrWhiteSpace($NuGetApiKey)) {
    throw 'A PowerShell Gallery API key is required when -Publish is specified.'
  }
}

$stagingDirectory = Join-Path $OutputDirectory $Version
$stagedModule = Join-Path $stagingDirectory 'cd-extras'
$stagedManifestPath = Join-Path $stagedModule 'cd-extras.psd1'

if (!$Publish) {
  Remove-Item -LiteralPath $stagingDirectory -Force -Recurse -ErrorAction Ignore
  $null = New-Item -ItemType Directory -Path $stagingDirectory
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'cd-extras') -Destination $stagedModule -Recurse
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'readme.md') `
    -Destination (Join-Path $stagedModule 'about_Cd-Extras.help.txt')

  $updateParameters = @{
    Path = $stagedManifestPath
    ModuleVersion = $baseVersion
    ReleaseNotes = $releaseNotes
  }
  if ($prerelease) { $updateParameters.Prerelease = $prerelease }
  Update-ModuleManifest @updateParameters
}

if (!(Test-Path -LiteralPath $stagedManifestPath)) {
  throw "Staged module '$stagedModule' does not exist. Run a build-only invocation before publishing."
}

$stagedManifest = Test-ModuleManifest -Path $stagedManifestPath
if (
  $stagedManifest.Version.ToString() -ne $baseVersion -or
  "$($stagedManifest.PrivateData.PSData.Prerelease)" -ne $prerelease
) {
  throw "Staged manifest version does not match requested version '$Version'."
}
if ($stagedManifest.PrivateData.PSData.ReleaseNotes.Trim() -ne $releaseNotes) {
  throw 'Staged manifest release notes do not match CHANGELOG.md.'
}

if ($Publish) {
  Publish-Module -Path $stagedModule -NuGetApiKey $NuGetApiKey -Repository PSGallery `
    -Confirm:$Confirm -WhatIf:$WhatIf
}
else {
  Write-Output $stagedModule
}
