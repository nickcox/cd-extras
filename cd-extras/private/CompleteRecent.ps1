function CompleteRecent {
  param($commandName, $parameterName, $wordToComplete)

  $recents = Get-RecentLocation $wordToComplete

  if (!$recents) { return }

  @($recents) | Where Path -match ($wordToComplete | RemoveSurroundingQuotes | RemoveTrailingSeparator | Escape) |
  IndexedComplete $false |
  DefaultIfEmpty { $null }
}
