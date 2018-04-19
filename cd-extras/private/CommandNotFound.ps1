function CommandNotFound($actions, $helpers) {

  $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = {
    param($CommandName, $CommandLookupEventArgs)
    if ($CommandName -like 'get-*') { return }

    if (!(&$helpers.isUnderTest) -and
      $CommandLookupEventArgs.CommandOrigin -ne 'Runspace') { return }

    $actions | % { $_.Invoke($CommandName, $CommandLookupEventArgs) }
  }.GetNewClosure()
}