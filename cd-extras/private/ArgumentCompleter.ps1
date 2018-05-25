function Complete {
  param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)

  # logic:
  # use a relative path if the supplied word isn't rooted (e.g. /temp/... or ~/... C:\...)
  # *and* the resolved path is a child of the current directory or its parent
  $resolve = {
    if (
      -not (IsRooted $wordToComplete) -and
      (Resolve-Path $_) -like (Resolve-Path ..).Path + "*") {
      Resolve-Path -Relative $_
    }
    else {$_}
  }

  # and trailing directory separator; quote if contains spaces
  $bowOnIt = { param($x) if ($x -notmatch ' ') { "$x${/}" } else { "'$x${/}'" } }

  $dirs = if ($wordToComplete -match '^\.{3,}') {
    # if we're multi-dotting...
    $dots = $Matches[0].Trim()
    $up = Get-Up ($dots.Length - 1)
    Expand-Path -Directory ($up + $wordToComplete.Replace($dots, ''))
  }
  else {
    Expand-Path -Directory $wordToComplete
  }

  $variDirs =
  Get-Variable "$wordToComplete*" |
    Where { $cde.CDABLE_VARS -and $_.Value -and (Test-Path ($_.Value) -PathType Container) } |
    Select -ExpandProperty Value

  (@($dirs) + @($variDirs)) |
    Sort -Unique |
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