@{
  RootModule        = 'cd-extras.psm1'
  ModuleVersion     = '2.0.0'
  GUID              = '206fccbd-dc96-4b23-908c-5ac821372e16'

  Author            = 'Nick Cox'
  Copyright         = '(c) Nick Cox. All rights reserved.'
  Description       = 'cd conveniences from bash and zsh'
  PowerShellVersion = '3.0'

  FunctionsToExport = '*-*'
  VariablesToExport = 'cde'
  AliasesToExport   = '*'

  PrivateData       = @{
    PSData = @{
      ReleaseNotes = '[2.0.0]
      - Rename `Export-Up` to `Get-Ancestors`
      - Swap `Include-Root` for `Exclude-Root` in `Export-Ancestors`
      - Change output of `Get-Stack -Undo` and `Get-Stack -Redo`
      - Add tilde syntax support to `Set-Location-Ex`
      - Add tilde redo support to `AUTO_CD`
      - Add `~~` as an alias of `Redo-Location`
      - Don''t fall back to default completions when no completions are available
      - Path completion should respect `-Force` parameter if available on command being completed'
      Tags         = @('cd+', 'cd-', 'AUTO_CD', 'CD_PATH', 'CDABLE_VARS', 'bash', 'zsh')
      LicenseUri   = 'https://github.com/nickcox/cd-extras/blob/master/LICENSE'
      ProjectUri   = 'https://github.com/nickcox/cd-extras'
    }
  }
}

