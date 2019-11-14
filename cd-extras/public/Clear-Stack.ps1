<#
.SYNOPSIS
Clear the items in the cd-extras history stack.

.PARAMETER Undo
Clear contents of the Undo stack only.

.PARAMETER Redo
Clear contents of the Redo stack only.
#>

function Clear-Stack {

  [CmdletBinding(DefaultParameterSetName = 'Both')]
  param(
    [Parameter(Mandatory = $true, ParameterSetName = 'Undo')]
    [switch] $Undo,

    [Parameter(Mandatory = $true, ParameterSetName = 'Redo')]
    [switch] $Redo
  )

  if ($PSCmdlet.ParameterSetName -in 'Undo', 'Both') { $undoStack.Clear() }
  if ($PSCmdlet.ParameterSetName -in 'Redo', 'Both') { $redoStack.Clear() }
}
