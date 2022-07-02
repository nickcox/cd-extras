<#
.SYNOPSIS
Retrieves a list of your most recently used locations.

.PARAMETER First
The number of locations to return ($cde.MaxRecentCompletions by default).

.PARAMETER Terms
Terms to match, separated with spaces or commas. The last term must match the leaf name of a directory
in order to be considered a match.

.EXAMPLE
PS C:\temp> # get the entire list
PS C:\temp> Get-RecentLocation

 n Name             Path
 - ----             ----
 1 cd-extras        C:\Users\Nick\projects\cd-extras
 2 C:\              C:\
 3 thread           C:\Temp\thread
 4 PowerShell       C:\Temp\PowerShell
 5 two              C:\Temp\two
 ...

.EXAMPLE
PS C:\temp> # get locations matching the given terms
PS C:\temp> Get-RecentLocation temp abc

n Name      Path
- ----      ----
1 abc def   C:\Temp\abc def
2 abc_app   C:\Temp\abc_app
3 abc-infra C:\Temp\abc-infra

.EXAMPLE
PS C:\temp> # get the first (most recent) location matching the given terms
PS C:\temp> Get-FrecentLocation temp abc -f 1

n Name      Path
- ----      ----
1 abc def   C:\Temp\abc def

.LINK
Set-RecentLocation
Remove-RecentLocation
#>
function Get-RecentLocation {

  [OutputType([IndexedPath])]
  [CmdletBinding(DefaultParameterSetName = '')]
  param(
    [Parameter(ParameterSetName = 'First')] [uint16] $First = $cde.MaxRecentCompletions,
    [Parameter(ValueFromRemainingArguments)] [string[]] $Terms
  )

  $recents = @(GetRecent $First $Terms)

  if ($recents.Count) { IndexPaths $recents }
}
