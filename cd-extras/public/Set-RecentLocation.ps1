<#
.SYNOPSIS
Navigate to a recently used location or work with the recent locations list.

.PARAMETER n
Navigate to the nth most recent location.

.PARAMETER Terms
Navigate to the most recent location matching the given terms. This can be a single term or a comma separated
list. The last (or only) term must match the leaf name of a directory in order to be considered a match.

.PARAMETER List
List the matching recent locations instead of changing directory. Equivalent to the Get-RecentLocation command.
The current directory is always excluded from the list.

.PARAMETER ListTerms
Terms to matching when listing recent locations. This can be a single term or a comma or space separated list.
The last (or only) term must match the leaf name of a directory in order to be considered a match.

.PARAMETER First
When listing recent locations, limits the list to the first n matches.

.PARAMETER Prune
Prune the recent locations list. Equivalent to the Remove-RecentLocation command.

.PARAMETER PrunePattern
The pattern to match when pruning recent locations. This should either be a leaf name of directories to remove
or a PowerShell wildcard pattern to be matched against the full directory path. ($PWD by default.)

.EXAMPLE
PS ~> # navigate to the most recent location matching the given terms
PS ~> cdr temp,py
PS C:\temp\python>

.EXAMPLE
PS ~> # list recent locations matching the given terms
PS ~> cdr -l temp,py

n Name   Path
- ----   ----
1 python C:\Temp\python

.EXAMPLE
PS ~> # remove the current directory from the recent locations list.
PS ~> cdr -p

.LINK
Get-RecentLocation
Remove-RecentLocation
#>
function Set-RecentLocation {

  [OutputType([void])]
  [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'n')]
  param(
    [Parameter(ParameterSetName = 'n', Position = 0)]
    [ushort] $n = 1,

    [Alias('NamePart')]
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
    [Parameter(ParameterSetName = 'prune', Position = 1, Mandatory)]
    [SupportsWildcards()]
    [string] $PrunePattern,

    [switch] $PassThru
  )

  if ($PSCmdlet.ParameterSetName -eq 'n' -and $n -ge 1) {
    $recents = @(GetRecent $n)
    if ($recents.Count -ge $n) { Set-LocationEx $recents[$n - 1] -PassThru:$PassThru }
  }

  if ($PSCmdlet.ParameterSetName -eq 'named') {
    $recents = @(GetRecent 1 $Terms)
    if ($recents) { Set-LocationEx $recents[0] -PassThru:$PassThru }
    elseif ($cde.RecentDirsFallThrough -and $Terms.Length -eq 1) { Set-LocationEx $Terms[0] -PassThru:$PassThru }
    else { Write-Error "Could not find '$Terms' in recent locations." -ErrorAction Stop }
  }

  if ($PSCmdlet.ParameterSetName -eq 'list' -and $List) {
    Get-RecentLocation -First $First -Terms $ListTerms
  }

  if ($PSCmdlet.ParameterSetName -eq 'prune' -and $Prune) {
    Remove-RecentLocation -Pattern $PrunePattern @args
  }
}
