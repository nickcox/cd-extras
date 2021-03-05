# Changes

## [2.9.3]
- Fix regression where `Step-Up` failed to change to root directory on Windows, thanks @thorstenkampe

## [2.9.2]
- Fix regression where `cd-extras` not starting on PowerShell v5, thanks @jetersen!
- Fix a bug where truncated menu completion entries not emitting unicode ellipsis character

## [2.9.1]
- Fix bug where multi-dotting stopped working with `AUTO_CD`, thanks @jamesmcgill
- Improve output of `Get-Ancestors` in registry provider

## [2.9.0]
- Enable auto-calculation of `$cde.MaxCompletions` when the option is set to `0` (or `$false`)
- Deduplicate menu completion entries by adding an index to the second and subsequent occurrences of each leaf item
- Add an option, `ToolTipExtraInfo` to augment the menu completion tooltip for path completion
- Sort path completions by type (directories first), then by name
- Default parameter set for `Get-Stack` now outputs `IndexedPath` entries for undo and redo stacks
- Fixed a bug where final character in double-dot expansion operator was ignored

## [2.8.0]
- Emit a warning beep if list of path completions has been truncated
- Don't invoke auto_cd unless at least one alphanumeric is given
- Always use `-Force` for path completion
- Fix issue where unable to complete into directories with surrounding quotes
- Fix issue where `Undo-Location` and `Redo-Location` throw error when intermediate directories have been deleted

## [2.7.0]
- Implement customisable word delimiters
- Fix inconsistent formatting when truncating coloured menu items
- Reduce default `MaxMenuLength`

## [2.6.0]
- Enable pipelining for `Expand-Path` and `Get-Up`
- Rename `MenuCompletion` option to `IndexedCompletion`

## [2.5.0]
- Enable piping into `setocd`, `Undo-Location` and `Redo-Location`
- Disable AUTO_CD when run as part of pipeline
- Make `NamePart` parameter mandatory when using `named` parameter set
- Ensure string paths, not `PathInfo` objects pushed onto stack
- Ensure tooltip displayed for root paths

## [2.4.0]
- Implement `PassThru` switch for navigation helpers
- Navigate forward, backward or upward by leaf name shouldn't be case sensitive

## [2.3.0]
- Make `$cde` an instance of `CdeOptions` class for appropriately constrained properties
- Fix issue with completion of `setocd` option parameter when partial value given

## [2.2.0]
- `Get-Ancestors` and `Get-Stack` now return a first class `IndexedPath` rather than an equivalent `PSCustomObject`
- New default `PathCompletions`: `Get-Item`, `Invoke-Item`, `Expand-Path`
- Fix issue navigating up into root directory in `WSMan` provider

## [2.1.0]
- Set-LocationEx will automatically `LiteralPath` in favour of `Path` if necessary
- Main parameter of `Expand-Path` renamed to `Path`, with `Candidate` retained as an alias
- `Expand-Path` handles square brackets as permissively as possible
- Path completion should always use the `Force` switch on *nix

## [2.0.0]
- Rename `Export-Up` to `Get-Ancestors`
- Swap `Include-Root` for `Exclude-Root` in `Export-Ancestors`
- Change output of `Get-Stack -Undo` and `Get-Stack -Redo`
- Add tilde syntax support to `Set-Location-Ex`
- Add tilde redo support to `AUTO_CD`
- Add `~~` as an alias of `Redo-Location`
- Don't fall back to default completions when no completions are available
- Path completion should respect `-Force` parameter if available on command being completed

## [1.12] 2019-10-07
- `~` as an alias for `Undo-Location`
- Fix regression where multiple `CD_PATHS` breaks

## [1.11] 2019-06-07
- Add support for `~n` as an alternative to `cd- n`
- Add support for `dirs -l`, `dirs -v`.
- Remove invalid `ALIASES` keyword in help comments.

## [1.10] 2019-06-06
- Support zsh style `cd -n` and `cd +n`.
- Add `dirsc` alias.
- Fix niggle with `Step-Up` through a directory with square brackets.

## [1.9] 2019-06-05
- Truncate completion menu items to 40 characters by default.
- Pass through `-File` and `Directory` switches to path completion where necessary.

## [1.8] 2019-06-04
- Stack now contains path strings rather than PathInfo objects.
- Fix bug where literal paths containing square brackets not pushed and popped correctly.
- Paths completions always use `-Force`.

## [1.7] 2019-04-27
- Support `cd +` and `cd -` as in PS 6.2
- Rename Step-Back to Step-Between
- Fix issue where `cd` not accepting piped input

## [1.6] 2019-03-31

- Implement double dot token in path expansions.
- Implement optional colourisation of path completions.
- Implement pass-through of -Force switch in path expansions.
- Fix issue where square brackets could break `up`.
- Fix issue where `cd` with -LiteralPath was broken.
- Fix issue where path shortening not working correctly with registry provider.

## [1.5.5] 2019-03-27

- Fix issue Step-Forward and Step-Between not working with menu completion turned off.
- Make setocd parameter mandatory.

## [1.5.4] 2019-03-27

- Fix issue where multi-dotting didn't work when CD_PATH had been set.

## [1.5.3] 2019-03-25

- Fix issue on Linux where attempting to move upwards past the root threw an error.
- Fix issue where NOARG_CD with a null target threw an error.
- Fix issue where NOARG_CD incorrectly listed as a flag.

## [1.5.2] 2019-03-25

- Fix potential conflict between function name and common alias.

## [1.5] 2019-03-23

- Implement MaxCompletions to limit to number of directory/path/file completions returned.
- Change completion type for 'Get-ChildItems' to path completion per default PowerShell behaviour.

## [1.4] 2019-02-21

- Use drive root path instead of name in ancestor menu completion.
- Fix issue on Linux where one can't `up` to the root directory.
- Fix issue where duplicates added to the stack.
- Reimplement `Step-Between` in terms of `Undo-Location` and `Redo-Location`.
- Add aliases `dirs` and `setocd`.
- Enable boolean options without an argument `setocd CDABLE_VARS`.

## [1.3.1] 2018-12-13

- Fix issue where cding into expanded directory fails when one exact match and several partial matches are available.

## [1.3] 2018-11-29

- Play nice and restore the cd alias when module is removed.
- Fix weird sort order when matching PWD and CD_PATH at the same time.

## [1.2] 2018-11-09

- Fix issue where square brackets not escaped in path completions.
- Fix issue where square brackets break Expand-Path.
- Improve completion on single or double dots.

## [1.1] 2018-11-09

- Removed `PostCommandLookup` on `cd` command and replace with `Set-LocationEx` proxy function and associated alias.

## [1.0] 2018-08-21

- Initial release
