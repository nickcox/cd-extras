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
Sets the current directory to ~\Modules\Shared\Microsoft.PowerShell.Utility, if it exists
#>
function Switch-LocationPart {

  [OutputType([void])]
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string] $Replace,
    [Parameter(Mandatory)][string] $With
  )

  $normalised = $Replace | NormaliseAndEscape

  if (!($PWD.Path -match $normalised)) {
    Write-Error "String '$normalised' isn't in '$PWD'" -ErrorAction Stop
  }

  $path = $PWD.Path -replace $normalised, $With

  if (Test-Path $path -PathType Container) { Set-LocationEx $path }
  else { Write-Error "No such directory: '$path'" -ErrorAction Stop }
}
