@{
  RootModule        = 'cd-extras.psm1'
  ModuleVersion     = '2.1.0'
  GUID              = '206fccbd-dc96-4b23-908c-5ac821372e16'

  Author            = 'Nick Cox'
  Copyright         = '(c) Nick Cox. All rights reserved.'
  Description       = 'cd conveniences from bash and zsh'
  PowerShellVersion = '3.0'

  FunctionsToExport = '*-*'
  VariablesToExport = 'cde'
  AliasesToExport   = '*'
  ScriptsToProcess  = 'classes/*.ps1'

  PrivateData       = @{
    PSData = @{
      ReleaseNotes = '[2.1.0]
      - Set-LocationEx will automatically `LiteralPath` in favour of `Path` if necessary
      - Main parameter of `Expand-Path` renamed to `Path`, with `Candidate` retained as an alias
      - `Expand-Path` handles square brackets as permissively as possible
      - Path completion should always use the `Force` switch on *nix'

      Tags         = @('cd+', 'cd-', 'AUTO_CD', 'CD_PATH', 'CDABLE_VARS', 'bash', 'zsh')
      LicenseUri   = 'https://github.com/nickcox/cd-extras/blob/master/LICENSE'
      ProjectUri   = 'https://github.com/nickcox/cd-extras'
    }
  }
}

