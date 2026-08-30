@{
  RootModule        = 'cd-extras.psm1'
  ModuleVersion     = '3.0.0'
  GUID              = '206fccbd-dc96-4b23-908c-5ac821372e16'

  Author            = 'Nick Cox'
  Copyright         = '(c) Nick Cox. All rights reserved.'
  Description       = 'Fast directory navigation, history, bookmarks and path completion for PowerShell'
  PowerShellVersion = '5.0'

  FunctionsToExport = @(
    'Add-Bookmark'
    'Clear-Stack'
    'Expand-Path'
    'Get-Ancestors'
    'Get-Bookmark'
    'Get-CdExtrasOption'
    'Get-FrecentLocation'
    'Get-RecentLocation'
    'Get-Stack'
    'Get-Up'
    'Redo-Location'
    'Remove-Bookmark'
    'Remove-RecentLocation'
    'Set-CdExtrasOption'
    'Set-FrecentLocation'
    'Set-LocationEx'
    'Set-RecentLocation'
    'Step-Up'
    'Switch-LocationPart'
    'Undo-Location'
  )
  VariablesToExport = 'cde'
  AliasesToExport   = @(
    '..'
    '~'
    '~~'
    'cd-'
    'cd:'
    'cd+'
    'cdf'
    'cdr'
    'dirs'
    'dirsc'
    'getocd'
    'gup'
    'mark'
    'setocd'
    'unmark'
    'up'
    'xpa'
    'xup'
  )
  ScriptsToProcess  = 'public/_Classes.ps1'

  PrivateData       = @{
    PSData = @{
      ReleaseNotes = @'
### Added

- Add recent and frecent directory navigation with `Get-RecentLocation`, `Set-RecentLocation`,
  `Get-FrecentLocation` and `Set-FrecentLocation`.
- Add directory bookmarks with `Add-Bookmark`, `Get-Bookmark` and `Remove-Bookmark`.
- Add optional CSV persistence for recent locations and bookmarks. The CSV contains `Path`,
  `LastEntered`, `EnterCount` and `Favour` columns and is enabled with `RECENT_DIRS_FILE`.
- Add configurable frecency providers and automatic zoxide integration when zoxide is available.
- Add `Get-CdExtrasOption` and its `getocd` alias.
- Add separate navigation, completion and configuration documentation.

### Changed

- Allow recent and frecent navigation by index or search terms.
- Allow `Set-CdExtrasOption` to update multiple options from any `IDictionary` implementation.
- Retain every bookmark when recent history is trimmed.
- Make `cdr -Prune` and `cdf -Prune` default to the current directory when no pattern is supplied.
- Normalise custom frecency results, discard invalid results and apply the result limit afterwards.
- Replace wildcard manifest exports with the explicit 3.0 public command and alias lists.
- Remove the completion warning beep and report truncated results in the completion tooltip.
- Increase the default `MaxMenuLength` from 35 to 60.
- Reduce filesystem path-completion overhead by reusing paths already present on filesystem items.

### Fixed

- Prevent concurrent shells from losing each other's persisted history updates.
- Persist deletion of the final recent entry and reconcile external CSV additions, removals and
  deletion consistently.
- Validate persisted CSV rows before replacing in-memory history.
- Prevent ordinary recent entries from displacing bookmarks.
- Reject missing paths and non-container items when creating bookmarks.
- Leave explicitly typed numeric navigation values unchanged during tab completion.

### Breaking changes

- Remove `Step-Between` and its `cdb` alias. Use `Set-RecentLocation` or `cdr` to move between
  recently used directories.
- Replace the `ToolTipExtraInfo` option with `ToolTip`. The new callback receives the completion item
  and a Boolean indicating whether results were truncated, and returns the complete tooltip text.
'@
      Tags         = @(
        'cd+'
        'cd-'
        'AUTO_CD'
        'CD_PATH'
        'CDABLE_VARS'
        'bookmarks'
        'frecency'
        'navigation'
        'zoxide'
        'bash'
        'zsh'
      )
      LicenseUri   = 'https://github.com/nickcox/cd-extras/blob/master/LICENSE'
      ProjectUri   = 'https://github.com/nickcox/cd-extras'
    }
  }
}
