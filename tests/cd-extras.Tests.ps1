${Script:/} = [System.IO.Path]::DirectorySeparatorChar

if (-not (Test-Path variable:IsWindows)) {
  $Global:IsWindows = $PSEdition -eq 'desktop' -or $env:OS -like "windows*"
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
    Clear-Stack -Undo -Redo
    $Global:cde = $xcde
    Pop-Location
  }

  BeforeEach {
    Set-Location TestDrive:\
    Clear-Stack -Undo -Redo
  }

  function CurrentDir() {
    Get-Location | Split-Path -Leaf
  }

  function ShouldBeOnWindows($expected) {
    if ($IsWindows) {
      $Input | Should Be $expected
    }
  }

  Describe 'cd' {
    It 'works with spaces' {
      cd 'powershell/directory with spaces'
      CurrentDir | Should Be 'directory with spaces'
    }
  }

  Describe 'Undo-Location' {
    It 'moves back to previous directory' {
      cd powershell
      cd src
      cd-
      CurrentDir | Should Be powershell
    }

    It 'moves back "n" locations' {
      cd powershell
      cd src
      cd Modules
      cd Shared
      cd- 2
      CurrentDir | Should Be src
    }

    It 'moves back to a named location' {
      cd powershell
      cd src
      cd Modules
      cd Shared
      cd- src
      CurrentDir | Should Be src
    }

    It 'throws if the named location cannot be found' {
      cd powershell/src
      {Undo-Location doesnotexist} | Should Throw "Could not find"
    }

    It 'matches more than one segment if necessary' {
      cd powershell
      cd src
      cd Modules
      cd Shared
      cd- src/mod
      CurrentDir | Should Be Modules
    }
  }

  Describe 'Redo-Location' {
    It 'moves forward on the stack' {
      cd powershell
      cd src
      cd-
      cd+
      CurrentDir | Should Be src
    }

    It 'moves forward "n" locations' {
      cd powershell
      cd src
      cd Modules
      cd Shared
      cd-
      cd-
      cd+ 2
      CurrentDir | Should Be Shared
    }

    It 'moves forward to a named location' {
      cd powershell
      cd src
      cd Modules
      cd Shared
      cd-
      cd-
      cd+ shared
      CurrentDir | Should Be Shared
    }

    It 'throws if the named location cannot be found' {
      cd powershell/src
      cd-
      {Redo-Location doesnotexist} | Should Throw
    }
  }

  Describe 'Step-Back' {
    It 'toggles between two directories' {
      cd ./powershell/src/Modules
      cd ../../demos/Apache
      cdb
      CurrentDir | Should Be Modules
      cdb
      CurrentDir | Should Be Apache
    }
  }

  Describe 'Multi-dot cd' {
    It 'can move up two directories' {
      Set-Location ./powershell/src/Modules/Shared/Microsoft.PowerShell.Utility
      cd ...
      CurrentDir | Should Be Modules
    }


    It 'can move up three directories' {
      Set-Location ./powershell/src/Modules/Shared/Microsoft.PowerShell.Utility
      cd ....
      CurrentDir | Should Be src
    }
  }

  Describe 'Path shortening cd' {
    It 'can move up multiple directories' {
      cd ./pow/src/Mod
      CurrentDir | Should Be Modules
    }

    It 'work with explicit Path parameter' {
      cd -Path ./pow/src/Mod
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
      CurrentDir | Should Be CronTab
    }

    It 'works with two arg cd' {
      Set-Location .\powershell\src\Modules\Shared\Microsoft.PowerShell.Utility
      cd Shared Unix
      Get-Location | Split-Path -parent | Should Be TestDrive:${/}powershell${/}src${/}Modules${/}Unix
    }

    It 'leaves an entry on the undo stack' {
      Set-Location .\powershell\src\Modules\Shared\Microsoft.PowerShell.Utility
      cd Shared Unix
      Get-Stack -Undo | select -First 1 | Split-Path -Leaf |
        Should Be Microsoft.PowerShell.Utility
    }

    It 'throws if the replaceable text is not in the current directory name' {
      Set-Location powershell\src\Modules\Shared\Microsoft.PowerShell.Utility
      {cd: shard Unix} | Should Throw "String 'shard'"
    }

    It 'throws if the replacement results in a path which does not exist' {
      Set-Location powershell\src\Modules\Shared\Microsoft.PowerShell.Utility
      {cd: Shared unice} | Should Throw "No such directory"
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

    It 'does not choke on root directory full path' {
      Set-Location $PSScriptRoot
      Step-Up (Get-Location).Drive.Root
      $PWD | Should Be (Get-Location).Drive.Root
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

    It 'does not choke on duplicate directory names' {
      Set-Location powershell/powershell
      $xup = Export-Up -NoGlobals
      $xup[0] | should match ([Regex]::Escape($pwd.Path))
      $xup[1] | should not match ([Regex]::Escape(($pwd.Path | Split-Path -Parent)))
    }

    It 'should not export the root directory by default' {
      $xup = Export-Up -NoGlobals -From ~
      $xup.Keys | Should -Not -Contain (Resolve-Path ~).Drive.Root
    }

    It 'should export the root directory when switch set' {
      $xup = Export-Up -NoGlobals -From ~ -IncludeRoot
      $xup.Keys | Should -Contain (Resolve-Path ~).Drive.Name
    }
  }

  Describe 'AUTO_CD' {

    BeforeEach {
      Set-CdExtrasOption AUTO_CD $true
      $Global:__cdeUnderTest = $true
    }

    It 'can change directory' {
      Set-Location powershell
      src
      CurrentDir | Should Be src
    }

    It 'can change directory using a partial match' {
      Set-Location powershell
      sr
      CurrentDir | Should Be src
    }

    It 'can change directory using multiple partial path segments' {
      Set-Location powershell
      sr/Res
      CurrentDir | Should Be ResGen
    }

    It 'can navigate up one level' {
      Set-Location p*\src\Sys*\Format*\common\Utilities
      ..
      CurrentDir | Should Be common
    }

    It 'can navigate up multiple levels' {
      Set-Location p*\src\Sys*\Format*\common\Utilities
      .....
      CurrentDir | Should Be src
    }

    It 'does nothing if more than one word given' {
      Set-Location powershell
      sr x
      CurrentDir | Should Be powershell
    }

    It 'does nothing when turned off' {
      Set-CdExtrasOption -Option AUTO_CD -Value $false
      Set-Location powershell
      { src } | Should Throw
      CurrentDir | Should Be powershell
    }
  }

  Describe 'CDABLE_VARS' {
    It 'can change directory using a variable name' {
      $Global:psh = Resolve-Path ./pow*/src/Mod*/Shared/*.Host
      Set-CdExtrasOption CDABLE_VARS $true
      cd psh
      CurrentDir | Should Be 'Microsoft.PowerShell.Host'
    }

    It 'works with AUTO_CD' {
      Set-CdExtrasOption CDABLE_VARS $true
      Set-CdExtrasOption AUTO_CD $true

      $Global:psh = Resolve-Path ./pow*/src/Mod*/Shared/*.Host
      $Global:__cdeUnderTest = $true
      psh
      CurrentDir | Should Be 'Microsoft.PowerShell.Host'
    }
  }

  Describe 'No arg cd' {
    It 'moves to the expected location' {
      $cde.NOARG_CD | Should Be '~'
      cd
      (Get-Location).Path | Should Be (Resolve-Path ~).Path
    }

    It 'leaves an entry in the Undo stack' {
      $startLocation = (Get-Location).Path
      $cde.NOARG_CD | Should Be '~'
      cd
      (Get-Stack -Undo | select -First 1).Path | Should Be $startLocation
    }
  }

  Describe 'CD_PATH' {
    It 'searches CD_PATH for candidate directories' {
      Set-CdExtrasOption -Option CD_PATH -Value @('TestDrive:\powershell\src\')
      cd ResGen
      CurrentDir | Should Be resgen
    }

    It 'works when there is one exact match and several partial matches' {
      Set-CdExtrasOption -Option CD_PATH -Value @('powershell\src\Modules\')
      cd windows
      CurrentDir | Should Be windows
    }

    It 'does not search CD_PATH when given directory is rooted or relative' {
      Set-CdExtrasOption -Option CD_PATH -Value @('TestDrive:\powershell\src\')
      {cd ./resgen -ErrorAction Stop} | Should Throw "Cannot find path"
    }
  }

  Describe 'Expand-Path' {
    It 'returns expected expansion Windows style' {
      Expand-Path p/s/m/U |
        Should Be (Join-Path $TestDrive powershell\src\Modules\Unix)
    }

    It 'returns expected expansion relative style' {
      Expand-Path ./p/s/m/U |
        Should Be (Join-Path $TestDrive powershell\src\Modules\Unix)
    }

    It 'expands rooted paths' {
      Expand-Path /p/s/m/U | # TestDrive root Windows only
        ShouldBeOnWindows (Join-Path $TestDrive powershell\src\Modules\Unix)
    }

    It 'can return multiple expansions' {
      (Expand-Path ./p/s/m/s/M).Length |
        Should Be 2
    }

    It 'considers CD_PATH for expansion' {
      Set-CdExtrasOption -Option CD_PATH -Value @('TestDrive:\powershell\src\')
      Expand-Path Microsoft.WSMan | Should HaveCount 2
    }

    It 'expands around periods' {
      Expand-Path p/s/.Con |
        Should Be (Join-Path $TestDrive powershell\src\Microsoft.PowerShell.ConsoleHost)
    }

    It 'works in Windows registry' {
      if ($IsWindows) {
        (Expand-Path HKLM:\Soft\Mic\).Count | Should BeGreaterOrEqual 1
      }
    }
  }

  Describe 'Get-Stack' {
    It 'shows the redo and undo stacks' {
      Get-Stack | Select -Expand Count | Should Be 2
    }

    It 'shows the undo stack' {
      cd powershell/src
      Get-Stack -Undo | Select -First 1 | Select Path | Should Not Be $null
    }

    It 'shows the redo stack' {
      cd powershell/src
      cd-
      Get-Stack -Redo | Select -First 1 | Select Path | Should Not Be $null
    }
  }

  Describe 'Clear-Stack' {
    It 'clears the undo stack' {
      cd powershell
      Get-Stack -Undo | Should Not BeNullOrEmpty
      Clear-Stack -Undo
      Get-Stack -Undo | Should BeNullOrEmpty
    }

    It 'clears the redo stack' {
      cd powershell
      cd-
      Get-Stack -Redo | Should Not BeNullOrEmpty
      Clear-Stack -Redo
      Get-Stack -Redo | Should BeNullOrEmpty
    }
  }

  InModuleScope cd-extras {

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

      It 'completes file paths' {
        Set-Location $PSScriptRoot
        (CompletePaths -filesOnly -wordToComplete './samp').CompletionText |
          Should Match "sampleStructure.txt"
      }

      It 'provides usable registry paths' {
        if ($IsWindows) {
          (CompletePaths -dirsOnly -wordToComplete 'HKLM:\Soft\Mic').CompletionText |
            Should Match "HKLM:\\Software\\Microsoft"
        }
      }

      It 'escapes square brackets' {
        $actual = CompletePaths -wordToComplete 'pow/directory[with]squarebrackets/o'
        $actual.CompletionText | Should BeLike "'*directory*squarebrackets${/}one${/}'"
      }

      It 'appends a directory seperator given a single dot' {
        $actual = CompletePaths -wordToComplete '.'
        @($actual)[0].CompletionText | Should Be ".${/}"
      }
    }

    Describe 'Stack expansion' {
      It 'expands the undo stack' {
        Set-LocationEx powershell
        Set-LocationEx src
        $actual = CompleteStack -wordToComplete '' -commandName 'Undo'
        $actual.Count | Should BeGreaterThan 1
      }

      It 'expands the redo stack' {
        Set-LocationEx powershell
        Set-LocationEx src
        cd- 2
        $actual = CompleteStack -wordToComplete '' -commandName 'Redo'
        $actual.Count | Should BeGreaterThan 1
      }

      It 'uses index completion when menu completion is on' {
        Set-LocationEx powershell
        Set-LocationEx src
        $cde.MenuCompletion = $true
        $actual = CompleteStack -wordToComplete '' -commandName 'Undo'
        $actual[0].CompletionText | Should Be 1
      }

      It 'uses the full path when menu completion is off' {
        Set-LocationEx powershell
        Set-LocationEx src
        $cde.MenuCompletion = $false
        $actual = CompleteStack -wordToComplete '' -commandName 'Undo'
        $actual[0].CompletionText | Should BeLike "*testdrive*"
      }

      It 'uses the full path when only one completion is available' {
        Set-LocationEx powershell
        $cde.MenuCompletion = $true
        $actual = CompleteStack -wordToComplete '' -commandName 'Undo'
        $actual[0].CompletionText | Should BeLike "testdrive:${/}"
      }
    }

    Describe 'Ancestor expansion' {
      It 'expands ancestors' {
        Set-Location p*\src\Sys*\Format*\common\Utilities
        $actual = CompleteAncestors -wordToComplete ''
        $actual.Count | Should BeGreaterThan 5
      }

      It 'uses index completion when menu completion is on' {
        Set-Location ./powershell/demos/Apache
        $cde.MenuCompletion = $true
        $actual = CompleteAncestors -wordToComplete ''
        $actual[0].CompletionText | Should Be 1
      }

      It 'uses the full path when menu completion is off' {
        Set-Location ./powershell/demos/Apache
        $cde.MenuCompletion = $false
        $actual = CompleteAncestors -wordToComplete ''
        $actual[0].CompletionText | Should BeLike "*powershell${/}demos"
      }

      It 'can complete against a more than one path segment' {
        Set-Location ./powershell/demos/Apache
        $actual = CompleteAncestors -wordToComplete 'll/de'
        $actual | Should -HaveCount 1
        $actual[0].CompletionText | Should BeLike "*powershell${/}demos"
      }

      It 'can match against a previously completed full path' {
        Set-Location ./powershell/demos/Apache
        $target = CompleteAncestors -wordToComplete 'demos'
        $actual = CompleteAncestors -wordToComplete $target[0].CompletionText
        $actual[0].CompletionText | Should BeLike $target[0].CompletionText
      }
    }
  }
}