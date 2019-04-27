<#
.SYNOPSIS
Toggle between undo and redo of the last location on the stack.

.ALIASES
cdb

.EXAMPLE
# toggles between the two most recent directories
PS C:\Windows\> cd system32
PS C:\Windows\System32> cdb
PS C:\Windows\> cdb
PS C:\Windows\System32> _
#>

function Step-Between() {
  if ($Script:cycleDirection -eq [CycleDirection]::Undo) {
    Undo-Location
    $Script:cycleDirection = [CycleDirection]::Redo
  }
  else {
    Redo-Location
    $Script:cycleDirection = [CycleDirection]::Undo
  }
}