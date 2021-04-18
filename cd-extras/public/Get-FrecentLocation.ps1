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
