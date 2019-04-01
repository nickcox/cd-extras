<#
.SYNOPSIS
Export each ancestor of the current or given directory (to a global variable by default).

.PARAMETER From
The folder from which to start. $PWD by default.

.PARAMETER Force
Overwrites any existing globals variables of the same names with the new values.

.PARAMETER NoGlobals
Don't copy output into global variables.

.PARAMETER IncludeRoot
Includes the root level path in the output.

.EXAMPLE
# Expand all ancestors of the given path (except the root) into global variables
C:\> Export-Up -From C:\projects\powershell\src\Microsoft.PowerShell.SDK

Name                           Value
----                           -----
Microsoft.PowerShell.SDK       C:\projects\powershell\src\Microsoft.PowerShell.SDK\
src                            C:\projects\powershell\src\
powershell                     C:\projects\powershell\
projects                       C:\projects\

C:\projects\powershell\src\Microsoft.PowerShell.SDK> $powershell
C:\projects\powershell\
C:\projects\powershell\src\Microsoft.PowerShell.SDK> _
#>
function Export-Up() {
  [CmdletBinding()]
  param(
    [string] $From = $PWD,
    [switch] $Force,
    [switch] $NoGlobals,
    [switch] $IncludeRoot
  )

  $start = Resolve-Path $From -ErrorAction Ignore
  if (!$start -or !($next = $start.Path)) {return}

  $getPair = { @{name = (Split-Path $next -Leaf); path = "$next" } }
  $output = [ordered]@{ (&$getPair).name = (&$getPair).path }

  try {
    while (
      ($next = $next | Split-Path) -and
      ($next -ne $start.Drive.Root)) {

      $pair = &$getPair

      # first one wins in the case of duplicate names
      if (!$output.Contains($pair.name)) {
        $output.Add($pair.name, $pair.path)
      }
    }

    # on Unix there's a weird empty path returned for the root directory
    # so we add it explicitly here instead of inside the loop
    if (
      $IncludeRoot -and
      $output.Values -notContains $start.Drive.Root
    ) {
      $output.Add($start.Drive.Root, $start.Drive.Root)
    }
  }
  catch [Management.Automation.PSArgumentException] {
    WriteLog "$_"
    $Global:Error.RemoveAt(0)
  }

  if (-not $NoGlobals) {
    $output.GetEnumerator() | % {
      New-Variable  $_.Name $_.Value -Scope Global -Force:$Force -ErrorAction Ignore
    }
  }

  $output
}