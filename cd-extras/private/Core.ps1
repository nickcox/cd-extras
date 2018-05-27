${Script:/} = [System.IO.Path]::DirectorySeparatorChar
$Script:Multidot = '^\.{3,}$'
$Script:fwd = 'forward'
$Script:back = 'back'
$Script:OLDPWD # used by Step-Back

function SetLocationEx {
  [CmdletBinding()]
  param([string]$Path, [switch]$PassThru)

  #don't push consecutive dupes onto stack
  if (
    (@((Get-Location -StackName $fwd -ea Ignore )) | Select -First 1).Path -ne
    (Get-Location).Path
  ) {
    if (Get-Item $path -ea Ignore) { Push-Location -StackName $fwd }
  }

  $Script:OLDPWD = $PWD
  Set-Location @PSBoundParameters
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

function PathIsDescendedFrom($maybeAncestor, $maybeDescendant) {
  (Resolve-Path $maybeAncestor) -like "$(Resolve-Path $maybeDescendant)*"
  (Resolve-Path $maybeDescendant) -like "$(Resolve-Path $maybeAncestor)*"
}

function EmitIndexedCompletion($items) {
  $items | % {
    $itemText =
      if ($cde.MenuCompletion -and $items.Count -gt 1) {"$($_.index)"}
      else {"'$($_.long)'"}

    New-Object Management.Automation.CompletionResult `
      $itemText,
      "$($_.index). $($_.short)" ,
      "ParameterValue",
      "$($_.index). $($_.long)"
  }
}

function RegisterCompletions([array] $commands, $param, $target) {
  Register-ArgumentCompleter -CommandName $commands -ParameterName $param -ScriptBlock $target
}

function DoUnderTest($block) {
  $Global:__cdeUnderTest = $true
  &$block
}