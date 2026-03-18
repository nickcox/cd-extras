function CompleteFrecent {
  param($commandName, $parameterName, $wordToComplete)

  $recents = Get-FrecentLocation $wordToComplete

  if (!$recents) { return }

  @($recents) | Where Path -match ($wordToComplete | RemoveSurroundingQuotes | RemoveTrailingSeparator | Escape) |
  IndexedComplete ($parameterName -eq 'n') |
  DefaultIfEmpty { $null }
}
