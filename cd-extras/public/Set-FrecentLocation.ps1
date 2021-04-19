<#
.SYNOPSIS
Navigate to a frecently used location or work with the frecent locations list.

.PARAMETER n
Navigate to the nth most frecent location.

.PARAMETER Terms
Navigate to the most frecent location matching the given terms. This can be a single term or a comma separated
list. The last (or only) term must match the leaf name of a directory in order to be considered a match.

.PARAMETER List
List the matching frecent locations instead of changing directory. Equivalent to the Get-FrecentLocation command.
The current directory is always excluded from the list.

.PARAMETER ListTerms
Terms to matching when listing frecent locations. This can be a single term or a comma or space separated list.
The last (or only) term must match the leaf name of a directory in order to be considered a match.

.PARAMETER First
When listing frecent locations, limits the list to the first n matches.

.PARAMETER Prune
Prune the recent locations list. Equivalent to the Remove-RecentLocation command.

.PARAMETER PrunePattern
The pattern to match when pruning recent locations. This should either be a leaf name of directories to remove
or a PowerShell wildcard pattern to be matched against the full directory path. ($PWD by default.)

.PARAMETER Mark
Bookmarks a directory to promote it to the top of the frecent locations list. Equivalent to the Add-Bookmark command.

.PARAMETER MarkPath
Path of the directory to bookmark. ($PWD by default.)

.PARAMETER Unmark
Remove bookmarks from one or more directories. Equivalent to the Remove-Bookmark command.

.PARAMETER UnmarkPattern
The pattern to match. This should either be a leaf name of directories you want to unmark or a PowerShell wildcard
pattern to be matched against the full directory path. ($PWD by default.)

.EXAMPLE
PS ~> # navigate to the most frecent location matching the given terms
PS ~> cdf temp,py
PS C:\temp\python>

.EXAMPLE
PS ~> # list frecent locations matching the given terms
PS ~> cdf -l temp,py

n Name   Path
- ----   ----
1 python C:\Temp\python

.EXAMPLE
PS ~> # remove the current directory from the recent locations list.
PS ~> cdf -p

.LINK
Get-FrecentLocation
Remove-FrecentLocation
Add-Bookmark
Remove-Bookmark
#>

function Set-FrecentLocation {

  [OutputType([void])]
  [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'n')]
  param(
    [Parameter(ParameterSetName = 'n', Position = 0)]
    [ushort] $n = 1,

    [Parameter(ParameterSetName = 'named', Position = 0)]
    [string[]] $Terms,

    [Alias('l')]
    [Parameter(ParameterSetName = 'list', Mandatory)]
    [switch] $List,
    [Parameter(ParameterSetName = 'list')]
    [ushort] $First = $cde.MaxRecentCompletions,
    [Parameter(ParameterSetName = 'list', ValueFromRemainingArguments)]
    [string[]] $ListTerms,

    [Alias('p')]
    [Parameter(ParameterSetName = 'prune', Mandatory)]
    [switch] $Prune,
    [Parameter(ParameterSetName = 'prune', Position = 1, ValueFromPipeline)]
    [SupportsWildcards()]
    [string] $PrunePattern = $PWD,

    [Alias('m')]
    [Parameter(ParameterSetName = 'mark', Mandatory)]
    [switch] $Mark,
    [Parameter(ParameterSetName = 'mark', Position = 1, ValueFromPipeline)]
    [string] $MarkPath = $PWD,

    [Alias('u')]
    [Parameter(ParameterSetName = 'unmark', Mandatory)]
    [switch] $Unmark,
    [Parameter(ParameterSetName = 'unmark', Position = 1, ValueFromPipeline)]
    [string] $UnmarkPattern = $PWD,

    [switch] $PassThru
  )

  if ($PSCmdlet.ParameterSetName -eq 'n' -and $n -ge 1) {
    $recents = @(GetFrecent $n)
    if ($recents.Count -ge $n) { Set-LocationEx $recents[$n - 1] -PassThru:$PassThru }
  }

  if ($PSCmdlet.ParameterSetName -eq 'named') {
    $recents = @(GetFrecent 1 $Terms)
    if ($recents) { Set-LocationEx $recents[0] -PassThru:$PassThru }
    elseif ($cde.RecentDirsFallThrough -and $Terms.Length -eq 1) { Set-LocationEx $Terms[0] -PassThru:$PassThru }
    else { Write-Error "Could not find '$Terms' in frecent locations." -ErrorAction Stop }
  }

  if ($PSCmdlet.ParameterSetName -eq 'list' -and $List) {
    Get-FrecentLocation -First $First -Terms $ListTerms
  }

  if ($PSCmdlet.ParameterSetName -eq 'prune' -and $Prune) {
    Remove-RecentLocation -Pattern $PrunePattern @args
  }

  if ($PSCmdlet.ParameterSetName -eq 'mark') {
    Add-Bookmark -Path $MarkPath
  }

  if ($PSCmdlet.ParameterSetName -eq 'unmark') {
    Remove-Bookmark -Pattern $UnmarkPattern
  }
}
