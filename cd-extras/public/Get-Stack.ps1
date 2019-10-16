<#
.SYNOPSIS
See the items in the cd-extras history stack.

.PARAMETER Undo
Show contents of the Undo stack.

.PARAMETER Redo
Show contents of the Redo stack.

.PARAMETER Indexed
Show indexed contents of the Undo stack.

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
C:\Windows\system32> Get-Stack -v

0   C:\Windows\system32
1   C:\Windows
2   C:\
#>
function Get-Stack {

  [OutputType([System.Collections.Hashtable])]
  [OutputType([String])]
  [CmdletBinding(DefaultParameterSetName = 'unindexed')]
  param(
    [Alias("v")]
    [Parameter(ParameterSetName = 'indexed', Position = 0)]
    [switch] $Indexed,

    [Alias("l", "p")]
    [Parameter(ParameterSetName = 'unindexed', Position = 0)]
    [switch] $Undo,

    [Parameter(ParameterSetName = 'unindexed', Position = 1)]
    [switch] $Redo
  )

  if ($Indexed) {
    $array = $undoStack.ToArray()
    "0`t$PWD <--"
    for ($i = 1; $i -le $array.Count; $i++) {
      "$i`t" + $array[$i - 1]
    }
  }
  else {
    if ($Undo -and -not $Redo -or $Indexed) { $undoStack }
    elseif ($Redo -and -not $Undo) { $redoStack }
    else {
      @{
        Undo = $undoStack
        Redo = $redoStack
      }
    }
  }
}