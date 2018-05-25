<#
.SYNOPSIS
Toggle between the current location and the previous location on the stack
without affecting the state of the stack.

.EXAMPLE
PS C:\Windows\> cd system32
PS C:\Windows\System32> cdb
PS C:\Windows\> cdb
PS C:\Windows\System32> _
#>

function Step-Back() {
  $Script:OLDPWD, $null = $PWD, (Set-Location $OLDPWD)
}