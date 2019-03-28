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
    $trailChar = if ($_.PSIsContainer) {${/}}
    $fullPath = $_ | 
      Select -Expand PSPath | 
      EscapeSquareBrackets |
      Convert-Path | 
      EscapeSquareBrackets # that's right... twice :D

    $completionText = if ($wordToComplete -match '^\.{1,2}$') {
      $wordToComplete
    }
    elseif (!($wordToComplete | IsRooted) -and ($fullPath | IsDescendedFrom ..)) {
      $_ | Resolve-Path -Relative
    }
    elseif ($homeDir = (Get-Location).Provider.Home) {
      $_ -replace "^$(NormaliseAndEscape $homeDir)", "~"
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
      (test-path Function:\Format-ColorizedFilename)) {
      Format-ColorizedFilename $_
    }
    else {
      $_.PSChildName
    }

    [Management.Automation.CompletionResult]::new(
      $completionText,
      $listItemText,
      'ParameterValue',
      ($fullPath |DefaultIfEmpty {$_})
    )
  }

  $switches = @{ File = $filesOnly; Directory = $dirsOnly; Force = $force }

  $dotted = if ($wordToComplete -match '^\.{3,}') {
    # if we're multi-dotting then first replace dots with the correct ancestor
    $dots = $Matches[0].Trim()
    $up = Get-Up ($dots.Length - 1)
    $up + $wordToComplete.Replace($dots, '')
  }
  else { $wordToComplete }

  $completions = Expand-Path @switches $dotted -MaxResults $cde.MaxCompletions

  #replace cdable_vars
  $variCompletions = if (
    $cde.CDABLE_VARS -and
    $wordToComplete -match '[^/\\]+' -and
    ($maybeVar = Get-Variable "$($Matches[0])*" |
        Where {$_.Value -and (Test-Path ($_.Value) -PathType Container)} |
        Select -Expand Value)
  ) {
    Expand-Path @switches ($wordToComplete -replace $Matches[0], $maybeVar) -MaxResults $cde.MaxCompletions
  }

  @($completions) + @($variCompletions) |
    Select -Unique |
    Select -First $cde.MaxCompletions |
    CompletionResult
}