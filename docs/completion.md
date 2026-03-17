# Completion guide

**Enhanced completion for `cd` and other commands**

`cd-extras` provides enhanced completion for `cd`, `pushd`, `ls`, `Get-Item` and `Invoke-Item`
by default, expanding all path segments in one go so that you don't have to individually tab
through each one. The path shortening logic is provided by `Expand-Path` and works as
[described in the `cd` guide](cd.md#path-shortening).

<!-- TOC -->

- [How it works](#how-it-works)
- [Single and double periods](#single-and-double-periods)
- [Multi-dot completions](#multi-dot-completions)
- [Variable based completions](#variable-based-completions)
- [Extending completion to other commands](#extending-completion-to-other-commands)
- [Colourised completions](#colourised-completions)

<!-- /TOC -->


## How it works

```powershell
[~]> cd /w/s/dr<tab><tab>
[~]> cd C:\Windows\System32\DriverState\

drivers   DriverState   DriverStore
          -----------

C:\Windows\System32\DriverState
```

Paths within [`$cde.CD_PATH`](cd.md#cd_path) are included in the completion results.

```powershell
[~]> $cde.CD_PATH += '~\Documents\'
[~]> cd win/mod<tab>
[~]> ~\Documents\WindowsPowerShell\Modules\_
```

> **Note:**
> The total number of completions offered is limited by the `MaxCompletions` [option](configuration.md)
> or calculated dynamically to fit the screen if `MaxCompletions` is falsy. Although the completions
> are sorted by type (folders first) and then by name for ease of reading, that sort is applied
> _after_ the limit has been applied to the original results. Those original results are sorted
> breadth first in order to keep the completion as responsive as possible.

> **Note:**
> If the number of available completions is greater than `MaxCompletions`, causing the list to be
> truncated, then that is noted in the completion tooltip by default.


## Single and double periods

Word delimiters (`.`, `_`, `-` [by default](configuration.md)) are expanded around so, for example, a
segment containing `.sdk` is expanded into `*.sdk*`.

```powershell
[~]> cd proj/pow/s/.sdk<tab>
[~]> cd ~\projects\powershell\src\Microsoft.PowerShell.SDK\_
```

or

```powershell
[~]> ls pr/pow/t/ins.sh<tab>
[~]> ls ~\projects\powershell\tools\install-powershell.sh
[~]> ls ~\projects\powershell\tools\install-powershell.sh | cat
#!/bin/bash
...

[~]>
```

A double-dot (`..`) token is expanded inside, so `s..32` becomes `s*32`.

```powershell
[~]> ls /w/s..32<tab>
[~]> ls C:\Windows\System32\_
```


## Multi-dot completions

The [multi-dot syntax](cd.md#multi-dot-cd) provides tab completion into ancestor directories.

```powershell
[~/projects/powershell/docs/git]> cd ...<tab>
[~/projects/powershell/docs/git]> cd ~\projects\powershell\_
```

```powershell
[C:/projects/powershell/docs/git]> cd .../<tab>

.git     .vscode    demos    docs   test
-----
.github    assets   docker   src    tools

~\projects\powershell\.git
```


## Variable based completions

When [CDABLE_VARS](cd.md#cdable_vars) is enabled, completions are available for the names of variables
that contain file paths. This can be combined with the `-Export` option of `Get-Ancestors` (`xup`),
which recursively exports each parent directory's path into a global variable with a corresponding
name.

```powershell
[C:/projects/powershell/src/Modules/Unix]> xup -Export -ExcludeRoot

n Name        Path
- ----        ----
1 Modules     C:\projects\powershell\src\Modules
2 src         C:\projects\powershell\src
3 powershell  C:\projects\powershell
4 projects    C:\projects

[C:/projects/powershell/src/Modules/Unix]> up pow
[C:/projects/powershell]> cd mod<tab>
[C:/projects/powershell]> cd .\src\modules\
```


## Extending completion to other commands

You can extend the list of commands that participate in enhanced completion for either
*directories* or *files*, or for both *files and directories*, using the `DirCompletions`
`FileCompletions` and `PathCompletions` [options](configuration.md) respectively.

(`FileCompletions` is the least useful of the three since you can't tab through intermediate
directories to get to the file you're looking for.)

```powershell
[~]> setocd DirCompletions md
[~]> md ~/pow/src<tab>
[~]> md ~\powershell\src\_
[~]> setocd PathCompletions Copy-Item
[~]> cp /t/<tab>
[~]> cp C:\temp\subdir\_
subdir  txtFile.txt  txtFile2.txt
------

C:\temp\subdir
```

In each case, completions work against the target's `Path` parameter; if you want enhanced
completion for a native executable or for a cmdlet without a `Path` parameter then you'll
need to provide a wrapper. Either the wrapper or the target itself should handle expanding
`~` where necessary.

```powershell
[~]> function Invoke-VSCode($path) { &code (rvpa $path) }
[~]> setocd PathCompletions Invoke-VSCode
[~]> Set-Alias co Invoke-VSCode
[~]> co ~/pr/po<tab>
[~]> co ~\projects\powershell\_
```

An alternative to registering a bunch of aliases is to create a tiny wrapper to pipe input
from `ls`, `gi` or `xpa`.

```powershell
[~]> function to($target) { &$target $input }
[~]> xpa ~/pr/po/r.md<tab>
[~]> xpa ~/projects/powershell/readme.md | to bat

-----------------------------------------------------------
File: C:\Users\Nick\projects\PowerShell\README.md
-----------------------------------------------------------
1 | ...
2 | ...
```

> **Note:**
> You can skip tab completion altogether and use [Expand-Path](navigation.md#expand-path-xpa) directly if you
> know exactly what you're looking for.

```powershell
[~]> xpa ~/pr/po/r.md | to bat

-----------------------------------------------------------
File: C:\Users\Nick\projects\PowerShell\README.md
-----------------------------------------------------------
1 | ...
2 | ...
```


## Colourised completions

The _`ColorCompletion`_ [option](configuration.md) enables colourisation of completions in the filesystem
provider via [_DirColors_][1] or via your own global `Format-ColorizedFilename` function of type
`[System.IO.FileSystemInfo] -> [String]`.

> **Note:**
> _ColorCompletion_ is off by default. Enable it with `setocd ColorCompletion`.


[1]: https://github.com/DHowett/DirColors
