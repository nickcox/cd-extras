function PostCommandLookup($commands, $toggleTest, $setLocation, $multidot) {

  $ExecutionContext.InvokeCommand.PostCommandLookupAction = {
    param($CommandName, $CommandLookupEventArgs)

    if ($commands -contains $CommandName -and
      (($CommandLookupEventArgs.CommandOrigin -eq 'Runspace') -or ($__cdeUnderTest))) {

      &$toggleTest

      $CommandName = $CommandName
      $setLocation = $setLocation
      $multidot = $multidot

      $CommandLookupEventArgs.CommandScriptBlock = {
        $fullCommand = (@($CommandName) + $args) -join ' '

        $tokens = [System.Management.Automation.PSParser]::Tokenize($fullCommand, [ref]$null)
        $params = $tokens | Where type -eq CommandParameter
        $arg = $tokens | Where type -eq CommandArgument

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

        # multidot
        elseif (@($arg).Length -eq 1 -and $args -match $Multidot) {
          Step-Up ($args[0].Length - 1)
        }

        # otherwise try to execute SetLocation
        else {

          try {
            &$setLocation @args -ErrorAction Stop
          }

          catch [Management.Automation.ItemNotFoundException] {
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