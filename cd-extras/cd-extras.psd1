@{
  RootModule        = 'cd-extras.psm1'
  ModuleVersion     = '1.6'
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
      Tags       = @('cd+', 'cd-', 'AUTO_CD', 'CD_PATH', 'CDABLE_VARS', 'bash', 'zsh')
      LicenseUri = 'https://github.com/nickcox/cd-extras/blob/master/LICENSE'
      ProjectUri = 'https://github.com/nickcox/cd-extras'
    }
  }
}

