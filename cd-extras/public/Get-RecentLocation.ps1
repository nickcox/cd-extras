function Get-RecentLocation {

  [OutputType([IndexedPath])]
  [CmdletBinding(DefaultParameterSetName = '')]
  param(
    [Parameter(ParameterSetName = 'First')] [ushort] $First = $cde.MaxRecentCompletions,
    [Parameter(ValueFromRemainingArguments)] [string[]] $Terms
  )

  $recents = @(GetRecent $First $Terms)

  if ($recents.Count) { IndexPaths $recents }
}
