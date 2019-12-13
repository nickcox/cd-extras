$cdAlias = if ($x = (Get-Alias -Name 'cd' -ErrorAction ignore)) { $x.Definition }

Get-ChildItem $PSScriptRoot/private/*.ps1 | % { . $_.FullName }
Get-ChildItem $PSScriptRoot/public/*.ps1 | % { . $_.FullName }

# remove stupid phantom module
Get-Module | ? Path -eq ("$PSScriptRoot/public/_Classes.ps1" | Resolve-Path) | Remove-Module

$global:cde = if ((Test-Path variable:cde) -and $cde -is [System.Collections.IDictionary]) {
  New-Object -Type CdeOptions -Property $global:cde
}
else {
  New-Object -Type CdeOptions
}

# some set up happens in Set-Option so make sure to call it here
Set-CdExtrasOption -Option 'AUTO_CD' -Value $global:cde.AUTO_CD

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
  $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = $null
  Set-Item Alias:cd $cdAlias
  Remove-Variable cde -Scope Global -ErrorAction Ignore
}
