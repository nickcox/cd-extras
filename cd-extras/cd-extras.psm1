$cdAlias = if ($x = (Get-Alias -Name 'cd' -ErrorAction ignore)) { $x.Definition }

Get-ChildItem $PSScriptRoot/private/*.ps1 | % { . $_.FullName }
Get-ChildItem $PSScriptRoot/public/*.ps1 | % { . $_.FullName }

# remove stupid phantom module
Get-Module | Where Path -eq ("$PSScriptRoot/public/_Classes.ps1" | Resolve-Path) | Remove-Module

$global:cde = if ((Test-Path variable:cde) -and $cde -is [System.Collections.IDictionary]) {
  [CdeOptions]$cde
}
else {
  [CdeOptions]::new()
}

RegisterCompletions @('Step-Up') 'n' { CompleteAncestors @args }
RegisterCompletions @('Undo-Location', 'Redo-Location') 'n' { CompleteStack @args }
RegisterCompletions @('Set-RecentLocation') 'NamePart' { CompleteRecent @args }
RegisterCompletions @('Set-FrecentLocation') 'NamePart' { CompleteFrecent @args }

# some set up happens in Set-Option so make sure to call it here
Set-CdExtrasOption -Option 'AUTO_CD' -Value $global:cde.AUTO_CD

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
  $Script:bg.Dispose()
  $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = $null
  Set-Item Alias:cd $cdAlias
  Remove-Variable cde -Scope Global -ErrorAction Ignore
}
