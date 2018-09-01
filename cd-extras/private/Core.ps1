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
  Clear-Stack -Redo

  # only push to stack if location is actuall changing
  if (
    ($target = Resolve-Path $Path -ErrorAction Ignore) -and (
      $target.Path -ne ((Get-Location).Path))
  ) { Push-Location -StackName $back }

  $Script:OLDPWD = $PWD
  Set-Location @PSBoundParameters
}

filter IsRootedOrRelative {
  ($_ | IsRooted) -or ($_ | IsRelative)
}

filter IsRooted {
  [System.IO.Path]::IsPathRooted($_) -or
  $_ -match '~(/|\\)*' # also consider the path rooted if it's relative to home
}

filter IsRelative {
  $_ -match '^+\.(/|\\)' # e.g. starts with ./, ../
}

function NormaliseAndEscape($pathPart) {
  $normalised = $pathPart -replace '/|\\', ${/}
  [regex]::Escape($normalised)
}

filter Escape {
  [regex]::Escape($_)
}

filter RemoveSurroundingQuotes {
  ($_ -replace "^'", '') -replace "'$", ''
}

filter RemoveTrailingSeparator {
  $_ -replace "(/|\\)$", ''
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

function IndexedComplete($items) {
  filter IndexedCompletion {
    $itemText = if ($cde.MenuCompletion -and @($items).Count -gt 1) {"$($_.index)"}
    else {"'$($_.long)'"}

    [Management.Automation.CompletionResult]::new(
      $itemText,
      "$($_.index). $($_.short)" ,
      "ParameterValue",
      "$($_.index). $($_.long)"
    )
  }

  $items | IndexedCompletion
}

function RegisterCompletions([array] $commands, $param, $target) {
  Register-ArgumentCompleter -CommandName $commands -ParameterName $param -ScriptBlock $target
}

function DoUnderTest($block) {
  $Global:__cdeUnderTest = $true
  &$block
}

function WriteLog($message) {
  if ($cde | Get-Member _logger) { &$cde._logger $message }
  else { Write-Verbose $message }
}