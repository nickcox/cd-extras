[CmdletBinding(DefaultParameterSetName = 'Build')]
param(
  [string] $Version,
  [string] $OutputDirectory = (Join-Path $PSScriptRoot 'out'),
  [Parameter(Mandatory, ParameterSetName = 'Publish')]
  [switch] $Publish,
  [Parameter(ParameterSetName = 'Publish')]
  [string] $PackagePath,
  [string] $NuGetApiKey = $env:PSNugetKey,
  [switch] $Confirm,
  [switch] $WhatIf
)

$ErrorActionPreference = 'Stop'

function Get-PackageVersion([string] $Path) {
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $resolvedPath = (Resolve-Path -LiteralPath $Path).Path
  $archive = [IO.Compression.ZipFile]::OpenRead($resolvedPath)

  try {
    $nuspecEntries = @($archive.Entries | Where-Object FullName -like '*.nuspec')
    if ($nuspecEntries.Count -ne 1) { throw "Package '$Path' must contain one nuspec file." }

    $stream = $nuspecEntries[0].Open()
    $reader = [IO.StreamReader]::new($stream)
    try { [xml] $nuspec = $reader.ReadToEnd() }
    finally {
      $reader.Dispose()
      $stream.Dispose()
    }

    return "$($nuspec.package.metadata.version)"
  }
  finally {
    $archive.Dispose()
  }
}

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

if ($baseVersion -ne $sourceManifest.Version.ToString()) {
  throw "Package version $baseVersion does not match manifest version $($sourceManifest.Version)."
}

if ($Publish) {
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
if ([string]::IsNullOrWhiteSpace($PackagePath)) {
  $PackagePath = Join-Path $stagingDirectory "cd-extras.$Version.nupkg"
}

if (!$Publish) {
  Remove-Item -LiteralPath $stagingDirectory -Force -Recurse -ErrorAction Ignore
  $null = New-Item -ItemType Directory -Path $stagingDirectory
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'cd-extras') -Destination $stagedModule -Recurse
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'readme.md') `
    -Destination (Join-Path $stagedModule 'about_Cd-Extras.help.txt')
  $null = New-Item -ItemType Directory -Path (Join-Path $stagedModule 'docs')
  $documentation = Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot 'docs') -File -Filter '*.md'
  Copy-Item -LiteralPath $documentation.FullName -Destination (Join-Path $stagedModule 'docs')
  Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'assets') -Destination (Join-Path $stagedModule 'assets') `
    -Recurse

  $updateParameters = @{
    Path = $stagedManifestPath
    ModuleVersion = $baseVersion
    ReleaseNotes = $releaseNotes
  }
  if ($prerelease) { $updateParameters.Prerelease = $prerelease }
  Update-ModuleManifest @updateParameters
}

if ($Publish) {
  if (!(Test-Path -LiteralPath $PackagePath -PathType Leaf)) {
    throw "Validated package '$PackagePath' does not exist."
  }
  if ((Get-PackageVersion -Path $PackagePath) -ne $Version) {
    throw "Package metadata does not match requested version '$Version'."
  }

  Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0
  Publish-PSResource -NupkgPath $PackagePath -ApiKey $NuGetApiKey -Repository PSGallery `
    -Confirm:$Confirm -WhatIf:$WhatIf
}
else {
  $stagedManifest = Test-ModuleManifest -Path $stagedManifestPath
  $stagedManifestData = Import-PowerShellDataFile -Path $stagedManifestPath
  if (
    $stagedManifest.Version.ToString() -ne $baseVersion -or
    "$($stagedManifestData.PrivateData.PSData.Prerelease)" -ne $prerelease
  ) {
    throw "Staged manifest version does not match requested version '$Version'."
  }
  if ($stagedManifest.PrivateData.PSData.ReleaseNotes.Trim() -ne $releaseNotes) {
    throw 'Staged manifest release notes do not match CHANGELOG.md.'
  }

  Import-Module Microsoft.PowerShell.PSResourceGet -RequiredVersion 1.2.0
  $package = Compress-PSResource -Path $stagedModule -DestinationPath $stagingDirectory -PassThru
  Write-Output $package.FullName
}
