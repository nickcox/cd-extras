[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string] $ModulePath,

  [Parameter(Mandatory)]
  [string] $StorePath,

  [Parameter(Mandatory)]
  [ValidateSet('Enter', 'Mark', 'Unmark', 'Remove', 'Clear', 'Count', 'HoldLock', 'EnterAndRemoveModule')]
  [string] $Operation,

  [Parameter(Mandatory)]
  [string] $TargetPath,

  [string] $ReadyPath,

  [string] $ContinuePath
)

$ErrorActionPreference = 'Stop'

Import-Module $ModulePath -Force
Set-CdExtrasOption FrecentProvider $null

function SignalReadyAndWait() {
  if (!$ReadyPath) { return }

  $null = New-Item -ItemType File -Path $ReadyPath -Force
  $deadline = [DateTime]::UtcNow.AddSeconds(10)
  while (!(Test-Path -LiteralPath $ContinuePath)) {
    if ([DateTime]::UtcNow -ge $deadline) {
      throw "Timed out waiting for continue file '$ContinuePath'."
    }
    Start-Sleep -Milliseconds 20
  }
}

if ($Operation -ne 'HoldLock') { SignalReadyAndWait }
Set-CdExtrasOption RECENT_DIRS_FILE $StorePath

switch ($Operation) {
  'Enter' { Set-LocationEx -LiteralPath $TargetPath }
  'Mark' { Add-Bookmark -Path $TargetPath }
  'Unmark' { Remove-Bookmark -Pattern $TargetPath -Confirm:$false }
  'Remove' { Remove-RecentLocation -Pattern $TargetPath -Confirm:$false }
  'Clear' { Remove-RecentLocation -Pattern * -Confirm:$false }
  'Count' { Write-Output (@(Get-RecentLocation).Count) }
  'HoldLock' {
    & (Get-Module cd-extras) {
      param($signalReadyAndWait)
      InvokeWithRecentLock $signalReadyAndWait
    } ${function:SignalReadyAndWait}
  }
  'EnterAndRemoveModule' {
    Set-LocationEx -LiteralPath $TargetPath
    Remove-Module cd-extras
  }
}
