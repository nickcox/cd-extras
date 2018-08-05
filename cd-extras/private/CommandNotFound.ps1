function CommandNotFound($actions, $isUnderTest) {

  $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = {
    param($CommandName, $CommandLookupEventArgs)

    if ($CommandName -like 'get-*') { return }

    if ($CommandLookupEventArgs.CommandOrigin -ne 'Runspace' -and
      !(&$isUnderTest)) { return }

    $actions | % { &$_ $CommandName $CommandLookupEventArgs }
  }.GetNewClosure()
}