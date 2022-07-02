$cdAlias = if ($x = (Get-Alias -Name 'cd' -ErrorAction ignore)) { $x.Definition }

Get-ChildItem -File -Filter *.ps1 $PSScriptRoot/private, $PSScriptRoot/public | % {
  . $_.FullName
}

# remove stupid phantom module
Get-Module | Where Path -eq ("$PSScriptRoot/public/_Classes.ps1" | Resolve-Path) | Remove-Module

$global:cde = [CdeOptions]::new()
(Get-Variable cde).Attributes.Add([ValidateScript]::new( { Set-CdExtrasOption -Validate } ))

RegisterCompletions @('Step-Up') 'n' { CompleteAncestors @args }
RegisterCompletions @('Undo-Location', 'Redo-Location') 'n' { CompleteStack @args }
RegisterCompletions @('Set-RecentLocation') 'Terms' { CompleteRecent @args }
RegisterCompletions @('Set-FrecentLocation') 'Terms' { CompleteFrecent @args }

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
  if ($background) { $background.Dispose() }
  $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = $null
  Set-Item Alias:cd $cdAlias
  Remove-Variable cde -Scope Global -ErrorAction Ignore
}
