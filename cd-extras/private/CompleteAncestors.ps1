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

  IndexedComplete ($ups.GetEnumerator() |
      Where Value -Match ($wordToComplete | RemoveSurroundingQuotes | Escape) |
      Completions)
}