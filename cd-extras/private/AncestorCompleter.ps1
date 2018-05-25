function CompleteAncestors {
  param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)
  $ups = Export-Up -NoGlobals -From ..
  if (-not $ups) { return }

  $keys = @($ups.Keys.GetEnumerator())
  $matches = $ups.GetEnumerator() |
    Where Key -Match (NormaliseAndEscape $wordToComplete) |
    % {
    @{
      short = $_.Key
      long  = $_.Value
      index = ($keys.IndexOf($_.Key) + 1)
    }
  }

  EmitIndexedCompletion @($matches)
}