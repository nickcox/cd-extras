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

  [OutputType([IndexedPath])]
  [CmdletBinding(DefaultParameterSetName = '')]
  param(
    [Parameter(ParameterSetName = 'First')] [ushort] $First = $cde.MaxRecentCompletions,
    [Parameter(ValueFromRemainingArguments)] [string[]] $Terms
  )

  $recents = @(GetFrecent $First $Terms)

  if ($recents.Count) { IndexPaths $recents }
}
