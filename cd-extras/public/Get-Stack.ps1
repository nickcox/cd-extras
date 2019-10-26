<#
.SYNOPSIS
See the items in the cd-extras history stack.

.PARAMETER Undo
Show contents of the Undo stack.

.PARAMETER Redo
Show contents of the Redo stack.

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
# Get indexed contents of undo stack
C:\> cd windows
C:\Windows> cd system32
C:\Windows\system32> Get-Stack -u

n Name      Path
- ----      ----
0 System32  C:\Windows\system32
1 Windows   C:\Windows
2 C:\       C:\
#>
function Get-Stack {

  [OutputType([System.Collections.Hashtable])]
  [OutputType([String])]
  [CmdletBinding()]
  param(
    [Alias("l", "p", "v")]
    [switch] $Undo,
    [switch] $Redo
  )

  if ($Undo -and -not $Redo) { IndexPaths $undoStack.ToArray() }
  elseif ($Redo -and -not $Undo) { IndexPaths $redoStack.ToArray() }
  else {
    @{
      Undo = $undoStack
      Redo = $redoStack
    }
  }
}