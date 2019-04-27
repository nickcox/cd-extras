${Script:/} = [System.IO.Path]::DirectorySeparatorChar
$Script:undoStack = [System.Collections.Stack]::new()
$Script:redoStack = [System.Collections.Stack]::new()
enum CycleDirection { Undo; Redo }
$Script:cycleDirection = [CycleDirection]::Undo # used by Step-Between

function DefaultIfEmpty([scriptblock] $default) {
  Begin { $any = $false }
  Process { if ($_) { $any = $true; $_ } }
  End { if (!$any) { &$default } }
}

filter IsRootedOrRelative {
  ($_ | IsRooted) -or ($_ | IsRelative)
}

filter IsRooted {
  [System.IO.Path]::IsPathRooted($_) -or
  $_ -match '~(/|\\)*' # also consider the path rooted if it's relative to home
}

filter IsRelative {
  $_ -match '^+\.' # e.g. starts with ./, ../, ...
}

filter IsDescendedFrom($maybeAncestor) {
  (Resolve-Path $_ -ErrorAction Ignore) -like "$(Resolve-Path $maybeAncestor)*"
}

filter NormaliseAndEscape {
  $_ | Normalise | Escape
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
  (
    $items = $stack | Where-Object Path -eq $namepart # full path match
  ) -or (
    $items = $stack | Where-Object { ($_ | Split-Path -Leaf) -eq $namepart } # full leaf match
  ) -or (
    $items = $stack | Where-Object { ($_ | Split-Path -Leaf).StartsWith($namepart) } # leaf starts with
  ) -or (
    $items = $stack | Where-Object Path -match ($namepart | NormaliseAndEscape) # anything...
  ) | Out-Null

  [array]::indexOf($stack, ($items | select -First 1))
}

function IndexedComplete() {
  Begin { $items = @() }
  Process { $items += $_ }
  End {
    $items | % {
      $itemText = if ($cde.MenuCompletion -and @($items).Count -gt 1) { "$($_.index)" }
      else { $_.long | SurroundAndTerminate }

      [Management.Automation.CompletionResult]::new(
        $itemText,
        "$($_.index). $($_.short)" ,
        "ParameterValue",
        "$($_.index). $($_.long)"
      )
    }
  }
}

function RegisterCompletions([array] $commands, $param, $target) {
  Register-ArgumentCompleter -CommandName $commands -ParameterName $param -ScriptBlock $target
}

function WriteLog($message) {
  if ((Get-Variable cde) -and ($cde | Get-Member _logger)) { &$cde._logger $message }
  else { Write-Verbose $message }
}