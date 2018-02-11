function PostCommandLookup($commands, $helpers) {
  $ExecutionContext.InvokeCommand.PostCommandLookupAction = $null

  $ExecutionContext.InvokeCommand.PostCommandLookupAction = {
    param($CommandName, $CommandLookupEventArgs)
    if (
      $CommandLookupEventArgs.CommandOrigin -eq "Runspace" -and
      $commands -contains $CommandName) {

      $helpers = $helpers # make available to inner closure

      $CommandLookupEventArgs.CommandScriptBlock = {
        $fullCommand = (@($commandname) + $args) -join ' '
        $tokens = [System.Management.Automation.PSParser]::Tokenize($fullCommand, [ref]$null)
        $params = $tokens | Where-Object type -eq CommandParameter
        $arg = $tokens | Where-Object type -eq CommandArgument

        # two arg: transpose
        if (
          @($arg).Length -eq 2 -and
          @($params).Length -eq 0 -and
          (-not ($args -match '^(/|\\)'))) {
          Transpose-Location @args
        }

        # single arg: expand if necessary
        elseif (@($arg).Length -eq 1 -and @($params).Length -eq 0) {

          try {
            &$helpers.setLocation @args -ErrorAction Stop
          }
          catch [Management.Automation.ItemNotFoundException] {
            if (
              ($expanded = &$helpers.expandPath $args $cde.CD_PATH) -and
              ($dirs = $expanded | Where {$_ -is [System.IO.DirectoryInfo]}) -and
              ($dirs.Count -eq 1)) {

              &$helpers.setLocation $dirs
            }

            else { throw }
          }
        }

        # noarg cd
        elseif (@($arg).Length -eq 0 -and @($params).Length -eq 0) {
          if (Test-Path $cde.NOARG_CD) {
            &$helpers.setLocation $cde.NOARG_CD
          }
        }

        else {
          &$helpers.setLocation @args
        }

      }.GetNewClosure()
    }
  }.GetNewClosure()
}