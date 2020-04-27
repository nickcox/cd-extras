@{
  RootModule        = 'cd-extras.psm1'
  ModuleVersion     = '2.8.0'
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
      ReleaseNotes = "[2.8.0]
      - Emit a warning beep if list of path completions has been truncated
      - Don't invoke auto_cd unless at least one alphanumeric is given
      - Always use `-Force` for path completion
      - Fix issue where unable to complete into directories with surrounding quotes
      - Fix issue where `Undo-Location` and `Redo-Location` throw error when intermediate directories have been deleted"

      Tags         = @('cd+', 'cd-', 'AUTO_CD', 'CD_PATH', 'CDABLE_VARS', 'bash', 'zsh')
      LicenseUri   = 'https://github.com/nickcox/cd-extras/blob/master/LICENSE'
      ProjectUri   = 'https://github.com/nickcox/cd-extras'
    }
  }
}

