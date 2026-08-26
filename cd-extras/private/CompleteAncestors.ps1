function CompleteAncestors {
  param($commandName, $parameterName, $wordToComplete)

  if ($parameterName -eq 'n' -and $wordToComplete -match '^\d+$') { return }

  $ups = Get-Ancestors
  if (!$ups) { return }

  $valueToMatch = $wordToComplete | RemoveSurroundingQuotes
  $normalised = $valueToMatch | NormaliseAndEscape

  $ups | Where Path -eq $valueToMatch |
  DefaultIfEmpty { $ups | Where Name -match $normalised } |
  DefaultIfEmpty { $ups | Where Path -match $normalised } |
  IndexedComplete
}
