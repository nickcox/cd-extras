. $PSScriptRoot/private/Core.ps1
. $PSScriptRoot/private/AutoCd.ps1
. $PSScriptRoot/private/PostCommandLookup.ps1
. $PSScriptRoot/private/CommandNotFound.ps1
. $PSScriptRoot/private/ArgumentCompleter.ps1

. $PSScriptRoot/public/Core.ps1
. $PSScriptRoot/public/Aliases.ps1

$defaults = [ordered]@{
  AUTO_CD = $true
  CD_PATH = @()
}

if (-not (Test-Path variable:cde)) {
  $global:cde = New-Object PSObject -Property $defaults
}
else {
  $global:cde = New-Object PSObject -Property $global:cde
}

if (-not (Get-Member -InputObject $global:cde -Name AUTO_CD)) {
  Add-Member -InputObject $cde AUTO_CD $defaults.AUTO_CD
}

if (-not (Get-Member -InputObject $global:cde -Name CD_PATH)) {
  Add-Member -InputObject $cde AUTO_CD $defaults.CD_PATH
}

Set-CdExtrasOption -Option 'AUTO_CD' -Value $global:cde.AUTO_CD

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
  $ExecutionContext.InvokeCommand.PostCommandLookupAction = $null
  $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = $null
}
