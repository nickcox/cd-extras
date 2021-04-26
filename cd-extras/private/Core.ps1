${Script:/} = [IO.Path]::DirectorySeparatorChar
$Script:undoStack = [Collections.Stack]::new()
$Script:redoStack = [Collections.Stack]::new()

$Script:recent = [Collections.Generic.Dictionary[string, RecentDir]]::new()
$Script:logger = { Write-Verbose ($args[0] | ConvertTo-Json) }
$Script:background

function DefaultIfEmpty([scriptblock] $default) {
  Begin { $any = $false }
  Process { if ($_) { $any = $true; $_ } }
  End { if (!$any) { &$default } }
}

filter Truncate([int] $maxLength = $cde.MaxMenuLength) {
  if (!$_ -or $_.Length -le $maxLength) { return $_ }

  if ($_.StartsWith([char]27)) {
    TruncatedColoured $_ $maxLength
  }
  else {
    $_.Substring(0, $maxLength - 1) + [char]0x2026 # ellipsis
  }
}

function TruncatedColoured([string]$string, $maxLen) {
  $textStart = $string.IndexOf('m') + 1
  $startFinalEscapeSequence = $string.LastIndexOf([char]27)
  $text = $string.Substring($textStart, $startFinalEscapeSequence - $textStart)

  if ($text.Length -le $maxLen) {
    $string
  }
  else {
    $string.Substring(0, $textStart) + ($text | Truncate) + "$([char]27)[0m"
  }
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
  ($_ | Get-Ancestors).Path -contains ($maybeAncestor | Resolve-Path)
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

filter EscapeWildcards {
  [WildcardPattern]::Escape($_)
}

function GetStackIndex([array]$stack, [string]$namepart) {
  (
    $items = $stack -eq ($namepart | Normalise | RemoveTrailingSeparator) # full path match
  ) -or (
    $items = $stack.Where{ ($_ | Split-Path -Leaf) -eq $namepart } # full leaf match
  ) -or (
    $items = $stack.Where{ ($_ | Split-Path -Leaf) -Match "^$($namepart | NormaliseAndEscape)" } # leaf starts with
  ) -or (
    $items = $stack -match ($namepart | NormaliseAndEscape) # anything...
  ) | Out-Null

  [array]::indexOf($stack, ($items | select -First 1))
}

function IndexedComplete([bool] $IndexedCompletion = $cde.IndexedCompletion) {
  Begin { $items = @() }
  Process { $items += $_ }
  End {
    $items | % {

      $completionText =
      if ($IndexedCompletion -and @($items).Count -gt 1) { "$($_.n)" }
      else { $_.path | SurroundAndTerminate }

      $listItemText = "$($_.n). $($_.name)"
      $tooltip =
      if ($_.name -ne $_.path) { "$($_.n). $($_.path)" }
      else { "$($_.n). ($($_.path))" }

      [Management.Automation.CompletionResult]::new(
        $completionText,
        $listItemText,
        'ParameterValue',
        $tooltip
      )
    }
  }
}

function IndexPaths(
  [array]$xs,
  $rootLabel = 'root' # this on happens on *nix
) {
  $xs = $xs -ne ''
  if (!$xs) { return }

  $i = 0
  $xs.ForEach{
    [IndexedPath] @{
      n    = ++$i
      Name = $_ | Split-Path -Leaf | DefaultIfEmpty { $rootLabel }
      Path = $_
    } }
}
function RegisterCompletions([string[]] $commands, $param, $target) {
  Register-ArgumentCompleter -CommandName $commands -ParameterName $param -ScriptBlock $target
}

function ImportRecent() {
  $dirs = Import-Csv $cde.RECENT_DIRS_FILE
  $cde.recentHash = if ($h = Get-FileHash -LiteralPath $cde.RECENT_DIRS_FILE) {
    $h.Hash.ToString()
  }

  $recent.Clear()
  $dirs.ForEach{
    $dir = [RecentDir]$_
    $dir.Favour = $_.Favour -and [bool]::Parse($_.Favour)
    $recent[$_.Path] = $dir
  }
}

function RefreshRecent() {
  if (!$cde.RECENT_DIRS_FILE) { return }

  try {
    if ($hasMutex = $cde.mutex.WaitOne(1)) {
      # assumes we already know the file exists
      $currentHash = (Get-FileHash -LiteralPath $cde.RECENT_DIRS_FILE).Hash.ToString()
      if ($currentHash -ne $cde.recentHash) {
        WriteLog ($currentHash, $cde.recentHash)
        ImportRecent
      }
    }
  }
  finally {
    if ($hasMutex) { $cde.mutex.ReleaseMutex() }
  }
}

function RecentsByTermWithSort([int] $first, [string[]] $terms, [scriptblock] $sort) {
  function MatchesTerms([string] $path) {
    function MatchPath() {
      $indexes = $terms.ForEach{ $path.IndexOf($_, [System.StringComparison]::CurrentCultureIgnoreCase) }.Where{ $_ -gt 0 }
      $indexes.Count -eq $terms.Count -and (!(Compare-Object -SyncWindow 0 $indexes ($indexes | Sort-Object)))
    }
    function MatchLeaf() { (Split-Path -Leaf $path) -match $terms[-1] }

    if (!$terms) { return $true }
    (MatchPath) -and (MatchLeaf)
  }

  RefreshRecent
  $recent.Values.Where( { ($_.Path -ne $pwd) -and (MatchesTerms $_.Path) }) |
  Sort-Object $sort -Descending |
  select -First $first -Expand Path
}

function GetFrecent([int] $first, [string[]] $terms) {
  function FrecencyFactor([ulong] $lastEntered) {
    $now = [System.DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()

    if ($lastEntered -gt ($now - 1000 * 60 * 60)) { 4 } # past hour
    elseif ($lastEntered -gt ($now - 1000 * 60 * 60 * 24)) { 2 } # past day
    elseif ($lastEntered -gt ($now - 1000 * 60 * 60 * 24 * 7)) { 1 / 2 } # past week
    else { 1 / 4 }
  }

  function FavourFactor([bool] $isFavoured) {
    ([int]$isFavoured * 1000) + 1
  }

  RecentsByTermWithSort $first $terms {
    $_.EnterCount * (FrecencyFactor $_.LastEntered) * (FavourFactor $_.Favour)
  }
}

function GetRecent([int] $first, [string[]] $terms) {
  RecentsByTermWithSort $first $terms { $_.LastEntered }
}

function UpdateRecent($path, $favour = $false) {
  if ($path -in $cde.RECENT_DIRS_EXCLUDE) { return }

  $entry =
  if (($current = $recent[$path])) { $current }
  else { [RecentDir] @{ Path = $path; EnterCount = $favour } }

  if (!$favour) {
    $entry.LastEntered = [System.DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $entry.EnterCount++
  }
  else {
    $entry.Favour = $true
  }

  $recent[$path] = $entry

  if ($recent.Count -gt $cde.MaxRecentDirs) {
    RemoveRecent (
      $recent.Values |
      Sort-Object Favour, LastEntered |
      select -First ($recent.Count - $cde.MaxRecentDirs) -expand Path)
  }

  PersistRecent
}

function Unfavour([RecentDir] $dir) {
  if (!$dir.LastEntered) { RemoveRecent(@($dir.Path)) }
  else {
    $dir.Favour = $false
    PersistRecent
  }
}

function RemoveRecent([string[]] $dirs) {
  $dirs | % { $recent.remove($_) } | Out-Null
  PersistRecent
}

function PersistRecent() {
  if ($cde.RECENT_DIRS_FILE) {
    if (!$background) { InitRunspace }

    try {
      if ($hasMutex = $cde.mutex.WaitOne(1000)) {
        $background.Stop()
        $null = $background.BeginInvoke()
      }
      else {
        WriteLog 'Recent dirs file in use'
      }
    }

    finally {
      if ($hasMutex) { $cde.mutex.ReleaseMutex() }
    }
  }
}

function InitRunspace() {
  # infra for backgrounding recent dirs persistence
  $Script:background = [PowerShell]::Create()
  $null = $background.AddScript( {
      try {
        if ($hasMutex = $cde.mutex.WaitOne(1000)) {
          $recent.Values | Export-Csv -LiteralPath $cde.RECENT_DIRS_FILE
          Write-Verbose ($cde.recentHash = (Get-FileHash $cde.RECENT_DIRS_FILE).Hash.ToString())
        }
      }
      finally {
        if ($hasMutex) { $cde.mutex.ReleaseMutex() }
      } })

  $runspace = [RunspaceFactory]::CreateRunspace()
  $runspace.Open()
  $runspace.SessionStateProxy.SetVariable('recent', $recent)
  $runspace.SessionStateProxy.SetVariable('cde', $cde)
  $background.Runspace = $runspace
}

function WriteLog($message) {
  $m = if ($message) { $message } else { '[null]' }
  &$logger $m
}
