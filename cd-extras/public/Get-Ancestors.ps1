<#
.SYNOPSIS
Export each ancestor of the current or given directory (to a global variable by default).

.PARAMETER From
The folder from which to start. $PWD by default.

.PARAMETER IncludeRoot
Includes the root level path in the output.

.PARAMETER Export
Copy output into global variables.

.PARAMETER Force
When used with Export, overwrites any existing globals variables of the same names with the new values.

.EXAMPLE
# Expand all ancestors of the given path (except the root) into global variables
C:\> Get-Ancestors -From C:\projects\powershell\src\Microsoft.PowerShell.SDK

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
function Get-Ancestors() {

  [OutputType([System.Collections.IEnumerable])]
  [CmdletBinding()]
  param(
    [string] $From = $PWD,
    [switch] $IncludeRoot,
    [switch] $Export,
    [switch] $Force
  )

  $start = Resolve-Path -LiteralPath $From -ErrorAction Ignore
  if (!$start -or !($next = $start.Path)) { return }

  $getPair = { @((Split-Path $next -Leaf), $next) }
  # $name, $path = &$getPair
  $n = 1
  $output = @( )

  while (
    ($next = $next | Split-Path) -and
    ($next -ne $start.Drive.Root)) {

    $name, $path = &$getPair
    $output += @{ Name = $name; Path = $path; n = $n++ }
  }

  # on Unix there's a weird empty path returned for the root directory
  # so we add it explicitly here instead of inside the loop
  if (
    $IncludeRoot -and
    $output.name -notContains $start.Drive.Root
  ) {
    $output += @{ Name = $start.Drive.Root; Path = $start.Drive.Root; n = $n++ }
  }

  if ($Export) {
    $output | % {
      New-Variable $_.name $_.path -Scope Global -Force:$Force -ErrorAction Ignore
    }
  }

  $output | select n, Name, Path
}