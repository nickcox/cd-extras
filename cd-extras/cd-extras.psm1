$cdAlias = if ($x = (Get-Alias -Name 'cd' -ErrorAction ignore)) { $x.Definition }

Get-ChildItem $PSScriptRoot/private/*.ps1 | % { . $_.FullName }
Get-ChildItem $PSScriptRoot/public/*.ps1 | % { . $_.FullName }

$defaults = [ordered]@{
  AUTO_CD         = $true
  CD_PATH         = @()
  CDABLE_VARS     = $false
  NOARG_CD        = '~'
  MaxCompletions  = 99
  MaxMenuLength   = 60
  DirCompletions  = @('Set-Location', 'Set-LocationEx', 'Push-Location')
  PathCompletions = @('Get-ChildItem', 'Get-Item', 'Invoke-Item', 'Expand-Path')
  FileCompletions = @()
  ColorCompletion = $false
  MenuCompletion  = $null -ne (Get-Module PSReadLine) -and (
    Get-PSReadLineKeyHandler -Bound | ? Function -eq MenuComplete
  )
}

$global:cde = if ((Test-Path variable:cde) -and $cde -is [System.Collections.IDictionary]) {
  New-Object PSObject -Property $global:cde
}
else {
  New-Object PSObject -Property $defaults
}

# account for any properties missing in user supplied hash
$defaults.GetEnumerator() | % {
  if (-not (Get-Member -InputObject $global:cde -Name $_.Name)) {
    $cde | Add-Member $_.Name $_.Value
  }
}

# some set up happens in Set-Option so make sure to call it here
Set-CdExtrasOption -Option 'AUTO_CD' -Value $global:cde.AUTO_CD

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
  $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = $null
  Set-Item Alias:cd $cdAlias
  Remove-Variable cde -Scope Global -ErrorAction Ignore
}
