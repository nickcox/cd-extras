function CompleteStack {
  param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)

  $stack = if (
    $commandName -and
    $commandName -match 'Redo' -or
    (
      $aliased = (Get-Alias $commandName -ea Ignore).ResolvedCommandName -and
      $aliased -match 'Redo'
    )
  ) { (Get-Stack -Redo) }
  else { (Get-Stack -Undo) }

  if (!$stack) { return }

  @($stack) | Where Path -match ($wordToComplete | RemoveSurroundingQuotes | RemoveTrailingSeparator | Escape) |
  IndexedComplete |
  DefaultIfEmpty { $null }
}
