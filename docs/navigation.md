# Navigation guide

*Quickly navigate backwards, forwards, upwards or into recently used directories*

<details>
<summary>[<i>Watch</i>]<p/></summary>

![Navigation Helpers](../assets/navigation-helpers.svg)

</details>

<!-- TOC -->

- [Commands](#commands)
- [Parameters](#parameters)
- [Frecency](#frecency)
- [Database](#database)
- [Bookmarks](#bookmarks)
- [Output](#output)
- [Completions](#completions)
- [Listing available navigation targets](#listing-available-navigation-targets)
- [Related commands](#related-commands)
  - [Get-Up (gup)](#get-up-gup)
  - [Get-Stack (dirs)](#get-stack-dirs)
  - [Clear-Stack (dirsc)](#clear-stack-dirsc)
  - [Expand-Path (xpa)](#expand-path-xpa)
- [Compatibility](#compatibility)
  - [OS X & Linux](#os-x--linux)
  - [Alternative providers](#alternative-providers)

<!-- /TOC -->


## Commands

_cd-extras_ provides the following navigation commands and corresponding aliases (shown in parens):

- `Undo-Location`, (`cd-` or `~`)
- `Redo-Location`, (`cd+` or `~~`)
- `Step-Up`, (`up`or `..`)
- `Set-RecentLocation`, (`cdr`)
- `Set-FrecentLocation`, (`cdf`)

```powershell
[C:/Windows/System32]> up # or ..
[C:/Windows]> cd- # or ~
[C:/Windows/System32]> cd+ # or ~~
[C:/Windows]> cdr
[C:/Windows/System32]> cdr
[C:/Windows]> _
```

> **Note:**
> That's `cd-` and `cd+`, without a space. `cd -` and `cd +`, with a space, also work but you won't
> get [auto-completion](#completions).

> **Note:**
> Repeated uses of `cd-`  keep moving backwards towards the beginning of the stack rather than
> toggling between the two most recent directories as in vanilla bash, neither will it echo the path
> of the target directory. Use `Set-RecentLocation` (`cdr`) to toggle between directories and the
> `-PassThru` switch if you need to output the new directory path.

```powershell
[C:/Windows/System32]> cd ..
[C:/Windows]> cd ..
[C:/]> cd-
[C:/Windows]> cd-
[C:/Windows/System32]> cd+
[C:/Windows]> cd+
[C:/]> cdr
[C:/Windows]> cdr -PassThru
Path
----
C:\

[C:/]> _
```


## Parameters

`up`, `cd+`, `cd-`, `cdr` and `cdf` each take an optional argument, `n` which navigates by the given
number of steps.

```powershell
[C:/Windows/System32]> .. 2 # or `up 2`
[C:/]> cd temp
[C:/temp]> cd- 2 # `cd -2`, `~ 2` or just `~2` also work
[C:/Windows/System32]> cd+ 2
[C:/temp]> cdr 2 # cdr ignores the current directory
[C:/]> _
```

`up`, `cd+` and `cd-` also accept a string, `NamePart`, used to select the nearest matching directory
from the available locations. Given a `NamePart`, _cd-extras_ will match the first directory whose
leaf name contains the given string. If none is found then it will attempt to match against the
full path of each candidate directory.

`cdr` and `cdf` use a slightly different name matching logic which is cribbed from [Zoxide][3].
Each command takes one or more `Terms` where each term must match part of a target directory, in order,
and the _last_ (or only) term must match the target's leaf name.


```powershell
[C:/Windows]> cd system32
[C:/Windows/System32]> cd drivers
[C:/Windows/System32/drivers]> cd- win # by leaf name
[C:/Windows/]> cd+ 32/dr # by full name
[C:/Windows/System32/drivers]> up win # by leaf name
[C:/Windows]> cdr drivers # by leaf
[C:/Windows/System32/drivers]> cdr
[C:/Windows]> cdr sys,dr # in sequence
[C:/Windows/System32/drivers]> _
```


## Frecency

While `Get-RecentLocation` (`cdr -l`) and `Set-RecentLocation` (`cdr`) work with the recent
directories list in the order that they were most recently visited, `Get-FrecentLocation` (`cdf -l`)
and `Set-FrecentLocation` (`cdf`) use a frecency algorithm as described in the [Zoxide docs][4].

_cd-extras_ includes a built-in frecency algorithm, but you can also use an external provider. If
[zoxide][3] is found on `PATH` when the module loads, it is automatically configured as the frecency
provider — no setup required.

You can also supply your own custom provider via the
[`FrecentProvider`](configuration.md) option. This is a scriptblock that receives the
search terms as arguments and should return a list of directory paths. Any external tool
that can query and list directories will work. Set `FrecentProvider` to `$null` to revert
to the built-in algorithm.

```powershell
# use a custom tool as the frecency provider
setocd FrecentProvider { &my-jump-tool query --list -- $args }

# revert to built-in frecency
setocd FrecentProvider $null
```


## Database

Recent locations, frecent locations, and bookmarks share a datastore which is not persisted between
sessions by default.
You can opt in to persisting to a CSV file by setting the `RECENT_DIRS_FILE` [option](configuration.md).

```powershell
setocd RECENT_DIRS_FILE $env:APPDATA/.recent-dirs
```

The size of the datastore - whether persisted or not - is configured with the `MaxRecentDirs` option.
Once the limit is reached, the least recently entered directories are discarded after every directory
change although bookmarked directories are never dropped.

You can manually remove entries with the `Remove-RecentLocation` command or by using the `-Prune`
switch with `Set-RecentLocation` and `Set-FrecentLocation`. This command expects a parameter,
`Pattern`, which is a PowerShell wildcard pattern used to match against the directory path or a
complete directory leaf name. If no pattern is given then the current working directory is removed.

```powershell
[~]> Set-Alias z Set-FrecentLocation
[~]> z -l # z -List

n Name    Path
- ----    ----
1 abc     C:\Temp\abc1
2 abc2    C:\Temp\abc2
3 def     C:\Temp\def

[~]> z -prune *abc*
[~]> z -l

n Name    Path
- ----    ----
1 def     C:\Temp\def

[~]> z -p def
[~]> z -l
[~]> _
```


## Bookmarks

Bookmarks promote directories to the top of the built-in frecency list, ensuring they rank above
unvisited or infrequently visited directories regardless of recency. Bookmarks only affect the
built-in frecency algorithm; if you're using a [custom `FrecentProvider`](configuration.md) (e.g.
zoxide), bookmarks have no effect on navigation results.

Directories may be bookmarked with the `Add-Bookmark` command (`mark`). `Add-Bookmark` takes a
`Path` parameter which can be omitted when bookmarking the current directory.
`Set-FrecentLocation` (`cdf`) provides a `-Mark` or `-m` switch with the same functionality.

```
[~]> Set-Alias z Set-FrecentLocation
[~]> z -mark C:\Temp\abc1
[~]> z a
[C:\Temp\abc1]> _
```

Use `Get-Bookmark` to list bookmarked directories (ordered by frecency), and `Remove-Bookmark`
(`unmark`) to remove one or more bookmarks. Both default to the current directory when no argument
is given.

```powershell
[~]> Get-Bookmark          # list all bookmarks
[~]> Get-Bookmark 5        # list the top 5 bookmarks
[~]> unmark                # remove bookmark for the current directory
[~]> unmark abc1           # remove bookmark matching the leaf name 'abc1'
[~]> unmark *              # remove all bookmarks
```


## Output

Each navigation command includes a `-PassThru` switch to return a `PathInfo` value in case you need
a reference to the resulting directory. The value will be `$null` if the action wasn't completed -
for example, if there was nothing in the stack or you attempted to navigate up from the root.

```powershell
[C:/Windows/System32]> up -PassThru

Path
----
C:\Windows

[C:/Windows]> cd- -PassThru

Path
----
C:\Windows\System32

[C:/Windows/System32]> _
```


## Completions

Auto-completions are provided for each of `cd-`, `cd+`, `cdr`, `cdf` and `up`.

Assuming the [_PSReadLine_][0] `MenuComplete` function is bound to tab...

```powershell
[C:]> Get-PSReadLineKeyHandler -Bound | Where Function -eq MenuComplete
```
```
Completion functions
====================

Key           Function     Description
---           --------     -----------
Tab           MenuComplete Complete the input if there is a single completion ...
...
```

...then tabbing through any of the navigation helpers will display a menu based completion.

```powershell
[C:/Windows/System32/drivers/etc]> up <tab><tab>
[C:/Windows/System32/drivers/etc]> up 2

1. drivers  2. System32  3. Windows  4. C:\
            ------------

C:\Windows\System32
```

The _`IndexedCompletion`_ option controls how completion text is displayed. When _IndexedCompletion_
is on and more than one completion is available, the completions offered are the *indices* of each
corresponding directory; the directory name is displayed in the menu below. The full directory path
is given in the tooltip if you have _PSReadLine_ tooltips enabled.

_cd-extras_ detects _PSReadLine_ options in order to set _IndexedCompletion_ at startup. If the
_PSReadLine_ `MenuComplete` option is bound to at least one key combination then _IndexedCompletion_
is turned on by default. You can turn it off if you prefer.

```powershell
[C:/Windows/System32/drivers/etc]> setocd IndexedCompletion 0
[C:/Windows/System32/drivers/etc]> up <tab><tab>
[C:/Windows/System32/drivers/etc]> up C:\Windows\System32

1. drivers  2. System32  3. Windows  4. C:\
            ------------

C:\Windows\System32
```


It's also possible to tab-complete `cd-`, `cd+`, `cdr`, `cdf` and `up` using a partial directory name
(i.e. the [`NamePart` parameter](#parameters)).

```powershell
[~/projects/PowerShell/src/Modules/Shared]> up pr<tab>
[~/projects/PowerShell/src/Modules/Shared]> up '~\projects'
[~/projects]> _
```


## Listing available navigation targets

As an alternative to menu completion you retrieve a list of available targets with:

- `Get-Stack -Undo` (`dirs -u`)
- `Get-Stack -Redo` (`dirs -r`)
- `Get-RecentLocation` (`cdr -l`)
- `Get-FrecentLocation` (`cdf -l`)
- `Get-Ancestors` (`xup`)

```powershell
[C:/Windows/System32/drivers]> Get-Ancestors # xup

n Name        Path
- ----        ----
1 System32    C:\Windows\System32
2 Windows     C:\Windows
3 C:\         C:\

[C:/Windows/System32/drivers]> up 2
[C:/Windows]> up 1
[C:/]> dirs -u # dirs -v also works

n Name        Path
- ----        ----
1 Windows     C:\Windows
2 drivers     C:\Windows\System32\drivers

[C:/]> cd- 2
[C:/Windows/System32/drivers]> cdr -l -First 3

n Name        Path
- ----        ----
1 C:\         C:\
2 Windows     C:\Windows
3 drivers     C:\Windows\System32\drivers

```


## Related commands

### Get-Up (gup)

Gets the path of an ancestor directory, either by name or by number of levels (`n`), returning the
parent of the current directory by default. It supports consuming values from the pipeline so you
can do things like:

```powershell
[C:/projects]> # find git repositories
[C:/projects]> ls .git -Force -Depth 2 | gup
C:\projects\cd-extras
C:\projects\work\app
...

[C:/projects]> # find chocolatey root directory
[C:/projects]> gcm choco | gup 2
C:\ProgramData\chocolatey
```


### Get-Stack (dirs)

View contents of undo (`cd-`) and redo (`cd+`) stacks.

Use `dirs -u` for an indexed list of undo locations, `dirs -r` for a corresponding list of redo
locations, or just `dirs` to see both.


### Clear-Stack (dirsc)

Clear contents of undo (`cd-`) and/or redo (`cd+`) stacks.

### Expand-Path (xpa)
Expands a candidate path by inserting wildcards between each segment. Use a trailing slash to
expand *children* of the matched path(s). Contents of `CD_PATH` will be included.

> **Note:**
> The expansion may match more than you expect. Test the output before piping it into a potentially
> destructive command.


## Compatibility

### OS X & Linux

_cd-extras_ works on non-Windows operating systems. The `IndexedCompletion` option is off by
default unless you configured PSReadLine with a `MenuComplete` keybinding _before_ importing
_cd-extras_.

```powershell
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
```

Otherwise you can enable _cd-extras_ menu completions manually with:

```powershell
setocd IndexedCompletion
```

### Alternative providers

_cd-extras_ is primarily intended to work against the filesystem provider but it should work with
other providers too.

```powershell
[~]> cd hklm:\
[HKLM:]> cd so/mic/win/cur/windowsupdate
[HKLM:/SOFTWARE/Microsoft/Windows/CurrentVersion/WindowsUpdate]> ..
[HKLM:/SOFTWARE/Microsoft/Windows/CurrentVersion]> cd-
[HKLM:/SOFTWARE/Microsoft/Windows/CurrentVersion/WindowsUpdate]> cd- 2
[~]> _
```


[0]: https://github.com/PowerShell/PSReadLine
[3]: https://github.com/ajeetdsouza/zoxide/wiki/Algorithm#matching
[4]: https://github.com/ajeetdsouza/zoxide/wiki/Algorithm#frecency
