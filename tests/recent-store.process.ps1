[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string] $ModulePath,

  [Parameter(Mandatory)]
  [string] $StorePath,

  [Parameter(Mandatory)]
  [ValidateSet('Enter', 'Mark', 'Unmark', 'Remove', 'Clear')]
  [string] $Operation,

  [Parameter(Mandatory)]
  [string] $TargetPath
)

$ErrorActionPreference = 'Stop'

Import-Module $ModulePath -Force
Set-CdExtrasOption FrecentProvider $null
Set-CdExtrasOption RECENT_DIRS_FILE $StorePath

switch ($Operation) {
  'Enter' { Set-LocationEx -LiteralPath $TargetPath }
  'Mark' { Add-Bookmark -Path $TargetPath }
  'Unmark' { Remove-Bookmark -Pattern $TargetPath -Confirm:$false }
  'Remove' { Remove-RecentLocation -Pattern $TargetPath -Confirm:$false }
  'Clear' { Remove-RecentLocation -Pattern * -Confirm:$false }
}
