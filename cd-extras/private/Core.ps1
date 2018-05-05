${Script:/} = [System.IO.Path]::DirectorySeparatorChar

function Set-LocationEx {
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

function DoUnderTest($block) {
  $Global:__cdeUnderTest = $true
  &$block
}