<#
.SYNOPSIS
Clear the items in the cd-extras history stack.

.PARAMETER Undo
Clear contents of the Undo stack

.PARAMETER Value
Clear contents of the Redo stack
#>

function Clear-Stack {

  [CmdletBinding()]
  param(
    [switch] $Undo,
    [switch] $Redo
  )

  if ($Undo) { $Script:back = 'back' + [Guid]::NewGuid() }
  if ($Redo) { $Script:fwd = 'fwd' + [Guid]::NewGuid() }
}