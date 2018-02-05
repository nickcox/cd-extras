general conveniences for the `cd` command inspired by bash and zsh

What is it?
==========

AUTO_CD
-------

Change directory without typing `cd`. Example:

```
~> projects
~/projects> cd-extras
~/projects/cd-extras> ..
~/projects> _
```

CD_PATH
--------
Additional paths to be searched for candidate directories. Example:
```
~> $cde.CD_PATH += '~/documents'
~> cd WindowsPowerShell
~/documents/WindowsPowerShell> _
```
Note that CD_PATHs are _not_ searched when an absolute or relative path is given. Example:
```
~> $cde.CD_PATH += '~/documents'
~> cd ./WindowsPowerShell
Set-Location : Cannot find path '~\WindowsPowerShell' because it does not exist.
```


Path expansion
-----------
`cd` will provide tab expansions by expanding all path segments rather than having to individually tab through each one. Example:
```
~> cd /w/s/set[Tab]
C:\Windows\System32\setup  C:\Windows\SysWOW64\setup
```

If only a single path is matched then `cd` can be used directly, without invoking tab expansion. Example:
```
~> cd /w/s/d/et
C:\Windows\System32\drivers\etc > _
```

Paths within the `$cde.CD_PATH` array will be considered for expansion. Example:
```
~> $cde.CD_PATH += "~\Documents\"
~> cd win/mod
~\Documents\WindowsPowerShell\Modules > _
```


Two argument cd
----------
Attempt to replace all instances of the first argument in the current path with the second argument, changing to the resulting directory if it exists. Uses `Transpose-Location` function.

Example:
```
~\Modules\Unix\Microsoft.PowerShell.Utility> cd unix shared
~\Modules\Shared\Microsoft.PowerShell.Utility>_
```


Navigation helpers
---------

Provides the following aliases (and functions):

* cd- (Undo-Location)
* cd+ (Redo-Location)
* cd: (Transpose-Location)
* up, .. (Raise-Location)

Example:
```
C:\Windows\System32> # Move backward using cd-, then forward using cd+
C:\Windows\System32> up
C:\Windows> cd-
C:\Windows\System32> cd+
C:\Windows>_
```

Note that the aliases are `cd-` and `cd+` *not* `cd -` and `cd +`.

Each of these functions except `cd:` takes an optional parameter, `n`, used to specify the number of levels or locations to traverse. Example:
```
C:\Windows\System32> .. 2
C:\> cd temp
C:\temp\> cd- 2
C:\Windows\System32> cd+ 2
C:\temp\> _
```


Additional helpers
---------

* Peek-Stack: view contents of undo (`cd-`) and redo (`cd+`) stacks
* Expand-Path: helper used for path segment expansion
* Set-CdExtrasOption: enable or disable `AUTO_CD` after the module has loaded


Get started
======

Install
-------
```
Install-Module cd-extras
Add-Content $PROFILE @("`n", "import-module cd-extras -DisableNameChecking")
Import-Module cd-extras -DisableNameChecking
```

Configure
--------
Two options are currently provided:

* AUTO_CD: [bool] default = $true
* CD_PATH: [array] default = @()

Either create a global hashtable, `cde`, with one or more of these keys _before_ importing the cd-extras module:
```
$global:cde = @{
  AUTO_CD = $false
  CD_PATH = @('C:\Users\Nick\Documents\')
}
Import-Module cd-extras -DisableNameChecking
```
or call the `Set-CdExtrasOption` function after importing the module:
```
Import-Module cd-extras -DisableNameChecking
Set-CdExtrasOption -Option AUTO_CD -Value $false
```