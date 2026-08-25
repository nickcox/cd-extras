<#
.SYNOPSIS
Bookmarks a directory to promote it to the top of the frecent locations list.

.PARAMETER Path
The literal path of a directory or other provider container to bookmark ($PWD by default).

.EXAMPLE
PS C:\temp> # bookmark the current directory
PS C:\temp> mark
PS C:\temp> Get-Bookmark
C:\temp

.EXAMPLE
PS C:\temp> # bookmark another directory
PS C:\temp> mark /
PS C:\temp> Get-Bookmark
C:\

.LINK
Get-Bookmark
Remove-Bookmark
Get-FrecentLocation
Set-FrecentLocation
#>

function Add-Bookmark() {

  [OutputType([void])]
  param(
    [Parameter(Position = 0, ValueFromPipeline)] [string] $Path = $PWD
  )

  Process {
    $resolved = Resolve-Path -LiteralPath $Path -ErrorAction Ignore

    if (!$resolved) {
      Write-Error "Cannot bookmark '$Path' because it does not exist." -Category InvalidArgument -TargetObject $Path
    }
    elseif (!(Test-Path -LiteralPath $resolved.Path -PathType Container)) {
      Write-Error "Cannot bookmark '$Path' because it is not a container." -Category InvalidArgument -TargetObject $Path
    }
    else {
      UpdateRecent $resolved.Path $true
    }
  }
}
