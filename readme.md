cd-extras
===

* [What is it?](#what-is-it)
  * [Navigation helpers](#navigation-helpers)
  * [AUTO_CD](#auto_cd)
  * [CD_PATH](#cd_path)
  * [Path expansion](#path_expansion)
  * [No argument cd](#no-argument-cd)
  * [Two argument cd](#two-argument-cd)
  * [Additional helpers](#additional-helpers)
* [Get started](#get-started)
  * [Install](#install)
  * [Configure](#configure)

What is it?
==========
general conveniences for the `cd` command in PowerShell inspired by bash and zsh

Navigation helpers
---------

Provides the following aliases (and functions):

* cd- (Undo-Location)
* cd+ (Redo-Location)
* cd: (Transpose-Location)
* up, .. (Raise-Location)

Examples:

```powershell

C:\Windows\System32> up # or ..
C:\Windows> cd-
C:\Windows\System32> cd+
C:\Windows> _
```

Note that the aliases are `cd-` and `cd+` *not* `cd -` and `cd +`. Repeated uses of `cd-` will keep moving backwards towards the beginning of the stack rather than toggling between the two most recent directories as in vanilla bash.

Each of these functions except `cd:` takes an optional parameter, `n`, used to specify the number of levels
or locations to traverse.

```powershell

C:\Windows\System32> .. 2 # or `up 2`
C:\> cd temp
C:\temp> cd- 2
C:\Windows\System32> cd+ 2
C:\temp> _
```

The `Raise-Location (up, ..)` function also supports passing a string parameter to change to the first ancestor directory which contains the given string.

```powershell

C:\Windows\System32\drivers\etc> up win # or `.. win`
C:\Windows> _
```

When the [AUTO_CD](#auto_cd) option is enabled, multiple dot syntax for `up` is supported as an alternative to `up [n]` or `.. [n]`.

```powershell

C:\Windows\System32\drivers\etc> ... # same as `up 2` or `.. 2`
C:\Windows\System32> cd-
C:\Windows\System32\drivers\etc> .... # same as `up 3` or `.. 3`
C:\Windows> _
```

AUTO_CD
-------

Change directory without typing `cd`.

```powershell

~> projects
~/projects> cd-extras
~/projects/cd-extras> ..
~/projects> _
```

CD_PATH
--------

Search additional locations for candidate directories.

```powershell

~> $cde.CD_PATH += '~/documents'
~> cd WindowsPowerShell
~/documents/WindowsPowerShell> _
```

Note that CD_PATHs are _not_ searched when an absolute or relative path is given.

```powershell

~> $cde.CD_PATH += '~/documents'
~> cd ./WindowsPowerShell
Set-Location : Cannot find path '~\WindowsPowerShell' because it does not exist.
```

Path expansion
-----------

`cd` will provide tab expansions by expanding all path segments rather than having to individually tab through each one.

```powershell

~> cd /w/s/set[Tab][Tab]
C:\Windows\System32\setup\  C:\Windows\SysWOW64\setup\
                            ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
```

Periods (`.`) are expanded around so a segment containing `.sdk` is expanded into `*.sdk*`.

```powershell

~> cd proj/pow/s/.sdk[Tab]
~\projects\powershell\src\Microsoft.PowerShell.SDK\
```

If an unambiguous match is available then `cd` can be used directly, without invoking tab expansion.

```powershell

~> cd /w/s/d/et[Return]
C:\Windows\System32\drivers\etc > _
```

Paths within the `$cde.CD_PATH` array will be considered for expansion.

```powershell

~> $cde.CD_PATH += "~\Documents\"
~> cd win/mod
~\Documents\WindowsPowerShell\Modules > _
```

No argument cd
----------

If the option `$cde.NOARG_CD` is defined then `cd` with no arguments will change to the nominated directory. Defaults to `'~'`.

```powershell

C:\Windows\System32\> cd
~> _
```

Two argument cd
----------

Replaces all instances of the first argument in the current path with the second argument,
changing to the resulting directory if it exists. Uses the `Transpose-Location` (`cd:`) function.

```powershell

~\Modules\Unix\Microsoft.PowerShell.Utility> cd unix shared
~\Modules\Shared\Microsoft.PowerShell.Utility>_
```

Additional helpers
---------

* Peek-Stack: view contents of undo (`cd-`) and redo (`cd+`) stacks
* Expand-Path: helper used for path segment expansion
* Set-CdExtrasOption: enable or disable `AUTO_CD` after the module has loaded

Get started
=======

Install
-------

```powershell

Install-Module cd-extras
Add-Content $PROFILE @("`n", "import-module cd-extras -DisableNameChecking")
Import-Module cd-extras -DisableNameChecking
```

Note: if you import the module without using the `-DisableNameChecking` switch, you'll see a warning about
the use of 'unapproved' verbs.

Configure
--------

Three options are currently provided:

* AUTO_CD: `[bool] = $true`. Any truthy value to enable auto_cd.
* CD_PATH: `[array] = @()`. Array of paths to be searched by cd and tab expansion.
* NOARG_CD: `[string] = '~'`. If specified, `cd` command with no arguments will change to this directory.

Either create a global hashtable, `cde`, with one or more of these keys _before_ importing the cd-extras module:

```powershell

$global:cde = @{
  AUTO_CD = $false
  CD_PATH = @('C:\Users\Nick\Documents\')
  NOARG_CD = 'C:\'
}
Import-Module cd-extras -DisableNameChecking
```

or call the `Set-CdExtrasOption` function after importing the module:

```powershell
Import-Module cd-extras -DisableNameChecking
Set-CdExtrasOption -Option AUTO_CD -Value $false
Set-CdExtrasOption -Option NOARG_CD -Value '~'
```