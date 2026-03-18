<#
.SYNOPSIS
Get one or all cd-extras options.

.PARAMETER Option
The name of the option to retrieve. If omitted, all options are returned.

.EXAMPLE
PS C:\> getocd

Returns all cd-extras options.

.EXAMPLE
PS C:\> getocd AUTO_CD

Returns the current value of the AUTO_CD option.

.EXAMPLE
PS C:\> getocd CD_PATH

Returns the current value of the CD_PATH option.
#>
function Get-CdExtrasOption {

  [CmdletBinding()]
  param (
    [ArgumentCompleter({ $global:cde | Get-Member -Type Property -Name "$($args[2])*" | % Name })]
    [Parameter(Position = 0)]
    [string] $Option
  )

  if ($Option) {
    $global:cde.$Option
  }
  else {
    $global:cde
  }
}
