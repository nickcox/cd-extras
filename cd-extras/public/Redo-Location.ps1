<#
.SYNOPSIS
Move back to a location previously navigated away from using Undo-Location.

.PARAMETER n
The number of locations to redo.

.EXAMPLE
C:\Windows\System32> # Move backward using Undo-Location, then forward using Redo-Location
C:\Windows\System32> cd ..
C:\Windows> Undo-Location
C:\Windows\System32> Redo-Location # (or cd+)
C:\Windows> _

.LINK
Undo-Location
#>
function Redo-Location {

  [CmdletBinding()]
  param([byte]$n = 1)
  1..$n | % {
    if ((Get-Location -StackName $back -ea Ignore) -ne $null) {
      Push-Location -StackName $fwd
      Pop-Location -StackName $back
    }
  }
}