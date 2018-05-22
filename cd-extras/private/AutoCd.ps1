function AutoCd($helpers) {
  return {
    param($CommandName, $CommandLookupEventArgs)
    if ($args.Length -gt 0) { return }

    $helpers = $helpers
    $scriptBlock = $null

    #If the command is three or more dots
    if ($CommandName -match '^\.{3,}$') {
      $scriptBlock = {
        &$helpers.raiseLocation ($CommandName.Length - 1)
      }
    }

    #If the command is already a valid path
    elseif (Test-Path $CommandName) {
      $scriptBlock = { &$helpers.setLocation $CommandName }
    }

    elseif ($cde.CDABLE_VARS) {
      if (
        (Test-Path variable:$CommandName) -and
        (Test-Path ($path = Get-Variable $CommandName -ValueOnly))
      ) {
        $scriptBlock = { &$helpers.setLocation $path }
      }
    }

    #Try smart expansion
    elseif ($expanded = &$helpers.expandPath $CommandName -Directory) {
      if ($expanded.Count -eq 1) {
        $scriptBlock = { &$helpers.setLocation $expanded }
      }
    }

    if ($scriptBlock) {
      $CommandLookupEventArgs.CommandScriptBlock = $scriptBlock.GetNewClosure()
      $CommandLookupEventArgs.StopSearch = $true
    }
  }.GetNewClosure()
}