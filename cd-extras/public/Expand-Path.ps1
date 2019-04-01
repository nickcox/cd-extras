<#
.SYNOPSIS
Attempts to expand a given candidate path by appending a wildcard character (*)
to the end of each path segment.

.PARAMETER Candidate
Candidate search string.

.PARAMETER MaxResults
Maximum number of results to return.

.PARAMETER SearchPaths
Set of paths to search in addition to the current directory. $cde.CD_PATH by default.

.PARAMETER File
Limits search results to leaf items.

.PARAMETER Directory
Limits search results to container items.

.ALIASES
xpa

.EXAMPLE
# Expand a well-known Windows path by abbreviating each segment
PS C:\> Expand-Path /win/sys/dr/et -Directory

    Directory: C:\Windows\System32\drivers


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
d-----       21/12/2017  11:50 PM                etc
#>
function Expand-Path {

  [OutputType([object[]])]
  [CmdletBinding()]
  param (
    [string] $Candidate = './',
    [int]    $MaxResults = [int]::MaxValue,
    [array]  $SearchPaths = $cde.CD_PATH,
    [switch] $File,
    [switch] $Directory,
    [switch] $Force
  )

  # if we've been given an empty string then expand everything below $PWD
  if (!$Candidate) { $Candidate = './' }

  $multiDot = [regex]::Match($Candidate, '^\.{3,}')
  $match = $multiDot.Value
  $replacement = ('../' * [Math]::Max(0, $match.LastIndexOf('.'))) -replace '.$'

  [string]$wildcardedPath = $Candidate `
    -replace [Regex]::Escape($match), $replacement `
    -replace '(\w/|\w\\|\w$)', '$0*' `
    -replace '(/\*|\\\*)', ('*' + ${/}) `
    -replace '(/$|\\$)', '$0*' `
    -replace '(\w)\.\.', '$1*' `
    -replace '(\.\w|\w\.$)', '*$0' `
    -replace '\[|\]', '*'

  $wildcardedPaths = if ($SearchPaths -and -not ($Candidate | IsRootedOrRelative)) {
    # always include the local path, regardless of whether it was passed
    # in the searchPaths parameter (this differs from the behaviour in bash)
    @($wildcardedPath) + (
      $SearchPaths | % { Join-Path $_ $wildcardedPath })
  }
  else { $wildcardedPath }

  WriteLog "`nExpanding $Candidate to: $wildcardedPaths"
  Get-Item $wildcardedPaths -Force:$Force -ErrorAction Ignore |
    Where {(!$File -or !$_.PSIsContainer) -and (!$Directory -or $_.PSIsContainer)} |
    Select -First $MaxResults
}