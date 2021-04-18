function CompleteStack {
  param($commandName, $parameterName, $wordToComplete)

  $stack = if (
    $commandName -match 'Redo' -or
    ($aliased = (Get-Alias $commandName -ea Ignore).ResolvedCommandName -and $aliased -match 'Redo')
  ) { (Get-Stack -Redo) }
  else { (Get-Stack -Undo) }

  if (!$stack) { return }

  @($stack) | Where Path -match ($wordToComplete | RemoveSurroundingQuotes | RemoveTrailingSeparator | Escape) |
  IndexedComplete |
  Select -First $cde.MaxRecentCompletions |
  DefaultIfEmpty { $null }
}
