<#
.SYNOPSIS
Get one or all cd-extras options.

.PARAMETER Option
The name of the option to retrieve. If omitted, all options are returned. An unknown option produces
an InvalidArgument error.

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
    $propertyName = @($global:cde | Get-Member -Type Property).Name |
    Where-Object { $_ -eq $Option } |
    Select-Object -First 1
    if (!$propertyName) {
      $exception = [ArgumentException]::new("Unknown cd-extras option '$Option'.")
      $errorRecord = [Management.Automation.ErrorRecord]::new(
        $exception,
        'UnknownCdExtrasOption',
        [Management.Automation.ErrorCategory]::InvalidArgument,
        $Option
      )
      $PSCmdlet.ThrowTerminatingError($errorRecord)
    }
    $global:cde.$propertyName
  }
  else {
    $global:cde
  }
}
