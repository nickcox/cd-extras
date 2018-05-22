function Complete($wordToComplete) {

  # logic:
  # use a relative path if the supplied word isn't rooted (e.g. /temp/... or ~/... C:\...)
  # *and* the resolved path is a child of the current directory or its parent
  $resolve = {
    if (
      -not (IsRooted $wordToComplete) -and
      (Resolve-Path $_) -like (Resolve-Path ..).Path + "*") {
      Resolve-Path -Relative $_
    }
    else {
      $_
    }
  }

  # and trailing directory separator; quote if contains spaces
  $bowOnIt = { param($x) if ($x -notmatch ' ') { "$x${/}" } else { "'$x${/}'" } }

  $dirs = if ($wordToComplete -match '^\.{3,}') {
    # if we're multi-dotting...
    $dots = $Matches[0].Trim()
    Expand-Path (
      Join-Path (Get-Up ($dots.Length - 1)) `
        $wordToComplete.Replace($dots, '')
    )
  }
  else {
    Expand-Path $wordToComplete -Directory
  }

  $variDirs =
  Get-Variable "$wordToComplete*" |
    Where { $cde.CDABLE_VARS -and (Test-Path ($_.Value) -PathType Container) } |
    Select -ExpandProperty Value

  (@($dirs) + @($variDirs)) |
    Select -Unique |
    % {

    $resolved = (&$resolve)

    $completionText = (&$bowOnIt $resolved)

    $listItemText = if (($_ | Split-Path -Parent) -eq (Resolve-Path .)) {
      $_ | Split-Path -Leaf
    }
    else { $_ }

    New-Object Management.Automation.CompletionResult `
      $completionText,
    $listItemText,
    'ParameterValue',
    $_
  }
}
function RegisterArgumentCompleter([array]$commands) {
  Register-ArgumentCompleter -CommandName $commands -ParameterName Path -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)

    Complete $wordToComplete
  }
}