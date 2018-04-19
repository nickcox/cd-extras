<#
.SYNOPSIS
Undo the previous n changes to the current location

.EXAMPLE
PS C:\Windows\System32> # Move backwards to the previous location

PS C:\Windows\System32> cd ..
PS C:\Windows> Undo-Location
PS C:\Windows\System32> _

.EXAMPLE
PS C:\Windows\System32> # Move backwards to the 2nd last location

PS C:\Windows\System32> cd ..
PS C:\Windows\> cd ..
PS C:\> Undo-Location 2
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
Move back to a location previously navigated away from using Undo-Location

.EXAMPLE
C:\Windows\System32> # Move backward using Undo-Location, then forward using Redo-Location
C:\Windows\System32> cd ..
C:\Windows> Undo-Location
C:\Windows\System32> Redo-Location
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
Navigate upward by n levels (one level by default)

.EXAMPLE
C:\Windows\System32> Raise-Location
C:\Windows> _

.EXAMPLE
C:\Windows\System32> Raise-Location 2
C:\> _
#>
function Raise-Location {

  [CmdletBinding(DefaultParameterSetName = 'levels')]
  param(
    [Parameter(ParameterSetName = 'levels', Position = 0)] [byte]$n = 1,
    [Parameter(ParameterSetName = 'named', Position = 0)] [string]$name
  )

  Push-Location -StackName $fwd

  if ($PSCmdlet.ParameterSetName -eq 'levels') {
    1..$n | % {
      $parent = (Get-Item .).Parent
      if ($parent) { Set-Location $parent.FullName }
    }
  }

  if ($PSCmdlet.ParameterSetName -eq 'named') {
    $next = Get-Item $PWD
    while ($next) {
      if ($next.Name -match $name) {
        Set-LocationEx $next.FullName
        break
      }
      $next = $next.Parent
    }
  }
}

<#
.SYNOPSIS
Attempt to replace all instances of 'replace' with 'with' in the current path,
changing to the resulting directory if it exists

.EXAMPLE
~\Modules\Unix\Microsoft.PowerShell.Utility> Transpose-Location unix shared
~\Modules\Shared\Microsoft.PowerShell.Utility> _
#>
function Transpose-Location {

  [CmdletBinding()]
  param(
    [Parameter(Mandatory)][string]$Replace,
    [Parameter(Mandatory)][string]$With)
  if (-not ($PWD.Path -match $Replace)) {
    throw "String '$Replace' isn't in '$PWD'"
  }
  if (Test-Path ($path = $PWD.Path -replace $Replace, $With) -PathType Container) {
    Set-LocationEx $path
  }
  else {
    throw "No such directory: '$path'"
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
  param ($Candidate, [array]$SearchPaths = @())

  [string]$wildcardedPath =
  $Candidate -replace '(\w/|\w\\|\w$)', '$0*' `
    -replace '(/\*|\\\*)', ('*' + [System.IO.Path]::DirectorySeparatorChar) `
    -replace '(/$|\\$)', '$0*' `
    -replace '(\.\w|\.$)', '*$0'

  if ($SearchPaths -and -not (IsRootedOrRelative $Candidate)) {
    # always include the local path, regardeless of whether it was passed
    # in the searchPaths parameter (this differs from the behaviour in bash)
    $wildcardedPaths = @($wildcardedPath) + (
      $SearchPaths |% { Join-Path $_ $wildcardedPath })
  }

  else { $wildcardedPaths = $wildcardedPath }

  Write-Verbose "Expanding $Candidate to: $wildcardedPaths"
  return Get-ChildItem $wildcardedPaths -Force -ErrorAction Ignore
}


<#
.SYNOPSIS
See the items in the cd-extras history stack (wraps Get-Location -Stack
in the context of the cd-extras module)
#>
function Peek-Stack {

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
    raiseLocation = {Raise-Location @args}
    setLocation   = {Set-LocationEx @args}
    expandPath    = {Expand-Path @args}
    transpose     = {Transpose-Location @args}
    isUnderTest   = {$Global:__cdeUnderTest -and !($Global:__cdeUnderTest = $false)}
  }

  $commandsToComplete = @('Push-Location', 'Set-Location')
  $commandsToAutoExpand = @('cd', 'Set-Location')
  RegisterArgumentCompleter $commandsToComplete
  PostCommandLookup $commandsToAutoExpand $helpers

  if ($cde.AUTO_CD) {
    CommandNotFound @(AutoCd $helpers) $helpers
  }
  else {
    CommandNotFound @() @()
  }
}
