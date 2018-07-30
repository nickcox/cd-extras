function PostCommandLookup($commands, $isUnderTest, $setLocation, $multidot) {

  $ExecutionContext.InvokeCommand.PostCommandLookupAction = {
    param($CommandName, $CommandLookupEventArgs)

    if ($commands -contains $CommandName -and
      ((&$isUnderTest) -or $CommandLookupEventArgs.CommandOrigin -eq 'Runspace')) {

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

        # otherwise try to execute SetLocation
        else {

          try {
            &$setLocation @args -ErrorAction Stop
          }

          catch [Management.Automation.PSArgumentException] {
            $Global:Error.Clear()

            if ($args -match $Multidot) {
              # multidot throws this exception on Windows
              Step-Up ($args[0].Length - 1)
            }
          }

          catch [Management.Automation.ItemNotFoundException] {
            $Global:Error.Clear()

            if ($args -match $Multidot) {
              # multidot throws this exception on Linux
              Step-Up ($args[0].Length - 1)
            }

            elseif (
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