<#
.SYNOPSIS
Update cd-extras option ('AUTO_CD', 'CD_PATH', ...etc).

.PARAMETER Option
The option to update.

.PARAMETER Value
The new value.

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

    [Parameter(ParameterSetName = 'Validate', Mandatory)]
    [switch] $Validate
  )

  if ($PSCmdlet.ParameterSetName -eq 'Set') {

    $flags = @(
      'AUTO_CD'
      'CDABLE_VARS'
      'ColorCompletion'
      'IndexedCompletion'
      'RecentDirsFallThrough'
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
        $value | Where { $Global:cde.$option -notcontains $_ } | % { $Global:cde.$option += $_ }
      }
    }
    else {
      $Global:cde.$option = $value
    }
  }

  if ($cde.RECENT_DIRS_FILE) {
    $path = $cde.RECENT_DIRS_FILE -replace '~', $HOME
    $cde.RECENT_DIRS_FILE = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath( $path )

    # save recent dirs from memory when dirs file set
    if ($recent.Count) { PersistRecent }

    # load recent dirs into memory at startup
    elseif (Test-Path $cde.RECENT_DIRS_FILE) {
      ImportRecent
    }

    else {
      Add-Content $cde.RECENT_DIRS_FILE ''
      $global:cde.recentHash = (Get-FileHash $cde.RECENT_DIRS_FILE).Hash.ToString()
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
  if ($Validate) { return $true }
}
