<#
.SYNOPSIS
Retrieves the list of bookmarked locations, ordered by how often they've been used.

.PARAMETER First
The number of bookmarks to return. (The entire list is returned by default.)

.EXAMPLE
PS C:\temp> # get the entire list
PS C:\temp> Get-Bookmark
C:\someDir
C:\someOtherDir

.EXAMPLE
PS C:\temp> # get the most used bookmark
PS C:\temp> Get-Bookmark 1
C:\someDir

.LINK
Add-Bookmark
Remove-Bookmark
Get-FrecentLocation
Set-FrecentLocation
#>

function Get-Bookmark {

  [OutputType([string[]])]
  param(
    [Parameter(Position = 0)] [ushort] $First = $cde.MaxRecentCompletions
  )
  $recent.Values.Where{ $_.Favour } |
  Sort-Object EnterCount, LastEntered -Descending |
  select -First $First -Expand Path
}
