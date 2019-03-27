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

  # given a full path, $_, return a fully formed completion result
  # logic: use a relative path if the supplied word isn't rooted (like /temp/... or ~/... C:\...)
  # *and* the resolved path is a child of the current directory or its parent
  # for absolute paths, replace home dir location with tilde
  filter CompletionResult {
    $friendly = $_ | Select -Expand PSPath | Convert-Path

    if ($wordToComplete -match '^\.{1,2}$') {
      $friendly = $wordToComplete
    }
    elseif (!($wordToComplete | IsRooted) -and ($_ | IsDescendedFrom ..)) {
      $friendly = Resolve-Path -Relative $_
    }
    elseif ($homeDir = (Get-Location).Provider.Home) {
      $friendly = $_ -replace "^$(NormaliseAndEscape $homeDir)", "~"
    }

    $trailChar = if ($_.PSIsContainer) {${/}}

    # add normalised trailing directory separator; quote if contains spaces
    $completionText = $friendly |
      RemoveTrailingSeparator |
      EscapeSquareBrackets |
      SurroundAndTerminate $trailChar

    # hack to support registry provider
    if ($_.PSProvider.Name -eq 'Registry') {
      $completionText = $completionText -replace $_.PSDrive.Root, "$($_.PSDrive.Name):"
    }

    [Management.Automation.CompletionResult]::new(
      $completionText,
      $friendly,
      'ParameterValue',
      $_
    )
  }

  $switches = @{ File = $filesOnly; Directory = $dirsOnly }

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