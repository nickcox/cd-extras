function RegisterArgumentCompleter([array]$commands) {

  Register-ArgumentCompleter -CommandName $commands -ParameterName Path -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)

    $dirs = Expand-Path $wordToComplete $cde.CD_PATH |
      Where-Object {$_ -is [System.IO.DirectoryInfo]} |
      % { $_.Fullname } |
      % { if ($_ -match ' ') { "'$_'" } else { $_ } } # quote if contains spaces

    $dirs | % {
      New-Object Management.Automation.CompletionResult $_, $_, "ParameterValue", $_
    }
  }.GetNewClosure()
}