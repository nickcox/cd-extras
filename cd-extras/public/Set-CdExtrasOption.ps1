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
      'MenuCompletion',
      'DirCompletions',
      'FileCompletions',
      'PathCompletions')]
    $Option,
    $Value)

  $Global:cde.$option = $value

  $isUnderTest = {$Global:__cdeUnderTest -and !($Global:__cdeUnderTest = $false)}

  $commandsToAutoExpand = @('cd', 'Set-Location')
  PostCommandLookup $commandsToAutoExpand $isUnderTest $Script:SetLocation $Script:Multidot

  RegisterCompletions @('Step-Up') 'n' {CompleteAncestors @args}
  RegisterCompletions @('Undo-Location', 'Redo-Location') 'n' {CompleteStack @args}
  if ($cde.DirCompletions) {
    RegisterCompletions $cde.DirCompletions 'Path' {CompletePaths -dirsOnly @args}
  }
  if ($cde.FileCompletions) {
    RegisterCompletions $cde.FileCompletions 'Path' {CompletePaths -filesOnly @args}
  }
  if ($cde.PathCompletions) {
    RegisterCompletions $cde.PathCompletions 'Path' {CompletePaths @args}
  }

  if ($cde.AUTO_CD) {
    CommandNotFound @(AutoCd($Script:SetLocation)) $isUnderTest
  }
  else {
    CommandNotFound @() $isUnderTest
  }
}
