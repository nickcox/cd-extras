class IndexedPath {
  [ushort] $n
  [string] $Name
  [string] $Path

  [string] ToString() { return $this.Path }
}

class CdeOptions {
  [String[]] $CD_PATH = @()
  [bool] $AUTO_CD = $true
  [bool] $CDABLE_VARS = $false
  [String] $NOARG_CD = '~'
  [String] $RECENT_DIRS_FILE = $null
  [String[]] $RECENT_DIRS_EXCLUDE = @()
  [bool] $RecentDirsFallThrough = $true
  [ushort] $MaxRecentDirs = 400
  [ushort] $MaxCompletions = 0
  [ushort] $MaxRecentCompletions = 100
  [ushort] $MaxMenuLength = 36
  [Char[]] $WordDelimiters = '.', '_', '-'
  [UInt16] $MaxCompletions = 0
  [UInt16] $MaxMenuLength = 36
  [String[]] $DirCompletions = @('Set-Location', 'Set-LocationEx', 'Push-Location')
  [String[]] $PathCompletions = @('Get-ChildItem', 'Get-Item', 'Invoke-Item', 'Expand-Path')
  [String[]] $FileCompletions = @()
  [bool] $ColorCompletion = $false
  [bool] $IndexedCompletion = (Get-Module PSReadLine) -and (
    Get-PSReadLineKeyHandler -Bound | Where Function -eq MenuComplete
  )
  [ScriptBlock] $ToolTip = { param ($item, $isTruncated)
    "{0} $(if ($isTruncated) {'{1}'})" -f
    $item, "$([char]27)[3m(+additional results not displayed)$([char]27)[0m"
  }
}

class RecentDir {
  [string] $Path
  [ulong] $LastEntered
  [uint] $EnterCount
  [bool] $Starred

  [string] ToString() { return "{0}, {1}" -f $this.LastEntered, $this.Count }
}
