Describe 'release metadata and build' {
  BeforeAll {
    $repositoryRoot = (Resolve-Path "$PSScriptRoot/..").Path
    $manifestPath = Join-Path $repositoryRoot 'cd-extras/cd-extras.psd1'
    $changelogPath = Join-Path $repositoryRoot 'CHANGELOG.md'
    $publishScript = Join-Path $repositoryRoot 'publishme.ps1'
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
    $manifest.ExportedFunctions.Keys | Sort-Object | Should -Be @(
      'Add-Bookmark'
      'Clear-Stack'
      'Expand-Path'
      'Get-Ancestors'
      'Get-Bookmark'
      'Get-CdExtrasOption'
      'Get-FrecentLocation'
      'Get-RecentLocation'
      'Get-Stack'
      'Get-Up'
      'Redo-Location'
      'Remove-Bookmark'
      'Remove-RecentLocation'
      'Set-CdExtrasOption'
      'Set-FrecentLocation'
      'Set-LocationEx'
      'Set-RecentLocation'
      'Step-Up'
      'Switch-LocationPart'
      'Undo-Location'
    )
    $manifest.ExportedAliases.Keys | Sort-Object | Should -Be @(
      '..'
      '~'
      '~~'
      'cd-'
      'cd:'
      'cd+'
      'cdf'
      'cdr'
      'dirs'
      'dirsc'
      'getocd'
      'gup'
      'mark'
      'setocd'
      'unmark'
      'up'
      'xpa'
      'xup'
    )
  }

  It 'builds stable metadata and help without publishing' {
    $stagedModule = & $publishScript -OutputDirectory TestDrive:/release
    $stagedManifest = Test-ModuleManifest (Join-Path $stagedModule 'cd-extras.psd1')

    $stagedManifest.Version.ToString() | Should -Be '3.0.0'
    $stagedManifest.PrivateData.PSData.Prerelease | Should -BeNullOrEmpty
    $stagedManifest.PrivateData.PSData.ReleaseNotes.Trim() |
    Should -Be $release.Groups['notes'].Value.Trim()
    Test-Path -LiteralPath (Join-Path $stagedModule 'about_Cd-Extras.help.txt') | Should -BeTrue
  }

  It 'retains a requested prerelease label in a build' {
    $stagedModule = & $publishScript -Version 3.0.0-rc1 -OutputDirectory TestDrive:/release
    $stagedManifest = Test-ModuleManifest (Join-Path $stagedModule 'cd-extras.psd1')

    $stagedManifest.Version.ToString() | Should -Be '3.0.0'
    $stagedManifest.PrivateData.PSData.Prerelease | Should -Be 'rc1'
  }

  It 'refuses publishing when the checkout does not have the matching tag' {
    Mock git { 'v2.9.4' }
    Mock Publish-Module

    { & $publishScript -Version 3.0.0 -Publish -NuGetApiKey test } |
    Should -Throw "*requires HEAD to have the exact tag 'v3.0.0'*"
    Assert-MockCalled Publish-Module -Times 0 -Exactly
  }
}
