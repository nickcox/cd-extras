${Script:/} = [System.IO.Path]::DirectorySeparatorChar

function Set-LocationEx {
  [CmdletBinding()]
  param($path)

  if ( #don't push dupes onto stack
    (@((Get-Location -StackName $fwd -ea Ignore )) | Select -First 1).Path -ne
    (Get-Location).Path) {
      if (Get-Item $path -ea Ignore) { Push-Location -StackName $fwd }
  }

  Set-Location $path
}

function IsRootedOrRelative($path) {
  if ([System.IO.Path]::IsPathRooted($path)) { return $true }
  return $path -match '^\W/|\W\\' #e.g. starts with ~/, ./, ../
}

function DoUnderTest($block) {
  $Global:__cdeUnderTest = $true
  &$block
}