<#
.SYNOPSIS
Attempts to expand a given candidate path by appending a wildcard character (*)
to the end of each path segment.

.EXAMPLE
PS> Expand-Path /win/sys/dr/et
Expands to @(
  C:\Windows\System32\drivers\etc,
  C:\Windows\System32\drivers\ETD.sys,
  C:\Windows\System32\drivers\ETDSMBus.sys)
#>
function Expand-Path {

  [CmdletBinding()]
  param (
    $Candidate,
    [array] $SearchPaths = @(),
    [switch] $File,
    [switch] $Directory)

  [string]$wildcardedPath =
  $Candidate -replace '(\w/|\w\\|\w$)', '$0*' `
    -replace '(/\*|\\\*)', ('*' + ${/}) `
    -replace '(/$|\\$)', '$0*' `
    -replace '(\.\w|\.$)', '*$0'

  if ($SearchPaths -and -not (IsRootedOrRelative $Candidate)) {
    # always include the local path, regardeless of whether it was passed
    # in the searchPaths parameter (this differs from the behaviour in bash)
    $wildcardedPaths = @($wildcardedPath) + (
      $SearchPaths | % { Join-Path $_ $wildcardedPath })
  }

  else { $wildcardedPaths = $wildcardedPath }

  $type = @{File = $File; Directory = $Directory}

  Write-Verbose "Expanding $Candidate to: $wildcardedPaths"
  return Get-ChildItem $wildcardedPaths @type -Force -ErrorAction Ignore
}