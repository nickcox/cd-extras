<#
.SYNOPSIS
Gets the path of an ancestor directory, either by name or by traversing upwards
by the given number of levels.

.PARAMETER n
Number of levels above the starting location. (One by default.)

.PARAMETER NamePart
Partial directory name for which to search.

.PARAMETER From
The directory from which to start. $PWD by default.

.EXAMPLE
# Get the parent of the current location
C:\Windows\System32> Get-Up
C:\Windows
C:\Windows\System32> _

.EXAMPLE
# Get the grandparent of the current location
C:\Windows\System32\drivers\etc> Get-Up 2
C:\Windows\System32

C:\Windows\System32\drivers\etc> _

.EXAMPLE
# Get the first ancestor containing the term 'win'
C:\Windows\System32\drivers\etc> Get-Up win
C:\Windows

C:\Windows\System32\drivers\etc> _

.LINK
Undo-Location
#>
function Get-Up {
  [OutputType([String])]
  [CmdletBinding(DefaultParameterSetName = 'n')]
  param(
    [Parameter(ParameterSetName = 'n', Position = 0)] [byte]$n = 1,
    [Parameter(ParameterSetName = 'named', Position = 0)] [string]$NamePart,
    [Parameter(ValueFromPipeline = $true)]
    [string] $From = $PWD
  )

  $ancestors = Get-Ancestors -From $From

  if ($PSCmdlet.ParameterSetName -eq 'n') {
    if (!$n) {
      return $From
    }

    return $ancestors.Path | select -Index ($n - 1)
  }

  if ($PSCmdlet.ParameterSetName -eq 'named') {

    if ($result = $ancestors | where Name -like "$NamePart*") {
      return $result.Path | select -first 1
    }

    # if we couldn't match by leaf name then match by complete path
    # this is mainly used for completion when MenuCompletion is off
    if ($result = $ancestors.Path -eq $NamePart) {
      return $result | select -first 1
    }

    Write-Error "Could not find '$NamePart' as an ancestor of '$From'." -ErrorAction Stop
  }
}
