<#
.SYNOPSIS
Attempt to replace all instances of 'replace' with 'with' in the current path,
changing to the resulting directory if it exists

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

  if (-not ($PWD.Path -match $Replace)) {
    Write-Error "String '$Replace' isn't in '$PWD'" -ErrorAction Stop
  }

  if (Test-Path ($path = $PWD.Path -replace $Replace, $With) -PathType Container) {
    SetLocationEx $path
  }
  else {
    Write-Error "No such directory: '$path'" -ErrorAction Stop
  }

}