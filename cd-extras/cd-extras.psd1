@{
  RootModule        = 'cd-extras.psm1'
  ModuleVersion     = '2.9.2'
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
      - Fix regression where `cd-extras` not starting on PowerShell v5, thanks @jetersen!
      - Fix a bug where truncated menu completion entries not emitting unicode ellipsis character'
      Tags         = @('cd+', 'cd-', 'AUTO_CD', 'CD_PATH', 'CDABLE_VARS', 'bash', 'zsh')
      LicenseUri   = 'https://github.com/nickcox/cd-extras/blob/master/LICENSE'
      ProjectUri   = 'https://github.com/nickcox/cd-extras'
    }
  }
}

