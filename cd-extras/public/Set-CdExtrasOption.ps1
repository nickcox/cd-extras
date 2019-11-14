<#
.SYNOPSIS
Update cd-extras option ('AUTO_CD', 'CD_PATH', ...etc).

.PARAMETER Option
The option to update.

.PARAMETER Value
The new value.

.EXAMPLE
PS C:\> Set-CdExtrasOption AUTO_CD
Enables flag AUTO_CD

.EXAMPLE
PS C:\> Set-CdExtrasOption AUTO_CD $false
Disables flag AUTO_CD

.EXAMPLE
PS C:\> Set-CdExtrasOption -Option CD_PATH -Value @('/temp')
Set the search paths to the single directory '/temp'
#>
function Set-CdExtrasOption {

  [OutputType([void])]
  [CmdletBinding()]
  param (
    [ArgumentCompleter( { $global:cde | Get-Member -Type NoteProperty | % Name })]
    [Parameter(Mandatory)]
    $Option,
    $Value
  )

  $flags = @(
    'AUTO_CD',
    'CDABLE_VARS'
    'ColorCompletion'
    'MenuCompletion'
  )

  if ($null -eq $Value -and $Option -in $flags) {
    $Value = $true
  }

  $completionTypes = @(
    'PathCompletions'
    'DirCompletions'
    'FileCompletions'
  )

  if ($Option -in $completionTypes) {
    if ($Global:cde.$option -notcontains $value) {
      $Global:cde.$option += $value
    }
  }
  else {
    $Global:cde.$option = $value
  }

  $isUnderTest = { $Global:__cdeUnderTest -and !($Global:__cdeUnderTest = $false) }

  RegisterCompletions @('Step-Up') 'n' { CompleteAncestors @args }
  RegisterCompletions @('Undo-Location', 'Redo-Location') 'n' { CompleteStack @args }

  if ($cde.DirCompletions) {
    RegisterCompletions $cde.DirCompletions 'Path' { CompletePaths -dirsOnly @args }
  }
  if ($cde.FileCompletions) {
    RegisterCompletions $cde.FileCompletions 'Path' { CompletePaths -filesOnly @args }
  }
  if ($cde.PathCompletions) {
    RegisterCompletions $cde.PathCompletions 'Path' { CompletePaths @args }
  }

  if ($cde.AUTO_CD) {
    CommandNotFound @(AutoCd) $isUnderTest
  }
  else {
    CommandNotFound @() $isUnderTest
  }
}
