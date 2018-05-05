function PostCommandLookup($commands, $helpers) {

  $ExecutionContext.InvokeCommand.PostCommandLookupAction = {
    param($CommandName, $CommandLookupEventArgs)

    if ($commands -contains $CommandName -and
      ((&$helpers.isUnderTest) -or $CommandLookupEventArgs.CommandOrigin -eq 'Runspace')) {

      $helpers = $helpers # make available to inner closure

      $CommandLookupEventArgs.CommandScriptBlock = {
        $fullCommand = (@($commandname) + $args) -join ' '
        $tokens = [System.Management.Automation.PSParser]::Tokenize($fullCommand, [ref]$null)
        $arguments = $tokens | Where type -eq CommandArgument | Select -Expand Content

        # two arg: transpose
        if (
          @($arguments).Length -eq 2 -and
          -not ($arguments -match '^(/|\\)') ) { &$helpers.transpose @arguments }

        # single arg: expand if necessary
        elseif (@($arguments).Length -eq 1) {

          try {
            &$helpers.setLocation $arguments -ErrorAction Stop
          }
          catch [Management.Automation.ItemNotFoundException] {
            if (
              ($dirs = &$helpers.expandPath $arguments $cde.CD_PATH -Directory) -and
              ($dirs.Count -eq 1)) {

              &$helpers.setLocation $dirs
            }

            else { throw }
          }
        }

        # noarg cd
        elseif (@($arguments).Length -eq 0) {
          if (Test-Path $cde.NOARG_CD) {
            &$helpers.setLocation $cde.NOARG_CD
          }
        }

        else { Set-Location @args }

      }.GetNewClosure()
    }
  }.GetNewClosure()
}