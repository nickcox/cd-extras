# Changes

## [1.5] 2019-03-23

Implement MaxCompletions to limit to number of directory/path/file completions returned.

## [1.4] 2019-02-21

Use drive root path instead of name in ancestor menu completion.
Fix issue on Linux where one can't `up` to the root directory.
Fix issue where duplicates added to the stack.
Reimplement `Step-Back` in terms of `Undo-Location` and `Redo-Location`.
Add aliases `dirs` and `setocd`.
Enable boolean options without an argument `setocd CDABLE_VARS`.

## [1.3.1] 2018-12-13

Fix issue where cding into expanded directory fails when one exact match and several partial matches are available.

## [1.3] 2018-11-29

Play nice and restore the cd alias when module is removed.
Fix weird sort order when matching PWD and CD_PATH at the same time.

## [1.2] 2018-11-09

Fix issue where square brackets not escaped in path completions.
Fix issue where square brackets break Expand-Path.
Improve completion on single or double dots.

## [1.1] 2018-11-09

Removed `PostCommandLookup` on `cd` command and replace with `Set-LocationEx` proxy function and associated alias.

## [1.0] 2018-08-21

Initial release
