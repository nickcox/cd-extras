function CompletePaths {
  param($commandName, $parameterName, $wordToComplete, $commandAst, $boundParameters)

  # given a full path, $_, return a fully formed completion result
  # logic: use a relative path if the supplied word isn't rooted (e.g. /temp/... or ~/... C:\...)
  # *and* the resolved path is a child of the current directory or its parent
  # for absolute paths, replace home dir location with tilde
  filter CompletionResult {
    $friendly = $_
    if (-not (IsRooted $wordToComplete) -and (PathIsDescendedFrom .. $_)) {
      $friendly = Resolve-Path -Relative $_
    }
    elseif ($homeDir = (Get-Location).Provider.Home) {
      $friendly = $_ -replace "^$(NormaliseAndEscape $homeDir)", "~"
    }

    # add normalised trailing directory separator; quote if contains spaces
    $completionText = $friendly -replace '[/|\\]$', '' | % {
      if ($_ -notmatch ' ') { "$_${/}" }
      else { "'$_${/}'" }
    }

    New-Object Management.Automation.CompletionResult `
      $completionText,
    $friendly,
    'ParameterValue',
    $_
  }

  $dirs = if ($wordToComplete -match '^\.{3,}') {
    # if we're multi-dotting...
    $dots = $Matches[0].Trim()
    $up = Get-Up ($dots.Length - 1)
    Expand-Path -Directory ($up + $wordToComplete.Replace($dots, ''))
  }
  else {
    Expand-Path -Directory $wordToComplete
  }

  #replace cdable_vars
  $variDirs = if (
    $cde.CDABLE_VARS -and
    $wordToComplete -match '[^/|\\]+' -and
    ($maybeVar = Get-Variable "$($Matches[0])*" |
        Where {$_.Value -and (Test-Path ($_.Value) -PathType Container)} |
        Select -ExpandProperty Value)
  ) {
    Expand-Path -Directory ($wordToComplete -replace $Matches[0], $maybeVar)
  }
  else { @() }

  (@($dirs) + @($variDirs)) | Sort-Object -Unique | CompletionResult
}