# `cd` guide

**Shortcuts and tab completions for the `cd` command**

<details>
<summary>[<i>Watch</i>]<p/></summary>

![cd enhancements](../assets/cd-enhancements.svg)

</details>

<!-- TOC -->

- [Path shortening](#path-shortening)
- [Multi-dot cd](#multi-dot-cd)
- [No argument cd](#no-argument-cd)
- [Two argument cd](#two-argument-cd)
- [AUTO_CD](#auto_cd)
  - [Tilde](#tilde)
  - [Multi-dot](#multi-dot)
- [CD_PATH](#cd_path)
- [CDABLE_VARS](#cdable_vars)

<!-- /TOC -->

`cd-extras` provides a proxy to `Set-Location` - called `Set-LocationEx` - and aliases it to `cd`
by default, giving it several new abilities:

* [Path shortening](#path-shortening)
* [Multi-dot `cd`](#multi-dot-cd)
* [No argument `cd`](#no-argument-cd)
* [Two argument `cd`](#two-argument-cd)
* [Enhanced tab completions](completion.md)


## Path shortening

If an unambiguous match is available then `cd` can change directory using an abbreviated path.
This effectively changes a path given as, `p` into `p*` or `~/pr/pow/src` into `~/pr*/pow*/src*`.
If you're not sure whether an unambiguous match is available then just hit tab to pick from a
[list of potential matches](completion.md) instead.

```powershell
[~]> cd pr
[~/projects]> cd cd-e
[~/projects/cd-extras]> cd ~
[~]> cd pr/cd
[~/projects/cd-extras]> _
```

Word delimiters (`.`, `_`, `-` by [default](configuration.md)) are expanded around so a segment
containing `.sdk` is expanded into `*.sdk*`.

```powershell
[~]> cd proj/pow/s/.sdk
[~/projects/powershell/src/Microsoft.PowerShell.SDK]> _
```

> **Note:**
> Powershell interprets a hyphen at the start of an argument as a parameter name. So while you can do
> this...
>
> ```powershell
> [~/projects/powershell]> cd src/-unix
> [~/projects/PowerShell/src/powershell-unix]> _
> ```
>
> ... you need to escape this:
>
> ```powershell
> [~/projects/powershell/src]> cd -unix
> Set-LocationEx: A parameter cannot be found that matches parameter name 'unix'.
>
> [~/projects/powershell/src]> cd `-unix # backtick escapes the hyphen
> [~/projects/PowerShell/src/powershell-unix]> _
> ```

Pairs of periods are expanded between so, for example, a segment containing `s..32` is expanded
into `s*32`.

```powershell
[~]> cd /w/s..32/d/et
[C:/Windows/System32/drivers/etc]> _
```

Directories in [`CD_PATH`](#cd_path) will be also be shortened.

```powershell
[C:/]> setocd CD_PATH ~/projects
[C:/]> cd p..shell
[~/projects/PowerShell/]> _
```

[`AUTO_CD`](#auto_cd) uses the same expansion algorithm when enabled.

```powershell
[~]> $cde.AUTO_CD
True

[~]> /w/s/d/et
[C:/Windows/System32/drivers/etc]> ~/pr/pow/src
[~/projects/PowerShell/src]> .sdk
[~/projects/PowerShell/src/Microsoft.PowerShell.SDK]> _
```


## Multi-dot cd

In the same way that you can navigate up one level with `cd ..`, `Set-LocationEx` supports
navigating multiple levels by adding additional dots. [`AUTO_CD`](#multi-dot) works the same way
if enabled.

```powershell
[C:/Windows/System32/drivers/etc]> cd ... # same as `up 2` or `.. 2`
[C:/Windows/System32]> cd-
[C:/Windows/System32/drivers/etc>] cd .... # same as `up 3` or `.. 3`
[C:/Windows]> _
```


## No argument cd

If the _`NOARG_CD`_ [option](configuration.md) is defined then `cd` without arguments navigates into that
directory (`~` by default). This overrides the out of the box behaviour of PowerShell >=6.0, where
no-arg `cd` _always_ navigates to `~` and of PowerShell < 6.0, where no-argument `cd` does nothing
at all.

```powershell
[~/projects/powershell]> cd
[~]> setocd NOARG_CD /
[~]> cd
[C:/]>
```


## Two argument cd

Replaces all instances of the first argument in the current path with the second argument,
changing to the resulting directory if it exists, using the `Switch-LocationPart` function.

You can also use the alias `cd:` or the explicit `ReplaceWith` parameter of `Set-LocationEx`.

```powershell
[~/Modules/Unix/Microsoft.PowerShell.Utility]> cd unix shared
[~/Modules/Shared/Microsoft.PowerShell.Utility]> cd: -Replace shared -With unix
[~/Modules/Unix/Microsoft.PowerShell.Utility]> cd unix -ReplaceWith shared
[~/Modules/Shared/Microsoft.PowerShell.Utility]> _
```


## AUTO_CD

**Change directory without typing `cd`**

<details>
<summary>[<i>Watch</i>]<p/></summary>

![AUTO_CD](../assets/auto-cd.svg)

</details>

```powershell
[~]> projects
[~/projects]> cd-extras
[~/projects/cd-extras]> /
[C:/]> _
```

As with the [enhanced `cd`](#path-shortening) command, [abbreviated paths](#path-shortening)
and [multi-dot syntax](#multi-dot-cd) are supported.

```powershell
[~]> pr
[~/projects]> cd-e
[~/projects/cd-extras]> cd
[~]> pr/cd
[~/projects/cd-extras]> _
```


### Tilde

`AUTO_CD` supports a shorthand syntax for `cd-` using tilde (`~`). You can use this with or
without a space between tilde and the number, although [tab completion](navigation.md#completions) only works
after a space (`~ <tab>`).

```powershell
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
[C:/temp]> _
```


### Multi-dot

[Multi-dot syntax](#multi-dot-cd) works with `AUTO_CD` as an alternative to `up [n]`.

```powershell
[C:/Windows/System32/drivers/etc]> ... # same as `up 2` or `.. 2`
[C:/Windows/System32]> cd-
[C:/Windows/System32/drivers/etc>] .... # same as `up 3` or `.. 3`
[C:/Windows]>  _
```


## CD_PATH

**Additional base directories for the `cd` command**

```powershell
[~]> setocd CD_PATH ~/documents
[~]> # or $cde.CD_PATH = ,'~/documents'
[~]> cd WindowsPowerShell
[~/documents/WindowsPowerShell]> _
```

[Tab-completion](completion.md), [path shortening](#path-shortening) and
[Expand-Path](navigation.md#expand-path-xpa) work with `CD_PATH` directories.

`CD_PATH`s are _not_ searched when an absolute or relative path is given.

```powershell
[~]> setocd CD_PATH ~/documents
[~]> cd ./WindowsPowerShell
Set-Location : Cannot find path '~\WindowsPowerShell'...
```

> **Note:**
> Unlike bash, the current directory is always included when a relative path is used. If a child
> with the same name exists in both the current directory and a `CD_PATH` directory then `cd` will
> prefer the former.

```powershell
[~]> md -f child, someDir/child
[~]> resolve-path someDir | setocd CD_PATH
[~]> cd child
[~/child]> cd child
[~/someDir/child]> _
```

> **Note:**
> The value of `CD_PATH` is an array, not a delimited string as it is in bash.
> ```powershell
> [~]> setocd CD_PATH ~/Documents/, ~/Downloads
> [~]> $cde.CD_PATH
> ~/Documents
> ~/Downloads
> ```


## CDABLE_VARS

**`cd` into variables without the `$` and enable tab completion into child directories**

Given a variable containing a folder path (configured in your `$PROFILE`, perhaps, or by invoking
[`Get-Ancestors -Export`](completion.md#variable-based-completions)), you can `cd` into it using the variable
name.

> **Note:**
> CDABLE_VARS is off by default; enable it with, [`setocd CDABLE_VARS`](configuration.md).

```powershell
[~/projects/powershell]> setocd CDABLE_VARS
[~/projects/powershell]> $bk1 = $pwd
[~/projects/powershell]> cd
[~]> cd bk1
[~/projects/powershell]> _
```

It works with relative paths too, so if you find yourself frequently `cd`ing into the same
subdirectories you could create a corresponding variable.

```powershell
[~/projects/powershell]> $gh = './.git/hooks'
[~/projects/powershell]> cd gh
[~/projects/powershell/.git/hooks]> _
```

You can combine it with [AUTO_CD](#auto_cd) for great good:

```powershell
[C:/projects/powershell/src/Modules/Unix]> xup -Export | out-null
[C:/projects/powershell/src/Modules/Unix]> projects
[C:/projects]> src
[C:/projects/powershell/src]> _
```
