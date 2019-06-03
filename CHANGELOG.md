# Changes
## [1.8] 2019-06-04
- Stack now contains path strings rather than PathInfo objects
- Fix bug where literal paths containing square brackets not pushed and popped correctly
- Paths completions always use `-Force`

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
