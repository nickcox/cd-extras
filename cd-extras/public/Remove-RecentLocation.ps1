function Remove-RecentLocation {

  [OutputType([void])]
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [string] $Pattern
  )

  Begin {
    $recents = @(GetRecent $cde.MaxRecentDirs); $accepted = @()
  }

  Process {
    $accepted += $recents.Where{
      !($_ -in $accepted) -and
      ($_ -like $Pattern -or (Split-Path -Leaf $_) -eq $Pattern) -and
      ($PSCmdlet.ShouldProcess($_)) }
  }

  End {
    if ($accepted) { RemoveRecent $accepted }
  }
}
