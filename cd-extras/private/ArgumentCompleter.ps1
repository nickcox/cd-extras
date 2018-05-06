function Complete($wordToComplete) {

  # logic:
  # use a relative path if the supplied word isn't rooted (e.g. /temp/... or ~/... C:\...)
  # *and* the resolved path is a child of the current directory or its parent
  $shouldBeRelative = {
    -not (IsRooted $wordToComplete) -and
    (Resolve-Path $_) -like (Resolve-Path ..).Path + "*" # eww
  }

  # and trailing directory separator; quote if contains spaces
  $bowOnIt = { if ($_ -notmatch ' ') { "$_${/}" } else { "'$_${/}'" }   }

  $dirs = Expand-Path $wordToComplete -Directory |
    % { if (&$shouldBeRelative) { Resolve-Path -Relative $_} else {$_} }

  $variDirs =
  Get-Variable "$wordToComplete*" |
    Where { $cde.CDABLE_VARS -and (Test-Path ($_.Value) -PathType Container) } |
    Select -ExpandProperty Value

  (@($dirs) + @($variDirs)) |
  Select -Unique |
  % {
    New-Object Management.Automation.CompletionResult (&$bowOnIt), $_, 'ParameterValue', $_
  }
}
function RegisterArgumentCompleter([array]$commands) {
  Register-ArgumentCompleter -CommandName $commands -ParameterName Path -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)

    Complete $wordToComplete
  }
}