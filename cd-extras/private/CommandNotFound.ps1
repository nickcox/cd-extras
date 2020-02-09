function CommandNotFound($actions, $isUnderTest) {

  $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = {
    param($CommandName, $CommandLookupEventArgs)

    if ($CommandName -like 'get-*') { return }

    # don't run as part of pipeline
    if ($MyInvocation.Line -match "$([regex]::Escape($CommandName))\s*\|") { return }

    # don't run if no word characters given
    if ($MyInvocation.Line -notmatch '\w') { return }

    # don't run unless invoked interactively
    if ($CommandLookupEventArgs.CommandOrigin -ne 'Runspace' -and !(&$isUnderTest)) { return }

    $actions | % { &$_ $CommandName $CommandLookupEventArgs }
  }.GetNewClosure()
}
