function AutoCd($helpers) {
  return {
    param($CommandName, $CommandLookupEventArgs)
    if ($CommandName -like 'get-*' -or $args.Length -gt 0) {
      return
    }

    $helpers = $helpers
    $scriptBlock = $null

    #If the command is two or more dots
    if ($CommandName -match '^\.{2,}$') {
      $scriptBlock = {
        &$helpers.raiseLocation ($CommandName.Length - 1)
      }
    }

    #If the command is already a valid path
    elseif (Test-Path $CommandName) {
      $scriptBlock = { &$helpers.setLocation $CommandName }
    }

    #Try smart expansion
    elseif ($expanded = &$helpers.expandPath $CommandName) {
      if ($expanded -is [System.IO.DirectoryInfo]) {
        $scriptBlock = { &$helpers.setLocation $expanded }
      }
    }

    if ($scriptBlock) {
      $CommandLookupEventArgs.CommandScriptBlock = $scriptBlock.GetNewClosure()
      $CommandLookupEventArgs.StopSearch = $true
    }
  }.GetNewClosure()
}