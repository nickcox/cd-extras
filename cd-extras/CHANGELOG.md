# Changes

## [1.3] 2018-11-29

Play nice and restore the cd alias when module is removed
Fix weird sort order when matching PWD and CD_PATH at the same time.

## [1.2] 2018-11-09

Fix issue where square brackets not escaped in path completions.
Fix issue where square brackets break Expand-Path.
Improve completion on single or double dots.

## [1.1] 2018-11-09

Removed `PostCommandLookup` on `cd` command and replace with `Set-LocationEx` proxy function and associated alias.

## [1.0] 2018-08-21

Initial release
