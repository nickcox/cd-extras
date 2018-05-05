<#
.SYNOPSIS
See the items in the cd-extras history stack (wraps Get-Location -Stack
in the context of the cd-extras module)
#>
function Show-Stack {

  [CmdletBinding()]
  param()
  @{
    Undo = (Get-Location -StackName $fwd -ea Ignore)
    Redo = (Get-Location -StackName $back -ea Ignore)
  }
}