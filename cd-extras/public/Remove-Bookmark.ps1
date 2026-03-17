<#
.SYNOPSIS
Remove bookmarks from one or more directories.

.PARAMETER Pattern
The pattern to match. This should either be a leaf name of directories you want to unmark
or a PowerShell wildcard pattern to be matched against the full directory path. ($PWD by default.)

.EXAMPLE
PS C:\temp> # unmark the current directory
PS C:\temp> unmark

.EXAMPLE
PS C:\temp> # remove all bookmarks
PS C:\temp> unmark *

.LINK
Get-Bookmark
Add-Bookmark
Get-FrecentLocation
Set-FrecentLocation
#>

function Remove-Bookmark() {

  [OutputType([void])]
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Position = 0, ValueFromPipeline)]
    [SupportsWildcards()]
    [string] $Pattern = $PWD
  )

  Begin {
    $recents = $recent.Values.Where{ $_.Favour }
    $accepted = @()
  }

  Process {
    $accepted += $recents.Where{
      !($_ -in $accepted) -and
      ($_.Path -like $Pattern -or (Split-Path -Leaf $_.Path) -eq $Pattern) -and
      ($PSCmdlet.ShouldProcess($_.Path)) }
  }

  End {
    $accepted | % { Unfavour $_ }
  }
}
