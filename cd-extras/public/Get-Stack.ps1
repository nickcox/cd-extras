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
C:\Windows\system32> Get-Stack -v

0   C:\Windows\system32
1   C:\Windows
2   C:\
#>

function Get-Stack {

  [OutputType([System.Collections.Hashtable])]
  [OutputType([String])]
  [CmdletBinding()]
  param(
    [Alias("v")]
    [switch] $Indexed,

    [Alias("l", "p")]
    [switch] $Undo,

    [switch] $Redo
  )

  $output = if ($Undo -and -not $Redo -or $Indexed) { $undoStack }
  elseif ($Redo -and -not $Undo) { $redoStack }
  else {
    @{
    Undo = $undoStack
    Redo = $redoStack
  }}

  if ($Indexed) {
    "0`t$PWD"
    for ($i = 0; $i -lt $output.Count; $i++) {
      "$($i+1)`t$($output[$i])"
    }
  }
  else {
    $output
  }
}