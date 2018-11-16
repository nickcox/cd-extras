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
  # logic: use a relative path if the supplied word isn't rooted (e.g. /temp/... or ~/... C:\...)
  # *and* the resolved path is a child of the current directory or its parent
  # for absolute paths, replace home dir location with tilde
  filter CompletionResult {
    $friendly = $_ | Select -Expand PSPath | Convert-Path

    if (!($wordToComplete | IsRooted) -and ($_ | IsDescendedFrom ..)) {
      $friendly = Resolve-Path -Relative $_
    }
    elseif ($homeDir = (Get-Location).Provider.Home) {
      $friendly = $_ -replace "^$(NormaliseAndEscape $homeDir)", "~"
    }

    $trailChar = if ($_.PSIsContainer) {${/}} else {''}

    # add normalised trailing directory separator; quote if contains spaces
    $completionText = $friendly -replace '[/\\]$', '' |
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

  $completions = if ($wordToComplete -match '^\.{3,}') {
    # if we're multi-dotting...
    $dots = $Matches[0].Trim()
    $up = Get-Up ($dots.Length - 1)
    Expand-Path @switches ($up + $wordToComplete.Replace($dots, ''))
  }
  else {
    Expand-Path @switches $wordToComplete
  }

  #replace cdable_vars
  $variCompletions = if (
    $cde.CDABLE_VARS -and
    $wordToComplete -match '[^/\\]+' -and
    ($maybeVar = Get-Variable "$($Matches[0])*" |
        Where {$_.Value -and (Test-Path ($_.Value) -PathType Container)} |
        Select -Expand Value)
  ) {
    Expand-Path @switches ($wordToComplete -replace $Matches[0], $maybeVar)
  }
  else { @() }

  @($completions) + @($variCompletions) | Sort-Object -Unique | CompletionResult
}