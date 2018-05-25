function CompleteStack {
  param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)

  $stack = if ($commandName -match 'Redo|\+') {Get-Stack -Redo} else {Get-Stack -Undo}
  if (-not $stack) { return }

  $matches = @($stack) -match $wordToComplete |
    % {
    @{
      short = $_;
      long  = $_;
      index = [array]::IndexOf($stack, $_) + 1
    }
  }

  EmitIndexedCompletion @($matches)
}