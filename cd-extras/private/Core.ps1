${Script:/} = [IO.Path]::DirectorySeparatorChar
$Script:esc = [char]27 # for PS <7
$Script:undoStack = [Collections.Stack]::new()
$Script:redoStack = [Collections.Stack]::new()

$Script:recent = @{}
$Script:logger = { Write-Verbose ($args[0] | ConvertTo-Json) }

function DefaultIfEmpty([scriptblock] $default) {
  Begin { $any = $false }
  Process { if ($_) { $any = $true; $_ } }
  End { if (!$any) { &$default } }
}

filter Truncate([int] $maxLength = $cde.MaxMenuLength) {
  if (!$_ -or $_.Length -le $maxLength) { return $_ }

  if ($_.StartsWith($esc)) {
    TruncatedColoured $_ $maxLength
  }
  else {
    $_.Substring(0, $maxLength - 1) + [char]0x2026 # ellipsis
  }
}

function TruncatedColoured([string]$string, $maxLen) {
  $textStart = $string.IndexOf('m') + 1
  $startFinalEscapeSequence = $string.LastIndexOf($esc)
  $textEnd = if ($startFinalEscapeSequence -gt $textStart) { $startFinalEscapeSequence } else { $string.Length - 1 }
  $text = $string.Substring($textStart, $textEnd - $textStart)

  if ($text.Length -le $maxLen) {
    $string
  }
  else {
    $string.Substring(0, $textStart) + ($text | Truncate) + "$esc[0m"
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
  if ($_ -match '[/\\].*?([/\\])$') { $_.TrimEnd('/', '\') } else { $_ }
}

filter EscapeWildcards {
  [WildcardPattern]::Escape($_)
}

function GetBestIndex([array]$array, [string]$namepart) {
  (
    $items = $array -eq ($namepart | Normalise | RemoveTrailingSeparator) # full path match
  ) -or (
    $items = $array.Where{ ($_ | Split-Path -Leaf) -eq $namepart } # full leaf match
  ) -or (
    $items = $array.Where{ ($_ | Split-Path -Leaf) -Match "^$($namepart | NormaliseAndEscape)" } # leaf starts with
  ) -or (
    $items = $array -match ($namepart | NormaliseAndEscape) # anything...
  ) | Out-Null

  [array]::indexOf($array, ($items | select -First 1))
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
  $xs = $xs -ne '' | Select -Unique
  if (!$xs) { return @() }

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

function InvokeWithRecentLock([scriptblock] $action) {
  $hasMutex = $false

  try {
    try {
      $hasMutex = $cde.mutex.WaitOne(1000)
    }
    catch [Threading.AbandonedMutexException] {
      $hasMutex = $true
    }

    if (!$hasMutex) {
      throw "Timed out waiting to update recent directories file '$($cde.RECENT_DIRS_FILE)'."
    }

    &$action
  }
  finally {
    if ($hasMutex) { $cde.mutex.ReleaseMutex() }
  }
}

function ThrowInvalidRecentStore($row, [int] $rowNumber, [string] $reason) {
  $message = "Recent directories file '$($cde.RECENT_DIRS_FILE)' row $rowNumber $reason."
  throw [Management.Automation.ErrorRecord]::new(
    [IO.InvalidDataException]::new($message),
    'InvalidRecentStore',
    [Management.Automation.ErrorCategory]::InvalidData,
    $row
  )
}

function ReadRecentStore() {
  $store = @{}

  if ($cde.RECENT_DIRS_FILE -and (Test-Path -LiteralPath $cde.RECENT_DIRS_FILE)) {
    $header = Get-Content -LiteralPath $cde.RECENT_DIRS_FILE -TotalCount 1 -ErrorAction Stop
    if ([string]::IsNullOrWhiteSpace($header)) {
      ThrowInvalidRecentStore $header 1 'has an empty header'
    }

    $schema = @($header, 'x,x,x,x') | ConvertFrom-Csv -ErrorAction Stop | select -First 1
    $columns = @($schema.PSObject.Properties.Name)
    foreach ($requiredColumn in 'Path', 'LastEntered', 'EnterCount', 'Favour') {
      if ($columns -notcontains $requiredColumn) {
        ThrowInvalidRecentStore $header 1 "is missing required column '$requiredColumn'"
      }
    }

    $rowNumber = 1
    (Import-Csv -LiteralPath $cde.RECENT_DIRS_FILE -ErrorAction Stop).ForEach{
      $rowNumber++

      if ([string]::IsNullOrWhiteSpace($_.Path)) {
        ThrowInvalidRecentStore $_ $rowNumber 'has an empty Path'
      }

      $lastEntered = [uint64]0
      if (![uint64]::TryParse($_.LastEntered, [ref]$lastEntered)) {
        ThrowInvalidRecentStore $_ $rowNumber "has invalid LastEntered value '$($_.LastEntered)'"
      }

      $enterCount = [uint32]0
      if (![uint32]::TryParse($_.EnterCount, [ref]$enterCount)) {
        ThrowInvalidRecentStore $_ $rowNumber "has invalid EnterCount value '$($_.EnterCount)'"
      }

      $favour = $false
      if (![bool]::TryParse($_.Favour, [ref]$favour)) {
        ThrowInvalidRecentStore $_ $rowNumber "has invalid Favour value '$($_.Favour)'"
      }

      if ($store.ContainsKey($_.Path)) {
        ThrowInvalidRecentStore $_ $rowNumber "duplicates path '$($_.Path)'"
      }

      $store[$_.Path] = [RecentDir]@{
        Path = $_.Path
        LastEntered = $lastEntered
        EnterCount = $enterCount
        Favour = $favour
      }
    }
  }

  $store
}

function GetRecentStoreHash() {
  if ($cde.RECENT_DIRS_FILE -and (Test-Path -LiteralPath $cde.RECENT_DIRS_FILE)) {
    (Get-FileHash -LiteralPath $cde.RECENT_DIRS_FILE).Hash.ToString()
  }
  else { $null }
}

function ReadRecentSnapshot() {
  $hashBefore = GetRecentStoreHash
  $store = ReadRecentStore
  $hashAfter = GetRecentStoreHash

  if ($hashBefore -ne $hashAfter) {
    throw [IO.IOException]::new("Recent directories file '$($cde.RECENT_DIRS_FILE)' changed while it was being read.")
  }

  [pscustomobject]@{ Store = $store; Hash = $hashAfter }
}

function SetRecentState([hashtable] $store, [AllowNull()] [string] $recentHash) {
  $Script:recent = $store
  $cde.recentHash = $recentHash
}

function WriteRecentStore([hashtable] $store) {
  if (!$cde.RECENT_DIRS_FILE) { return }

  if (!$store.Count) {
    if (Test-Path -LiteralPath $cde.RECENT_DIRS_FILE) {
      Remove-Item -LiteralPath $cde.RECENT_DIRS_FILE -ErrorAction Stop
    }
    return
  }

  $parent = [IO.Path]::GetDirectoryName($cde.RECENT_DIRS_FILE)
  $leaf = [IO.Path]::GetFileName($cde.RECENT_DIRS_FILE)
  $tempFile = Join-Path $parent ".$leaf.$PID.$([guid]::NewGuid().ToString('N')).tmp"
  $backupFile = "$tempFile.backup"

  try {
    $store.Values |
    Sort-Object Path |
    Export-Csv -NoTypeInformation -LiteralPath $tempFile

    if (Test-Path -LiteralPath $cde.RECENT_DIRS_FILE) {
      [IO.File]::Replace($tempFile, $cde.RECENT_DIRS_FILE, $backupFile)
    }
    else {
      [IO.File]::Move($tempFile, $cde.RECENT_DIRS_FILE)
    }
  }
  finally {
    Remove-Item -LiteralPath $tempFile, $backupFile -ErrorAction Ignore
  }
}

function ImportRecent() {
  InvokeWithRecentLock {
    $snapshot = ReadRecentSnapshot
    $store = $snapshot.Store
    $previousCount = $store.Count
    TrimRecent $store
    if ($store.Count -ne $previousCount) { WriteRecentStore $store }
    $storeHash = if ($store.Count -ne $previousCount) { GetRecentStoreHash } else { $snapshot.Hash }
    SetRecentState $store $storeHash
  }
}

function RefreshRecent() {
  if (!$cde.RECENT_DIRS_FILE) { return }

  InvokeWithRecentLock {
    $currentHash = GetRecentStoreHash

    if ($currentHash -ne $cde.recentHash) {
      WriteLog ($currentHash, $cde.recentHash)
      $snapshot = ReadRecentSnapshot
      SetRecentState $snapshot.Store $snapshot.Hash
    }
  }
}

function RecentsByTermWithSort([int] $first, [string[]] $terms, [scriptblock] $sort) {
  function MatchesTerms([string] $path) {
    function MatchPath($terms, $idx = 0) {
      $fst, $rst = $terms
      if (!$fst) { return $true }
      $nextIdx = $path.IndexOf($fst, $idx, [StringComparison]::CurrentCultureIgnoreCase)
      return ($nextIdx -ge 0) -and (MatchPath $rst ($nextIdx + $fst.Length))
    }
    function MatchLeaf($term) { (Split-Path -Leaf $path) -match $term }

    if (!$terms) { return $true }
    (MatchPath ($terms | Normalise)) -and (MatchLeaf ($terms[-1] | NormaliseAndEscape))
  }

  RefreshRecent
  $recent.Values.Where( { ($_.Path -ne ($pwd | RemoveTrailingSeparator)) -and (MatchesTerms $_.Path) }) |
  Sort-Object $sort -Descending |
  select -First $first -Expand Path
}

function GetFrecent([int] $first, [string[]] $terms) {
  function FrecencyFactor([uint64] $lastEntered) {
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
  $path = $path | RemoveTrailingSeparator
  if ($path -in $cde.RECENT_DIRS_EXCLUDE) { return }

  $lastEntered = [System.DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
  InvokeRecentStoreOperation {
    param($store)

    $entry = if (($current = $store[$path])) {
      $current
    }
    else {
      [RecentDir] @{ Path = $path; EnterCount = $favour }
    }

    if (!$favour) {
      $entry.LastEntered = $lastEntered
      $entry.EnterCount++
    }
    else {
      $entry.Favour = $true
    }

    $store[$path] = $entry
  }
}

function Unfavour([RecentDir] $dir) {
  InvokeRecentStoreOperation {
    param($store)

    if (($entry = $store[$dir.Path])) {
      if (!$entry.LastEntered) { $store.Remove($dir.Path) | Out-Null }
      else { $entry.Favour = $false }
    }
  }
}

function RemoveRecent([string[]] $dirs) {
  InvokeRecentStoreOperation {
    param($store)
    $dirs | % { $store.Remove($_) } | Out-Null
  }
}

function TrimRecent([hashtable] $store = $recent) {
  $bookmarkCount = @($store.Values.Where{ $_.Favour }).Count
  $ordinaryCapacity = [Math]::Max(0, [int]$cde.MaxRecentDirs - $bookmarkCount)
  $ordinary = @($store.Values.Where{ !$_.Favour })

  if ($ordinary.Count -gt $ordinaryCapacity) {
    $ordinary |
      Sort-Object @{ Expression = 'LastEntered'; Descending = $true }, @{ Expression = 'Path'; Descending = $false } |
      select -Skip $ordinaryCapacity -Expand Path |
      % { $store.Remove($_) } |
      Out-Null
  }
}

function InvokeRecentStoreOperation([scriptblock] $operation) {
  if (!$cde.RECENT_DIRS_FILE) {
    &$operation $recent
    TrimRecent
    return
  }

  InvokeWithRecentLock {
    $store = (ReadRecentSnapshot).Store
    &$operation $store
    TrimRecent $store
    WriteRecentStore $store
    SetRecentState $store (GetRecentStoreHash)
  }
}

function PersistRecent() {
  if (!$cde.RECENT_DIRS_FILE) { return }

  InvokeWithRecentLock {
    TrimRecent
    WriteRecentStore $recent
    SetRecentState $recent (GetRecentStoreHash)
  }
}

function WriteLog($message) {
  $m = if ($message) { $message } else { '[null]' }
  &$logger $m
}
