<#
.SYNOPSIS
Undo the previous n changes to the current location.

.PARAMETER n
The number of locations to undo.

.PARAMETER NamePart
Partial path name to choose from undo stack.

.EXAMPLE
PS C:\Windows\System32> # Move backwards to the previous location
PS C:\Windows\System32> cd ..
PS C:\Windows> Undo-Location # (or cd-)
PS C:\Windows\System32> _

.EXAMPLE
PS C:\Windows\System32> # Move backwards to the 2nd last location
PS C:\Windows\System32> cd ..
PS C:\Windows\> cd ..
PS C:\> Undo-Location 2 # (or cd- 2)
PS C:\Windows\System32> _

.EXAMPLE
PS C:\Windows\System32> # Move backwards by name
PS C:\Windows\System32> cd ..
PS C:\Windows\> cd ..
PS C:\> Undo-Location system # (or cd- system)
PS C:\Windows\System32> _

.LINK
Redo-Location
#>
function Undo-Location {
  [CmdletBinding(DefaultParameterSetName = 'number')]
  param(
    [Parameter(ParameterSetName = 'number', Position = 0)] [byte]$n = 1,
    [Parameter(ParameterSetName = 'named', Position = 0)] [string]$NamePart)

  if ($PSCmdlet.ParameterSetName -eq 'number' -and $n -ge 1) {
    1..$n | % {
      if ($null -ne (Get-Location -StackName $back -ea Ignore)) {
        Push-Location -StackName $fwd
        Pop-Location -StackName $back -ea Ignore
      }
    }
  }

  if ($PSCmdlet.ParameterSetName -eq 'named') {
    if (-not ($stack = Get-Stack -Undo)) { return }

    $match = GetStackIndex $stack $NamePart

    if ($match -ge 0) {
      Undo-Location ($match + 1)
    }
    else {
      Write-Error "Could not find $NamePart in undo stack" -ErrorAction Stop
    }
  }
}