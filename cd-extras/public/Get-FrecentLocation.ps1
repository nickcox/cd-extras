<#
.SYNOPSIS
Retrieves a list of your most frecently used locations. (Excluding the current directory.)

.PARAMETER First
The number of locations to return ($cde.MaxRecentCompletions by default).

.PARAMETER Terms
Terms to match, separated with spaces or commas. The last term must match the leaf name
of a directory in order to be considered a match. The current directory is always excluded from
the list.

.EXAMPLE
PS C:\temp> # get the entire list
PS C:\temp> Get-FrecentLocation

n Name             Path
 - ----             ----
 1 PowerShell       C:\Temp\PowerShell
 2 thread           C:\Temp\thread
 3 two              C:\Temp\two
 4 abc_app          C:\Temp\abc_app
 5 test             C:\Temp\test
 ...

.EXAMPLE
PS C:\temp> # get locations matching the given terms
PS C:\temp> Get-FrecentLocation temp abc

n Name      Path
- ----      ----
1 abc def   C:\Temp\abc def
2 abc_app   C:\Temp\abc_app
3 abc-infra C:\Temp\abc-infra

.EXAMPLE
PS C:\temp> # get the first (most frecent) location matching the given terms
PS C:\temp> Get-FrecentLocation temp abc -f 1

n Name      Path
- ----      ----
1 abc def   C:\Temp\abc def

.LINK
Add-Bookmark
Remove-Bookmark
Set-FrecentLocation
Remove-RecentLocation
#>

function Get-FrecentLocation {

  [OutputType([object[]])]
  param(
    [Parameter(ParameterSetName = 'First')] [uint16] $First = $cde.MaxRecentCompletions,
    [Parameter(ValueFromRemainingArguments)] [string[]] $Terms
  )

  $recents = if ($cde.FrecentProvider) {
    function PathsEqual(
      [Management.Automation.PathInfo] $left,
      [Management.Automation.PathInfo] $right
    ) {
      if ($left.Provider.Name -cne $right.Provider.Name) { return $false }

      $comparison = if (
        $left.Provider.Name -ceq 'FileSystem' -and
        [Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT
      ) { [StringComparison]::OrdinalIgnoreCase }
      else { [StringComparison]::Ordinal }

      [string]::Equals(
        ($left.ProviderPath | RemoveTrailingSeparator),
        ($right.ProviderPath | RemoveTrailingSeparator),
        $comparison
      )
    }

    $providerResults = @(&$cde.FrecentProvider @Terms)
    $accepted = @()

    if ($First) {
      foreach ($providerResult in $providerResults) {
        if ($null -eq $providerResult) { continue }

        $path = "$providerResult"
        if ([string]::IsNullOrWhiteSpace($path)) { continue }

        $driveName = $null
        if (!$ExecutionContext.SessionState.Path.IsPSAbsolute($path, [ref]$driveName)) {
          Write-Error "FrecentProvider returned relative path '$path'. Providers must return absolute paths." `
            -Category InvalidData -TargetObject $providerResult
          continue
        }

        $resolved = Resolve-Path -LiteralPath $path -ErrorAction Ignore
        if (!$resolved) {
          Write-Error "FrecentProvider returned missing path '$path'. Providers must return existing directories." `
            -Category InvalidData -TargetObject $providerResult
          continue
        }

        if (!(Test-Path -LiteralPath $resolved.Path -PathType Container)) {
          Write-Error "FrecentProvider returned non-directory path '$path'. Providers must return existing directories." `
            -Category InvalidData -TargetObject $providerResult
          continue
        }

        if (PathsEqual $resolved $PWD) { continue }
        if ($accepted.Where{ PathsEqual $_ $resolved }) { continue }

        $accepted += $resolved
        if ($accepted.Count -ge $First) { break }
      }
    }

    $accepted.Path
  }
  else { @(GetFrecent $First $Terms) }

  if ($recents.Count) { IndexPaths $recents }
}
