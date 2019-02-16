<#
.SYNOPSIS
Navigate upward by n levels (one level by default)
or to the first parent directory matching a given search term.

.PARAMETER n
Number of levels above the starting location. (One by default.)

.PARAMETER NamePart
Partial directory name for which to search.

.EXAMPLE
# Set location to the parent of the current directory
C:\Windows\System32> up
C:\Windows> _

.EXAMPLE
# Set location to the grandparent of the current directory
C:\Windows\System32> up 2
C:\> _

.EXAMPLE
# Set location to the first ancestor of the current directory where the name contains 'win'
C:\Windows\System32> up win
C:\Windows> _
#>
function Step-Up {

  [CmdletBinding(DefaultParameterSetName = 'levels')]
  param(
    [Parameter(ParameterSetName = 'levels', Position = 0)] [byte]$n = 1,
    [Parameter(ParameterSetName = 'named', Position = 0)] [string]$NamePart
  )

  if ($target = Get-Up @PSBoundParameters) {
    Set-LocationEx $target
  }
}