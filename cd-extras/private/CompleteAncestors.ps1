function CompleteAncestors {
  param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)
  $ups = Export-Up -NoGlobals -From .. -IncludeRoot
  if (-not $ups) { return }

  $values = @($ups.Values.GetEnumerator())

  filter Completions {
    @{
      short = $_.Key
      long  = $_.Value
      index = ($values.IndexOf($_.Value) + 1)
    }
  }

  $valueToMatch = $wordToComplete | RemoveSurroundingQuotes
  $normalised = $valueToMatch | NormaliseAndEscape

  $ups.GetEnumerator() | where Value -eq $valueToMatch |
    DefaultIfEmpty { $ups.GetEnumerator() | where Key -match $normalised } |
    DefaultIfEmpty { $ups.GetEnumerator() | where Value -match $normalised } |
    Completions |
    IndexedComplete
}