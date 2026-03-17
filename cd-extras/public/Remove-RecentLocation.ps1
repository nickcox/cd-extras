<#
.SYNOPSIS
Remove one or more directories from the recent locations list. Note that the list is shared by both
the Get-RecentLocation and Get-FrecentLocation commands, so removing a location will make it unavailable
in both commands.

.PARAMETER Pattern
The pattern to match. This should either be a leaf name of directories to remove or a PowerShell wildcard
pattern to be matched against the full directory path. ($PWD by default.)

.EXAMPLE
PS C:\temp> # remove the current directory
PS C:\temp> Remove-RecentLocation

.EXAMPLE
PS C:\temp> # remove all recent locations
PS C:\temp> Remove-RecentLocation *

.LINK
Get-RecentLocation
Set-RecentLocation
Get-FrecentLocation
Set-FrecentLocation
#>

function Remove-RecentLocation {

  [OutputType([void])]
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Position = 0, ValueFromPipeline)]
    [SupportsWildcards()]
    [string] $Pattern = $PWD
  )

  Begin {
    $recents = @(GetRecent $cde.MaxRecentDirs) + @($PWD)
    $accepted = @()
  }

  Process {
    $accepted += $recents.Where{
      !($_ -in $accepted) -and
      ($_ -like $Pattern -or (Split-Path -Leaf $_) -eq $Pattern) -and
      ($PSCmdlet.ShouldProcess($_)) }
  }

  End {
    if ($accepted) { RemoveRecent $accepted }
  }
}
