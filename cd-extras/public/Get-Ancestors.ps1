<#
.SYNOPSIS
List ancestors of the current or given directory, optionally exporting each one into a global variable.

.PARAMETER From
The folder from which to start. $PWD by default.

.PARAMETER ExcludeRoot
Excludes the root level path in the output.

.PARAMETER Export
Copy output into global variables.

.PARAMETER Force
When used with Export, overwrites any existing globals variables of the same names with the new values.

.EXAMPLE
# List the ancestors of the current directory, including the root directory
C:\Windows\System32\drivers\etc> Get-Ancestors

n Name     Path
- ----     ----
1 drivers  C:\Windows\System32\drivers
2 System32 C:\Windows\System32
3 Windows  C:\Windows
4 C:\      C:\

.EXAMPLE
# Expand all ancestors of the given path (except the root) into global variables
C:\> Get-Ancestors -From C:\projects\powershell\src\Microsoft.PowerShell.SDK -ExcludeRoot -Export

n Name        Path
- ----        ----
1 src         C:\projects\powershell\src
2 powershell  C:\projects\powershell
3 projects    C:\projects

C:\projects\powershell\src\Microsoft.PowerShell.SDK> $powershell
C:\projects\powershell\

C:\projects\powershell\src\Microsoft.PowerShell.SDK> _
#>
function Get-Ancestors() {

  [OutputType([System.Collections.IEnumerable])]
  [CmdletBinding()]
  param(
    [parameter(ValueFromPipeline = $true)]
    [string] $From = $PWD,
    [switch] $ExcludeRoot,
    [switch] $Export,
    [switch] $Force
  )

  $start = Resolve-Path -LiteralPath $From -ErrorAction Ignore
  if (!$start -or !($next = $start.Path)) { return }

  $getPair = { @((Split-Path $next -Leaf), $next) }

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
    !$ExcludeRoot -and
    $output.name -notContains $start.Drive.Root -and
    $From -ne $start.Drive.Root
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