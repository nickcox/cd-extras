${Script:/} = [System.IO.Path]::DirectorySeparatorChar

function SetLocationEx {
  [CmdletBinding()]
  param($path)

  #don't push dupes onto stack
  if (
    (@((Get-Location -StackName $fwd -ea Ignore )) | Select -First 1).Path -ne
    (Get-Location).Path) {
      if (Get-Item $path -ea Ignore) { Push-Location -StackName $fwd }
  }

  Set-Location $path
}

function IsRootedOrRelative($path) {
  IsRooted $path -or IsRelative $path
}

function IsRooted($path) {
  # for our purposes, we consider the path rooted if it's relative to home
  return [System.IO.Path]::IsPathRooted($path) -or $path -match '~(/|\\)*'
}

function IsRelative($path) {
  #e.g. starts with ./, ../
  return $path -match '^+\.(/|\\)'
}

function NormaliseAndEscape($pathPart) {
  $normalised = $pathPart -replace '/|\\', ${/}
  return [regex]::Escape($normalised)
}

function GetStackIndex([array]$stack, [string]$namepart) {
  $index = [array]::FindIndex(
    $stack,
    [Predicate[System.Management.Automation.PathInfo]] {
      ($leafName = $args[0] | Split-Path -Leaf) -and
        $leafName -match [regex]::Escape($namePart)
    })

  if ($index -ge 0) { return $index }

  return [array]::FindIndex(
    $stack,
    [Predicate[System.Management.Automation.PathInfo]] {
      $args[0] -match (NormaliseAndEscape $namepart)
    })
}

function DoUnderTest($block) {
  $Global:__cdeUnderTest = $true
  &$block
}