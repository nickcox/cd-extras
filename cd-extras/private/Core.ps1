${Script:/} = [IO.Path]::DirectorySeparatorChar
$Script:undoStack = [Collections.Stack]::new()
$Script:redoStack = [Collections.Stack]::new()

# Dictionary[dirName, (accessTime, accessCount)]
$Script:recent = [Collections.Generic.Dictionary[string, RecentDir]]::new()
$Script:recentHash = $null
$Script:logger = { Write-Verbose ($args[0] | ConvertTo-Json) }
$Script:bg

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

function RefreshRecent() {
  # assumes we already know the file exists
  if (!$cde.RECENT_DIRS_FILE) { return }

  $currentHash = (Get-FileHash -LiteralPath $cde.RECENT_DIRS_FILE).Hash.ToString()
  if ($currentHash -ne $recentHash) {
    WriteLog 'RecentDirs file has changed'
    $recent.Clear()
    (Import-Csv $cde.RECENT_DIRS_FILE).ForEach{ $recent[$_.Path] = [RecentDir]$_ }
  }
}

function RecentsByTermWithSort([string[]] $terms, [scriptblock] $sort, [int] $first) {
  function MatchesTerms([string] $path) {
    function MatchPath() {
      $indexes = $terms.ForEach{ $path.IndexOf($_, [System.StringComparison]::CurrentCultureIgnoreCase) }.Where{ $_ -gt 0 }
      $indexes.Count -eq $terms.Count -and (!(Compare-Object -SyncWindow 0 $indexes ($indexes | sort)))
    }
    function MatchLeaf() { (Split-Path -Leaf $path) -match $terms[-1] }

    if (!$terms) { return $true }
    (MatchPath) -and (MatchLeaf)
  }

  RefreshRecent
  $recent.Values.Where( { ($_.Path -ne $pwd) -and (MatchesTerms $_.Path) }, 'First', $first) |
  sort $sort -Descending |
  select -Expand Path
}

function GetFrecent([int] $first = $cde.MaxRecentCompletions, [string[]] $terms) {
  function FrecencyFactor([ulong] $lastEntered) {
    $now = [System.DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()

    if ($lastEntered -gt ($now - 1000 * 60 * 60)) { 4 } # past hour
    elseif ($lastEntered -gt ($now - 1000 * 60 * 60 * 24)) { 2 } # past day
    elseif ($lastEntered -gt ($now - 1000 * 60 * 60 * 24 * 7)) { 1 / 2 } # past week
    else { 1 / 4 }
  }

  RecentsByTermWithSort $terms { $_.EnterCount * (FrecencyFactor $_.LastEntered) } $first
}

function GetRecent([int] $first, [string[]] $terms) {
  RecentsByTermWithSort $terms { $_.LastEntered } $first
}

function SaveRecent($path) {
  if ($path -in ($cde.RECENT_DIRS_EXCLUDE | Resolve-Path).Path) { return }

  $current = $recent[$path]
  $accessCount = if ($current) { $current.EnterCount + 1 } else { 1 }

  $recent[$path] = [RecentDir] @{
    Path        = $path
    LastEntered = [System.DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    EnterCount  = $accessCount
  }

  if ($recent.Count -gt $cde.MaxRecentDirs) {
    $null = $recent.Remove((GetRecent $cde.MaxRecentDirs | select -last 1))
  }

  PersistRecent
}

function RemoveRecent([string[]] $dirs) {
  $dirs | % { $recent.remove($_) } | Out-Null
  PersistRecent
}

function PersistRecent() {
  if ($cde.RECENT_DIRS_FILE) {
    if (!$bg) { InitRunspace }
    $bg.Stop()
    $null = $bg.BeginInvoke()
  }
}

function InitRunspace() {
  # infra for backgrounding recent dirs persistence
  $script:bg = [PowerShell]::Create()
  $null = $bg.AddScript( {
      $recent.Values | Export-Csv -LiteralPath $cde.RECENT_DIRS_FILE
      $Script:recentHash = (Get-FileHash $cde.RECENT_DIRS_FILE).Hash.ToString()
    } )

  $runspace = [RunspaceFactory]::CreateRunspace()
  $runspace.Open()
  $runspace.SessionStateProxy.SetVariable('recent', $recent)
  $runspace.SessionStateProxy.SetVariable('recentHash', $recentHash)
  $runspace.SessionStateProxy.SetVariable('cde', $cde)
  $bg.Runspace = $runspace
}

function WriteLog($message) {
  &$logger $message
}
