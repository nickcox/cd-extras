Describe 'release metadata and build' {
  BeforeAll {
    $repositoryRoot = (Resolve-Path "$PSScriptRoot/..").Path
    $manifestPath = Join-Path $repositoryRoot 'cd-extras/cd-extras.psd1'
    $changelogPath = Join-Path $repositoryRoot 'CHANGELOG.md'
    $publishScript = Join-Path $repositoryRoot 'publishme.ps1'
    $approvedExports = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'approved-exports.psd1')
    $manifest = Test-ModuleManifest -Path $manifestPath
    $changelog = Get-Content -Raw $changelogPath
    $release = [regex]::Match(
      $changelog,
      '(?ms)^## \[(?<version>[^]]+)\]\s*\r?\n(?<notes>.*?)(?=^## \[|\z)'
    )
  }

  It 'defines stable 3.0.0 metadata' {
    $manifest.Version.ToString() | Should -Be '3.0.0'
    $manifest.PrivateData.PSData.Prerelease | Should -BeNullOrEmpty
  }

  It 'keeps the manifest version and release notes aligned with the latest changelog entry' {
    $release.Success | Should -BeTrue
    $release.Groups['version'].Value | Should -Be $manifest.Version.ToString()
    $release.Groups['notes'].Value.Trim() | Should -Be $manifest.PrivateData.PSData.ReleaseNotes.Trim()
  }

  It 'exports the approved command and alias lists' {
    $manifest.ExportedFunctions.Keys | Sort-Object | Should -Be $approvedExports.Functions
    $manifest.ExportedAliases.Keys | Sort-Object | Should -Be $approvedExports.Aliases
    $manifest.ExportedVariables.Keys | Sort-Object | Should -Be $approvedExports.Variables
  }

  It 'validates the public API and session cleanup in a clean process' {
    $powerShellCommand = if ($PSEdition -eq 'Core') { 'pwsh' } else { 'powershell.exe' }
    $powerShell = Get-Command $powerShellCommand -CommandType Application -ErrorAction Stop |
    Select-Object -First 1 -ExpandProperty Definition
    $validationScript = Join-Path $PSScriptRoot 'validate-module.ps1'
    $approvedExportsPath = Join-Path $PSScriptRoot 'approved-exports.psd1'
    $output = & $powerShell -NoLogo -NoProfile -File $validationScript `
      -ModulePath $manifestPath -ApprovedExportsPath $approvedExportsPath 2>&1 |
    Out-String

    $LASTEXITCODE | Should -Be 0 -Because $output
  }

  # Packaging runs in pwsh; Windows PowerShell validates the module itself in the tests above.
  It 'builds stable metadata and help without publishing' -Skip:($PSEdition -ne 'Core') {
    $package = & $publishScript -OutputDirectory TestDrive:/release
    $stagedModule = Join-Path (Split-Path -Parent $package) 'cd-extras'
    $stagedManifest = Test-ModuleManifest (Join-Path $stagedModule 'cd-extras.psd1')

    Test-Path -LiteralPath $package | Should -BeTrue
    $stagedManifest.Version.ToString() | Should -Be '3.0.0'
    $stagedManifest.PrivateData.PSData.Prerelease | Should -BeNullOrEmpty
    $stagedManifest.PrivateData.PSData.ReleaseNotes.Trim() |
    Should -Be $release.Groups['notes'].Value.Trim()
    Test-Path -LiteralPath (Join-Path $stagedModule 'about_Cd-Extras.help.txt') | Should -BeTrue
    Test-Path -LiteralPath (Join-Path $stagedModule 'docs/navigation.md') | Should -BeTrue
    Test-Path -LiteralPath (Join-Path $stagedModule 'assets/overview.svg') | Should -BeTrue
  }

  It 'retains a requested prerelease label in a build' -Skip:($PSEdition -ne 'Core') {
    $package = & $publishScript -Version 3.0.0-rc1 -OutputDirectory TestDrive:/release
    $stagedModule = Join-Path (Split-Path -Parent $package) 'cd-extras'
    $stagedManifest = Test-ModuleManifest (Join-Path $stagedModule 'cd-extras.psd1')
    $stagedManifestData = Import-PowerShellDataFile (Join-Path $stagedModule 'cd-extras.psd1')

    $stagedManifest.Version.ToString() | Should -Be '3.0.0'
    $stagedManifestData.PrivateData.PSData.Prerelease | Should -Be 'rc1'
  }

  It 'refuses publishing when the checkout does not have the matching tag' -Skip:($PSEdition -ne 'Core') {
    Mock git { 'v2.9.4' }
    Mock Publish-PSResource

    { & $publishScript -Version 3.0.0 -Publish -NuGetApiKey test } |
    Should -Throw "*requires HEAD to have the exact tag 'v3.0.0'*"
    Assert-MockCalled Publish-PSResource -Times 0 -Exactly
  }

  It 'publishes the exact package that was built and validated' -Skip:($PSEdition -ne 'Core') {
    $package = & $publishScript -OutputDirectory TestDrive:/release
    Mock git { $global:LASTEXITCODE = 0; 'v3.0.0' }
    Mock Publish-PSResource

    & $publishScript -Version 3.0.0 -PackagePath $package -Publish -NuGetApiKey test -Confirm:$false

    Assert-MockCalled Publish-PSResource -Times 1 -Exactly -ParameterFilter {
      $NupkgPath -eq $package -and $Repository -eq 'PSGallery'
    }
  }

  It 'refuses a package whose metadata does not match the release version' -Skip:($PSEdition -ne 'Core') {
    $package = & $publishScript -Version 3.0.0-rc1 -OutputDirectory TestDrive:/release
    Mock git { $global:LASTEXITCODE = 0; 'v3.0.0' }
    Mock Publish-PSResource

    { & $publishScript -Version 3.0.0 -PackagePath $package -Publish -NuGetApiKey test } |
    Should -Throw "*Package metadata does not match requested version '3.0.0'*"
    Assert-MockCalled Publish-PSResource -Times 0 -Exactly
  }
}
