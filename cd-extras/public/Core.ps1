<#
.SYNOPSIS
Undo the previous n changes to the current location.

.PARAMETER n
The number of locations to undo.

.EXAMPLE
PS C:\Windows\System32> # Move backwards to the previous location

PS C:\Windows\System32> cd ..
PS C:\Windows> Undo-Location # (or cd-)
PS C:\Windows\System32> _

.EXAMPLE
PS C:\Windows\System32> # Move backwards to the 2nd last location

PS C:\Windows\System32> cd ..
PS C:\Windows\> cd ..
PS C:\> Undo-Location 2 # (or cd- 2)
PS C:\Windows\System32> _

.LINK
Redo-Location
#>
function Undo-Location {

  [CmdletBinding()]
  param([byte]$n = 1)

  1..$n | % {
    if ((Get-Location -StackName $fwd -ea Ignore) -ne $null) {
      Push-Location -StackName $back
      Pop-Location -StackName $fwd
    }
  }
}


<#
.SYNOPSIS
Move back to a location previously navigated away from using Undo-Location.

.PARAMETER n
The number of locations to redo.

.EXAMPLE
C:\Windows\System32> # Move backward using Undo-Location, then forward using Redo-Location
C:\Windows\System32> cd ..
C:\Windows> Undo-Location
C:\Windows\System32> Redo-Location # (or cd+)
C:\Windows> _

.LINK
Undo-Location
#>
function Redo-Location {

  [CmdletBinding()]
  param([byte]$n = 1)
  1..$n | % {
    if ((Get-Location -StackName $back -ea Ignore) -ne $null) {
      Push-Location -StackName $fwd
      Pop-Location -StackName $back
    }
  }
}


<#
.SYNOPSIS
Gets the path of an ancestor directory, either by name or by traversing upwards
by the  given number of levels.

.PARAMETER n
Number of levels above the starting location. (One by default.)

.PARAMETER NamePart
Partial directory name for which to search.

.PARAMETER From
The directory from which to start. $PWD by default.

.EXAMPLE
C:\Windows\System32> Get-Up
C:\Windows\
C:\Windows\System32> Get-Up 2
C:\
C:\Windows\System32> Get-Up win
C:\Windows\

.LINK
Undo-Location
#>
function Get-Up {
  [CmdletBinding(DefaultParameterSetName = 'levels')]
  param(
    [Parameter(ParameterSetName = 'levels', Position = 0)] [byte]$n = 1,
    [Parameter(ParameterSetName = 'named', Position = 0)] [string]$NamePart,
    [string] $From = $PWD
  )

  $next = $From | Resolve-Path

  if ($PSCmdlet.ParameterSetName -eq 'levels' -and $n -ge 1) {
    1..$n | % {
      if ($parent = $next | Split-Path -Parent) { $next = $parent }
    }
    return $next
  }

  if ($PSCmdlet.ParameterSetName -eq 'named') {
    while ($next = $next | Split-Path -Parent) {
      if (($next | Split-Path -Leaf) -match $NamePart) { return $next }
    }
  }
}

<#
.SYNOPSIS
Export each ancestor of the current or given directory to a global variable.

.PARAMETER From
The folder from which to start. $PWD by default.

.PARAMETER Force
Overwrites any existing globals variables with the same names.

.EXAMPLE
C:\projects\powershell\src\Microsoft.PowerShell.SDK > Export-Up

Name                           Value
----                           -----
Microsoft.PowerShell.SDK       C:\projects\powershell\src\Microsoft.PowerShell.SDK\
src                            C:\projects\powershell\src\
powershell                     C:\projects\powershell\
projects                       C:\projects\

C:\projects\powershell\src\Microsoft.PowerShell.SDK > $powershell
C:\projects\powershell\
C:\projects\powershell\src\Microsoft.PowerShell.SDK > _
#>
function Export-Up() {
  [CmdletBinding()]
  param(
    [string] $From = $PWD,
    [switch] $Force
  )

  if (-not ($next = Resolve-Path $From)) { return }

  $getPair = { @{name = (Split-Path $next -Leaf); path = "$next" } }
  $output = [ordered]@{ (&$getPair).name = (&$getPair).path }

  while (
    ($next = $next | Split-Path -Parent) -and
    ($next -ne (Resolve-Path $next).Drive.Root)) {

    $output.Add((&$getPair).name, (&$getPair).path)
  }

  $output.GetEnumerator() | % {
    New-Variable  $_.Name $_.Value -Scope Global -Force:$Force -ErrorAction Ignore
  }

  $output
}

<#
.SYNOPSIS
Navigate upward by n levels (one level by default)
or to the first parent directory matching a given search term

.EXAMPLE
C:\Windows\System32> Step-Up
C:\Windows> _

.EXAMPLE
C:\Windows\System32> Step-Up 2
C:\> _

.EXAMPLE
C:\Windows\System32> Step-Up win
C:\Windows> _
#>
function Step-Up {

  [CmdletBinding(DefaultParameterSetName = 'levels')]
  param(
    [Parameter(ParameterSetName = 'levels', Position = 0)] [byte]$n = 1,
    [Parameter(ParameterSetName = 'named', Position = 0)] [string]$name
  )

  if ($target = Get-Up @PSBoundParameters) {
    SetLocationEx $target
  }
}

<#
.SYNOPSIS
Attempt to replace all instances of 'replace' with 'with' in the current path,
changing to the resulting directory if it exists

.EXAMPLE
~\Modules\Unix\Microsoft.PowerShell.Utility> Set-TransposedLocation unix shared
~\Modules\Shared\Microsoft.PowerShell.Utility> _
#>
function Set-TransposedLocation {

  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Replace,
    [Parameter(Mandatory)][string]$With)
  if (-not ($PWD.Path -match $Replace)) {
    Write-Error "String '$Replace' isn't in '$PWD'" -ErrorAction Stop
  }
  if (Test-Path ($path = $PWD.Path -replace $Replace, $With) -PathType Container) {
    SetLocationEx $path
  }
  else {
    Write-Error "No such directory: '$path'" -ErrorAction Stop
  }
}


<#
.SYNOPSIS
Attempts to expand a given candidate path by appending a wildcard character (*)
to the end of each path segment.

.EXAMPLE
PS> Expand-Path /win/sys/dr/et
Expands to @(
  C:\Windows\System32\drivers\etc,
  C:\Windows\System32\drivers\ETD.sys,
  C:\Windows\System32\drivers\ETDSMBus.sys)
#>
function Expand-Path {

  [CmdletBinding()]
  param (
    $Candidate,
    [array] $SearchPaths = @(),
    [switch] $File,
    [switch] $Directory)

    [string]$wildcardedPath =
    $Candidate -replace '(\w/|\w\\|\w$)', '$0*' `
      -replace '(/\*|\\\*)', ('*' + ${/}) `
      -replace '(/$|\\$)', '$0*' `
      -replace '(\.\w|\.$)', '*$0'

    if ($SearchPaths -and -not (IsRootedOrRelative $Candidate)) {
      # always include the local path, regardeless of whether it was passed
      # in the searchPaths parameter (this differs from the behaviour in bash)
      $wildcardedPaths = @($wildcardedPath) + (
        $SearchPaths | % { Join-Path $_ $wildcardedPath })
    }

    else { $wildcardedPaths = $wildcardedPath }

    $type = @{File = $File; Directory = $Directory}

    Write-Verbose "Expanding $Candidate to: $wildcardedPaths"
    return Get-ChildItem $wildcardedPaths @type -Force -ErrorAction Ignore
  }


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


<#
.SYNOPSIS
Update cd-extras option ('AUTO_CD' or 'CD_PATH')

.EXAMPLE
PS C:\> # disable AUTO_CD
PS C:\> Set-CdExtrasOption -Option AUTO_CD -Value $true
#>
function Set-CdExtrasOption {

  [CmdletBinding()]
  param (
    [ValidateSet(
      'AUTO_CD',
      'CD_PATH',
      'NOARG_CD')]
    $Option,
    $Value)

  $Global:cde.$option = $value

  $Script:fwd = 'forward'
  $Script:back = 'back'

  $helpers = @{
    raiseLocation = {Step-Up @args}
    setLocation = {SetLocationEx @args}
    expandPath = {Expand-Path @args}
    transpose = {Set-TransposedLocation @args}
    isUnderTest = {$Global:__cdeUnderTest -and !($Global:__cdeUnderTest = $false)}
  }

  $commandsToComplete = @('Push-Location', 'Set-Location')
  $commandsToAutoExpand = @('cd', 'Set-Location')
  RegisterArgumentCompleter $commandsToComplete
  PostCommandLookup $commandsToAutoExpand $helpers

  if ($cde.AUTO_CD) {
    CommandNotFound @(AutoCd $helpers) $helpers
  }
  else {
    CommandNotFound @() $helpers
  }
}
