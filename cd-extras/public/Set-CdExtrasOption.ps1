<#
.SYNOPSIS
Update cd-extras option ('AUTO_CD', 'CD_PATH', ...etc).

.PARAMETER Option
The option to update.

.PARAMETER Value
The new value.

.PARAMETER Options
A dictionary of options and values to update.

.EXAMPLE
PS C:\> setocd AUTO_CD

Enables AUTO_CD

.EXAMPLE
PS C:\> setocd AUTO_CD $false

Disables AUTO_CD

.EXAMPLE
PS C:\> Set-CdExtrasOption -Option CD_PATH -Value @('/temp')

Set the directory search paths to the single directory, '/temp'
#>
function Set-CdExtrasOption {

  [OutputType([void], [bool])]
  [CmdletBinding(DefaultParameterSetName = 'Set')]
  param (
    [ArgumentCompleter( { $global:cde | Get-Member -Type Property -Name "$($args[2])*" | % Name })]
    [Parameter(ParameterSetName = 'Set', Mandatory, Position = 0)]
    [string] $Option,
    [Parameter(ParameterSetName = 'Set', Position = 1, ValueFromPipeline)]
    $Value,

    [Parameter(ParameterSetName = 'SetMany', Mandatory, Position = 0)]
    [Collections.IDictionary] $Options,

    [Parameter(ParameterSetName = 'Validate', Mandatory)]
    [switch] $Validate
  )

  # first update the $cde variable per the given settings
  if ($PSCmdlet.ParameterSetName -eq 'Set' -or $PSCmdlet.ParameterSetName -eq 'SetMany') {

    $flags = @(
      'AUTO_CD'
      'CDABLE_VARS'
      'ColorCompletion'
      'IndexedCompletion'
      'RecentDirsFallThrough'
    )

    $completionTypes = @(
      'PathCompletions'
      'DirCompletions'
      'FileCompletions'
    )

    if ($null -eq $Value -and $Option -in $flags) {
      $Value = $true
    }

    $opts = if ($Option) { $Option } else { $Options.Keys }
    $opts | % {
      $opt = $_
      $val = if ($Options -is [hashtable] -and $Options.Keys -contains $_) { $Options[$_] } else { $Value }

      if ($opt -in $completionTypes) {
        if ($Global:cde.$opt -notcontains $val) {
          $Global:cde.$opt += $val
        }
      }
      else {
        $Global:cde.$opt = $val
      }
    }
  }

  # then perform various side effects based on the current settings
  if ($cde.RECENT_DIRS_FILE) {

    $path = $cde.RECENT_DIRS_FILE -replace '~', $HOME
    $cde.RECENT_DIRS_FILE = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath( $path )

    # save recent dirs from memory when dirs file set
    if ($recent.Count -gt 1 -or !(Test-Path $cde.RECENT_DIRS_FILE)) { PersistRecent }

    # load recent dirs into memory at startup
    elseif (Test-Path $cde.RECENT_DIRS_FILE) {
      ImportRecent
    }
  }

  $cde.RECENT_DIRS_EXCLUDE = $cde.RECENT_DIRS_EXCLUDE.ForEach{ Resolve-Path $_ }

  if ($cde.DirCompletions) {
    RegisterCompletions $cde.DirCompletions 'Path' { CompletePaths -dirsOnly @args }
  }
  if ($cde.FileCompletions) {
    RegisterCompletions $cde.FileCompletions 'Path' { CompletePaths -filesOnly @args }
  }
  if ($cde.PathCompletions) {
    RegisterCompletions $cde.PathCompletions 'Path' { CompletePaths @args }
  }

  $isUnderTest = { $Script:__cdeUnderTest -and !($Script:__cdeUnderTest = $false) }
  if ($cde.AUTO_CD) {
    CommandNotFound @(AutoCd) $isUnderTest
  }
  else {
    CommandNotFound @() $isUnderTest
  }

  # can be used to ensure side effects have run without actually changing any options
  # this is used when the $cde variable is updated irectly
  if ($Validate) { return $true }
}
