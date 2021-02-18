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
function Get-Ancestors {

  [OutputType([IndexedPath])]
  [CmdletBinding()]
  param(
    [Alias('FullName', 'Path')]
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [string] $From = $PWD,
    [switch] $ExcludeRoot,
    [switch] $Export,
    [switch] $Force
  )

  Process {

    $start = Resolve-Path -LiteralPath $From

    # this works around registry provider having a root that can't be easily navigated to
    $root = if ($start.Provider.VolumeSeparatedByColon) { "$($start.Drive.Name):${/}" } else { $start.Drive.Root }

    if (!$start -or ($start.Path -eq $root)) { return }

    $next = $start.Path
    $paths = @(while ($next -and ($next = $next | Split-Path) -and ($next -ne $root)) { $next })

    # on Unix there's a weird empty path returned for the root directory
    # so we add it explicitly here instead of inside the loop
    if (!$ExcludeRoot -and $From -ne $root) { $paths += $root }

    $output = IndexPaths $paths

    if ($Export) {
      @($output) | % {
        New-Variable $_.name $_.path -Scope Global -Force:$Force -ErrorAction SilentlyContinue
      }
    }

    $output
  }
}
