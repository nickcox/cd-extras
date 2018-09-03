function PostCommandLookup($commands, $toggleTest, $setLocation) {

  $ExecutionContext.InvokeCommand.PostCommandLookupAction = {
    param($CommandName, $CommandLookupEventArgs)

    if ($commands -contains $CommandName -and
      (($CommandLookupEventArgs.CommandOrigin -eq 'Runspace') -or ($__cdeUnderTest))) {

      &$toggleTest

      $CommandName = $CommandName
      $setLocation = $setLocation

      $CommandLookupEventArgs.CommandScriptBlock = {

        $tokens = [System.Management.Automation.PSParser]::Tokenize($MyInvocation.Line, [ref]$null)
        $params = $tokens | Where type -eq CommandParameter
        $arg = $tokens | Where {$_.type -eq 'CommandArgument' -or $_.type -eq 'String'}
        $pipe = $tokens | Where {$_.type -eq 'Operator' -and $_.content -eq '|'}

        # two arg: transpose
        if (
          @($args).Length -eq 2 -and
          @($params).Length -eq 0 -and
          -not ($args -match '^(/|\\)') ) { Switch-LocationPart @args }

        # noarg cd
        elseif (@($arg).Length -eq 0 -and @($params).Length -eq 0) {
          if (Test-Path $cde.NOARG_CD) {
            &$setLocation $cde.NOARG_CD
          }
        }

        # otherwise try to execute SetLocation
        else {

          try {
            # basic support for piping
            if (@($pipe).Count -gt 0 -and @($arg).Length -eq 1) {
              &$setLocation $arg.Content
            }
            else {
              &$setLocation @args -ErrorAction Stop
            }
          }

          catch [Management.Automation.ItemNotFoundException], [Management.Automation.PSArgumentException] {
            $Global:Error.RemoveAt(0)

            if (
              @($arg).Length -eq 1 -and
              $cde.CDABLE_VARS -and
              (Test-Path "variable:$($arg.Content)") -and
              ($path = Get-Variable $arg.Content -ValueOnly) -and
              (Test-Path $path)
            ) {
              &$setLocation $path
            }
            elseif (
              @($arg).Length -eq 1 -and
              ($dirs = Expand-Path $arg.Content -Directory) -and
              ($dirs.Count -eq 1)) {

              &$setLocation $dirs
            }

            else { throw }
          }
        }
      }.GetNewClosure()
    }
  }.GetNewClosure()
}