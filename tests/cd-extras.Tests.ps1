Push-Location $PSScriptRoot
$Global:cde = $null
Import-Module ../cd-extras/cd-extras.psd1 -Force -DisableNameChecking
Add-Member -InputObject $cde IsUnderTest $true

Describe 'cd-extras' {
  BeforeAll {
    Push-Location
    Get-Content sampleStructure.txt | % { mkdir "TestDrive:\$_"}
  }

  AfterAll { Pop-Location }

  BeforeEach {
    Set-Location TestDrive:\
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
      It 'can be called explicitly' {
        Set-Location powershell\src\Modules\Shared\Microsoft.PowerShell.Utility
        cd: shared Unix
        Get-Location | Split-Path -parent | Should Be TestDrive:\powershell\src\Modules\Unix
      }

      It 'works with two arg cd' {
        Set-Location powershell\src\Modules\Shared\Microsoft.PowerShell.Utility
        DoUnderTest { cd shared unix }
        Get-Location | Split-Path -parent | Should Be TestDrive:\powershell\src\Modules\Unix
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

    Describe 'Tab-Expansion' {
      It 'expands multiple items' {
        $actual = Complete 'pow/t/c' | % {$_.CompletionText}
        $actual.Count | Should Be 3

        function ShouldContain($likeStr) {
          $actual | Where {$_ -like $likeStr} | Should Not BeNullOrEmpty
        }

        ShouldContain '*test\csharp\'
        ShouldContain '*test\common\'
        ShouldContain '*tools\credscan\'
      }

      It 'expands around periods' {
        $actual = Complete 'pow/s/.sdk'
        $actual.CompletionText | Should BeLike '*powershell\src\Microsoft.PowerShell.SDK\'
      }
    }

    Describe 'AUTO_CD' {
      It 'can change directory' {
        Set-Location powershell
        DoUnderTest { src }
        Get-Location | Split-Path -Leaf | Should Be src
      }

      It 'can navigate up one level' {
        Set-Location p*\src\Sys*\Format*\common\Utilities
        ..
        Get-Location | Split-Path -Leaf | Should Be common
      }

      It 'can navigate up multiple levels' {
        Set-Location p*\src\Sys*\Format*\common\Utilities
        DoUnderTest { ..... }
        Get-Location | Split-Path -Leaf | Should Be src
      }
    }

    Describe 'No arg cd' {
      It 'moves to the expected location' {
        Set-Location TestDrive:\
        DoUnderTest { cd }
        $cde.NOARG_CD | Should Be '~'
        (Get-Location).Path | Should Be (Resolve-Path ~).Path
      }
    }

    Describe 'CD_PATH' {
      It 'searches CD_PATH for candidate directories' {
        Set-CdExtrasOption -Option CD_PATH -Value @('TestDrive:\powershell\src\')
        DoUnderTest {cd resgen}
        Get-Location | Split-Path -Leaf | Should Be resgen
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
  }
}

Pop-Location