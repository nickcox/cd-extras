${Script:/} = [System.IO.Path]::DirectorySeparatorChar
$Script:fwd = 'fwd'
$Script:back = 'back'
enum CycleDirection { Undo; Redo }
$Script:cycleDirection = [CycleDirection]::Undo # used by Step-Back

function DefaultIfEmpty([scriptblock] $default) {
  Begin { $any = $false }
  Process { if ($_) {$any = $true; $_} }
  End { if (!$any) {&$default} }
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

filter IsDescendedFrom($maybeAncestor) {
  (Resolve-Path $_ -ErrorAction Ignore) -like "$(Resolve-Path $maybeAncestor)*"
}

function NormaliseAndEscape($pathPart) {
  $pathPart | Normalise | Escape
}

filter Normalise {
  $_ -replace '/|\\', ${/}
}

filter Escape {
  [regex]::Escape($_)
}

filter RemoveSurroundingQuotes {
  ($_ -replace "^'", '') -replace "'$", ''
}

filter SurroundAndTerminate($trailChar) {
  if ($_ -notmatch ' |\[|\]') { "$_$trailChar" }
  else { "'$_$trailChar'" }
}

filter RemoveTrailingSeparator {
  $_ -replace "[/\\]$", ''
}

filter EscapeSquareBrackets {
  $_ -replace '\[', '`[' -replace ']', '`]'
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

function IndexedComplete($items) {
  # accept input from parameter or from pipeline
  if (!$items) {$items = @(); $input | % {$items += $_}}

  $items | % {
    $itemText = if ($cde.MenuCompletion -and @($items).Count -gt 1) {"$($_.index)"}
    else {$_.long | SurroundAndTerminate}

    [Management.Automation.CompletionResult]::new(
      $itemText,
      "$($_.index). $($_.short)" ,
      "ParameterValue",
      "$($_.index). $($_.long)"
    )
  }
}

function RegisterCompletions([array] $commands, $param, $target) {
  Register-ArgumentCompleter -CommandName $commands -ParameterName $param -ScriptBlock $target
}

function WriteLog($message) {
  if ((Get-Variable cde) -and ($cde | Get-Member _logger)) { &$cde._logger $message }
  else { Write-Verbose $message }
}

# earlier versions of posh-git export '??' as a public alias, so we use ??? here
function ??? ($default) {
  Begin { $any = $false } 
  Process { if ($_) {$any = $true; $_} } 
  End { if (!$any) {$default} } 
}