<#
.SYNOPSIS
Update cd-extras option ('AUTO_CD', 'CD_PATH', ...etc)

.PARAMETER Option
The option to set

.PARAMETER Value
The option value

.EXAMPLE
PS C:\> Set-CdExtrasOption -Option AUTO_CD -Value $false

.EXAMPLE
PS C:\> Set-CdExtrasOption -Option CD_PATH -Value @('/temp')
#>
function Set-CdExtrasOption {

  [CmdletBinding()]
  param (
    [ValidateSet(
      'AUTO_CD',
      'CD_PATH',
      'NOARG_CD',
      'CDABLE_VARS',
      'CompletionStyle',
      'Completable')]
    $Option,
    $Value)

  $Global:cde.$option = $value

  $helpers = @{
    raiseLocation = {Step-Up @args}
    setLocation   = {SetLocationEx @args}
    expandPath    = {Expand-Path @args}
    transpose     = {Switch-LocationPart @args}
    multiDot      = $Multidot
    isUnderTest   = {$Global:__cdeUnderTest -and !($Global:__cdeUnderTest = $false)}
  }

  $commandsToAutoExpand = @('cd', 'Set-Location')
  PostCommandLookup $commandsToAutoExpand $helpers

  RegisterCompletions $cde.Completable 'Path' {CompletePaths @args}
  RegisterCompletions @('Step-Up') 'n' {CompleteAncestors @args}
  RegisterCompletions @('Undo-Location', 'Redo-Location') 'n' {CompleteStack @args}


  if ($cde.AUTO_CD) {
    CommandNotFound @(AutoCd $helpers) $helpers
  }
  else {
    CommandNotFound @() $helpers
  }
}
