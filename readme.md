[![Coverage Status](https://coveralls.io/repos/github/nickcox/cd-extras/badge.svg?branch=master)](https://coveralls.io/github/nickcox/cd-extras?branch=master)

# cd-extras

<!-- TOC -->

- [Navigation helpers](#navigation-helpers)
  - [Navigate by `n` steps](#navigate-by-n-steps)
  - [Navigate by name](#navigate-by-name)
- [AUTO_CD](#auto_cd)
- [CD_PATH](#cd_path)
- [CDABLE_VARS](#cdable_vars)
- [No argument cd](#no-argument-cd)
- [Two argument cd](#two-argument-cd)
- [Expansion](#expansion)
  - [Enhanced expansion for built-ins](#enhanced-expansion-for-built-ins)
  - [Navigation helper expansions](#navigation-helper-expansions)
  - [Multi-dot and variable based expansions](#multi-dot-and-variable-based-expansions)
- [Path shortening](#path-shortening)
- [Additional helpers](#additional-helpers)
- [Note on compatibility](#note-on-compatibility)
  - [Alternative providers](#alternative-providers)
  - [OS X & Linux](#os-x--linux)
- [Install](#install)
- [Configure](#configure)
  - [_cd-extras_ options](#cd-extras-options)
  - [Using a different alias](#using-a-different-alias)

<!-- /TOC -->

# What is it?

general conveniences for the `cd` command in PowerShell, mostly stolen from bash and zsh.

![Basic Navigation](./basic-navigation.gif)

## Navigation helpers

Provides the following aliases (and corresponding functions):

- `up`, `..` (`Step-Up`)
- `cd-` (`Undo-Location`)
- `cd+` (`Redo-Location`)
- `cdb` (`Step-Back`)

Examples:

```sh
[C:\Windows\System32]> up # or ..
[C:\Windows]> cd-
[C:\Windows\System32]> cd+
[C:\Windows]> █
```

Note that the aliases are `cd-` and `cd+` - without a space - _not_ `cd -` and `cd +`.
Repeated uses of `cd-` will keep moving backwards towards the beginning of the stack
rather than toggling between the two most recent directories as in vanilla bash.
Use `Step-Back` (`cdb`) if you want to toggle between undo and redo.

```sh
[C:\Windows\System32]> ..
[C:\Windows]> ..
[C:\]> cd-
[C:\Windows]> cd-
[C:\Windows\System32]> cd+
[C:\Windows]> cd+
[C:\]> cdb
[C:\Windows]> cdb
[C:\]> █
```

### Navigate by `n` steps

`up`, `cd+` and `cd-` each take a single optional parameter: either a number, `n`,
specifying how many steps to traverse...

```sh
[C:\Windows\System32]> .. 2 # or `up 2`
[C:\]> cd temp
[C:\temp]> cd- 2
[C:\Windows\System32]> cd+ 2
[C:\temp]> █
```

### Navigate by name

...or a string, `NamePart`, used to change to the nearest directory whose name matches
the given argument. Given a `NamePart`, _cd-extras_ will search, starting at the current
location, for directories whose _leaf_ name contains the given string. If none is found
then it will attempt to match against the full path instead.
[Tab completion](#navigation-helper-expansions) is available for these three helpers.

```sh
[C:\Windows]> cd system32
[C:\Windows\System32]> cd drivers
[C:\Windows\System32\drivers]> cd- sys
[C:\Windows\System32]> cd+
[C:\Windows\System32\drivers]> cd- win
[C:\Windows\]> cd+ 32/dr
[C:\Windows\System32\drivers]> up win
[C:\Windows\]> █
```

When the [AUTO_CD](#auto_cd) option is enabled, multiple dot syntax is supported as an
alternative to `up [n]` with [tab completions](#multi-dot-and-variable-based-expansions)
available.

```sh
[C:\Windows\System32\drivers\etc]> ... # same as `up 2` or `.. 2`
[C:\Windows\System32]> cd-
[C:\Windows\System32\drivers\etc>] .... # same as `up 3` or `.. 3`
[C:\Windows]> █
```

## AUTO_CD

Change directory without typing `cd`.

```sh
[~]> projects
[~/projects]> cd-extras
[~/projects/cd-extras]> █
```

As with the `cd` command, [abbreviated paths](#path-shortening) are supported.

```sh
[~]> pr
[~/projects]> cd-e
[~/projects/cd-extras]> █
```

## CD_PATH

Search additional locations for candidate directories. [Tab-expansion](#enhanced-expansion-for-built-ins)
into `CD_PATH` directories is provided.

```sh
[~]> $cde.CD_PATH = @('~/documents')
[~]> # or Set-CdExtrasOption CD_PATH @('~/documents')
[~]> cd WindowsPowerShell
[~/documents/WindowsPowerShell]> █
```

Note that `CD_PATH`s are _not_ searched when an absolute or relative path is given.

```sh
[~]> $cde.CD_PATH = @('~/documents')
[~]> cd ./WindowsPowerShell
Set-Location : Cannot find path '~\WindowsPowerShell' because it does not exist.
```

## CDABLE_VARS

Save yourself a `$` when cding into folders using a variable name and enable
[completion](#multi-dot-and-variable-based-expansions) for child directories.
Given a variable containing the path to a folder (configured, perhaps, in your
`$PROFILE` or by invoking [`Export-Up`](#multi-dot-and-variable-based-expansions)),
you can `cd` into it using the name of the variable.

```sh
[~]> $power = '~/projects/powershell'
[~]> cd power
[~/projects/powershell]> █
```

This works with relative paths too, so if you find yourself frequently `cd`ing into the
same subdirectories you could create a corresponding variable.

```sh
[~/projects/powershell]> $gh = './.git/hooks'
[~/projects/powershell]> cd gh
[~/projects/powershell/.git/hooks]> █
```

CDABLE_VARS is off by default. Enable it with: `Set-CdExtrasOption CDABLE_VARS`.

## No argument cd

If the option `$cde.NOARG_CD` is defined then `cd` with no arguments will move into the
nominated directory. Defaults to `'~'`.

```sh
[~/projects/powershell]> cd
[~]> Set-CdExtrasOption NOARG_CD /
[~]> cd
[C:]>
```

## Two argument cd

Replaces all instances of the first argument in the current path with the second argument,
changing to the resulting directory if it exists. Uses the `Switch-LocationPart` function.
You can also use the alias `cd:` or the explicit `ReplaceWith` parameter.

```sh
[~\Modules\Unix\Microsoft.PowerShell.Utility]> cd unix shared
[~\Modules\Shared\Microsoft.PowerShell.Utility]> cd: shared unix
[~\Modules\Unix\Microsoft.PowerShell.Utility]> cd unix -ReplaceWith shared
[~\Modules\Shared\Microsoft.PowerShell.Utility]> █
```

## Expansion

### Enhanced expansion for built-ins

`cd`, `pushd` and `ls` (by default) provide enhanced tab completions, expanding all path
segments so that you don't have to individually tab (⇥) through each one.

```sh
[~]> cd /w/s/set⇥⇥
[~]> cd C:\Windows\SysWOW64\setup\█
C:\Windows\System32\setup\  C:\Windows\SysWOW64\setup\
                            ──────────────────────────
```

Periods (`.`) are expanded around so, for example, a segment containing `.sdk`
is expanded into `*.sdk*`.

```sh
[~]> cd proj/pow/s/.sdk⇥
[~]> cd ~\projects\powershell\src\Microsoft.PowerShell.SDK\█
```

You can change the list of commands that participate in enhanced directory completion
using the `DirCompletions` [option](#configure):

```sh
[~]> $cde.DirCompletions += 'mkdir'
[~]> # or Set-CdExtrasOption DirCompletions ($cde.DirCompletions + 'mkdir')
[~]> mkdir ~/pow/src⇥
[~]> mkdir ~\powershell\src\█
```

It's also possible to opt into enhanced file-only or general (file & directory)
completion using the `FileCompletions` and `PathCompletions` options respectively.
Note that the `FileCompletions` option is often less useful than the others as you
won't be able to tab through directories to get to the file you're looking for.

```sh
[~]> $cde.PathCompletions += 'Invoke-Item'
[~]> # or Set-CdExtrasOption PathCompletions ($cde.PathCompletions + 'Invoke-Item')
[~]> ii /t/⇥
[~]> C:\temp\subdir\█
C:\temp\subdir  C:\temp\txtFile.txt  C:\temp\txtFile2.txt
──────────────
```

In each case, expansions work against the target's `Path` parameter.
If you want enhanced completion for a native executable or a cmdlet without
a `Path` parameter then you'll need to provide a wrapper. Either the wrapper
or the target itself should handle expanding `~` where necessary. e.g:

```sh
[~]> function Invoke-VSCode($path) { &code (Resolve-Path $path) }
[~]> $cde.DirCompletions += 'Invoke-VSCode'
[~]> Set-Alias co Invoke-VSCode
[~]> co ~/pr/po⇥
[~]> co ~\projects\powershell\█
```

Paths within the `$cde.CD_PATH` array are included for all completion types.

```sh
[~]> $cde.CD_PATH += '~\Documents\'
[~]> cd win/mod⇥
[~]> ~\Documents\WindowsPowerShell\Modules\█
```

### Navigation helper expansions

Expansions are provided for the `cd+`, `cd-` and `up` (_aka_ `..`) aliases.

When the `MenuCompletion` option is set to `$true` and more than one completion is available,
the completions offered are the indexes of each corresponding directory; the full path is
displayed in the menu below. _cd-extras_ will attempt to detect `PSReadLine` in order to set
this option appropriately at start-up. For example:

```sh
[C:\Windows\System32\drivers\etc]> up ⇥
[C:\Windows\System32\drivers\etc]> up 1
1. drivers  2. System32  3. Windows  4. C:\
──────────
```

It's also possible tab-complete these three commands (`cd+`, `cd-`, `up`) using a
partial directory name (the [`NamePart` parameter](#navigate-by-name)).

```sh
[~\projects\PowerShell\src\Modules\Shared]> up pr⇥
[~\projects\PowerShell\src\Modules\Shared]> up '~\projects'
[~\projects]> █
```

### Multi-dot and variable based expansions

The multi-dot syntax provides tab completion into ancestor directories.

```sh
[C:\projects\powershell\docs\git]> cd ...⇥
[C:\projects\powershell\docs\git]> cd C:\projects\powershell\█
```

```sh
[C:\projects\powershell\docs\git]> cd .../⇥

C:\projects\powershell\.git     C:\projects\powershell\.vscode
───────────────────────────
C:\projects\powershell\demos    C:\projects\powershell\docs

C:\projects\powershell\test     C:\projects\powershell\.github

C:\projects\powershell\assets   C:\projects\powershell\docker

C:\projects\powershell\src      C:\projects\powershell\tools
```

`Export-Up` (`xup`) recursively expands each parent path into a global variable
with a corresponding name. Why? In combination with [CDABLE_VARS](#cdable_vars),
it can be useful for navigating a deeply nested folder structure without needing
to count `..`s. For example:

```sh
[C:\projects\powershell\src\Modules\Unix]> xup

Name                           Value
----                           -----
Unix                           C:\projects\powershell\src\Modules\Unix
Modules                        C:\projects\powershell\src\Modules
src                            C:\projects\powershell\src
powershell                     C:\projects\powershell
projects                       C:\projects

[C:\projects\powershell\src\Modules\Unix]> cd po⇥
[C:\projects\powershell\src\Modules\Unix]> cd C:\projects\powershell\█
```

might be easier than:

```sh
[C:\projects\powershell\src\Modules\Unix]> cd ....⇥ # or cd ../../../⇥
[C:\projects\powershell\src\Modules\Unix]> cd C:\projects\powershell\█
```

You can combine `CDABLE_VARS` with [AUTO_CD](#auto_cd) for great good:

```sh
[C:\projects\powershell\src\Modules\Unix]> projects
[C:\projects]> src
[C:\projects\powershell\src]> █
```

## Path shortening

If an unambiguous match is available then `cd` can be used directly, without first
invoking tab expansion.

```sh
[~]> cd /w/s/d/et
[C:\Windows\System32\drivers\etc]> cd ~/pr/pow/src
[~\projects\PowerShell\src]> cd .sdk
[~\projects\PowerShell\src\Microsoft.PowerShell.SDK]> █
```

`AUTO_CD` works the same way if enabled.

```sh
[~]> /w/s/d/et
[C:\Windows\System32\drivers\etc]> ~/pr/pow/src
[~\projects\PowerShell\src]> .sdk
[~\projects\PowerShell\src\Microsoft.PowerShell.SDK]> █
```

## Additional helpers

- Get-Stack (_dirs_)
  - view contents of undo (`cd-`) and redo (`cd+`) stacks;
    limit output with the `-Undo` or `-Redo` switches
- Get-Up (_gup_)
  - get the path of an ancestor directory, either by name or by traversing upwards `n` levels
- Expand-Path (_xpa_)
  - expand a candidate path by inserting wildcards between each segment
- Set-CdExtrasOption (_setocd_)
  - [configure](#configure) cd-extras

## Note on compatibility

### Alternative providers

_cd-extras_ is primarily intended to work against the filesystem provider. Most things should work
with other providers too though.

```sh
[~]> cd hklm:\
[HKLM:]> cd so/mic/win/cur/windowsupdate
[HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate]> ..
[HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion]> cd-
[HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate]> cd- 2
[~]> █
```

### OS X & Linux

Functionality is tested and should work on non-Windows operating systems. It's entirely
possible you'll encounter some rough edges, though. In particular you'll notice that _cd-extras_
is quite permissive with respect to the casing of paths; this means path shortening won't work
in cases where multiple possible path abbreviations differ only by case.

# Get started

## Install

From the [gallery](https://www.powershellgallery.com/packages/cd-extras/1.3.1)

```
Install-Module cd-extras
Import-Module cd-extras

# add to profile. e.g:
Add-Content $PROFILE @("`n", "Import-Module cd-extras")
```

or from get the latest from github

```
git clone git@github.com:nickcox/cd-extras.git
Import-Module cd-extras\cd-extras\cd-extras.psd1 # for reals
```

## Configure

### _cd-extras_ options

- _AUTO_CD_: `[bool] = $true`
  - Any truthy value enables auto_cd.
- _CD_PATH_: `[array] = @()`
  - Paths to be searched by `cd` and tab expansion. Note: this is an array, not a delimited string.
- _CDABLE_VARS_: `[bool] = $false`
  - `cd` and tab-expand into directory paths stored in variables without prefixing the variable
    name with `$`.
- _NOARG_CD_: `[string] = '~'`
  - If specified, `cd` command with no arguments will change to this directory.
- _MenuCompletion_: `[bool] = $true` (if PSReadLine available)
  - If truthy, indexes are offered as completions for `up`, `cd+` and `cd-` with full paths
    displayed in the menu
- _DirCompletions_: `[array] = @('Push-Location', 'Set-Location', 'Get-ChildItem')`
  - Commands that participate in enhanced tab expansion for directories.
- _FileCompletions_: `[array] = @()`
  - Commands that participate in enhanced tab expansion for files.
- _PathCompletions_: `[array] = @()`
  - Commands that participate in enhanced tab expansion for any type of path (files & directories).

To configure _cd-extras_ create a hashtable, `cde`, with one or more of these keys _before_ importing
it:

```sh
$global:cde = @{
  AUTO_CD = $false
  CD_PATH = @('~\Documents\', '~\Downloads')
}

Import-Module cd-extras
```

or call the `Set-CdExtrasOption` (`setocd`) function after importing the module:

```sh
Import-Module cd-extras

setocd CDABLE_VARS
setocd AUTO_CD $false
setocd NOARG_CD '/'
```

Note: if you want to opt out of the default [`DirCompletions`](#Enhanced-expansion-for-built-ins)
then you should do it before _cd-extras_ is loaded since PowerShell doesn't provide any way of
unregistering argument completers.

### Using a different alias

_cd-extras_ aliases `cd` to its proxy command, `Set-LocationEx`, by default. If you want to use a
different alias then you'll probably want to restore the default `cd` alias at the same time.

```ps
[~]> set-alias cd set-location -Option AllScope
[~]> set-alias cde set-locationex
[~]> cde /w/s/d/et
[C:\Windows\System32\drivers\etc]> cd- # note: still cd-, not cde-
[~]> █
```

`cd-extras` will only remember locations visited via `Set-LocationEx` or its alias.
