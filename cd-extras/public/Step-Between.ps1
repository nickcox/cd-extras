<#
.SYNOPSIS
Toggle between undo and redo of the last location on the stack.

.EXAMPLE
# toggles between the two most recent directories
PS C:\Windows\> cd system32
PS C:\Windows\System32> cdb
PS C:\Windows\> cdb
PS C:\Windows\System32> _
#>

function Step-Between {
  [OutputType([void], [Management.Automation.PathInfo])]
  param ([switch] $PassThru)

  if ($Script:cycleDirection -eq [CycleDirection]::Undo) {
    Undo-Location -PassThru:$PassThru
    $Script:cycleDirection = [CycleDirection]::Redo
  }
  else {
    Redo-Location -PassThru:$PassThru
    $Script:cycleDirection = [CycleDirection]::Undo
  }
}
