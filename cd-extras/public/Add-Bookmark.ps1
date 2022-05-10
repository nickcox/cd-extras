<#
.SYNOPSIS
Bookmarks a directory to promote it to the top of the frecent locations list.

.PARAMETER Path
The path to bookmark ($PWD by default).

.EXAMPLE
PS C:\temp> # bookmark the current directory
PS C:\temp> mark
PS C:\temp> Get-Bookmark
C:\temp

.EXAMPLE
PS C:\temp> # bookmark another directory
PS C:\temp> mark /
PS C:\temp> Get-Bookmark
C:\

.LINK
Get-Bookmark
Remove-Bookmark
Get-FrecentLocation
Set-FrecentLocation
#>

function Add-Bookmark() {

  [OutputType([void])]
  param(
    [Parameter(Position = 0, ValueFromPipeline)] [string] $Path = $PWD
  )

  Process { if (Test-Path $Path) { UpdateRecent (Resolve-Path $Path) $true } }
}
