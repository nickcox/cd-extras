${Script:/} = [System.IO.Path]::DirectorySeparatorChar
$Script:Multidot = '^\.{3,}$'
$Script:fwd = 'fwd'
$Script:back = 'back'
$Script:OLDPWD # used by Step-Back
$Script:setLocation = {SetLocationEx @args}

function SetLocationEx {
  [CmdletBinding()]
  param([string]$Path, [switch]$PassThru)

  # discard any existing forward (redo) stack
  $Script:fwd = 'fwd' + [Guid]::NewGuid()

  # don't push consecutive dupes onto stack
  if (
    (@((Get-Location -StackName $back -ea Ignore )) | Select -First 1).Path -ne
    (Get-Location).Path
  ) {
    if (Get-Item $path -ea Ignore) { Push-Location -StackName $back }
  }

  $Script:OLDPWD = $PWD
  Set-Location @PSBoundParameters
}

function IsRootedOrRelative($path) {
  (IsRooted $path) -or (IsRelative $path)
}

function IsRooted($path) {
  return [System.IO.Path]::IsPathRooted($path) -or
  $path -match '~(/|\\)*' # also consider the path rooted if it's relative to home
}

function IsRelative($path) {
  return $path -match '^+\.(/|\\)' # e.g. starts with ./, ../
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
  (Resolve-Path $maybeDescendant) -like "$(Resolve-Path $maybeAncestor)*"
}

filter IndexedCompletion {
  $itemText = if ($cde.MenuCompletion -and $items.Count -gt 1) {"$($_.index)"}
  else {"'$($_.long)'"}

  [Management.Automation.CompletionResult]::new(
    $itemText,
    "$($_.index). $($_.short)" ,
    "ParameterValue",
    "$($_.index). $($_.long)"
  )
}

function RegisterCompletions([array] $commands, $param, $target) {
  Register-ArgumentCompleter -CommandName $commands -ParameterName $param -ScriptBlock $target
}

function DoUnderTest($block) {
  $Global:__cdeUnderTest = $true
  &$block
}