function AutoCd() {

  return {
    param($CommandName, $CommandLookupEventArgs)

    $scriptBlock = $null

    # If the command is already a valid path
    if ((Test-Path $CommandName) -and ($CommandName -notmatch '^\.{3,}')) {
      $scriptBlock = { Set-LocationEx $CommandName }
    }

    # Try smart expansion
    elseif ($expanded = Expand-Path $CommandName -Directory) {
      if ($expanded.Count -eq 1) {
        $scriptBlock = { Set-LocationEx $expanded }
      }
    }

    elseif ($cde.CDABLE_VARS) {
      if (
        (Test-Path variable:$CommandName) -and
        ($path = Get-Variable $CommandName -ValueOnly) -and
        (Test-Path $path)
      ) {
        $scriptBlock = { Set-LocationEx $path }
      }
    }

    if ($scriptBlock -and ($scriptBlock = $scriptBlock.GetNewClosure())) {
      $CommandLookupEventArgs.CommandScriptBlock = {
        if ($args.Length -eq 0) { &$scriptBlock }
      }.GetNewClosure()
      $CommandLookupEventArgs.StopSearch = $true
    }
  }
}