[![Coverage Status](https://coveralls.io/repos/github/nickcox/cd-extras/badge.svg?branch=master)
](https://coveralls.io/github/nickcox/cd-extras?branch=master)
[![cd-extras](https://img.shields.io/powershellgallery/v/cd-extras.svg?style=flat&label=cd-extras)
](https://www.powershellgallery.com/packages/cd-extras)

![Overview](./assets/overview.svg)

cd-extras
===========

<!-- TOC -->

- [Navigation helpers](#navigation-helpers)
  - [Even faster](#even-faster)
  - [Navigation helper completions](#navigation-helper-completions)
  - [Viewing available locations](#viewing-available-locations)
- [`cd` enhancements](#cd-enhancements)
  - [Path shortening](#path-shortening)
  - [Multi-dot `cd`](#multi-dot-cd)
  - [No argument `cd`](#no-argument-cd)
  - [Two argument `cd`](#two-argument-cd)
- [Enhanced completion for `cd` and others](#enhanced-completion-for-cd-and-others)
  - [Single and double periods](#single-and-double-periods)
  - [Multi-dot completions](#multi-dot-completions)
  - [Variable based completions](#variable-based-completions)
  - [Extending completion to other commands](#extending-completion-to-other-commands)
  - [Colourised completions](#colourised-completions)
- [AUTO CD](#auto-cd)
  - [Tilde](#tilde)
  - [Multi-dot](#multi-dot)
- [CD PATH](#cd-path)
- [CDABLE VARS](#cdable-vars)
- [Additional helpers](#additional-helpers)
  - [Get-Up (gup)](#get-up-gup)
  - [Get-Stack (dirs)](#get-stack-dirs)
  - [Clear-Stack (dirsc)](#clear-stack-dirsc)
  - [Expand-Path (xpa)](#expand-path-xpa)
- [Compatibility](#compatibility)
  - [Alternative providers](#alternative-providers)
  - [OS X & Linux](#os-x--linux)
- [Install](#install)
- [Configure](#configure)
  - [cd-extras options](#cd-extras-options)
  - [Navigation helper key handlers](#navigation-helper-key-handlers)
  - [Using a different alias](#using-a-different-alias)

<!-- /TOC -->

# Navigation helpers

<details>
<summary>[<i>Watch</i>]<p/></summary>

![Navigation Helpers](assets/navigation-helpers.svg)

</details>

_cd-extras_ provides the following aliases (and corresponding functions):

- `cd-`, `~`, (`Undo-Location`)
- `cd+`, `~~`, (`Redo-Location`)
- `up`, `..` (`Step-Up`)
- `cdb` (`Step-Between`)

```pwsh
[C:/Windows/System32]> up # or ..
[C:/Windows]> cd- # or ~
[C:/Windows/System32]> cd+ # or ~~
[C:/Windows]> █
```

Note that the aliases are `cd-` and `cd+`, without a space. `cd -` and `cd +` (with a space)
also work but you won't get [tab completions](#navigation-helper-completions).

Repeated uses of `cd-`  keep moving backwards towards the beginning of the stack rather than
toggling between the two most recent directories as in vanilla bash. Use `Step-Between` (`cdb`)
if you want to toggle between directories.

```pwsh
[C:/Windows/System32]> cd ..
[C:/Windows]> cd ..
[C:/]> cd-
[C:/Windows]> cd-
[C:/Windows/System32]> cd+
[C:/Windows]> cd+
[C:/]> cdb
[C:/Windows]> cdb
[C:/]> █
```

## Even faster

`up`, `cd+` and `cd-` each take a single optional parameter: either a number of steps, `n`...

```pwsh
[C:/Windows/System32]> .. 2 # or `up 2`
[C:/]> cd temp
[C:/temp]> cd- 2 # `cd -2`, `~ 2` or just `~2` also work
[C:/Windows/System32]> cd+ 2
[C:/temp]> █
```

...or a string, `NamePart`, used to select the nearest matching directory from the available
locations. Given a `NamePart`, _cd-extras_ will search from the current location for directories
whose _leaf_ name contains the given string (ex. ¹). If none is found then it will attempt to
find a match within the full path of each candidate directory (ex. ²).

```pwsh
[C:/Windows]> cd system32
[C:/Windows/System32]> cd drivers
[C:/Windows/System32/drivers]> cd- win # [ex. 1] by leaf name
[C:/Windows/]> cd+ 32/dr # [ex. 2] by full name
[C:/Windows/System32/drivers]> up win # by leaf name again
[C:/Windows]> █
```

Each helper includes a `-PassThru` switch which returns a `PathInfo` value in case you need a
reference to the resulting directory. The value will be `$null` if the action wasn't completed
(for example, because there was nothing in the stack).

```pwsh
[C:/Windows/System32]> up -PassThru

Path
----
C:\Windows

[C:/Windows]> cd- -PassThru

Path
----
C:\Windows\System32

[C:/Windows/System32]> █
```

## Navigation helper completions

Tab completions are provided for each of `cd-` (_aka_ `~`), `cd+` (_aka_ `~~`) and `up`
(_aka_ `..`).

When the `MenuCompletion` option is set and more than one completion is available, the
completions offered are the indexes of each corresponding directory; the name itself is
displayed in the menu below. The full directory path is shown in the tooltip if you also
have `PSReadLine` tooltips enabled. _cd-extras_ will attempt to detect `PSReadLine` options
in order to set `MenuCompletion` appropriately at start-up.

```pwsh
[C:/Windows/System32/drivers/etc]> up ⇥
[C:/Windows/System32/drivers/etc]> up 1

1. drivers  2. System32  3. Windows  4. C:\
───────────

C:\Windows\System32\drivers
```

It's also possible tab-complete `cd-`, `cd+` and `up` using a partial directory name (i.e.
the [`NamePart` parameter](#even-faster)).

```pwsh
[~/projects/PowerShell/src/Modules/Shared]> up pr⇥
[~/projects/PowerShell/src/Modules/Shared]> up '~\projects'
[~/projects]> █
```

## Viewing available locations

As an alternative to menu completion you retrieve a list of available navigation targets with:

- `Get-Stack -Undo` (`dirs -u`)
- `Get-Stack -Redo` (`dirs -r`)
- `Get-Ancestors` (`xup`)

```pwsh
[C:/Windows/System32/drivers]> Get-Ancestors # xup

n Name        Path
- ----        ----
1 System32    C:\Windows\System32
2 Windows     C:\Windows
3 C:\         C:\

[C:/Windows/System32/drivers]> up 2
[C:/Windows]> up 1
[C:/]> dirs -u

n Name        Path
- ----        ----
1 Windows     C:\Windows
2 drivers     C:\Windows\System32\drivers

[C:/]> cd- 2
[C:/Windows/System32/drivers]> █
```

# `cd` enhancements

<details>
<summary>[<i>Watch</i>]<p/></summary>

![Navigation Helpers](assets/cd-enhancements.svg)

</details>

`cd-extras` provides a proxy to `Set-Location` - called `Set-LocationEx` - and aliases it to
`cd` by default, giving it several new abilities:

* [Path shortening](#Path-shortening)
* [Multi-dot `cd`](#Multi-dot-cd)
* [No argument `cd`](#No-argument-cd)
* [Two argument `cd`](#Two-argument-cd)
* [Enhanced tab completions](#Enhanced-completion-for-cd-and-others)

## Path shortening

If an unambiguous match is available then `cd` can change directory using an abbreviated path.
This effectively changes a path given as, `p` into `p*` or `~/pr/pow/src` into `~/pr*/pow*/src*`.

```pwsh
[~]> cd pr
[~/projects]> cd cd-e
[~/projects/cd-extras]> cd ~
[~]> cd pr/cd
[~/projects/cd-extras]> █
```

Periods (`.`) are expanded around so a segment containing `.sdk` is expanded into `*.sdk*`.

```pwsh
[~]> cd proj/pow/s/.sdk
[~/projects/powershell/src/Microsoft.PowerShell.SDK]> █
```

Pairs of periods are expanded between so a segment containing `s..32` is expanded into `s*32`.

```pwsh
[~]> cd /w/s..32/d/et
[C:/Windows/System32/drivers/etc]> █
```

Directories in [`CD_PATH`](#cd-path) will be matched.

```pwsh
[C:/]> setocd CD_PATH ~/projects
[C:/]> cd p..shell
[~/projects/PowerShell/]> █
```

[`AUTO_CD`](#auto-cd) uses the same expansion algorithm when enabled.

```pwsh
[~]> # $cde.AUTO_CD -> True
[~]> /w/s/d/et
[C:/Windows/System32/drivers/etc]> ~/pr/pow/src
[~/projects/PowerShell/src]> .sdk
[~/projects/PowerShell/src/Microsoft.PowerShell.SDK]> █
```

If you're not sure whether an unambiguous match is available then just hit tab to pick from
a [list of potential matches](#enhanced-completion-for-cd-and-others) instead.

## Multi-dot `cd`

In the same way that you can navigate up one level with `cd ..`, `Set-LocationEx` supports
navigating multiple levels by adding additional dots. [`AUTO_CD`](#auto-cd) works the same
way if enabled.

```pwsh
[C:/Windows/System32/drivers/etc]> cd ... # same as `up 2` or `.. 2`
[C:/Windows/System32]> cd-
[C:/Windows/System32/drivers/etc>] cd .... # same as `up 3` or `.. 3`
[C:/Windows]> █
```

## No argument `cd`

If the `NOARG_CD` [option](#configure) is defined then `cd` without arguments navigates into
that directory (`~` by default). This overrides the out of the box behaviour on PowerShell>=
6.0, where no-arg `cd` always navigates to `~` and PowerShell < 6.0, where no argument `cd`
doesn't do anything at all.

```pwsh
[~/projects/powershell]> cd
[~]> setocd NOARG_CD /
[~]> cd
[C:/]>
```

## Two argument `cd`

Replaces all instances of the first argument in the current path with the second argument,
changing to the resulting directory if it exists, using the `Switch-LocationPart` function.

You can also use the alias `cd:` or the explicit `ReplaceWith` parameter of
`Set-LocationEx`.

```pwsh
[~/Modules/Unix/Microsoft.PowerShell.Utility]> cd unix shared
[~/Modules/Shared/Microsoft.PowerShell.Utility]> cd: -Replace shared unix
[~/Modules/Unix/Microsoft.PowerShell.Utility]> cd unix -ReplaceWith shared
[~/Modules/Shared/Microsoft.PowerShell.Utility]> █
```

# Enhanced completion for `cd` and others

`cd`, `pushd`, `ls`, `Get-Item` and `Invoke-Item` (by default) provide enhanced completion,
expanding all path segments in one go so that you don't have to individually tab (⇥) through
each one. The path shortening logic is provided by `Expand-Path` and works as [described above
](#path-shortening).

```pwsh
[~]> cd /w/s/dr⇥⇥
[~]> cd C:/Windows/System32/DriverState/

drivers   DriverState   DriverStore
          ───────────

C:\Windows\System32\DriverState
```

Paths within [`$cde.CD_PATH`](#cd-path) are included in the completion results.

```pwsh
[~]> $cde.CD_PATH += '~\Documents\'
[~]> cd win/mod⇥
[~]> ~\Documents\WindowsPowerShell\Modules\█
```

## Single and double periods

Periods (`.`) are expanded around so, for example, a segment containing `.sdk` is expanded
into `*.sdk*`.

```pwsh
[~]> cd proj/pow/s/.sdk⇥
[~]> cd ~\projects\powershell\src\Microsoft.PowerShell.SDK\█
```

or

```pwsh
[~]> ls pr/pow/t/ins.sh⇥
[~]> ls ~\projects\powershell\tools\install-powershell.sh
[~]> ls ~\projects\powershell\tools\install-powershell.sh | cat
#!/bin/bash
...

[~]>
```

A double-dot (`..`) token is expanded inside, so `s..32` becomes `s*32`.

```pwsh
[~]> ls /w/s..32⇥
[~]> ls C:\Windows\System32\█
```

## Multi-dot completions

The [multi-dot syntax](#multi-dot-cd) provides tab completion into ancestor directories.

```pwsh
[~/projects/powershell/docs/git]> cd ...⇥
[~/projects/powershell/docs/git]> cd ~\projects\powershell\█
```

```pwsh
[C:/projects/powershell/docs/git]> cd .../⇥

.git     .vscode    demos    docs   test
─────
.github    assets   docker   src    tools

~\projects\powershell\.git
```

## Variable based completions

When [CDABLE_VARS](#cdable-vars) is enabled, completions are available for the names of
variables that contain file paths. This can be combined with the `-Export` option of
`Get-Ancestors` (`xup`), which recursively exports each parent directory's path into a
global variable with a corresponding name.

```pwsh
[C:/projects/powershell/src/Modules/Unix]> xup -Export -ExcludeRoot

n Name        Path
- ----        ----
1 Modules     C:\projects\powershell\src\Modules
2 src         C:\projects\powershell\src
3 powershell  C:\projects\powershell
4 projects    C:\projects

[C:/projects/powershell/src/Modules/Unix]> up pow
[C:/projects/powershell]> cd mod⇥
[C:/projects/powershell]> cd .\src\modules\
```

## Extending completion to other commands

You can extend the list of commands that participate in enhanced completion for either
*directories* or *files*, or for both *files and directories*, using the `DirCompletions`
`FileCompletions` and `PathCompletions` [options](#configure) respectively.

(`FileCompletions` is the least useful of the three since you can't tab through intermediate
directories to get to the file you're looking for.)

```pwsh
[~]> setocd DirCompletions mkdir
[~]> mkdir ~/pow/src⇥
[~]> mkdir ~\powershell\src\█
```



```pwsh
[~]> setocd PathCompletions Copy-Item
[~]> cp /t/⇥
[~]> cp C:\temp\subdir\█
subdir  txtFile.txt  txtFile2.txt
──────

C:\temp\subdir
```

In each case, completions work against the target's `Path` parameter; if you want enhanced
completion for a native executable or for a cmdlet without a `Path` parameter then you'll
need to provide a wrapper. Either the wrapper or the target itself should handle expanding
`~` where necessary.

```pwsh
[~]> function Invoke-VSCode($path) { &code (xpa $path) }
[~]> setocd PathCompletions Invoke-VSCode
[~]> Set-Alias co Invoke-VSCode
[~]> co ~/pr/po⇥
[~]> co ~\projects\powershell\█
```

An alternative to registering a bunch of aliases is to create a tiny wrapper to pipe input
from `ls` or `gi`.

```pwsh
[~]> function to($target) { &$target $input }
[~]> ls ~/pr/po/r.md⇥
[~]> ls ~/projects/powershell/readme.md | to bat

───────────────────────────────────────────────────────
File: C:\Users\Nick\projects\PowerShell\README.md
───────────────────────────────────────────────────────
1 | ...
2 | ...
```

You could skip tab completion altogether and use [Expand-Path](#Additional-helpers)
directly if you're feeling confident.

```pwsh
[~]> xpa ~/pr/po/r.md | to bat

───────────────────────────────────────────────────────
File: C:\Users\Nick\projects\PowerShell\README.md
───────────────────────────────────────────────────────
1 | ...
2 | ...
```

## Colourised completions

The `ColorCompletion` option (`setocd ColorCompletion`) enables colourisation of completions
in the filesystem provider via [DirColors][1] or via your own global `Format-ColorizedFilename`
function.

# AUTO CD

<details>
<summary>[<i>Watch</i>]<p/></summary>

![AUTO_CD](assets/auto-cd.svg)

</details>

Change directory without typing `cd`.

```pwsh
[~]> projects
[~/projects]> cd-extras
[~/projects/cd-extras]> /
[C:/]> █
```

As with the [enhanced `cd`](#cd-enhancements) command, [abbreviated paths](#path-shortening)
and [multi-dot syntax](#multi-dot-cd) are supported.

```pwsh
[~]> pr
[~/projects]> cd-e
[~/projects/cd-extras]> cd
[~]> pr/cd
[~/projects/cd-extras]> █
```

## Tilde

`AUTO_CD` supports a shorthand syntax for `cd-` using tilde (`~`). You can use this with or
without a space between tilde and the number, although [tab completion
](#navigation-helper-completions) only works after a space (`~ ⇥`).

```pwsh
[C:/Windows/System32]> /
[C:/]> temp
[C:/temp]> dirs -u

n Name      Path
- ----      ----
0 temp      C:\temp
1 C:\       C:\
2 System32  C:\Windows\System32

[C:/temp]> ~2 # or ~ 2
[C:/Windows/System32]> ~~2 # or ~~ 2
[C:/temp]> █
```

## Multi-dot

Multi-dot syntax works with `AUTO_CD` as an alternative to `up [n]`.

```pwsh
[C:/Windows/System32/drivers/etc]> ... # same as `up 2` or `.. 2`
[C:/Windows/System32]> cd-
[C:/Windows/System32/drivers/etc>] .... # same as `up 3` or `.. 3`
[C:/Windows]>  █
```

# CD PATH

Search additional locations for candidate directories.

```pwsh
[~]> setocd CD_PATH ~/documents
[~]> # or $cde.CD_PATH = ,'~/documents'
[~]> cd WindowsPowerShell
[~/documents/WindowsPowerShell]> █
```

[Tab-completion](#enhanced-completion-for-cd-and-others) and [path shortening](#path-shortening)
work with `CD_PATH` directories. Note that `CD_PATH`s are _not_ searched when an absolute or
relative path is given.

```pwsh
[~]> setocd CD_PATH ~/documents
[~]> cd ./WindowsPowerShell
Set-Location : Cannot find path '~\WindowsPowerShell'...
```

# CDABLE VARS

Save yourself a `$` when cding into folders using a variable name and enable [completion
](#variable-based-completions) for child directories.

Given a variable containing the path to a folder (configured in your `$PROFILE`, perhaps,
or by invoking [`Get-Ancestors`](#variable-based-completions)), you can `cd` into it using
the name of the variable.

```pwsh
[~]> $power = '~/projects/powershell'
[~]> cd power
[~/projects/powershell]> █
```

This works with relative paths too, so if you find yourself frequently `cd`ing into the same
subdirectories you could create a corresponding variable.

```pwsh
[~/projects/powershell]> $gh = './.git/hooks'
[~/projects/powershell]> cd gh
[~/projects/powershell/.git/hooks]> █
```

CDABLE_VARS is off by default; enable it with, [`setocd CDABLE_VARS`](#configure). You can
combine it with [AUTO_CD](#auto-cd) for great good:

```pwsh
[C:/projects/powershell/src/Modules/Unix]> xup -Export | out-null
[C:/projects/powershell/src/Modules/Unix]> projects
[C:/projects]> src
[C:/projects/powershell/src]> █
```

# Additional helpers

## Get-Up (_gup_)

Gets the path of an ancestor directory, either by name or by `n` levels.
Returns the parent of the current directory by default.


## Get-Stack (_dirs_)

View contents of undo (`cd-`) and redo (`cd+`) stacks.

Use `dirs -u` for an indexed list of undo locations or `dirs -r` for a corresponding list of
redo locations.


## Clear-Stack (_dirsc_)

Clear contents of undo (`cd-`) and/or redo (`cd+`) stacks.

## Expand-Path (_xpa_)
Expands a candidate path by inserting wildcards between each segment. Use a trailing slash to
expand *children* of the matched path(s).

**note:** the expansion may match more than you expect. always test the output before piping it
into a potentially destructive command.


# Compatibility

## Alternative providers

_cd-extras_ is primarily intended to work against the filesystem provider but it should work
fine with other providers too.

```pwsh
[~]> cd hklm:\
[HKLM:]> cd so/mic/win/cur/windowsupdate
[HKLM:/SOFTWARE/Microsoft/Windows/CurrentVersion/WindowsUpdate]> ..
[HKLM:/SOFTWARE/Microsoft/Windows/CurrentVersion]> cd-
[HKLM:/SOFTWARE/Microsoft/Windows/CurrentVersion/WindowsUpdate]> cd- 2
[~]> █
```

## OS X & Linux

`cd-extras` works on non-Windows operating systems. Note that the `MenuCompletion` option
may be off be default unless you configure PSReadLine with a `MenuComplete` keybinding _before_
importing `cd-extras`.

```pwsh
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
```

Otherwise you can enable `cd-extras` menu completions manually with:

```pwsh
setocd MenuCompletion
```

# Install

From the [gallery](https://www.powershellgallery.com/packages/cd-extras/)

```pwsh
Install-Module cd-extras
Import-Module cd-extras

# add to profile. e.g:

Add-Content $PROFILE `n, 'Import-Module cd-extras'
```

or get the latest from github

```pwsh
git clone git@github.com:nickcox/cd-extras.git
Import-Module cd-extras/cd-extras/cd-extras.psd1 # yep, three :D

```

# Configure

## _cd-extras_ options

- _AUTO_CD_: `[bool] = $true`
  - Any truthy value enables auto_cd.
- _CDABLE_VARS_: `[bool] = $false`
  - `cd` and tab-complete into directory paths stored in variables without prefixing the variable
  name with `$`.
- _NOARG_CD_: `[string] = '~'`
  - If specified, `cd` command with no arguments will change to the given directory.
- _CD_PATH_: `[string[]] = @()`
  - Paths to be searched by `cd` and tab completion. Note that this is an array, not a delimited
  string.
- _MenuCompletion_: `[bool] = $true` (if PSReadLine available)
  - If truthy, indexes are offered as completions for `up`, `cd+` and `cd-` with full paths
    displayed in the menu.
- _DirCompletions_: `[string[]] = 'Set-Location', 'Set-LocationEx', 'Push-Location'`
  - Commands that participate in enhanced tab completion for directories.
- _PathCompletions_: `[string[]] = 'Get-ChildItem', 'Get-Item', 'Invoke-Item', 'Expand-Path'`
  - Commands that participate in enhanced tab completion for any type of path (files &
  directories).
- _FileCompletions_: `[string[]] = @()`
  - Commands that participate in enhanced tab completion for files.
- _ColorCompletion_ : `[bool] = false`
  - If truthy, offered Dir/Path/File completions will be coloured by
  `Format-ColorizedFilename`, if available.
- _MaxMenuLength_ : `[int] = 60`
  - Truncate completion menu items to this length. Column layout may break below about 60
  characters.
- _MaxCompletions_ : `[int] = 99`
  - Limit the number of Dir/Path/File completions offered. Should probably be at least one less
  than `(Get-PSReadLineOption).CompletionQueryItems`.

To configure _cd-extras_ create a hashtable, `cde`, with one or more of these keys _before_
importing it:

```pwsh
$cde = @{
  AUTO_CD = $false
  CD_PATH = '~/Documents/', '~/Downloads'
}

Import-Module cd-extras
```

or call the `Set-CdExtrasOption` (`setocd`) function after importing the module:

```pwsh
Import-Module cd-extras

setocd PathCompletions Invoke-VSCode # appends PathCompletions
setocd CDABLE_VARS # turns CDABLE_VARS on
setocd AUTO_CD $false # turns AUTO_CD off
setocd NOARG_CD /
```

Note: if you want to opt out of the default [completions](#enhanced-completion-for-cd-and-others)
then you should do it before _cd-extras_ is loaded since PowerShell doesn't provide any way of
unregistering argument completers.

```pwsh
$cde = @{
  DirCompletions = @()
}

Import-Module cd-extras
```

## Navigation helper key handlers

If you want to bind [navigation helpers](#navigation-helpers) to `PSReadLine` [key handlers][2]
then you'll probably want to redraw the prompt after navigation.

```pwsh
function invokePrompt() { [Microsoft.PowerShell.PSConsoleReadLine]::InvokePrompt() }
@{
  'Alt+^'         = { if (up  -PassThru) { invokePrompt } }
  'Alt+['         = { if (cd- -PassThru) { invokePrompt } }
  'Alt+]'         = { if (cd+ -PassThru) { invokePrompt } }
  'Alt+Backspace' = { if (cdb -PassThru) { invokePrompt } }
}.GetEnumerator() | % { Set-PSReadLineKeyHandler $_.Name $_.Value }
```

## Using a different alias

_cd-extras_ aliases `cd` to its proxy command, `Set-LocationEx`. If you want to use a different
alias then you'll probably want to restore the original `cd` alias too.

```pwsh
[~]> set-alias cd set-location -Option AllScope
[~]> set-alias cde set-locationex
[~]> cde /w/s/d/et
[C:/Windows/System32/drivers/etc]> cd- # still cd-, not cde-
[~]> █
```

`cd-extras` will only remember locations visited via `Set-LocationEx` or its alias.

[1]: https://github.com/DHowett/DirColors
[2]: https://docs.microsoft.com/powershell/module/psreadline/set-psreadlinekeyhandler
