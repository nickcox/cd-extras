@{
  RootModule        = 'cd-extras.psm1'
  ModuleVersion     = '2.9.0'
  GUID              = '206fccbd-dc96-4b23-908c-5ac821372e16'

  Author            = 'Nick Cox'
  Copyright         = '(c) Nick Cox. All rights reserved.'
  Description       = 'cd conveniences from bash and zsh'
  PowerShellVersion = '5.0'

  FunctionsToExport = '*-*'
  VariablesToExport = 'cde'
  AliasesToExport   = '*'
  ScriptsToProcess  = 'public/_Classes.ps1'

  PrivateData       = @{
    PSData = @{
      ReleaseNotes = '
- Enable auto-calculation of `$cde.MaxCompletions` when the option is set to `0` (or `$false`)
- Deduplicate menu completion entries by adding an index to the second and subsequent occurrences of each leaf item
- Add an option, `ToolTipExtraInfo` to augment the menu completion tooltip for path completion
- Sort path completions by type (directories first), then by name
- Default parameter set for `Get-Stack` now outputs `IndexedPath` entries for undo and redo stacks
- Fixed a bug where final character in double-dot expansion operator was ignored'

      Tags         = @('cd+', 'cd-', 'AUTO_CD', 'CD_PATH', 'CDABLE_VARS', 'bash', 'zsh')
      LicenseUri   = 'https://github.com/nickcox/cd-extras/blob/master/LICENSE'
      ProjectUri   = 'https://github.com/nickcox/cd-extras'
    }
  }
}

