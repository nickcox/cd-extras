#Requires -Modules @{ ModuleName = 'Microsoft.PowerShell.PSResourceGet'; RequiredVersion = '1.2.0' }

[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string] $PackagePath,
  [Parameter(Mandatory)]
  [string] $Version,
  [string] $WorkingDirectory = (Join-Path ([IO.Path]::GetTempPath()) "cd-extras-package-$([guid]::NewGuid())"),
  [string] $PowerShellExecutable = (Get-Process -Id $PID).Path
)

$ErrorActionPreference = 'Stop'
$PackagePath = (Resolve-Path -LiteralPath $PackagePath).Path
$repositoryName = "cd-extras-$([guid]::NewGuid())"
$repositoryDirectory = Split-Path -Parent $PackagePath
$moduleDirectory = Join-Path $WorkingDirectory 'modules'
$registered = $false

try {
  $null = New-Item -ItemType Directory -Path $moduleDirectory -Force
  Register-PSResourceRepository -Name $repositoryName -Uri $repositoryDirectory -Trusted
  $registered = $true

  $saveParameters = @{
    Name = 'cd-extras'
    Version = $Version
    Repository = $repositoryName
    Path = $moduleDirectory
    TrustRepository = $true
  }
  if ($Version -match '-') { $saveParameters.Prerelease = $true }
  Save-PSResource @saveParameters

  $installedManifests = @(
    Get-ChildItem -LiteralPath $moduleDirectory -Filter 'cd-extras.psd1' -File -Recurse
  )
  if ($installedManifests.Count -ne 1) {
    throw "Expected one installed cd-extras manifest, found $($installedManifests.Count)."
  }

  $installedManifest = Test-ModuleManifest -Path $installedManifests[0].FullName
  $installedVersion = $installedManifest.Version.ToString()
  $installedPrerelease = "$($installedManifest.PrivateData.PSData.Prerelease)"
  $expectedVersion = if ($installedPrerelease) {
    "$installedVersion-$installedPrerelease"
  }
  else {
    $installedVersion
  }
  if ($expectedVersion -ne $Version) {
    throw "Installed package version '$expectedVersion' does not match '$Version'."
  }

  $installedModuleRoot = Split-Path -Parent $installedManifest.Path
  $aboutHelp = Join-Path $installedModuleRoot 'about_Cd-Extras.help.txt'
  if (!(Test-Path -LiteralPath $aboutHelp -PathType Leaf)) {
    throw 'The installed package does not contain about_Cd-Extras.help.txt.'
  }

  $documentationFiles = @(
    Get-ChildItem -LiteralPath $installedModuleRoot -File |
    Where-Object Extension -in '.md', '.txt'
  ) + @(
    Get-ChildItem -LiteralPath (Join-Path $installedModuleRoot 'docs') -File -Filter '*.md'
  )
  foreach ($documentationFile in $documentationFiles) {
    $content = Get-Content -Raw -LiteralPath $documentationFile.FullName
    $links = @([regex]::Matches($content, '!?(?:\[[^]]*\])\((?<target>[^)]+)\)')) +
    @([regex]::Matches($content, '(?m)^\[[^]]+\]:\s*(?<target>\S+)'))

    foreach ($link in $links) {
      $target = $link.Groups['target'].Value.Trim('<', '>')
      if (!$target -or $target.StartsWith('#') -or $target -match '^[a-z][a-z0-9+.-]*:') { continue }
      $relativePath = ($target -split '#', 2)[0]
      if (!(Test-Path -LiteralPath (Join-Path $documentationFile.DirectoryName $relativePath))) {
        throw "$($documentationFile.Name) contains an unresolved package link: $target"
      }
    }
  }

  $previousModulePath = $env:PSModulePath
  try {
    $env:PSModulePath = $moduleDirectory + [IO.Path]::PathSeparator + (Join-Path $PSHOME 'Modules')
    $validationScript = Join-Path $PSScriptRoot 'validate-module.ps1'
    $approvedExports = Join-Path $PSScriptRoot 'approved-exports.psd1'
    & $PowerShellExecutable -NoLogo -NoProfile -File $validationScript `
      -ModulePath $installedManifest.Path -ApprovedExportsPath $approvedExports
    if ($LASTEXITCODE -ne 0) {
      throw "Installed package smoke test failed with exit code $LASTEXITCODE."
    }
  }
  finally {
    $env:PSModulePath = $previousModulePath
  }
}
finally {
  if ($registered) { Unregister-PSResourceRepository -Name $repositoryName -ErrorAction Ignore }
  Remove-Item -LiteralPath $WorkingDirectory -Recurse -Force -ErrorAction Ignore
}
