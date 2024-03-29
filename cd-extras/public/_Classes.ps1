class IndexedPath {
  [byte] $n
  [string] $Name
  [string] $Path

  [string] ToString() { return $this.Path }
}

class CdeOptions {
  [String[]] $CD_PATH = @()
  [bool] $AUTO_CD = $true
  [bool] $CDABLE_VARS = $false
  [string] $NOARG_CD = '~'
  [Char[]] $WordDelimiters = '.', '_', '-'
  [UInt16] $MaxCompletions = 0
  [UInt16] $MaxMenuLength = 36
  [String[]] $DirCompletions = @('Set-Location', 'Set-LocationEx', 'Push-Location')
  [String[]] $PathCompletions = @('Get-ChildItem', 'Get-Item', 'Invoke-Item', 'Expand-Path')
  [String[]] $FileCompletions = @()
  [bool] $ColorCompletion = $false
  [bool] $IndexedCompletion = (Get-Module PSReadLine) -and (
    Get-PSReadLineKeyHandler -Bound | ? Function -eq MenuComplete
  )
  [ScriptBlock] $ToolTip = { param ($item, $isTruncated)
    "{0} $(if ($isTruncated) {'{1}'})" -f
    $item, "$([char]27)[3m(+additional results not displayed)$([char]27)[0m"
  }
}
