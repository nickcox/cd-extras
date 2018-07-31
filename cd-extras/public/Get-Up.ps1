<#
.SYNOPSIS
Gets the path of an ancestor directory, either by name or by traversing upwards
by the  given number of levels.

.PARAMETER n
Number of levels above the starting location. (One by default.)

.PARAMETER NamePart
Partial directory name for which to search.

.PARAMETER From
The directory from which to start. $PWD by default.

.EXAMPLE
C:\Windows\System32> Get-Up
C:\Windows\
C:\Windows\System32> Get-Up 2
C:\
C:\Windows\System32> Get-Up win
C:\Windows\

.LINK
Undo-Location
#>
function Get-Up {
  [CmdletBinding(DefaultParameterSetName = 'levels')]
  param(
    [Parameter(ParameterSetName = 'levels', Position = 0)] [byte]$n = 1,
    [Parameter(ParameterSetName = 'named', Position = 0)] [string]$NamePart,
    [string] $From = $PWD
  )

  $next = $From | Resolve-Path

  if ($PSCmdlet.ParameterSetName -eq 'levels' -and $n -ge 1) {
    1..$n | % {
      if ($parent = $next | Split-Path -Parent) { $next = $parent }
    }
    return $next
  }

  if ($PSCmdlet.ParameterSetName -eq 'named') {
    while ($next = $next | Split-Path -Parent) {
      if (($next | Split-Path -Leaf) -match (NormaliseAndEscape $NamePart)) { return $next }
    }

    # if we couldn't match by leaf name then match by complete path
    # this is only really used for completion when MenuCompletion is off
    $next = $From | Resolve-Path | select -Expand Path
    $resolvedTarget = Resolve-Path $NamePart -ErrorAction Ignore | Select -Expand Path

    do {
      if ($next -eq $resolvedTarget) { return $next }
    } while ($next = $next | Split-Path -Parent)

    Write-Error "Could not find '$NamePart' as an ancestor of the given path." -ErrorAction Stop
  }
}