function CompleteStack($wordToComplete, $direction) {
  $stack = if ($direction -eq '+') {Get-Stack -Redo} else {Get-Stack -Undo}
  if (-not $stack) { return }

  $matches = @($stack) -match $wordToComplete | Select -Unique

  @($matches) | % {
    $index = [array]::IndexOf($stack, $_) + 1
    New-Object Management.Automation.CompletionResult `
      "'$_'",
      "$index. $_" ,
      "ParameterValue",
      "$index. $_"
  }
}

function RegisterStackCompletion() {
  Register-ArgumentCompleter -CommandName 'Undo-Location' -ParameterName 'n' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)

    CompleteStack $wordToComplete '-'
  }

  Register-ArgumentCompleter -CommandName 'Redo-Location' -ParameterName 'n' -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)

    CompleteStack $wordToComplete '+'
  }
}