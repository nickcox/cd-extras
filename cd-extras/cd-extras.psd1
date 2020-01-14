@{
  RootModule        = 'cd-extras.psm1'
  ModuleVersion     = '2.5.0'
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
      ReleaseNotes = '[2.5.0]
      - Enable piping into `setocd`, `Undo-Location` and `Redo-Location`
      - Disable AUTO_CD when run as part of pipeline
      - Make `NamePart` parameter mandatory when using `named` parameter set
      - Ensure string paths, not `PathInfo` objects pushed onto stack
      - Ensure tooltip displayed for root paths'

      Tags         = @('cd+', 'cd-', 'AUTO_CD', 'CD_PATH', 'CDABLE_VARS', 'bash', 'zsh')
      LicenseUri   = 'https://github.com/nickcox/cd-extras/blob/master/LICENSE'
      ProjectUri   = 'https://github.com/nickcox/cd-extras'
    }
  }
}

