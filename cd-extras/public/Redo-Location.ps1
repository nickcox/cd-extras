<#
.SYNOPSIS
Move back to a location previously navigated away from using Undo-Location.

.PARAMETER n
The number of locations to redo.

.PARAMETER NamePart
Partial path name to choose from redo stack.

.EXAMPLE
C:\Windows\System32> # Move backward using Undo-Location, then forward using Redo-Location
C:\Windows\System32> cd ..
C:\Windows> Undo-Location
C:\Windows\System32> Redo-Location # (or cd+)
C:\Windows> _

.EXAMPLE
C:\Windows\System32> # Move backward using Undo-Location, then forward using Redo-Location
C:\Windows\System32> cd ..
C:\Windows> Undo-Location
C:\Windows\System32> Redo-Location windows # (or cd+ windows)
C:\Windows> _

.LINK
Undo-Location
#>
function Redo-Location {
  [CmdletBinding(DefaultParameterSetName = 'number')]
  param(
    [Parameter(ParameterSetName = 'number', Position = 0)] [byte]$n = 1,
    [Parameter(ParameterSetName = 'named', Position = 0)] [string]$NamePart)

  if ($PSCmdlet.ParameterSetName -eq 'number' -and $n -ge 1) {
    1..$n | % {
      if ($null -ne (Get-Location -StackName $back -ea Ignore)) {
        Push-Location -StackName $fwd
        Pop-Location -StackName $back
      }
    }
  }

  if ($PSCmdlet.ParameterSetName -eq 'named') {
    if (-not ($stack = Get-Stack -Redo)) { return }

    $match = GetStackIndex $stack $NamePart

    if ($match -ge 0) {
      Redo-Location ($match + 1)
    }
    else {
      Write-Error "Could not find $NamePart in redo stack" -ErrorAction Stop
    }
  }
}