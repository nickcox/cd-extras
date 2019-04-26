function CompletePaths {
  param(
    [Switch] $dirsOnly,
    [Switch] $filesOnly,
    $commandName,
    $parameterName,
    $wordToComplete,
    $commandAst,
    $boundParameters
  )

  $force = $boundParameters -and [bool]$boundParameters['Force']

  # given a full path, $_, return a fully formed completion result
  # logic: use a relative path if the supplied word isn't rooted (like /temp/... or ~/... C:\...)
  # *and* the resolved path is a child of the current directory or its parent
  # for absolute paths, replace home dir location with tilde
  filter CompletionResult {

    # add normalised trailing directory separator; quote if contains spaces
    $trailChar = if ($_.PSIsContainer) { ${/} }
    $fullPath = $_ | select -Expand PSPath | Convert-Path

    $completionText = if ($wordToComplete -match '^\.{1,2}$') {
      $wordToComplete
    }
    elseif (!($wordToComplete | IsRooted) -and ($fullPath | IsDescendedFrom ..)) {
      $_ | Resolve-Path -Relative
    }
    elseif ($homeDir = (Get-Location).Provider.Home) {
      $_ -replace "^$($homeDir | NormaliseAndEscape)", "~"
    }
    else {
      $fullPath
    }

    $completionText = $completionText |
      RemoveTrailingSeparator |
      SurroundAndTerminate $trailChar

    # there seems to be a weird bug in PowerShell where square brackets must be escaped
    # by every/many(?) command(s) _except_ Get-ChildItem, where they must *not* be escaped
    if ($commandName -ne 'Get-ChildItem') {
      $completionText = $completionText | EscapeSquareBrackets
    }

    # hack to support registry provider
    if ($_.PSProvider.Name -eq 'Registry') {
      $completionText = $completionText -replace $_.PSDrive.Root, "$($_.PSDrive.Name):"
    }

    # dirColors support
    $listItemText = if (
      ($cde.ColorCompletion) -and
      ($_.PSProvider.Name -eq 'FileSystem') -and
      (Test-Path Function:\Format-ColorizedFilename)) {
      Format-ColorizedFilename $_
    }
    else {
      $_.PSChildName
    }

    [Management.Automation.CompletionResult]::new(
      $completionText,
      $listItemText,
      'ParameterValue',
      ($fullPath | DefaultIfEmpty { $_ })
    )
  }

  $switches = @{ File = $filesOnly; Directory = $dirsOnly; Force = $force }

  $completions = Expand-Path @switches $wordToComplete -MaxResults $cde.MaxCompletions

  #replace cdable_vars
  $variCompletions = if (
    $cde.CDABLE_VARS -and
    $wordToComplete -match '[^/\\]+' -and
    ($maybeVar = Get-Variable "$($Matches[0])*" -ValueOnly | where { Test-Path $_ -PathType Container })
  ) {
    Expand-Path @switches ($wordToComplete -replace $Matches[0], $maybeVar) -MaxResults $cde.MaxCompletions
  }

  @($completions) + @($variCompletions) |
  select -Unique |
  select -First $cde.MaxCompletions |
  CompletionResult
}