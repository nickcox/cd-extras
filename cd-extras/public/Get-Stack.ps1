<#
.SYNOPSIS
See the items in the cd-extras history stack.

.PARAMETER Undo
Show contents of the Undo stack only.

.PARAMETER Redo
Show contents of the Redo stack only.

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
    [Parameter(Mandatory = $true, ParameterSetName = 'Undo')]
    [switch] $Undo,

    [Parameter(Mandatory = $true, ParameterSetName = 'Redo')]
    [switch] $Redo
  )

  if ($PSCmdlet.ParameterSetName -eq 'Undo') { IndexPaths $undoStack.ToArray() }
  elseif ($PSCmdlet.ParameterSetName -eq 'Redo') { IndexPaths $redoStack.ToArray() }

  else {
    @{
      Undo = $undoStack
      Redo = $redoStack
    }
  }
}
