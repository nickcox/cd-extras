function RegisterArgumentCompleter([array]$commands) {

  Register-ArgumentCompleter -CommandName $commands -ParameterName Path -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)

    $currentDir = New-Object Uri ($pwd)

    $dirs = Expand-Path $wordToComplete $cde.CD_PATH |
      Where-Object {$_ -is [System.IO.DirectoryInfo]} |
      % { if ($currentDir.IsBaseOf((New-Object Uri ($_)))) { Resolve-Path -Relative $_} else {$_} } |
      % { if ($_ -match ' ') { "'$_'" } else { $_ } } | # quote if contains spaces
      % { $_ + [System.IO.Path]::DirectorySeparatorChar} | # put a bow on it
      Select -Unique

    $dirs | % {
      New-Object Management.Automation.CompletionResult $_, $_, "ParameterValue", $_
    }
  }.GetNewClosure()
}