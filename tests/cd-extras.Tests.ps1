Describe 'cd-extras' {
  BeforeAll {
    $Script:xcde = $cde
    $Global:cde = $null
    Push-Location $PSScriptRoot
    Import-Module ../cd-extras/cd-extras.psd1 -Force
    Get-Content sampleStructure.txt | % { mkdir "TestDrive:\$_"}
  }

  AfterAll {
    $Global:cde = $xcde
    Pop-Location
  }

  BeforeEach {
    Set-Location TestDrive:\
  }

  InModuleScope cd-extras {

    Describe 'Undo-Location' {
      It 'moves back to previous directory' {
        SetLocationEx powershell
        SetLocationEx src
        cd-
        Get-Location | Should Be TestDrive:\powershell
      }
    }

    Describe 'Redo-Location' {
      It 'moves forward on the stack' {
        SetLocationEx powershell
        SetLocationEx src
        cd-
        cd+
        Get-Location | Should Be TestDrive:\powershell\src
      }
    }

    Describe 'Switch-LocationPart' {
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

      It 'throws if the replaceable text is not in the current directory name' {
        Set-Location powershell\src\Modules\Shared\Microsoft.PowerShell.Utility
        {cd: shard unix} | Should Throw
      }

      It 'throws if the replacement results in a path which does not exist' {
        Set-Location powershell\src\Modules\Shared\Microsoft.PowerShell.Utility
        {cd: shared unice} | Should Throw
      }
    }

    Describe 'Step-Up' {
      It 'can navigate upward by a given number of directories' {
        Set-Location p*\src\Sys*\Format*\common\Utilities
        Step-Up 4
        Get-Location | Split-Path -Leaf | Should Be src
      }

      It 'can navigate upward by name' {
        Set-Location p*\src\Sys*\Format*\common\Utilities
        Step-Up src
        Get-Location | Split-Path -Leaf | Should Be src
      }

      It 'can navigate upward by partial name' {
        Set-Location p*\src\Sys*\Format*\common\Utilities
        Step-Up com
        Get-Location | Split-Path -Leaf | Should Be common
      }

      It 'can navigate within the registry on Windows' {
        Set-Location HKLM:\Software\Microsoft\Windows\CurrentVersion
        Step-Up 2
        Get-Location | Split-Path -Leaf | Should Be Microsoft
      }

      It 'can navigate within the registry on Windows by name' {
        Set-Location HKLM:\Software\Microsoft\Windows\CurrentVersion
        Step-Up mic
        Get-Location | Split-Path -Leaf | Should Be Microsoft
      }
    }

    Describe 'Export-Up' {
      It 'exports parents up to but not including the root' {
        Set-Location p*\src\Sys*\Format*\common\Utilities
        Export-Up -Force
        $Global:utilities | Should Be (Resolve-Path .).Path
        $Global:common | Should Be (Resolve-Path ..).Path
        $Global:formatAndOutput | Should Be (Resolve-Path ../..).Path
        # ...
      }
    }

    Describe 'Tab-Expansion' {
      It 'expands multiple items' {
        $actual = Complete 'pow/t/c' | % {$_.CompletionText}
        $actual | Should HaveCount 3

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

      It 'completes directories with spaces correctly' {
        $actual = Complete 'pow/directory with spaces/child one'
        $actual.CompletionText | Should BeLike "'*\child one\'"
      }

      It 'completes relative directories with spaces correctly' {
        $actual = Complete './pow/directory with spaces/child one'
        $actual.CompletionText | Should BeLike "'*\child one\'"
      }
    }

    Describe 'AUTO_CD' {
      It 'can change directory' {
        Set-Location powershell
        DoUnderTest { src }
        Get-Location | Split-Path -Leaf | Should Be src
      }

      It 'can change directory using a partial match' {
        Set-Location powershell
        DoUnderTest { sr }
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

      It 'does nothing when turned off' {
        Set-CdExtrasOption -Option AUTO_CD -Value $false
        Set-Location powershell
        {DoUnderTest { src }} | Should Throw
        Get-Location | Split-Path -Leaf | Should Be powershell
      }
    }

    Describe 'CDABLE_VARS' {
      It 'can change directory using a variable name' {
        $Global:psh = Resolve-Path ./pow*/src/mod*/shared/*.host
        Set-CdExtrasOption CDABLE_VARS $true
        DoUnderTest { cd psh }
        Get-Location | Split-Path -Leaf | Should Be 'Microsoft.PowerShell.Host'
      }

      It 'works with AUTO_CD' {
        $Global:psh = Resolve-Path ./pow*/src/mod*/shared/*.host
        Set-CdExtrasOption CDABLE_VARS $true
        Set-CdExtrasOption AUTO_CD $true
        DoUnderTest { psh }
        Get-Location | Split-Path -Leaf | Should Be 'Microsoft.PowerShell.Host'
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

      It 'expands rooted paths' {
        Expand-Path /p/s/m/u |
          Should Be (Join-Path $TestDrive powershell\src\Modules\Unix)
      }

      It 'can return multiple expansions' {
        (Expand-Path p/s/m/s/m).Length |
          Should Be 2
      }

      It 'considers CD_PATH for expansion' {
        Set-CdExtrasOption -Option CD_PATH -Value @('TestDrive:\powershell\src\')
        Expand-Path Microsoft.WSMan | Should HaveCount 2
      }

      It 'expands around periods' {
        Expand-Path p/s/.con |
          Should Be (Join-Path $TestDrive powershell\src\Microsoft.PowerShell.ConsoleHost)
      }
    }

    Describe 'Show-Stack' {
      It 'shows the redo and undo stacks' {
        Show-Stack | Select -Expand Count | Should Be 2
        (Show-Stack)['Undo'] | Should Not BeNullOrEmpty
        (Show-Stack)['Redo'] | Should Not BeNullOrEmpty
      }
    }
  }
}