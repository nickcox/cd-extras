function CommandNotFound($actions) {

  $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = $null

  $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = {
    param($CommandName, $CommandLookupEventArgs)

    $actions | % {$_.Invoke(
        $CommandName,
        $CommandLookupEventArgs)
    }
  }.GetNewClosure()
}