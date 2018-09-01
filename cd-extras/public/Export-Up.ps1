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
C:\projects\powershell\src\Microsoft.PowerShell.SDK > Export-Up

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

  if (-not ($next = Resolve-Path $From -ErrorAction Ignore).Path) { return }

  $getPair = { @{name = (Split-Path $next -Leaf); path = "$next" } }
  $output = [ordered]@{ (&$getPair).name = (&$getPair).path }

  try {
    while (
      ($next = $next | Split-Path -Parent) -and
      ($next -ne (Resolve-Path $next).Drive.Root)) {

      $pair = &$getPair

      # in the case of duplicate names, first one wins
      if (!$output.Contains($pair.name)) {
        $output.Add($pair.name, $pair.path)
      }
    }

    if ($IncludeRoot -and $output.Count -gt 1) {
      $drive = (Resolve-Path $From).Drive
      $output.Add($drive.Name, $drive.Root)
    }
  }
  catch [Management.Automation.PSArgumentException] {
    Write-Verbose "$_"
    $Global:Error.RemoveAt(0)
  }

  if (-not $NoGlobals) {
    $output.GetEnumerator() | % {
      New-Variable  $_.Name $_.Value -Scope Global -Force:$Force -ErrorAction Ignore
    }
  }

  $output
}