function CompletePaths {
  param(
    [Switch] $dirsOnly,
    [Switch] $filesOnly,
    $commandName,
    $parameterName,
    $wordToComplete,
    $commandAst,
    $boundParameters = @{ }
  )

  <#
    Given a full path, $_, return a fully formed completion result.
    Logic: use a relative path if the supplied word isn't rooted
    (like /temp/... or ~/... or C:\...) *and* the resolved path is a
    descendant of the current directory or its parent.

    For absolute paths, replace home dir location with tilde.
  #>
  filter CompletionResult {

    $fullPath = $_ | Convert-Path

    $completionText = if ($wordToComplete -match '^\.{1,2}$') {
      $wordToComplete
    }
    elseif (!($wordToComplete | IsRooted) -and ($fullPath | IsDescendedFrom ..)) {
      $fullPath | Resolve-Path -Relative
    }
    elseif ($homeDir = (Get-Location).Provider.Home) {
      $fullPath -replace "^$($homeDir | NormaliseAndEscape)", "~"
    }
    else {
      $fullPath
    }

    # add normalised trailing directory separator; quote if contains spaces
    $trailChar = if ($_.PSIsContainer) { ${/} }

    $completionText = $completionText |
    RemoveTrailingSeparator |
    SurroundAndTerminate $trailChar |
    EscapeWildcards

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
      ($listItemText | Truncate),
      [Management.Automation.CompletionResultType]::ParameterValue,
      $($fullPath)
    )
  }

  $switches = @{
    File      = $boundParameters['File'] -or $filesOnly
    Directory = $boundParameters['Directory'] -or $dirsOnly
    Force     = $boundParameters['Force'] -or (
      # always force on *nix; on Windows dotted directories aren't automatically hidden
      (Test-Path Variable:\IsWindows) -and !$IsWindows
    ) -or (
      # or if the command doesn't have a force switch
      $commandName -and (Get-Command $commandName -ea Ignore).Parameters.Keys -notcontains 'Force')
  }

  $completions = Expand-Path @switches $wordToComplete -MaxResults $cde.MaxCompletions

  #replace cdable_vars
  $variCompletions = if (
    $cde.CDABLE_VARS -and
    $wordToComplete -match '[^/\\]+' -and # separate variable from slashes before or after it
    ($maybeVar = Get-Variable "$($Matches[0])*" -ValueOnly | where { Test-Path $_ -PathType Container })
  ) {
    Expand-Path @switches ($wordToComplete -replace $Matches[0], $maybeVar) -MaxResults $cde.MaxCompletions
  }

  @($completions) + @($variCompletions) |
  select -Unique |
  select -First $cde.MaxCompletions |
  CompletionResult |
  DefaultIfEmpty { $null }
}
