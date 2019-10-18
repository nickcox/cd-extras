function CompleteAncestors {
  param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)
  $ups = Get-Ancestors -IncludeRoot
  if (-not $ups) { return }

  $valueToMatch = $wordToComplete | RemoveSurroundingQuotes
  $normalised = $valueToMatch | NormaliseAndEscape

  $ups | where Path -eq $valueToMatch |
  DefaultIfEmpty { $ups | where Name -match $normalised } |
  DefaultIfEmpty { $ups | where Path -match $normalised } |
  IndexedComplete
}