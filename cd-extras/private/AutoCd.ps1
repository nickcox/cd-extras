function AutoCd($setLocation) {

  return {
    param($CommandName, $CommandLookupEventArgs)

    $setLocation = $setLocation
    $scriptBlock = $null

    # If the command is three or more dots
    if ($CommandName -match $Script:Multidot) {
      $scriptBlock = {
        Step-Up ($CommandName.Length - 1)
      }
    }

    # If the command is already a valid path
    elseif (Test-Path $CommandName) {
      $scriptBlock = { &$setLocation $CommandName }
    }

    # Try smart expansion
    elseif ($expanded = Expand-Path $CommandName -Directory) {
      if ($expanded.Count -eq 1) {
        $scriptBlock = { &$setLocation $expanded }
      }
    }

    elseif ($cde.CDABLE_VARS) {
      if (
        (Test-Path variable:$CommandName) -and
        ($path = Get-Variable $CommandName -ValueOnly) -and
        (Test-Path $path)
      ) {
        $scriptBlock = { &$setLocation $path }
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