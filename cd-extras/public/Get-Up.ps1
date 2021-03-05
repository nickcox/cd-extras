<#
.SYNOPSIS
Gets the path of an ancestor directory, either by traversing upward by n levels or by finding
the first ancestor matching a given search term.

.PARAMETER n
Number of levels above the starting location. (One by default.)

.PARAMETER NamePart
Directory name, partial directory name or path fragment for which to search.

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

.EXAMPLE
# Get the root of each git repository below the current path
C:\projects> ls .git -Force -Recurse -Depth 2 | gup
C:\projects\cd-extras
C:\projects\work\app
...

C:\projects> _

.LINK
Step-Up
#>
function Get-Up {
  [OutputType([String])]
  [CmdletBinding(DefaultParameterSetName = 'n')]
  param(
    [Parameter(ParameterSetName = 'n', Position = 0)]
    [byte] $n = 1,

    [Parameter(ParameterSetName = 'named', Position = 0, Mandatory)]
    [string] $NamePart,

    [Alias('FullName', 'Path')]
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [string] $From = $PWD
  )

  Process {

    $ancestors = @((Get-Ancestors -From $From).Path)

    if ($PSCmdlet.ParameterSetName -eq 'n') {

      if (!$n -or !$ancestors) { return $From } else { return $ancestors[$n - 1] }
    }

    if ($PSCmdlet.ParameterSetName -eq 'named') {

      if (($match = GetStackIndex $ancestors $NamePart) -ge 0) {
        $ancestors[$match]
      }
      else {
        Write-Error "Could not find '$NamePart' as an ancestor of '$From'." -ErrorAction Stop
      }
    }
  }
}
