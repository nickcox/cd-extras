<#
.SYNOPSIS
Attempts to expand a given candidate path by appending a wildcard character (*) to the end of each path segment.

.PARAMETER Path
Candidate search string.

.PARAMETER MaxResults
Maximum number of results to return.

.PARAMETER SearchPaths
Set of paths to search in addition to the current directory. $cde.CD_PATH by default.

.PARAMETER File
Limits search results to leaf items.

.PARAMETER Directory
Limits search results to container items.

.PARAMETER Force
Indicates that this cmdlet gets items that cannot otherwise be accessed, such as hidden items.

.EXAMPLE
# Expand a well-known Windows path by abbreviating each segment
PS C:\> Expand-Path /w/s/d/etc

    Directory: C:\Windows\System32\drivers


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
d-----       21/12/2017  11:50 PM                etc

.EXAMPLE
# Expand the contents of a well-known Windows path
PS C:\> Expand-Path /w/s/d/etc/

    Directory: C:\Windows\System32\drivers\etc

Mode                LastWriteTime         Length Name
----                -------------         ------ ----
-a----       19/03/2017   8:01 AM            824 hosts
-a----       16/11/2019   9:10 AM            507 hosts.ics
-a----       19/03/2019   3:49 PM           3683 lmhosts.sam
-a----       19/03/2017   8:01 AM            407 networks
-a----       19/03/2017   8:01 AM           1358 protocol
-a----       19/03/2017   8:01 AM          17635 services
#>
function Expand-Path {

  [OutputType([object])]
  [CmdletBinding()]
  param (
    [alias("Candidate")]
    [parameter(ValueFromPipeline = $true)]
    [String]    $Path = './',
    [UInt16]    $MaxResults = [UInt16]::MaxValue,
    [String[]]  $SearchPaths = $cde.CD_PATH,
    [Switch]    $File,
    [Switch]    $Directory,
    [Switch]    $Force
  )

  # if we've been given an empty string then expand everything below $PWD
  if (!$Path) { $Path = './' }

  $multiDot = [regex]::Match($Path, '^\.{3,}')
  $match = $multiDot.Value
  $replacement = ('../' * [Math]::Max(0, $match.LastIndexOf('.'))) -replace '.$'

  [string]$wildcardedPath = $Path `
    -replace [Regex]::Escape($match), $replacement `
    -replace '`?\[|`?\]', '?' <# be as permissive as possible about square brackets #> `
    -replace '\w/|\w\\|\w$|\?$', '$0*' <# asterisks around slashes and at end #> `
    -replace '/\*|\\\*', "*${/}" <# /* or \* --> */ #> `
    -replace '/$|\\$', '$0*' <# append trailing aster if ends with slash #> `
    -replace '(\w)\.\.(\w)', '$1*' <# support double dot operator #> `
    -replace '\.\w|\w\.$', '*$0' <# expand around dots #>

  $wildcardedPaths = if ($SearchPaths -and -not ($Path | IsRootedOrRelative)) {
    # always include the local path, regardless of whether it was passed
    # in the searchPaths parameter (this differs from the behaviour in bash)
    @($wildcardedPath) + ($SearchPaths | Join-Path -ChildPath $wildcardedPath)
  }
  else { $wildcardedPath }

  WriteLog "`nExpanding $Path to: $wildcardedPaths"
  Get-Item $wildcardedPaths -Force:$Force -ErrorAction Ignore |
  Where { (!$File -or !$_.PSIsContainer) -and (!$Directory -or $_.PSIsContainer) } |
  Select -First $MaxResults
}
