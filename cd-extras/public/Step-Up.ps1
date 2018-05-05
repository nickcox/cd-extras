<#
.SYNOPSIS
Navigate upward by n levels (one level by default)
or to the first parent directory matching a given search term

.EXAMPLE
C:\Windows\System32> Step-Up
C:\Windows> _

.EXAMPLE
C:\Windows\System32> Step-Up 2
C:\> _

.EXAMPLE
C:\Windows\System32> Step-Up win
C:\Windows> _
#>
function Step-Up {

  [CmdletBinding(DefaultParameterSetName = 'levels')]
  param(
    [Parameter(ParameterSetName = 'levels', Position = 0)] [byte]$n = 1,
    [Parameter(ParameterSetName = 'named', Position = 0)] [string]$name
  )

  if ($target = Get-Up @PSBoundParameters) {
    SetLocationEx $target
  }
}