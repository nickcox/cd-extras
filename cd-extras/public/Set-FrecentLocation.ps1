function Set-FrecentLocation {
  [OutputType([void])]
  [CmdletBinding(SupportsShouldProcess, DefaultParameterSetName = 'n')]
  param(
    [Parameter(ParameterSetName = 'n', Position = 0)]
    [ushort] $n = 1,

    [Parameter(ParameterSetName = 'named', Position = 0)]
    [string[]] $NamePart,

    [Alias("l")]
    [Parameter(ParameterSetName = 'list', Mandatory)]
    [switch] $List,
    [Parameter(ParameterSetName = 'list')]
    [ushort] $First = $cde.MaxRecentCompletions,
    [Parameter(ParameterSetName = 'list', ValueFromRemainingArguments)]
    [string[]] $Terms,

    [Alias("p")]
    [Parameter(ParameterSetName = 'prune', Mandatory)]
    [switch] $Prune,
    [Parameter(ParameterSetName = 'prune', Position = 1, Mandatory, ValueFromPipeline)]
    [string] $PrunePattern,

    [switch] $PassThru
  )

  if ($PSCmdlet.ParameterSetName -eq 'n' -and $n -ge 1) {
    $recents = @(GetFrecent $n $NamePart)
    if ($recents.Count -ge $n) { Set-LocationEx $recents[$n - 1] -PassThru:$PassThru }
  }

  if ($PSCmdlet.ParameterSetName -eq 'named') {
    $recents = @(GetFrecent 1 $NamePart)
    if ($recents) { Set-LocationEx $recents[0] -PassThru:$PassThru }
    elseif ($cde.RecentDirsFallThrough -and $NamePart.Length -eq 1) { Set-LocationEx $NamePart[0] -PassThru:$PassThru }
    else { Write-Error "Could not find '$NamePart' in recent locations." -ErrorAction Stop }
  }

  if ($PSCmdlet.ParameterSetName -eq 'list' -and $List) {
    Get-FrecentLocation -First $First -Terms $Terms
  }

  if ($PSCmdlet.ParameterSetName -eq 'prune' -and $Prune) {
    Remove-RecentLocation -Pattern $PrunePattern
  }
}
