function CommandNotFound($actions, $isUnderTest) {

  $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = {
    param($CommandName, $CommandLookupEventArgs)

    if ($CommandName -like 'get-*') { return }

    # don't run unless invoked interactively
    if ($CommandLookupEventArgs.CommandOrigin -ne 'Runspace' -and !(&$isUnderTest)) { return }
    $invocation = if ($isUnderTest) { $CommandName } else { $MyInvocation.Line }

    # only match stuff that looks AUTO_CDish
    if ($invocation -notmatch '^[\w~/\\\.]*$|^\.{3,}$') { return }

    $actions | % { &$_ $CommandName $CommandLookupEventArgs }
  }.GetNewClosure()
}
