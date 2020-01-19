class IndexedPath {
  [byte] $n
  [string] $Name
  [string] $Path
}

class CdeOptions {
  [String[]] $CD_PATH = @()
  [bool] $AUTO_CD = $true
  [bool] $CDABLE_VARS = $false
  [string] $NOARG_CD = '~'
  [Char[]] $WordDelimiters = '.', '_', '-'
  [UInt16] $MaxCompletions = 99
  [UInt16] $MaxMenuLength = 60
  [String[]] $DirCompletions = @('Set-Location', 'Set-LocationEx', 'Push-Location')
  [String[]] $PathCompletions = @('Get-ChildItem', 'Get-Item', 'Invoke-Item', 'Expand-Path')
  [String[]] $FileCompletions = @()
  [bool] $ColorCompletion = $false
  [bool] $IndexedCompletion = $null -ne (Get-Module PSReadLine) -and (
    Get-PSReadLineKeyHandler -Bound | ? Function -eq MenuComplete
  )
}
