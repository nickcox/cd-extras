class IndexedPath {
  [ushort] $n
  [string] $Name
  [string] $Path

  [string] ToString() { return $this.Path }
}

class RecentDir {
  [string] $Path
  [ulong] $LastEntered
  [uint] $EnterCount
  [bool] $Favour

  [string] ToString() { return "{0}, {1}, {2}" -f $this.LastEntered, $this.Count, $this.Favour }
}

class CdeOptions {
  hidden [string] $recentHash
  hidden [Threading.Mutex] $mutex = [Threading.Mutex]::new($false, 'cde.RECENT_DIRS_FILE')

  [bool] $AUTO_CD = $true
  [bool] $CDABLE_VARS = $false
  [string[]] $CD_PATH = @()
  [string] $NOARG_CD = '~'
  [string] $RECENT_DIRS_FILE = $null
  [string[]] $RECENT_DIRS_EXCLUDE = @()
  [bool] $RecentDirsFallThrough = $true
  [ushort] $MaxRecentDirs = 120
  [ushort] $MaxRecentCompletions = 60
  [ushort] $MaxCompletions = 0
  [ushort] $MaxMenuLength = 36
  [char[]] $WordDelimiters = '.', '_', '-'
  [string[]] $DirCompletions = @('Set-Location', 'Set-LocationEx', 'Push-Location')
  [string[]] $PathCompletions = @('Get-ChildItem', 'Get-Item', 'Invoke-Item', 'Expand-Path')
  [string[]] $FileCompletions = @()
  [bool] $ColorCompletion = $false
  [bool] $IndexedCompletion = (Get-Module PSReadLine) -and (
    Get-PSReadLineKeyHandler -Bound | Where Function -eq MenuComplete
  )
  [ScriptBlock] $ToolTip = { param ($item, $isTruncated)
    "{0} $(if ($isTruncated) {'{1}'})" -f
    $item, "$([char]27)[3m(+additional results not displayed)$([char]27)[0m"
  }
}
