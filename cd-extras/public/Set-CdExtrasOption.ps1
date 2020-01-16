<#
.SYNOPSIS
Update cd-extras option ('AUTO_CD', 'CD_PATH', ...etc).

.PARAMETER Option
The option to update.

.PARAMETER Value
The new value.

.EXAMPLE
C:\> setocd AUTO_CD

Enables AUTO_CD

.EXAMPLE
C:\> setocd AUTO_CD $false

Disables AUTO_CD

.EXAMPLE
C:\> Set-CdExtrasOption -Option CD_PATH -Value @('/temp')

Set the directory search paths to the single directory, '/temp'
#>
function Set-CdExtrasOption {
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
  [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidGlobalVars", "")]

  [OutputType([void])]
  [CmdletBinding()]
  param (
    [ArgumentCompleter( { $global:cde | Get-Member -Type Property -Name "$($args[2])*" | % Name })]
    [Parameter(Mandatory)]
    $Option,

    [parameter(ValueFromPipeline)]
    $Value
  )

  $flags = @(
    'AUTO_CD',
    'CDABLE_VARS'
    'ColorCompletion'
    'IndexedCompletion'
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
      $value | ? { $Global:cde.$option -notcontains $_ } | % { $Global:cde.$option += $_ }
    }
  }
  else {
    $Global:cde.$option = $value
  }

  $isUnderTest = { $Script:__cdeUnderTest -and !($Script:__cdeUnderTest = $false) }

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
