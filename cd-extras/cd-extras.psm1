Get-ChildItem $PSScriptRoot/private/*.ps1 | % { . $_.FullName}
Get-ChildItem $PSScriptRoot/public/*.ps1 | % { . $_.FullName}

$defaults = [ordered]@{
  AUTO_CD  = $true
  CD_PATH  = @()
  NOARG_CD = '~'
}

if ((Test-Path variable:cde) -and $cde -is [System.Collections.IDictionary]) {
  $global:cde = New-Object PSObject -Property $global:cde
}
else {
  $global:cde = New-Object PSObject -Property $defaults
}

# account for any properties missing in user supplied hash
$defaults.GetEnumerator() | % {
  if (-not (Get-Member -InputObject $global:cde -Name $_.Name)) {
    Add-Member -InputObject $cde $_.Name $_.Value
  }
}

Set-CdExtrasOption -Option 'AUTO_CD' -Value $global:cde.AUTO_CD

$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
  $ExecutionContext.InvokeCommand.PostCommandLookupAction = $null
  $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = $null
  Remove-Variable cde -Scope Global -ErrorAction Ignore
}
