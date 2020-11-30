Function Set-LocationEx {
  <#
.SYNOPSIS
	Sets the current working location to a specified location and adds an entry to the undo stack.

.DESCRIPTION
	The Set-Location cmdlet sets the working location to a specified location. That location could be a directory, a sub-directory, a registry location, or any provider path.

	You can also use the StackName parameter of to make a named location stack the current location stack. For more information about location stacks, see the Notes.

.PARAMETER LiteralPath
	Specifies a path of the location. The value of the LiteralPath parameter is used exactly as it is typed. No characters are interpreted as wildcard characters. If the path includes escape characters, enclose it in single quotation marks. Single quotation marks tell Windows PowerShell not to interpret any characters as escape sequences.

.PARAMETER PassThru
	Returns a System.Management.Automation.PathInfo object that represents the location. By default, this cmdlet does not generate any output.

.PARAMETER Path
  Specify the path of a new working location.

.PARAMETER ReplaceWith
	Replaces the path part given in the 'Path' parameter with this value.

.PARAMETER StackName
	Specifies the location stack name that this cmdlet makes the current location stack. Enter a location stack name. To indicate the unnamed default location stack, type $Null" or an empty string ("").

	The Location cmdlets act on the current stack unless you use the StackName parameter to specify a different stack.

.PARAMETER UseTransaction
	Includes the command in the active transaction. This parameter is valid only when a transaction is in progress. For more information, see Includes the command in the active transaction. This parameter is valid only when a transaction is in progress. For more information, see

.EXAMPLE
	PS C:\>cd -Path "HKLM:"
	PS HKLM:\>
	This command sets the current location to the root of the HKLM: drive.

.EXAMPLE
	PS C:\>cd -Path "Env:" -PassThru

	Path
	----
	Env:\
	PS Env:\>
	This command sets the current location to the root of the Env: drive. It uses the PassThru parameter to direct Windows PowerShell to return a PathInfo object that represents the Env: location.

.EXAMPLE
	PS C:\>cd C:
  This command sets the current location C: drive in the file system provider.

.EXAMPLE
	PS C:\>cd
  This command sets the current location to `$cde.NOARG_CD`. (The home directory by default.)

.EXAMPLE
  PS C:\Users\Bob\Documents>cd bob sue
  PS C:\Users\Sue\Documents> _
	This command attempts to replace 'bob' in the current location with sue so that the working directory is changed to C:\Users\Sue\Documents.

.NOTES
	The Set-LocationEx cmdlet is designed to work with the data exposed by any provider. To list the providers available in your session, type `Get-PSProvider`. For more information, see about_Providers.

	A stack is a last-in, first-out list in which only the most recently added item can be accessed. You add items to a stack in the order that you use them, and then retrieve them for use in the reverse order. Windows PowerShell lets you store provider locations in location stacks. Windows PowerShell creates an unnamed default location stack. You can create multiple named location stacks. If you do not specify a stack name, Windows PowerShell uses the current location stack. By default, the unnamed default location is the current location stack, but you can use the Set-Location cmdlet to change the current location stack.

	To manage location stacks, use the Windows PowerShell Location cmdlets, as follows:

	- To add a location to a location stack, use the Push-Location cmdlet.

	- To get a location from a location stack, use the Pop-Location cmdlet.

	- To display the locations in the current location stack, use the Stack parameter of the Get-Location cmdlet. To display the locations in a named location stack, use the StackName parameter of Get-Location . - To create a new location stack, use the StackName parameter of Push-Location . If you specify a stack that does not exist, Push-Location creates the stack. - To make a location stack the current location stack, use the StackName parameter of Set-Location .

	The unnamed default location stack is fully accessible only when it is the current location stack. If you make a named location stack the current location stack, you cannot no longer use Push-Location or Pop-Location cmdlets add or get items from the default stack or use Get-Location to display the locations in the unnamed stack. To make the unnamed stack the current stack, use the StackName parameter of Set-Location with a value of $Null or an empty string ("").

.INPUTS
	System.String

.OUTPUTS
	None, System.Management.Automation.PathInfo, System.Management.Automation.PathInfoStack

.LINK
	Online Version: http://go.microsoft.com/fwlink/?LinkId=821632

.LINK
	Get-Location

.LINK
  Undo-Location

.LINK
  Redo-Location

.LINK
  Get-Stack
#>

  [CmdletBinding(
    DefaultParameterSetName = 'Path',
    SupportsTransactions = $true,
    HelpUri = 'https://go.microsoft.com/fwlink/?LinkID=113397')
  ]
 	param(
    [Parameter(ParameterSetName = 'Path', Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [string] ${Path},

    [Parameter(ParameterSetName = 'Path', Position = 1)]
    [string] ${ReplaceWith},

    [Parameter(ParameterSetName = 'LiteralPath', Mandatory, ValueFromPipelineByPropertyName)]
    [Alias('PSPath')]
    [string] ${LiteralPath},

    [switch] ${PassThru},

    [Parameter(ParameterSetName = 'Stack', ValueFromPipelineByPropertyName)]
    [string] ${StackName}
  )

 	begin {

    $startLocation = $PWD.Path

    $outBuffer = $null
    if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
      $PSBoundParameters['OutBuffer'] = 1
    }

    # two arg
    if ($ReplaceWith) {
      Switch-LocationPart $Path $ReplaceWith
      break
    }

    #cd -n, cd ~n
    elseif ($Path -match '^(\-|~)(\d+)$') {
      Undo-Location ([Math]::Max([int]$Matches[2], 1))
      break
    }

    # cd +n, cd ~~n
    elseif ($Path -match '^(\+|~~)(\d+)$') {
      Redo-Location ([Math]::Max([int]$Matches[2], 1))
      break
    }

    # no arg
    elseif ($PSBoundParameters.Count -eq 0 -and !$myInvocation.ExpectingInput) {
      $Path = $cde.NOARG_CD | DefaultIfEmpty { $PWD }
    }

    elseif ($PSCmdlet.ParameterSetName -eq 'Path') {
      if ($Path -and !(Test-Path $Path -PathType Container -ErrorAction Ignore) -or ($Path -match '^\.{3,}')) {
        if (
          # cdable vars
          $cde.CDABLE_VARS -and
          ($vpath = Get-Variable $Path -ValueOnly -ErrorAction Ignore) -and
          (Test-Path $vpath -PathType Container -ErrorAction Ignore)
        ) { $Path = $vpath }
        elseif (
          # expand-path
          ($dirs = $Path | RemoveTrailingSeparator | Expand-Path -Directory) -and
          (@($dirs).Count -eq 1 -or ($dirs = $dirs | Where Name -eq $Path).Count -eq 1)) {
          $Path = $dirs | Resolve-Path | Select -Expand ProviderPath
        }
      }
    }

    if ($Path -and !$myInvocation.ExpectingInput) {
      if (Resolve-Path $Path -ErrorAction Ignore) {
        $PSBoundParameters['Path'] = $Path
      }
      elseif (Resolve-Path -LiteralPath $Path -ErrorAction Ignore) {
        # the default Set-Location command doesn't support silently switching these parameters
        # but it seems like the right thing to do here
        $PSBoundParameters['LiteralPath'] = $Path
        $null = $PSBoundParameters.Remove('Path')
      }
    }

    $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand(
      'Microsoft.PowerShell.Management\Set-Location',
      [System.Management.Automation.CommandTypes]::Cmdlet
    )
    $scriptCmd = { & $wrappedCmd @PSBoundParameters }
    $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
    $steppablePipeline.Begin($PSCmdlet)
 	}

 	process {

    if ($steppablePipeline) {
      $steppablePipeline.Process($_)
    }
  }

 	end {

    if ($PWD.Path -ne $startLocation) {
      $redoStack.Clear()
      $undoStack.Push($startLocation)
      $Script:cycleDirection = [CycleDirection]::Undo
    }

    if ($steppablePipeline) {
      $steppablePipeline.End()
    }
 	}
}
