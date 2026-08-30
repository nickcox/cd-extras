# Configuration

To configure _cd-extras_ call the `Set-CdExtrasOption` (`setocd`) function after importing the
module:

```powershell
Import-Module cd-extras

setocd AUTO_CD $false
setocd CD_PATH '~/Documents/', '~/Downloads'
setocd PathCompletions Invoke-VSCode # appends PathCompletions
setocd CDABLE_VARS # turns CDABLE_VARS on
setocd MaxCompletions 0 # auto calculate the maximum number of completions to display

# append the mode string for each item to the completion tooltip
setocd ToolTip { "$($args[0]) ($($args[0].Mode))" }
```

Multiple options can also be set at once by passing any dictionary that implements
`System.Collections.IDictionary`, including a hashtable or ordered dictionary:

```powershell
Import-Module cd-extras
setocd ([ordered]@{ AUTO_CD = $false; CD_PATH = '~/Documents/', '~/Downloads' })
```

Use `Get-CdExtrasOption` (`getocd`) to inspect the active configuration. With no argument it returns
the complete options object; with an option name it returns that option's value:

```powershell
getocd
getocd AUTO_CD
```

<!-- TOC -->

- [Options reference](#options-reference)
- [Navigation helper key handlers](#navigation-helper-key-handlers)
- [Using a different alias](#using-a-different-alias)

<!-- /TOC -->


## Options reference

- _AUTO_CD_: `[bool] = $true`
  - Enables auto_cd.
- _CDABLE_VARS_: `[bool] = $false`
  - Enables cdable_vars.
- _NOARG_CD_: `[string] = '~'`
  - If specified, `cd` with no arguments will change into the given directory.
- _CD_PATH_: `[string[]] = @()`
  - Paths to be searched by `cd` and tab completion. An array, not a delimited string.
- _RECENT_DIRS_FILE_: `[string] = $null`
  - Path to a CSV file for persisting recent, frecent and bookmarked locations between sessions.
    If not set, the datastore is not persisted. When a missing file is configured, the current
    in-memory store is saved to it. An existing file is the complete persisted state and replaces
    the in-memory store. Invalid CSV reports an error and leaves the last valid state unchanged.
- _RECENT_DIRS_EXCLUDE_: `[string[]] = @()`
  - Directories to exclude from the recent locations list.
- _RecentDirsFallThrough_: `[bool] = $true`
  - When truthy, `cdr` and `cdf` will treat the argument as a literal path if no matching
    recent or frecent entry is found.
- _MaxRecentDirs_: `[uint16] = 120`
  - Normal maximum number of entries in the recent locations datastore. Every bookmark is retained,
    so bookmarks can make the total exceed this value. Any remaining capacity is used for the most
    recently entered non-bookmarked directories.
- _MaxRecentCompletions_: `[uint16] = 60`
  - Default number of results returned by `Get-RecentLocation`, `Get-FrecentLocation`,
    and related completions.
- _FrecentProvider_: `[scriptblock] = $null`
  - An optional scriptblock that provides frecent directory paths. If [zoxide][3] is found
    on `PATH` at module load time, this is automatically set to `{ &zoxide query -l -- $args }`.
    The scriptblock must return absolute paths to existing directories in ranked order. Empty values,
    missing paths, non-directory paths, duplicate paths and the current directory are removed before
    the result limit is applied. Set to `$null` to use the built-in frecency algorithm.
- _WordDelimiters_ : `[char[]] = '.', '_', '-'`
  - Word boundaries within path segments. For example, `.foo` will be expanded into `*.foo*`.
- _ToolTip_ : `[ScriptBlock] = { param ($item, $isTruncated) ... }`
  - Information displayed in the menu-completion tooltip. This is passed two arguments: the current item,
  and a boolean indicating whether the list of completions has been truncated. It should return a string.
- _IndexedCompletion_: `[bool] = $true (if MenuComplete key bound)`
  - If truthy, indexes are offered as completions for `up`, `cd+` and `cd-` with full paths
    displayed in the menu.
- _DirCompletions_: `[string[]] = 'Set-Location', 'Set-LocationEx', 'Push-Location'`
  - Commands that participate in enhanced tab completion for directories.
- _PathCompletions_: `[string[]] = 'Get-ChildItem', 'Get-Item', 'Invoke-Item', 'Expand-Path'`
  - Commands that participate in enhanced tab completion for any path (files or directories).
- _FileCompletions_: `[string[]] = @()`
  - Commands that participate in enhanced tab completion for files.
- _ColorCompletion_ : `[bool] = $false`
  - When truthy, dir/path/file completions will be coloured by `Format-ColorizedFilename`, if
    available.
- _MaxMenuLength_ : `[uint16] = 60`
  - Truncate completion menu items to this length.
- _MaxCompletions_ : `[uint16] = 0`
  - Limit the number of menu completions offered. When set to zero, _cd-extras_ attempts to
  calculate the maximum number of completions that can fit on the screen given the current
  `$Host.UI.RawUI.WindowSize` and `$cde.MaxMenuLength`. A non-zero value should be no greater than
  `(Get-PSReadLineOption).CompletionQueryItems`.


## Navigation helper key handlers

If you want to bind [navigation helpers](navigation.md) to _PSReadLine_ [key handlers][2]
then you'll probably want to redraw the prompt after navigation.

```powershell
function invokePrompt() { [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt() }
@{
  'Alt+^'         = { if (up  -PassThru) { invokePrompt } }
  'Alt+['         = { if (cd- -PassThru) { invokePrompt } }
  'Alt+]'         = { if (cd+ -PassThru) { invokePrompt } }
  'Alt+Backspace' = { if (cdr -PassThru) { invokePrompt } }
}.GetEnumerator() | % { Set-PSReadLineKeyHandler $_.Name $_.Value }
```


## Using a different alias

_cd-extras_ aliases `cd` to its proxy command, `Set-LocationEx`. If you want a different alias
then you'll probably want to restore the original `cd` alias too.

```powershell
[~]> set-alias cd set-location -Option AllScope
[~]> set-alias cde set-locationex
[~]> cde /w/s/d/et
[C:/Windows/System32/drivers/etc]> cd- # still cd-, not cde-
[~]> _
```

> **Note:**
> `cd-extras` will only remember locations visited via `Set-LocationEx` or its alias.

```powershell
[~]> dirs -u

[~]> Set-Location code
[~/code]> cd-
[~/code]> _
```


[2]: https://docs.microsoft.com/powershell/module/psreadline/set-psreadlinekeyhandler
[3]: https://github.com/ajeetdsouza/zoxide/wiki/Algorithm#matching
