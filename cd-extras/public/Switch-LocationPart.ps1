<#
.SYNOPSIS
Attempt to replace all instances of 'replace' with 'with' in the current path,
changing to the resulting directory if it exists

.PARAMETER Replace
Part of the current directory path to replace.

.PARAMETER With
Text with which to replace.

.EXAMPLE
~\Modules\Unix\Microsoft.PowerShell.Utility> Switch-LocationPart unix shared
~\Modules\Shared\Microsoft.PowerShell.Utility> _
#>
function Switch-LocationPart {

  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Replace,
    [Parameter(Mandatory)][string]$With
  )

  $normalised = $Replace -replace '/|\\', ${/}

  if (-not ($PWD.Path -match [regex]::Escape($normalised))) {
    Write-Error "String '$normalised' isn't in '$PWD'" -ErrorAction Stop
  }

  if (Test-Path (
      $path = $PWD.Path -replace [regex]::Escape($normalised), $With
    ) -PathType Container) {

    Set-LocationEx $path
  }
  else {
    Write-Error "No such directory: '$path'" -ErrorAction Stop
  }
}