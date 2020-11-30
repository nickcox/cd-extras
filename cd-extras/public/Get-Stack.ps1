<#
.SYNOPSIS
Get the items in the cd-extras history stack.

.PARAMETER Undo
Returns the contents of the Undo stack only.

.PARAMETER Redo
Returns the contents of the Redo stack only.

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
C:\Windows\system32> dirs -u

n Name      Path
- ----      ----
1 Windows   C:\Windows
2 C:\       C:\

.LINK
Undo-Location
Redo-Location
#>
function Get-Stack {

  [OutputType([IndexedPath], ParameterSetName = ('Undo', 'Redo'))]
  [OutputType([System.Collections.Hashtable], ParameterSetName = 'Both')]
  [CmdletBinding(DefaultParameterSetName = 'Both')]
  param(
    [Alias("l", "p", "v")]
    [Parameter(ParameterSetName = 'Undo')]
    [switch] $Undo,

    [Parameter(ParameterSetName = 'Redo')]
    [switch] $Redo
  )

  if ($Undo) { IndexPaths $undoStack.ToArray() }
  elseif ($Redo) { IndexPaths $redoStack.ToArray() }

  else {
    @{
      Undo = IndexPaths $undoStack.ToArray()
      Redo = IndexPaths $redoStack.ToArray()
    }
  }
}
