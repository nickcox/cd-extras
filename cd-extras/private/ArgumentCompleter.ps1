function Complete($wordToComplete) {
  $currentDir = New-Object Uri ($pwd)

  $dirs = Expand-Path $wordToComplete $cde.CD_PATH -Directory |
    % { if ($currentDir.IsBaseOf((New-Object Uri ($_)))) { Resolve-Path -Relative $_} else {$_} } |
    % { "$_" + [System.IO.Path]::DirectorySeparatorChar } | # put a bow on it
    % { if ($_ -match ' ') { "'$_'" } else { $_ } } | # quote if contains spaces
    Select -Unique

  $dirs |% {
    New-Object Management.Automation.CompletionResult $_, $_, "ParameterValue", $_
  }
}
function RegisterArgumentCompleter([array]$commands) {
  Register-ArgumentCompleter -CommandName $commands -ParameterName Path -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)

    Complete $wordToComplete
  }
}