<#
.SYNOPSIS
See the items in the cd-extras history stack.
(Wraps Get-Location -Stack in the context of the cd-extras module.)

.PARAMETER Undo
Show contents of the Undo stack

.PARAMETER Redo
Show contents of the Redo stack
#>

function Get-Stack {

  [CmdletBinding()]
  param(
    [switch] $Undo,
    [switch] $Redo
  )

  $getUndo = { (Get-Location -StackName $back -ea Ignore) }
  $getRedo = { (Get-Location -StackName $fwd -ea Ignore) }

  if ($Undo -and -not $Redo) { return &$getUndo }
  if ($Redo -and -not $Undo) { return &$getRedo }

  @{
    Undo = &$getUndo
    Redo = &$getRedo
  }
}