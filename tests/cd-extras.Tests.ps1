if (-not (Test-Path variable:IsWindows)) {
  $IsWindows = $env:OS -like "windows*"
}

Describe 'cd-extras' {

  BeforeAll {
    $Script:xcde = if (Test-Path variable:cde) {$cde} else {$null}
    $Global:cde = $null
    Push-Location $PSScriptRoot
    Import-Module ../cd-extras/cd-extras.psd1 -Force
    Get-Content sampleStructure.txt | % { New-Item -ItemType Directory "TestDrive:/$_" -Force}
  }

  AfterAll {
    $Global:cde = $xcde
    Pop-Location
  }

  BeforeEach {
    Set-Location TestDrive:\
  }

  InModuleScope cd-extras {

    function CurrentDir() {
      Get-Location | Split-Path -Leaf
    }

    function ShouldBeOnWindows($expected) {
      if ($IsWindows) {
        $Input | Should Be $expected
      }
    }

    Describe 'Set-Location' {
      It 'works with spaces' {
        DoUnderTest {cd 'powershell/directory with spaces'}
        CurrentDir | Should Be 'directory with spaces'
      }
    }

    Describe 'Undo-Location' {
      It 'moves back to previous directory' {
        DoUnderTest { cd powershell}
        DoUnderTest { cd src }
        cd-
        CurrentDir | Should Be powershell
      }

      It 'moves back "n" locations' {
        DoUndertest { cd powershell }
        DoUndertest { cd src }
        DoUndertest { cd Modules }
        DoUndertest { cd Shared }
        cd- 2
        CurrentDir | Should Be src
      }

      It 'moves back to a named location' {
        DoUndertest { cd powershell }
        DoUndertest { cd src }
        DoUndertest { cd Modules }
        DoUndertest { cd Shared }
        cd- src
        CurrentDir | Should Be src
      }

      It 'throws if the named location cannot be found' {
        DoUnderTest { cd powershell/src }
        {Undo-Location doesnotexist} | Should Throw
      }

      It 'matches more than one segment if necessary' {
        DoUndertest { cd powershell }
        DoUndertest { cd src }
        DoUndertest { cd Modules }
        DoUndertest { cd Shared }
        cd- src/mod
        CurrentDir | Should Be Modules
      }
    }

    Describe 'Redo-Location' {
      It 'moves forward on the stack' {
        DoUndertest { cd powershell }
        DoUndertest { cd src }
        cd-
        cd+
        CurrentDir | Should Be src
      }

      It 'moves forward "n" locations' {
        DoUndertest { cd powershell }
        DoUndertest { cd src }
        DoUndertest { cd Modules }
        DoUndertest { cd Shared }
        cd-
        cd-
        cd+ 2
        CurrentDir | Should Be Shared
      }

      It 'moves forward to a named location' {
        DoUndertest { cd powershell }
        DoUndertest { cd src }
        DoUndertest { cd Modules }
        DoUndertest { cd Shared }
        cd-
        cd-
        cd+ shared
        CurrentDir | Should Be Shared
      }

      It 'throws if the named location cannot be found' {
        DoUnderTest { cd powershell/src }
        cd-
        {Redo-Location doesnotexist} | Should Throw
      }
    }

    Describe 'Step-Back' {
      It 'toggles between two directories' {
        DoUndertest { cd ./powershell/src/Modules }
        DoUndertest { cd ../../demos/Apache }
        cdb
        Get-Location | Select -Expand Path | Should BeLike "*src${/}Modules"
        cdb
        Get-Location | Select -Expand Path | Should BeLike "*demos${/}Apache"
      }
    }

    Describe 'Multi-dot cd' {
      It 'can move up multiple directories' {
        Set-Location ./powershell/src/Modules/Shared/Microsoft.PowerShell.Utility
        DoUnderTest {cd ...}
        CurrentDir | Should Be Modules
      }
    }

    Describe 'Path shortening cd' {
      It 'can move up multiple directories' {
        DoUnderTest {cd ./pow/src/Mod}
        CurrentDir | Should Be Modules
      }

      It 'work with explicit Path parameter' {
        DoUnderTest {cd -Path ./pow/src/Mod}
        CurrentDir | Should Be Modules
      }
    }

    Describe 'Switch-LocationPart' {
      It 'can be called explicitly' {
        Set-Location .\powershell\src\Modules\Shared\Microsoft.PowerShell.Utility
        cd: shared Unix
        Get-Location | Split-Path -parent | Should Be TestDrive:${/}powershell${/}src${/}Modules${/}Unix
      }

      It 'can replace more than one path segment' {
        Set-Location .\powershell\demos\Apache\Apache
        cd: Apache/Apache crontab/CronTab
      }

      It 'works with two arg cd' {
        Set-Location .\powershell\src\Modules\Shared\Microsoft.PowerShell.Utility
        DoUnderTest { cd Shared Unix }
        Get-Location | Split-Path -parent | Should Be TestDrive:${/}powershell${/}src${/}Modules${/}Unix
      }

      It 'throws if the replaceable text is not in the current directory name' {
        Set-Location powershell\src\Modules\Shared\Microsoft.PowerShell.Utility
        {cd: shard Unix} | Should Throw
      }

      It 'throws if the replacement results in a path which does not exist' {
        Set-Location powershell\src\Modules\Shared\Microsoft.PowerShell.Utility
        {cd: Shared unice} | Should Throw
      }
    }

    Describe 'Step-Up' {
      It 'can navigate upward by a given number of directories' {
        Set-Location p*\src\Sys*\Format*\common\Utilities
        Step-Up 4
        CurrentDir | Should Be src
      }

      It 'can navigate upward by name' {
        Set-Location p*\src\Sys*\Format*\common\Utilities
        Step-Up src
        CurrentDir | Should Be src
      }

      It 'can navigate upward by partial name' {
        Set-Location p*\src\Sys*\Format*\common\Utilities
        Step-Up com
        CurrentDir | Should Be common
      }

      It 'can navigate within the registry on Windows' {
        if ($IsWindows) {
          Set-Location HKLM:\Software\Microsoft\Windows\CurrentVersion
          Step-Up 2
          CurrentDir | Should Be Microsoft
        }
      }

      It 'can navigate within the registry on Windows by name' {
        if ($IsWindows) {
          Set-Location HKLM:\Software\Microsoft\Windows\CurrentVersion
          Step-Up mic
          CurrentDir | Should Be Microsoft
        }
      }

      It 'can navigate by full name if no matching leaf name' {
        Set-Location powershell\src\Modules\Shared\
        Step-Up (Resolve-Path ..).Path
        CurrentDir | Should Be Modules
      }

      It 'throws if the given name part is not found' {
        Set-Location powershell\src\Modules\Shared\
        {Step-Up zrc} | Should Throw
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

    Describe 'AUTO_CD' {
      BeforeAll {
        Set-CdExtrasOption -Option AUTO_CD -Value $true
      }

      It 'can change directory' {
        Set-Location powershell
        DoUnderTest { src }
        CurrentDir | Should Be src
      }

      It 'can change directory using a partial match' {
        Set-Location powershell
        DoUnderTest { sr }
        CurrentDir | Should Be src
      }

      It 'can change directory using multiple partial path segments' {
        Set-Location powershell
        DoUnderTest { sr/Res }
        CurrentDir | Should Be ResGen
      }

      It 'can navigate up one level' {
        Set-Location p*\src\Sys*\Format*\common\Utilities
        ..
        CurrentDir | Should Be common
      }

      It 'can navigate up multiple levels' {
        Set-Location p*\src\Sys*\Format*\common\Utilities
        DoUnderTest { ..... }
        CurrentDir | Should Be src
      }

      It 'does nothing if more than one word given' {
        Set-Location powershell
        DoUnderTest { sr x }
        CurrentDir | Should Be powershell
      }

      It 'does nothing when turned off' {
        Set-CdExtrasOption -Option AUTO_CD -Value $false
        Set-Location powershell
        {DoUnderTest { src }} | Should Throw
        CurrentDir | Should Be powershell
      }
    }

    Describe 'CDABLE_VARS' {
      It 'can change directory using a variable name' {
        $Global:psh = Resolve-Path ./pow*/src/Mod*/Shared/*.Host
        Set-CdExtrasOption CDABLE_VARS $true
        DoUnderTest { cd psh }
        CurrentDir | Should Be 'Microsoft.PowerShell.Host'
      }

      It 'works with AUTO_CD' {
        Set-CdExtrasOption CDABLE_VARS $true
        Set-CdExtrasOption AUTO_CD $true

        $Global:psh = Resolve-Path ./pow*/src/Mod*/Shared/*.Host
        DoUnderTest { psh }
        CurrentDir | Should Be 'Microsoft.PowerShell.Host'
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
        DoUnderTest {cd ResGen}
        CurrentDir | Should Be resgen
      }

      It 'does not search CD_PATH when given directory is rooted or relative' {
        Set-CdExtrasOption -Option CD_PATH -Value @('TestDrive:\powershell\src\')
        {DoUnderTest {cd ./resgen}} | Should Throw
      }
    }

    Describe 'Expand-Path' {
      It 'returns expected expansion Windows style' {
        Expand-Path p/s/m/u |
          ShouldBeOnWindows (Join-Path $TestDrive powershell\src\Modules\Unix)
      }

      It 'returns expected expansion relative style' {
        Expand-Path ./p/s/M/U |
          Should Be (Join-Path $TestDrive powershell\src\Modules\Unix)
      }

      It 'expands rooted paths' {
        Expand-Path /p/s/m/u | # TestDrive root Windows only
        ShouldBeOnWindows (Join-Path $TestDrive powershell\src\Modules\Unix)
      }

      It 'can return multiple expansions' {
        (Expand-Path ./p/s/m/s/m).Length |
        ShouldBeOnWindows 2
      }

      It 'considers CD_PATH for expansion' {
        Set-CdExtrasOption -Option CD_PATH -Value @('TestDrive:\powershell\src\')
        Expand-Path Microsoft.WSMan | Should HaveCount 2
      }

      It 'expands around periods' {
        Expand-Path p/s/.Con |
          Should Be (Join-Path $TestDrive powershell\src\Microsoft.PowerShell.ConsoleHost)
      }
    }

    Describe 'Get-Stack' {
      It 'shows the redo and undo stacks' {
        Get-Stack | Select -Expand Count | Should Be 2
      }

      It 'shows the undo stack' {
        DoUnderTest { cd powershell/src }
        Get-Stack -Undo | Select -First 1 | Select Path | Should Not Be $null
      }

      It 'shows the redo stack' {
        DoUnderTest { cd powershell/src }
        cd-
        Get-Stack -Redo | Select -First 1 | Select Path | Should Not Be $null
      }
    }

    Describe 'Tab expansion' {
      It 'expands multiple items' {
        $actual = CompletePaths -wordToComplete 'pow/t/c' | Select -Expand CompletionText
        $actual | Should HaveCount 3

        function ShouldContain($likeStr) {
          $actual | Where {$_ -like $likeStr} | Should Not BeNullOrEmpty
        }

        ShouldContain "*test${/}csharp${/}"
        ShouldContain "*test${/}common${/}"
        ShouldContain "*tools${/}credscan${/}"
      }

      It 'expands around periods' {
        $actual = CompletePaths -wordToComplete './pow/s/.SDK'
        $actual.CompletionText | Should BeLike "*powershell${/}src${/}Microsoft.PowerShell.SDK${/}"
      }

      It 'completes directories with spaces correctly' {
        $actual = CompletePaths  -wordToComplete 'pow/directory with spaces/child one'
        $actual.CompletionText | Should BeLike "'*${/}child one${/}'"
      }

      It 'completes relative directories with spaces correctly' {
        $actual = CompletePaths -wordToComplete './pow/directory with spaces/child one'
        $actual.CompletionText | Should BeLike "'*${/}child one${/}'"
      }

      It 'completes relative directories with a relative prefix' {
        Set-Location $PSScriptRoot
        $actual = CompletePaths -wordToComplete '../cd-extras/public'
        $actual.CompletionText | Should Be "..${/}cd-extras${/}public${/}"
      }

      It 'expands multiple dots' {
        Set-Location p*\src\Sys*\Format*\common\Utilities
        (CompletePaths -wordToComplete '...').CompletionText | Should Match 'FormatAndOutput'
      }

      It 'completes CDABLE_VARS' {
        Set-CdExtrasOption -Option CDABLE_VARS $true
        $Global:dir = Resolve-Path ./powershell/src
        (CompletePaths -wordToComplete 'dir').CompletionText | Should Match 'src'
      }
    }

    Describe 'Stack expansion' {
      It 'expands the undo stack' {
        SetLocationEx powershell
        SetLocationEx src
        $actual = CompleteStack -wordToComplete '' -commandName 'Undo'
        $actual.Count | Should BeGreaterThan 1
      }

      It 'expands the redo stack' {
        SetLocationEx powershell
        SetLocationEx src
        cd- 2
        $actual = CompleteStack -wordToComplete '' -commandName 'Redo'
        $actual.Count | Should BeGreaterThan 1
      }
    }

    Describe 'Ancestor expansion' {
      It 'expands ancestors' {
        Set-Location p*\src\Sys*\Format*\common\Utilities
        $actual = CompleteAncestors -wordToComplete ''
        $actual.Count | Should BeGreaterThan 5
      }

      It 'uses the full path when menu completion is off' {
        Set-Location ./powershell/demos/Apache
        $cde.MenuCompletion = $false
        $actual = CompleteAncestors -wordToComplete ''
        $actual[0].CompletionText | Should BeLike "*powershell${/}demos'"
      }
    }
  }
}