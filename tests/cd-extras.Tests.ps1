Push-Location $PSScriptRoot
$Global:cde = $null
Import-Module ../cd-extras/cd-extras.psd1 -Force -DisableNameChecking

Describe 'cd-extras' {
  BeforeAll {
    Push-Location
    Get-Content sampleStructure.txt | % { mkdir "TestDrive:\$_"}
  }

  AfterAll { Pop-Location }

  BeforeEach { Set-Location TestDrive:\ }

  Describe 'AUTO_CD' {
    It 'can change directory' {
      Set-Location powershell
      src
      Get-Location | Split-Path -Leaf | Should Be src
    }

    It 'can cd up one level' {
      Set-Location p*\src\Sys*\Format*\common\Utilities
      ..
      Get-Location | Split-Path -Leaf | Should Be common
    }

    It 'can cd up multiple levels' {
      Set-Location p*\src\Sys*\Format*\common\Utilities
      .....
      Get-Location | Split-Path -Leaf | Should Be src
    }
  }

  Describe 'Raise-Location' {
    It 'can navigate upward by a given number of directories' {
      Set-Location p*\src\Sys*\Format*\common\Utilities
      Raise-Location 4
      Get-Location | Split-Path -Leaf | Should Be src
    }

    It 'can navigate upward by name' {
      Set-Location p*\src\Sys*\Format*\common\Utilities
      Raise-Location src
      Get-Location | Split-Path -Leaf | Should Be src
    }

    It 'can navigate upward by partial name' {
      Set-Location p*\src\Sys*\Format*\common\Utilities
      Raise-Location com
      Get-Location | Split-Path -Leaf | Should Be common
    }
  }

  Describe 'CD_PATH' {
    It 'searches CD_PATH for candidate directories' {
      Set-CdExtrasOption -Option CD_PATH -Value @('TestDrive:\powershell\src\')
      # todo
    }
  }

  Describe 'Expand-Path' {
    It 'returns expected expansion' {
      Expand-Path p/s/m/u |
        Should Be (Join-Path $TestDrive powershell\src\Modules\Unix)
    }

    It 'can return multiple expansions' {
      (Expand-Path p/s/m/s/m).Length |
        Should Be 2
    }

    It 'considers CD_PATH for expansion' {
      Set-CdExtrasOption -Option CD_PATH -Value @('TestDrive:\powershell\src\')
      (Expand-Path Microsoft.WSMan $cde.CD_PATH).Length |
        Should Be 2
    }

    It 'expands around periods' {
      Expand-Path p/s/.con |
        Should Be (Join-Path $TestDrive powershell\src\Microsoft.PowerShell.ConsoleHost)
    }
  }

  Describe 'No arg cd' {
    Set-Location TestDrive:\
    cd
    # Get-Location | Should Be (Resolve-Path ~)
  }

  InModuleScope cd-extras {

    Describe 'Undo-Location' {
      It 'moves back to previous directory' {
        Set-LocationEx powershell
        Set-LocationEx src
        cd-
        Get-Location | Should Be TestDrive:\powershell
      }
    }

    Describe 'Redo-Location' {
      It 'moves forward on the stack' {
        Set-LocationEx powershell
        Set-LocationEx src
        cd-
        cd+
        Get-Location | Should Be TestDrive:\powershell\src
      }
    }

    Describe 'Transpose-Location' {
      It 'replaces one part of a path with another' {
        Set-Location powershell\src\Modules\Shared\Microsoft.PowerShell.Utility
        cd: shared Unix
        Get-Location | Split-Path -parent | Should Be TestDrive:\powershell\src\Modules\Unix
      }
    }

    Describe 'Raise-Location' {
      It 'moves up "n" levels' {
        Set-Location powershell\src\Modules\Shared\
        up
        Get-Location | Should Be "$TestDrive\powershell\src\Modules"
        up 2
        Get-Location | Should Be "$TestDrive\powershell"
      }
    }
  }
}

Pop-Location