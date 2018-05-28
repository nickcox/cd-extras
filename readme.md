cd-extras
===

* [What is it?](#what-is-it)
  * [Navigation helpers](#navigation-helpers)
  * [AUTO_CD](#auto_cd)
  * [CD_PATH](#cd_path)
  * [CDABLE_VARS](#cdable_vars)
  * [Tab expansion](#tab-expansion)
  * [No argument cd](#no-argument-cd)
  * [Two argument cd](#two-argument-cd)
  * [Additional helpers](#additional-helpers)

* [Get started](#get-started)
  * [Install](#install)
  * [Configure](#configure)

What is it?
==========
general conveniences for the `cd` command in PowerShell inspired by bash and zsh

![Basic Navigation](./basic-navigation.gif)

Navigation helpers
---------

Provides the following aliases (and corresponding functions):

* `up`, `..` (`Step-Up`)
* `cd-` (`Undo-Location`)
* `cd+` (`Redo-Location`)
* `cd:` (`Switch-LocationPart`)
* `cdb` (`Step-Back`)

Examples:

```sh

[C:\Windows\System32]> up # or ..
[C:\Windows]> cd-
[C:\Windows\System32]> cd+
[C:\Windows]> _
```

Note that the aliases are `cd-` and `cd+` *not* `cd -` and `cd +`.
Repeated uses of `cd-` will keep moving backwards towards the beginning of the stack
rather than toggling between the two most recent directories as in vanilla bash. (You can
use `Step-Back` (`cdb`) to toggle between the current and previous directories.)

`up`, `cd+` and `cd-` each take a single optional parameter: either a number, `n`,
used to specify the number of levels or locations to traverse...

```sh

[C:\Windows\System32]> .. 2 # or `up 2`
[C:\]> cd temp
[C:\temp]> cd- 2
[C:\Windows\System32]> cd+ 2
[C:\temp]> _
```

...or a string, `NamePart`, used to change to the nearest directory whose name matches
the given argument.

```sh

[C:\Windows\System32\drivers\etc]> up win # or `.. win`
[C:\Windows]> _
```

The logic of `cd- <NamePart>` and `cd+ <NamePart>` is to search the stack, starting at
the current location, for directories whose name contains the given string. If none is found
then it will attempt to match against the full path instead. For example:

```sh
[C:\Windows]> cd system32
[C:\Windows\System32]> cd drivers
[C:\Windows\System32\drivers]> cd- sys
[C:\Windows\System32]> cd+
[C:\Windows\System32\drivers]> cd- win
[C:\Windows\]> cd+ 32/dr
[C:\Windows\System32\drivers]> _
```

When the [AUTO_CD](#auto_cd) option is enabled, multiple dot syntax for `up` is supported
as an alternative to `up [n]` or `.. [n]`.

```sh

[C:\Windows\System32\drivers\etc]> ... # same as `up 2` or `.. 2`
[C:\Windows\System32]> cd-
[C:\Windows\System32\drivers\etc>] .... # same as `up 3` or `.. 3`
[C:\Windows]> _
```

The multi-dot syntax also provides tab completion into ancestor directories.

```sh

[C:\projects\powershell\docs\git]> cd .../<[Tab]>

C:\projects\powershell\.git     C:\projects\powershell\.vscode
‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
C:\projects\powershell\demos    C:\projects\powershell\docs

C:\projects\powershell\test     C:\projects\powershell\.github

C:\projects\powershell\assets   C:\projects\powershell\docker

C:\projects\powershell\src      C:\projects\powershell\tools
```

The `Export-Up` (`xup`) function recursively expands each parent path into a global variable
with a corresponding name. Why? In combination with [CDABLE_VARS](#cdable_vars),
it can be useful for navigating a deeply nested folder structure without needing to count
`..`s. For example:

```sh

[~\projects\powershell\src\Modules\Unix]> xup

Name                           Value
----                           -----
Unix                           ~\projects\powershell\src\Modules\Unix
Modules                        ~\projects\powershell\src\Modules
src                            ~\projects\powershell\src
powershell                     ~\projects\powershell
projects                       ~\projects

[~\projects\powershell\src\Modules\Unix]> cd po<[Tab]>
[~\projects\powershell\src\Modules\Unix]> cd ~\projects\powershell\<[Tab]>

.git     .github  .vscode  assets   demos    docker   docs     src      test     tools
‾‾‾‾‾‾‾‾
```

might be easier than:

```sh

[C:\projects\powershell\src\Modules\Unix]> cd ....<[Tab]> # or cd ../../../<[Tab]>
[C:\projects\powershell\src\Modules\Unix]> cd C:\projects\powershell\
.git     .github  .vscode  assets   demos    docker   docs     src      test     tools
‾‾‾‾‾‾‾‾
```

AUTO_CD
-------

Change directory without typing `cd`.

```sh

[~]> projects
[~/projects]> cd-extras
[~/projects/cd-extras]> ..
[~/projects]> _
```

CD_PATH
--------

Search additional locations for candidate directories.

```sh

[~]> $cde.CD_PATH = @('~/documents')
[~]> cd WindowsPowerShell
[~/documents/WindowsPowerShell]> _
```

Note that CD_PATHs are _not_ searched when an absolute or relative path is given.

```sh

[~]> $cde.CD_PATH = @('~/documents')
[~]> cd ./WindowsPowerShell
Set-Location : Cannot find path '~\WindowsPowerShell' because it does not exist.
```

CDABLE_VARS
-----------

Save yourself a `$` when cding into folders using a variable name.
Given a variable containing the path to a folder (configured, perhaps, in your `$PROFILE`
or by invoking `Export-Up`), you can cd into it using the name of the variable.

```sh
[~]> $power = '~/projects/powershell'
[~]> cd power
[~/projects/powershell]> _

```

This also works with relative paths so if you find yourself frequently `cd`ing into the same
subdirectories you could create a corresponding variable.

```sh
[~/projects/powershell]> $gh = './.git/hooks'
[~/projects/powershell]> cd gh
[~/projects/powershell/.git/hooks]> _

```

CDABLE_VARS is off by default. Enable it with: `Set-CdExtrasOption CDABLE_VARS $true`.

Tab expansion
-----------

`cd` and `ls` will provide tab expansions by expanding all path segments so that
you don't have to individually tab through each one.

```sh

[~]> cd /w/s/set<[Tab]><[Tab]>
C:\Windows\System32\setup\  C:\Windows\SysWOW64\setup\
                            ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
```

Periods (`.`) are expanded around so a segment containing `.sdk` is expanded into `*.sdk*`.

```sh

[~]> cd proj/pow/s/.sdk<[Tab]>
[~]> cd .\projects\powershell\src\Microsoft.PowerShell.SDK\
[~\projects\powershell\src\Microsoft.PowerShell.SDK]> cd..
[~\projects\powershell\src]> cd .SDK
[~\projects\powershell\src\Microsoft.PowerShell.SDK]> _

```

If an unambiguous match is available then `cd` can be used directly, without first invoking tab expansion.

```sh

[~]> cd /w/s/d/et<[Return]>
[C:\Windows\System32\drivers\etc]> _
```

Paths within the `$cde.CD_PATH` array will be considered for expansion.

```sh

[~]> $cde.CD_PATH += "~\Documents\"
[~]> cd win/mod
[~\Documents\WindowsPowerShell\Modules]> _
```

Expansions are also provided for `cd+`, `cd-` and `up` aliases. If the `MenuCompletion` option
is set to `$true` then the completions offered will be index of the corresponding directory;
the full path is displayed in the menu below. `cd-extras` will attempt to detect `PSReadLine`
at start-up in order to set this option appropriately. For example:

```sh

[C:\Windows\System32\drivers\etc]> up <[Tab]>
1. drivers  2. System32  3. Windows
‾‾‾‾‾‾‾‾‾‾‾

[C:\Windows\System32\drivers\etc]> up 3<[Return]>
[C:\Windows]> _
```

It's also possible to tab through these three aliases using a partial directory name.

```sh
[~\projects\PowerShell\src\Modules\Shared]> up pr<[Tab]>
[~\projects\PowerShell\src\Modules\Shared]> up '~\projects'<[Return]>
[~\projects]> _
```

No argument cd
----------

If the option `$cde.NOARG_CD` is defined then `cd` with no arguments
will change to the nominated directory. Defaults to `'~'`.

```sh

[C:\Windows\System32\]> cd
[~]> _
```

Two argument cd
----------

Replaces all instances of the first argument in the current path with the second argument,
changing to the resulting directory if it exists. Uses the `Switch-LocationPart` (`cd:`) function.

```sh

[~\Modules\Unix\Microsoft.PowerShell.Utility]> cd unix shared
[~\Modules\Shared\Microsoft.PowerShell.Utility]> _
```

Additional helpers
---------

* Get-Stack
  * view contents of undo (`cd-`) and redo (`cd+`) stacks;
  limit output with the `-Undo` or `-Redo` switches
* Get-Up
  * get the path of an ancestor directory,
  either by name or by traversing upwards n levels
* Expand-Path
  * helper used for path segment expansion
* Set-CdExtrasOption
  * [configure](#configure) cd-extras

Get started
=======

Install
-------

```sh

Install-Module cd-extras
Import-Module cd-extras

# add to profile by hand or:
Add-Content $PROFILE @("`n", "Import-Module cd-extras")
```

Configure
---------

Options provided:

* _AUTO_CD_: `[bool] = $true`
  * Any truthy value will enable auto_cd.
* _CD_PATH_: `[array] = @()`
  * Paths to be searched by cd and tab expansion. This is an array, not a delimited string.
* _CDABLE_VARS_: `[bool] = $false`
  * cd into directory paths stored in variables without prefixing the variable name with `$`.
* _NOARG_CD_: `[string] = '~'`
  * If specified, `cd` command with no arguments will change to this directory.
* _MenuCompletion_: `[bool] = $true` (if PSReadLine available)
  * If truthy, indexes are offered as completions for `up`, `cd+` and `cd-` with full paths
  displayed in the menu
* _Completable_: `[array] = @('Push-Location', 'Set-Location', 'Get-ChildItem')`
  * Commands that participate in advanced tab expansion.

Either create a global hashtable, `cde`, with one or more of these keys _before_ importing the cd-extras module:

```sh

$global:cde = @{
  AUTO_CD = $false
  CD_PATH = @('~\Documents\', '~\Downloads')
}

Import-Module cd-extras
```

or call the `Set-CdExtrasOption` function after importing the module:

```sh

Import-Module cd-extras

Set-CdExtrasOption -Option AUTO_CD -Value $false
Set-CdExtrasOption -Option NOARG_CD -Value '/'
```