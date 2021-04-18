function CompleteAncestors {
  param($commandName, $parameterName, $wordToComplete)
  $ups = Get-Ancestors
  if (!$ups) { return }

  $valueToMatch = $wordToComplete | RemoveSurroundingQuotes
  $normalised = $valueToMatch | NormaliseAndEscape

  $ups | Where Path -eq $valueToMatch |
  DefaultIfEmpty { $ups | Where Name -match $normalised } |
  DefaultIfEmpty { $ups | Where Path -match $normalised } |
  IndexedComplete |
  DefaultIfEmpty { $null }
}
