<#
.SYNOPSIS
Undo the previous n changes to the current location.

.PARAMETER n
The number of locations to undo.

.EXAMPLE
PS C:\Windows\System32> # Move backwards to the previous location

PS C:\Windows\System32> cd ..
PS C:\Windows> Undo-Location # (or cd-)
PS C:\Windows\System32> _

.EXAMPLE
PS C:\Windows\System32> # Move backwards to the 2nd last location

PS C:\Windows\System32> cd ..
PS C:\Windows\> cd ..
PS C:\> Undo-Location 2 # (or cd- 2)
PS C:\Windows\System32> _

.LINK
Redo-Location
#>
function Undo-Location {

  [CmdletBinding()]
  param([byte]$n = 1)

  1..$n | % {
    if ((Get-Location -StackName $fwd -ea Ignore) -ne $null) {
      Push-Location -StackName $back
      Pop-Location -StackName $fwd
    }
  }
}