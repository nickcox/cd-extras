<#
.SYNOPSIS
See the items in the cd-extras history stack.
(Wraps Get-Location -Stack in the context of the cd-extras module.)

.PARAMETER Undo
Show contents of the Undo stack.

.PARAMETER Redo
Show contents of the Redo stack.

.ALIASES
dirs

.EXAMPLE
# Get contents of both stacks (default)
C:\> cd windows
C:\Windows> cd system32
C:\Windows\System32> cd-
C:\Windows> Get-Stack

Name                           Value
----                           -----
Redo                           C:\windows\System32
Undo                           C:\

.EXAMPLE
# Get contents of undo stack
C:\> cd windows
C:\Windows> cd system32
C:\Windows\system32> Get-Stack -Undo

Path
----
C:\Windows
C:\
#>

function Get-Stack {

  [OutputType([System.Collections.Hashtable])]
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