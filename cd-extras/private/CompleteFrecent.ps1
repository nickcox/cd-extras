function CompleteFrecent {
  param($commandName, $parameterName, $wordToComplete)

  if ($parameterName -eq 'n' -and $wordToComplete -match '^\d+$') { return }

  $recents = Get-FrecentLocation $wordToComplete

  if (!$recents) { return }

  @($recents) | Where Path -match ($wordToComplete | RemoveSurroundingQuotes | RemoveTrailingSeparator | Escape) |
  IndexedComplete ($parameterName -eq 'n') |
  DefaultIfEmpty { $null }
}
