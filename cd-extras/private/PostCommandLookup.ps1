function PostCommandLookup($commands, $helpers) {

  $ExecutionContext.InvokeCommand.PostCommandLookupAction = {
    param($CommandName, $CommandLookupEventArgs)

    if ($commands -contains $CommandName -and
      ((&$helpers.isUnderTest) -or $CommandLookupEventArgs.CommandOrigin -eq 'Runspace')) {

      $helpers = $helpers # make available to inner closure

      $CommandLookupEventArgs.CommandScriptBlock = {
        $fullCommand = (@($commandname) + $args) -join ' '
        $tokens = [System.Management.Automation.PSParser]::Tokenize($fullCommand, [ref]$null)
        $params = $tokens | Where type -eq CommandParameter

        # two arg: transpose
        if (
          @($args).Length -eq 2 -and
          @($params).Length -eq 0 -and
          -not ($args -match '^(/|\\)') ) { &$helpers.transpose @args }

        # single arg: expand if necessary
        elseif (@($args).Length -eq 1 -and @($params).Length -eq 0) {

          try {
            &$helpers.setLocation @args -ErrorAction Stop
          }
          catch [Management.Automation.ItemNotFoundException] {
            if (
              ($dirs = &$helpers.expandPath $args $cde.CD_PATH -Directory) -and
              ($dirs.Count -eq 1)) {

              &$helpers.setLocation $dirs
            }

            else { throw }
          }
        }

        # noarg cd
        elseif (@($args).Length -eq 0 -and @($params).Length -eq 0) {
          if (Test-Path $cde.NOARG_CD) {
            &$helpers.setLocation $cde.NOARG_CD
          }
        }

        else { &$helpers.setLocation @args }

      }.GetNewClosure()
    }
  }.GetNewClosure()
}