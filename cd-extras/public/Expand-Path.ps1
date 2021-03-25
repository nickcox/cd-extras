<#
.SYNOPSIS
Attempts to expand a given candidate path by appending a wildcard character (*) to the end of each path segment.

.PARAMETER Path
Candidate search string.

.PARAMETER MaxResults
Maximum number of results to return.

.PARAMETER SearchPaths
Set of paths to search in addition to the current directory. $cde.CD_PATH by default.

.PARAMETER WordDelimiters
Set of characters to expand around. $cde.WordDelimiters by default.

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
PS C:\> Expand-Path /w/s..32/d/etc/

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
    [parameter(ValueFromPipeline, Mandatory)]
    [String]    $Path,
    [UInt16]    $MaxResults = [UInt16]::MaxValue,
    [String[]]  $SearchPaths = $cde.CD_PATH,
    [Char[]]    $WordDelimiters = $cde.WordDelimiters,
    [Switch]    $File,
    [Switch]    $Directory,
    [Switch]    $Force
  )

  Process {
    $delimiterGroup = if ($WordDelimiters) {
      '[{0}]' -f [Regex]::Escape($WordDelimiters -join '')
    }
    else { '$^' } # no delimiters

    # replace multi-dot with an appropriate number of `../`
    $multiDot = [regex]::Match($Path, '^\.{3,}').Value
    $replacement = ('../' * [Math]::Max(0, $multiDot.Length - 1)) -replace '.$'
    $uncShare = if ($Path -match '^\\\\([a-z0-9_.$-]+)\\([a-z0-9_.$-]+)') { $Matches[0] } else { '' }

    [string]$wildcardedPath = $Path `
      -replace '^' + [Regex]::Escape($uncShare) `
      -replace [Regex]::Escape($multiDot), $replacement `
      -replace '`?\[|`?\]', '?' <# be as permissive as possible about square brackets #> `
      -replace '\w(?=[/\\])|[\w/\\]$', '$0*' <# asterisks around slashes and at end #> `
      -replace '(\w)\.\.(\w)', '$1*$2' <# support double dot operator #> `
      -replace "$delimiterGroup\w+", '*$0' <# expand around dots, etc. #>

    if ($uncShare) {
      $wildcardedPath = $uncShare + $wildcardedPath
    }

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
}
