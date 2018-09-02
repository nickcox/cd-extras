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
  $escapedValue = $valueToMatch | Normalise | Escape

  $ups.GetEnumerator() |  Where Value -eq $valueToMatch |
    DefaultIfEmpty {$ups.GetEnumerator() | Where Key -match $escapedValue} |
    DefaultIfEmpty {$ups.GetEnumerator() | Where Value -match $escapedValue} |
    Completions |
    IndexedComplete
}