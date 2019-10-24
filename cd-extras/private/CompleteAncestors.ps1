function CompleteAncestors {
  param($commandName, $parameterName, $wordToComplete)
  $ups = Get-Ancestors

  $valueToMatch = $wordToComplete | RemoveSurroundingQuotes
  $normalised = $valueToMatch | NormaliseAndEscape

  $ups | where Path -eq $valueToMatch |
  DefaultIfEmpty { $ups | where Name -match $normalised } |
  DefaultIfEmpty { $ups | where Path -match $normalised } |
  IndexedComplete |
  DefaultIfEmpty { $null }
}