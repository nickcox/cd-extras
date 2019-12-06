<#
.SYNOPSIS
Move forward to a location previously navigated away from using Undo-Location.

.PARAMETER n
The number of locations to redo.

.PARAMETER NamePart
Partial path name to choose from redo stack.

.EXAMPLE
C:\Windows\System32> # Move backward using Undo-Location, then forward using Redo-Location
C:\Windows\System32> cd ..
C:\Windows> cd-
C:\Windows\System32> Redo-Location # (or cd+)
C:\Windows> _

.EXAMPLE
C:\Windows\System32> # Move backward using Undo-Location, then forward using Redo-Location
C:\Windows\System32> cd ..
C:\Windows> cd-
C:\Windows\System32> cd+ windows # (or Redo-Location windows)
C:\Windows> _

.LINK
Undo-Location
Get-Stack
#>
function Redo-Location {
  [OutputType([void], [Management.Automation.PathInfo])]
  [CmdletBinding(DefaultParameterSetName = 'n')]
  param(
    [Parameter(ParameterSetName = 'n', Position = 0)] [byte]$n = 1,
    [Parameter(ParameterSetName = 'named', Position = 0)] [string]$NamePart,
    [switch]$PassThru
  )

  if ($PSCmdlet.ParameterSetName -eq 'n' -and $n -ge 1) {
    1..$n | % {
      if ($redoStack.Count) {
        $undoStack.Push($PWD)
        $redoStack.Pop() | EscapeWildcards | Set-Location -PassThru:$PassThru
      }
    }
  }

  if ($PSCmdlet.ParameterSetName -eq 'named') {
    $match = GetStackIndex $redoStack.ToArray() $NamePart

    if ($match -ge 0) {
      Redo-Location ($match + 1)
    }
    else {
      Write-Error "Could not find '$NamePart' in redo stack" -ErrorAction Stop
    }
  }
}
