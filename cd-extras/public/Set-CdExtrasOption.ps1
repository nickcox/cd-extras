<#
.SYNOPSIS
Update cd-extras option ('AUTO_CD' or 'CD_PATH')

.EXAMPLE
PS C:\> # disable AUTO_CD
PS C:\> Set-CdExtrasOption -Option AUTO_CD -Value $true
#>
function Set-CdExtrasOption {

  [CmdletBinding()]
  param (
    [ValidateSet(
      'AUTO_CD',
      'CD_PATH',
      'NOARG_CD')]
    $Option,
    $Value)

  $Global:cde.$option = $value

  $Script:fwd = 'forward'
  $Script:back = 'back'

  $helpers = @{
    raiseLocation = {Step-Up @args}
    setLocation = {SetLocationEx @args}
    expandPath = {Expand-Path @args}
    transpose = {Set-TransposedLocation @args}
    isUnderTest = {$Global:__cdeUnderTest -and !($Global:__cdeUnderTest = $false)}
  }

  $commandsToComplete = @('Push-Location', 'Set-Location')
  $commandsToAutoExpand = @('cd', 'Set-Location')
  RegisterArgumentCompleter $commandsToComplete
  PostCommandLookup $commandsToAutoExpand $helpers

  if ($cde.AUTO_CD) {
    CommandNotFound @(AutoCd $helpers) $helpers
  }
  else {
    CommandNotFound @() $helpers
  }
}
