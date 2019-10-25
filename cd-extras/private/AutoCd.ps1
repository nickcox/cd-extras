function AutoCd() {

  return {
    param($CommandName, $CommandLookupEventArgs)

    $scriptBlock = $null

    # If the command is already a valid path
    if ((Test-Path $CommandName)) {
      $scriptBlock = { Set-LocationEx $CommandName }
    }

    # tilde syntax: ~n
    elseif ($CommandName -match '^(~)(\d+)$') {
      $scriptBlock = { Undo-Location ([int]$Matches[2]) }
    }

    # tilde syntax: ~~n
    elseif ($CommandName -match '^(~~)(\d+)$') {
      $scriptBlock = { Redo-Location ([int]$Matches[2]) }
    }

    # Try smart expansion
    elseif ($expanded = Expand-Path $CommandName -Directory) {
      if ($expanded.Count -eq 1) {
        $scriptBlock = { $expanded | Resolve-Path -Relative | Set-LocationEx }
      }
    }

    elseif ($cde.CDABLE_VARS) {
      if (
        ($path = Get-Variable $CommandName -ValueOnly -ErrorAction Ignore) -and
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