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
  filter Colourise {
    if (
      ($cde.ColorCompletion) -and
      ($_.PSProvider.Name -eq 'FileSystem') -and
      (Test-Path Function:\Format-ColorizedFilename)) {
      Format-ColorizedFilename $_
    }
    else {
      $_.PSChildName
    }
  }

  filter CompletionResult {
    Begin { $seenNames = @{} } # for disambiguation purposes
    Process {
      $fullPath = $_ | Convert-Path

      $completionText = if ($wordToComplete -match '^\.{1,2}$') {
        $wordToComplete
      }
      elseif (!($wordToComplete | IsRooted) -and ($_ | Resolve-Path -Relative | IsDescendedFrom ..)) {
        $_ | Resolve-Path -Relative
      }
      else {
        $fullPath -replace "^$($HOME | NormaliseAndEscape)", "~"
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

      filter Dedupe {
        $n = ++$seenNames[$_]
        if ($n -le 1) { $_ } else { "$_ ($n)" }
      }

      $extraInfo = if ($cde.ToolTipExtraInfo) { ' ' + (&$cde.ToolTipExtraInfo $_) }

      [Management.Automation.CompletionResult]::new(
        $completionText,
        ($_ | Colourise | Truncate | Dedupe),
        [Management.Automation.CompletionResultType]::ParameterValue,
        $fullPath + $extraInfo
      )
    }
  }

  $wordToExpand = if ($wordToComplete) { $wordToComplete | RemoveSurroundingQuotes } else { './' }

  $maxCompletions =
  if ($cde.MaxCompletions) {
    $cde.MaxCompletions
  }
  else {
    # calculate a number that should fit onto one screen
    $columnPadding = 5
    $winSize = $Host.UI.RawUI.WindowSize
    $options = if (Get-Module PSReadLine) { Get-PSReadLineOption } else {
      @{ShowToolTips = $false; ExtraPromptLineCount = 0; CompletionQueryItems = 256 }
    }
    $tooltipHeight = if ($options.ShowToolTips) { 2 } else { 0 }
    $promptLines = 1 + $options.ExtraPromptLineCount
    $psReadLineMax = $options.CompletionQueryItems
    $numCols = [int][Math]::Floor($winSize.Width / ($cde.MaxMenuLength + $columnPadding))
    $numRows = $winSize.Height - $promptLines - $tooltipHeight - 1
    $maxVisible = $numCols * $numRows

    [Math]::Min($psReadLineMax, $maxVisible)
  }

  $switches = @{
    File       = $boundParameters['File'] -or $filesOnly
    Directory  = $boundParameters['Directory'] -or $dirsOnly
    Force      = $true
    MaxResults = $maxCompletions + 1 # fetch one more than we need so we know if we're truncating the results
  }

  $completions = Expand-Path @switches $wordToExpand

  #replace cdable_vars
  $variableCompletions = if (
    $cde.CDABLE_VARS -and
    $completions.Length -lt $maxCompletions -and
    $wordToComplete -match '[^/\\]+' -and # separate variable from slashes before or after it
    ($maybeVar = Get-Variable "$($Matches[0])*" -ValueOnly | where { Test-Path $_ -PathType Container })
  ) {
    Expand-Path @switches ($wordToExpand -replace $Matches[0], $maybeVar)
  }

  $allCompletions = @($completions) + @($variableCompletions) | ? { $_ }
  if ($allCompletions.Length -gt $maxCompletions) {
    [System.Console]::Beep() # audible warning if list of completions has been truncated
  }

  if (!$allCompletions) { return }

  $allCompletions |
  Select -Unique |
  Sort-Object { !$_.PSIsContainer, $_.PSChildName } |
  Select -First $maxCompletions |
  CompletionResult
}
