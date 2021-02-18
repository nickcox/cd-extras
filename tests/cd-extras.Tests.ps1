BeforeDiscovery {
  ${Script:/} = [System.IO.Path]::DirectorySeparatorChar

  if (-not (Test-Path variable:IsWindows)) {
    $Script:IsWindows = $PSEdition -eq 'desktop' -or $env:OS -like "windows*"
  }

  $Script:xcde = if (Test-Path variable:cde) { $cde }
  $Global:cde = $null
  Push-Location $PSScriptRoot
  Import-Module ../cd-extras/cd-extras.psd1 -Force
}

Describe 'cd-extras' {

  BeforeAll {
    Get-Content sampleStructure.txt | New-Item -ItemType Directory -Path { "TestDrive:/$_" }
    function CurrentDir() {
      Get-Location | Split-Path -Leaf
    }
  }

  AfterAll {
    Clear-Stack
    $Global:cde = $xcde
    Pop-Location
  }

  BeforeEach {
    Set-Location TestDrive:\
    setocd CD_PATH @()
    Clear-Stack
  }

  Describe 'cd' {
    It 'works with spaces' {
      cd 'powershell/directory with spaces'
      CurrentDir | Should -Be 'directory with spaces'
    }

    It 'pushes to the undo stack' {
      (Get-Stack -Undo) | Should -Be $null
      cd powershell
      cd src
      (Get-Stack -Undo).Count | Should -Be 2
      (Get-Stack -Undo).Name | select -First 1 | should -Be 'powershell'
    }

    It 'does not push duplicates' {
      (Get-Stack -Undo) | Should -Be $null
      cd powershell
      cd src
      cd ../src
      (Get-Stack -Undo).Count | Should -Be 2
      (Get-Stack -Undo).Name | Select -First 1 | Should -Be 'powershell'
    }

    It 'supports piping values' {
      @('powershell', 'src') | cd
      CurrentDir | Should -Be 'src'
      cd-
      CurrentDir | Should -Not -Be 'src'
    }

    It 'supports literal paths' {
      cd 'pow/directory[with]squarebrackets'
      CurrentDir | Should -Be 'directory[with]squarebrackets'
    }

    It 'is not fazed by a trailing separator' {
      cd 'pow/directory[with]squarebrackets/'
      CurrentDir | Should -Be 'directory[with]squarebrackets'
    }
  }

  Describe 'Undo-Location' {
    It 'moves back to previous directory' {
      cd powershell; cd src
      cd-
      CurrentDir | Should -Be powershell
    }

    It 'moves back "n" locations' {
      cd powershell; cd src; cd Modules; cd Shared
      cd- 2
      CurrentDir | Should -Be src
    }

    It 'works with the zsh style syntax' {
      cd powershell; cd src; cd Modules; cd Shared
      cd -2
      CurrentDir | Should -Be src
    }

    It 'works with the tilde syntax' {
      cd powershell; cd src; cd Modules; cd Shared
      cd ~2
      CurrentDir | Should -Be src
    }

    It 'moves back to a named location, regardless of case' {
      cd powershell; cd src; cd Modules; cd Shared
      cd- Src
      CurrentDir | Should -Be src
    }

    It 'prefers an exact match if available' {
      cd powershell; cd src; cd libpsl-native; cd test; cd googletest
      $backThreePath = "Testdrive:${/}powershell${/}src"
      cd- $backThreePath
      $PWD.Path | Should -Be $backThreePath
    }

    It 'throws if the named location cannot be found' {
      cd powershell/src
      { Undo-Location doesnotexist } | Should -Throw "Could not find*"
    }

    It 'matches more than one segment if necessary' {
      cd powershell; cd src; cd Modules; cd Shared
      cd- src/mod
      CurrentDir | Should -Be Modules
    }

    It 'pops a directory with literal square brackets' {
      cd 'powershell/directory`[with`]squarebrackets/one'; cd ..
      cd-
      CurrentDir | Should -Be one
    }

    It 'pushes current directory when moving into a directory with literal square brackets' {
      cd powershell; cd 'directory`[with`]squarebrackets/one'
      cd-
      CurrentDir | Should -Be powershell
    }

    It 'pushes current directory when CDing into a directory with question mark' {
      cd powershell; cd demos/A?ure;
      cd-
      CurrentDir | Should -Be powershell
    }

    It 'supports the PassThru switch' {
      cd powershell; cd src
      $path = cd- -PassThru
      $path | Split-Path -Leaf | Should -Be Powershell
    }
  }

  Describe 'Redo-Location' {
    It 'moves forward on the stack' {
      cd powershell; cd src; cd-
      cd+
      CurrentDir | Should -Be src
    }

    It 'moves forward "n" locations' {
      cd powershell; cd src; cd Modules; cd Shared; cd-; cd-
      cd+ 2
      CurrentDir | Should -Be Shared
    }

    It 'works with the zsh style syntax' {
      cd powershell; cd src; cd Modules; cd Shared; cd-; cd-
      cd +2
      CurrentDir | Should -Be Shared
    }

    It 'works with the tilde syntax' {
      cd powershell; cd src; cd Modules; cd Shared; cd-; cd-
      cd ~~2
      CurrentDir | Should -Be Shared
    }

    It 'moves forward to a named location' {
      cd powershell; cd src; cd Modules; cd Shared; cd-; cd-
      cd+ shared
      CurrentDir | Should -Be Shared
    }

    It 'throws if the named location cannot be found' {
      cd powershell/src
      cd-
      { Redo-Location doesnotexist } | Should -Throw
    }

    It 'pops a directory with square brackets' {
      cd 'powershell/directory`[with`]squarebrackets/one'; cd-
      cd+
      CurrentDir | Should -Be one
    }

    It 'supports the PassThru switch' {
      cd powershell; cd src; cd-
      $path = cd+ -PassThru
      $path | Split-Path -Leaf | Should -Be src
    }
  }

  Describe 'Step-Between' {
    It 'toggles between two directories' {
      cd ./powershell/src/Modules
      cd ../../demos/Apache
      cdb
      CurrentDir | Should -Be Modules
      cdb
      CurrentDir | Should -Be Apache
    }

    It 'supports the PassThru switch' {
      cd ./powershell/src/Modules
      cd ../../demos/Apache
      $path = cdb -PassThru
      $path | SPlit-Path -Leaf | Should -Be Modules
      $path = cdb -PassThru
      $path | SPlit-Path -Leaf | Should -Be Apache
    }
  }

  Describe 'Multi-dot cd' {
    It 'can move up two directories' {
      Set-Location ./powershell/src/Modules/Shared/Microsoft.PowerShell.Utility
      cd ...
      CurrentDir | Should -Be Modules
    }

    It 'can move up three directories' {
      Set-Location ./powershell/src/Modules/Shared/Microsoft.PowerShell.Utility
      cd ....
      CurrentDir | Should -Be src
    }

    It 'works even when CD_PATH is set' {
      setocd CD_PATH @('TestDrive:\powershell\src\')
      Set-Location ./powershell/src/Modules/Shared/Microsoft.PowerShell.Utility
      cd ...
      CurrentDir | Should -Be Modules
    }
  }

  Describe 'Path shortening cd' {
    It 'can shorten directories' {
      cd ./pow/src/Mod
      CurrentDir | Should -Be Modules
    }

    It 'works with explicit Path parameter' {
      cd -Path ./pow/src/Mod
      CurrentDir | Should -Be Modules
    }

    It 'works in the registry provider' -Skip:(!$IsWindows) {
      cd HKLM:/
      cd so/mic
      CurrentDir | Should -Be Microsoft
    }

    It 'supports the double dot operator' {
      cd pow/src/Typ..Gen
      CurrentDir | Should -Be TypeCatalogGen
    }
  }

  Describe 'Switch-LocationPart' {
    It 'can be called explicitly' {
      Set-Location .\powershell\src\Modules\Shared\Microsoft.PowerShell.Utility
      cd: shared Unix
      Get-Location | Split-Path | Should -Be TestDrive:${/}powershell${/}src${/}Modules${/}Unix
    }

    It 'can replace more than one path segment' {
      Set-Location .\powershell\demos\Apache\Apache
      cd: Apache/Apache crontab/CronTab
      CurrentDir | Should -Be CronTab
    }

    It 'works with two arg cd' {
      Set-Location .\powershell\src\Modules\Shared\Microsoft.PowerShell.Utility
      cd Shared Unix
      Get-Location | Split-Path | Should -Be TestDrive:${/}powershell${/}src${/}Modules${/}Unix
    }

    It 'leaves an entry on the Undo stack' {
      Set-Location .\powershell\src\Modules\Shared\Microsoft.PowerShell.Utility
      cd Shared Unix
      (Get-Stack -Undo).Name | Select -First 1 | Should -Be Microsoft.PowerShell.Utility
    }

    It 'throws if the replaceable text is not in the current directory name' {
      Set-Location powershell\src\Modules\Shared\Microsoft.PowerShell.Utility
      { cd: shard Unix } | Should -Throw "String 'shard'*"
    }

    It 'throws if the replacement results in a path which does not exist' {
      Set-Location powershell\src\Modules\Shared\Microsoft.PowerShell.Utility
      { cd: Shared unice } | Should -Throw "No such directory*"
    }
  }

  Describe 'Step-Up' {
    It 'moves up one level if no arguments given' {
      Set-Location p*\src\Sys*\Format*\common\Utilities
      Step-Up
      CurrentDir | Should -Be common
    }

    It 'can navigate upward by a given number of directories' {
      Set-Location p*\src\Sys*\Format*\common\Utilities
      Step-Up 4
      CurrentDir | Should -Be src
    }

    It 'can navigate upward by name' {
      Set-Location p*\src\Sys*\Format*\common\Utilities
      Step-Up src
      CurrentDir | Should -Be src
    }

    It 'can navigate upward by partial name' {
      Set-Location p*\src\Sys*\Format*\common\Utilities
      Step-Up com
      CurrentDir | Should -Be common
    }

    It 'can navigate within the registry on Windows' -Skip:(!$IsWindows) {
      Set-Location HKLM:\Software\Microsoft\Windows\CurrentVersion
      Step-Up 2
      CurrentDir | Should -Be Microsoft
    }

    It 'can navigate within the registry on Windows by name' -Skip:(!$IsWindows) {
      Set-Location HKLM:\Software\Microsoft\Windows\CurrentVersion
      Step-Up mic
      CurrentDir | Should -Be Microsoft
    }

    It 'can navigate by full name if no matching leaf name' {
      Set-Location powershell\src\Modules\Shared\
      Step-Up (Resolve-Path ..).Path
      CurrentDir | Should -Be Modules
    }

    It 'does not choke on navigating up from root' {
      cd $PSScriptRoot
      cd /
      $PWD | Should -Be (Get-Location).Drive.Root
      Step-Up 3
      $PWD | Should -Be (Get-Location).Drive.Root
    }

    It 'does not choke on root directory full path' -Skip:(!$IsWindows) {
      Set-Location $PSScriptRoot
      Step-Up (Get-Location).Drive.Root
      $PWD | Should -Be (Get-Location).Drive.Root
    }

    It 'throws if the given name part is not found' {
      Set-Location powershell\src\Modules\Shared\
      { Step-Up zrc } | Should -Throw
    }

    It 'supports the PassThru switch' {
      Set-Location p*\src\Sys*\Format*\common\Utilities
      $path = Step-Up -PassThru
      $path | Split-Path -Leaf | Should -Be common
    }
  }

  Describe 'Get-Up' {
    It 'returns the parent directory by default' {
      Set-Location pow*/docs/git
      Get-Up | Should -Be (Resolve-Path ..).Path
    }

    It 'can take an arbitrary path' {
      Get-Up -From powershell\docs\git | Should -Be (Resolve-Path powershell\docs).Path
    }

    It 'return $null when n is out of range' {
      Set-Location pow*/docs/git
      Get-Up 255 | Should -BeNullOrEmpty
    }

    It 'is fine with square brackets' {
      Set-Location 'powershell/directory`[with`]squarebrackets/one'
      Get-Up | Split-Path -Leaf | Should -Be 'directory[with]squarebrackets'
    }

    It 'should return -From when n is 0' {
      Get-Up -n 0 | should -Be $PWD.Path
    }

    It 'supports pipelines' {
      (Get-Item powershell\src\Modules\), (Get-Item powershell\demos\install\) |
      Get-Up | should -Be @((Get-Item powershell\src).FullName, (Get-Item powershell\demos).FullName)
    }
  }

  Describe 'Get-Ancestors' {
    It 'exports ancestors when Export switch set' {
      Set-Location p*\src\Sys*\Format*\common\Utilities
      Get-Ancestors -Export -Force
      $Global:common | Should -Be (Resolve-Path ..).Path
      $Global:formatAndOutput | Should -Be (Resolve-Path ../..).Path
      # ...
    }

    It 'does not choke on duplicate directory names' {
      Set-Location powershell/powershell
      $xup = (Get-Ancestors).Path
      $xup[0] | Should -BeLike ($pwd.Path | Split-Path)
      $xup[1] | Should -BeLike ($pwd.Path | Split-Path | Split-Path)
    }

    It 'should -not export the root directory when switch set' {
      $xup = Get-Ancestors -From ~ -ExcludeRoot
      $xup.Path | Should -Not -Contain (Resolve-Path ~).Drive.Root
    }

    It 'should export the root directory by default' {
      $xup = Get-Ancestors -From ~
      $xup.Path | Should -Contain (Resolve-Path ~).Drive.Root
    }
  }

  Describe 'AUTO_CD' {

    BeforeEach {
      Set-CdExtrasOption AUTO_CD $true
      &(Get-Module cd-extras) Set-Variable __cdeUnderTest -Scope Script $true
      $error.Clear()
    }

    AfterEach {
      $error.Count | Should -Be 0
    }

    It 'can change directory' {
      Set-Location powershell
      src
      CurrentDir | Should -Be src
    }

    It 'can change directory using a partial match' {
      Set-Location powershell
      sr
      CurrentDir | Should -Be src
    }

    It 'can change directory using multiple partial path segments' {
      Set-Location powershell
      sr/Res
      CurrentDir | Should -Be ResGen
    }

    It 'can navigate up multiple levels' {
      Set-Location p*\src\Sys*\Format*\common\Utilities
      .....
      CurrentDir | Should -Be src
    }

    It 'does nothing if more than one word given' {
      Set-Location powershell
      sr x
      CurrentDir | Should -Be powershell
    }

    It 'does nothing when turned off' {
      Set-CdExtrasOption -Option AUTO_CD -Value $false
      Set-Location powershell
      { src } | Should -Throw
      CurrentDir | Should -Be powershell
      $error.Clear()
    }

    It 'supports the double dot operator' {
      pow/src/Typ..Gen
      CurrentDir | Should -Be TypeCatalogGen
    }

    It 'works in the registry provider' -Skip:(!$IsWindows) {
      cd HKLM:
      so/mic
      CurrentDir | Should -Be Microsoft
    }

    It 'supports tilde undo syntax' {
      cd powershell; cd src; cd Modules; cd Shared
      ~2
      CurrentDir | Should -Be src
    }

    It 'supports tilde redo syntax' {
      cd powershell; cd src; cd Modules; cd Shared
      cd- 2
      ~~2
      CurrentDir | Should -Be Shared
    }
  }

  Describe 'CDABLE_VARS' {
    It 'can change directory using a variable name' {
      Set-CdExtrasOption CDABLE_VARS
      $Global:psh = Resolve-Path ./pow*/src/Mod*/Shared/*.Host

      cd psh
      CurrentDir | Should -Be 'Microsoft.PowerShell.Host'
    }

    It 'works with AUTO_CD' {
      Set-CdExtrasOption CDABLE_VARS
      Set-CdExtrasOption AUTO_CD
      $Global:psh = Resolve-Path ./pow*/src/Mod*/Shared/*.Host

      &(Get-Module cd-extras) Set-Variable __cdeUnderTest -Scope Script $true
      psh
      CurrentDir | Should -Be 'Microsoft.PowerShell.Host'
    }
  }

  Describe 'No arg cd' {
    It 'moves to the expected location' {
      $cde.NOARG_CD = '/'
      cd
      (Get-Location).Path | Should -Be (Resolve-Path /).Path
    }

    It 'leaves an entry in the Undo stack' {
      $startLocation = (Get-Location).Path
      $cde.NOARG_CD = '~'
      cd
      (Get-Stack -Undo).Path | select -First 1 | Should -Be $startLocation
    }

    It 'does not change location when null' {
      $startLocation = (cd $env:TEMP -PassThru).Path
      $cde.NOARG_CD = $null
      cd
      $pwd | Should -Be $startLocation
    }
  }

  Describe 'CD_PATH' {
    It 'searches CD_PATH for candidate directories' {
      Set-CdExtrasOption -Option CD_PATH -Value @(
        'TestDrive:\powershell\src\', 'TestDrive:\powershell\docs\')

      cd ResGen
      CurrentDir | Should -Be resgen
    }

    It 'works when there is one exact match and several partial matches' {
      Set-CdExtrasOption -Option CD_PATH -Value @('powershell\src\Modules\')
      cd Windows
      CurrentDir | Should -Be windows
    }

    It 'does not search CD_PATH when given directory is rooted or relative' {
      Set-CdExtrasOption -Option CD_PATH -Value @('TestDrive:\powershell\src\')
      { cd ./resgen -ErrorAction Stop } | Should -Throw "Cannot find path*"
    }
  }

  Describe 'Expand-Path' {
    It 'returns expected expansion Windows style' {
      Expand-Path p/s/m/UN |
      Should -Be (Join-Path $TestDrive powershell\src\Modules\Unix)
    }

    It 'returns expected expansion relative style' {
      Expand-Path ./p/s/m/U |
      Should -Be (Join-Path $TestDrive powershell\src\Modules\Unix)
    }

    It 'expands rooted paths' -Skip:(!$IsWindows) {
      # rooted paths on TestDrive only seem to work on Windows
      Expand-Path /p/s/m/U | Should -Be (Join-Path $TestDrive powershell\src\Modules\Unix)
    }

    It 'can return multiple expansions' {
      (Expand-Path ./p/s/m/s/M) | Should -HaveCount 2
    }

    It 'considers CD_PATH for expansion' {
      Set-CdExtrasOption -Option CD_PATH -Value @('TestDrive:\powershell\src\')
      Expand-Path Microsoft.WSMan | Should -HaveCount 2
    }

    It 'expands around periods' {
      $cde.WordDelimiters | should -Contain '.'
      Expand-Path p/s/.Con |
      Should -Be (Join-Path $TestDrive powershell\src\Microsoft.PowerShell.ConsoleHost)
    }

    It 'does not expand around periods when no delimiters are set' {
      $delimiters = $cde.WordDelimiters
      $cde.WordDelimiters = $null

      Expand-Path p/s/.Con |
      Should -BeNullOrEmpty

      $cde.WordDelimiters = $delimiters
    }

    It 'supports the double dot operator' {
      Expand-Path pow/src/Typ..Gen |
      Should -Be (Join-Path $TestDrive powershell\src\TypeCatalogGen)
    }

    It 'supports pipelines' {
      'pow/src/Typ..Gen', 'p/s/m/UN' | Expand-Path |
      Should -Be @(
        (Join-Path $TestDrive powershell\src\TypeCatalogGen)
        (Join-Path $TestDrive powershell\src\Modules\Unix)
      )
    }

    It 'works in Windows registry' -Skip:(!$IsWindows) {
      (Expand-Path HKLM:\Soft\Mic\*).Count | Should -BeGreaterOrEqual 1
    }
  }

  Describe 'Get-Stack' {
    BeforeEach {
      Clear-Stack
    }

    It 'shows the redo and undo stacks' {
      (Get-Stack).Count | Should -Be 2
    }

    It 'shows the undo stack' {
      cd powershell/src
      Get-Stack -Undo | Should -Not -BeNullOrEmpty
      Get-Stack -Redo | Should -BeNullOrEmpty
    }

    It 'returns indexes for the undo stack' {
      cd powershell
      cd src
      cd .SDK

      Get-Stack -Undo | % n | Should -Be 1, 2, 3
    }

    It 'do not return duplicate indexes for duplicate paths' {
      cd powershell
      cd src
      cd ..
      cd ..

      $undos = Get-Stack -Undo
      $undos | where n -eq 1 | % Path | Should -Be (
        $undos | where n -eq 3 | % Path)
    }

    It 'shows the redo stack' {
      cd powershell/src
      cd-
      Get-Stack -Redo | Should -Not -BeNullOrEmpty
    }
  }

  Describe 'Clear-Stack' {
    It 'clears the undo stack' {
      cd powershell
      Get-Stack -Undo | Should -Not -BeNullOrEmpty
      Clear-Stack -Undo
      Get-Stack -Undo | Should -BeNullOrEmpty
    }

    It 'clears the redo stack' {
      cd powershell
      cd-
      Get-Stack -Redo | Should -Not -BeNullOrEmpty
      Clear-Stack -Redo
      Get-Stack -Redo | Should -BeNullOrEmpty
    }
  }

  InModuleScope cd-extras {

    Describe 'Path expansion' {
      It 'expands multiple items' {
        $actual = CompletePaths -wordToComplete 'pow/t/c' | % CompletionText
        $actual | Should -HaveCount 3

        function ShouldContain($likeStr) {
          $actual -like $likeStr | Should -Not -BeNullOrEmpty
        }

        ShouldContain "*test${/}csharp${/}"
        ShouldContain "*test${/}common${/}"
        ShouldContain "*tools${/}credscan${/}"
      }

      It 'expands around periods' {
        $cde.WordDelimiters | should -Contain '.'
        $actual = CompletePaths -wordToComplete './pow/s/.SDK'
        $actual.CompletionText | Should -BeLike "*powershell${/}src${/}Microsoft.PowerShell.SDK${/}"
      }

      It 'expands around underscores' {
        $cde.WordDelimiters | should -Contain '_'
        cd powershell\tools\releaseBuild\Images
        $actual = CompletePaths -wordToComplete '_centos'
        $actual.CompletionText |
        Should -Be ".${/}microsoft_powershell_centos7${/}"

        $actual = CompletePaths -wordToComplete 'microsoft_'
        $actual | Should -HaveCount 4
      }

      It 'expands around hyphens' {
        $cde.WordDelimiters | should -Contain '-'
        cd powershell\src
        $actual = CompletePaths -wordToComplete '-native'
        $actual | Should -HaveCount 2

        $actual[0].CompletionText |
        Should -Be ".${/}libpsl-native${/}"
        $actual[1].CompletionText |
        Should -Be ".${/}powershell-native${/}"
      }

      It 'completes directories with spaces correctly' {
        $actual = CompletePaths  -wordToComplete 'pow/directory with spaces/child one'
        $actual.CompletionText | Should -BeLike "'*${/}child one${/}'"
      }

      It 'drops surrounding quotes' {
        $actual = CompletePaths  -wordToComplete "'pow/directory with spaces/child one'"
        $actual.CompletionText | Should -BeLike "'*${/}child one${/}'"
      }

      It 'completes relative directories with spaces correctly' {
        $actual = CompletePaths -wordToComplete './pow/directory with spaces/child one'
        $actual.CompletionText | Should -BeLike "'*${/}child one${/}'"
      }

      It 'completes relative directories with a relative prefix' {
        Set-Location $PSScriptRoot
        $actual = CompletePaths -wordToComplete '../cd-extras/public'
        $actual.CompletionText | Should -Be "..${/}cd-extras${/}public${/}"
      }

      It 'completes absolute paths with an absolute prefix' {
        $root = (Resolve-Path $PSScriptRoot).Drive.Root

        $actual = CompletePaths -wordToComplete $root
        $actual[0].CompletionText | Should -BeLike "$root*"
      }

      It 'expands multiple dots' {
        Set-Location p*\src\Sys*\Format*\common\Utilities
        (CompletePaths -wordToComplete '...').CompletionText | Should -Match 'FormatAndOutput'
      }

      It 'completes CDABLE_VARS' {
        setocd CDABLE_VARS
        $Global:dir = Resolve-Path ./powershell/src
        (CompletePaths -wordToComplete 'dir').CompletionText | Should -Match 'src'
      }

      It 'completes file paths' {
        Set-Location $PSScriptRoot
        (CompletePaths -filesOnly -wordToComplete './samp').CompletionText |
        Should -Match "sampleStructure.txt"
      }

      It 'provides usable registry paths' -Skip:(!$IsWindows) {
        (CompletePaths -dirsOnly -wordToComplete 'HKLM:\Soft\Mic').CompletionText |
        Should -Match "HKLM:\\Software\\Microsoft"
      }

      It 'completes paths with square brackets' {
        $actual = CompletePaths -wordToComplete 'pow/directory[with]squarebrackets/o'
        $actual.CompletionText | Should -BeLike "'*${/}powershell${/}directory*squarebrackets${/}one${/}'"
      }

      It 'appends a directory separator given a single dot' {
        $actual = CompletePaths -wordToComplete '.'
        @($actual)[0].CompletionText | Should -Be ".${/}"
      }

      It 'supports the double dot operator' {
        $actual = CompletePaths -wordToComplete 'pow/src/Typ..Gen'
        $actual.CompletionText | Should -BeLike "*src${/}TypeCatalogGen${/}"
      }

      It 'completes items in the current directory by default' {
        cd pow/demos
        $actual = CompletePaths -wordToComplete ''
        $actual | % CompletionText | Should -HaveCount 12
      }

      It 'truncates long menu items' {
        setocd ColorCompletion 0
        $actual = CompletePaths -wordToComplete 'pow/reallyreally..long'
        $actual.ListItemText.Length | Should -BeLessThan ($actual.CompletionText | Split-Path -Leaf).Length
        $actual.ListItemText.Length | Should -Be $cde.MaxMenuLength
      }

      It 'truncates long coloured menu items' {
        function Format-ColorizedFilename ($file) { "$([char]27)[32m$($file.Name)$([char]27)[0m" }

        setocd ColorCompletion 1
        $actual = CompletePaths -wordToComplete 'pow/reallyreally..long'
        $actual.ListItemText.LastIndexOf([char]27) | Should -BeGreaterThan 0

        $actualTextStart = $actual.ListItemText.IndexOf('m') + 1
        $startFinalEscapeSequence = $actual.ListItemText.LastIndexOf([char]27)
        $actualText = $actual.ListItemText.Substring($actualTextStart, $startFinalEscapeSequence - $actualTextStart)

        $actualText.Length | Should -BeLessThan ($actual.CompletionText | Split-Path -Leaf).Length
        $actualText.Length | Should -Be $cde.MaxMenuLength

        setocd ColorCompletion 0
      }

      It 'does not truncate short coloured menu items' {
        function Format-ColorizedFilename ($file) { "$([char]27)[32m$($file.Name)$([char]27)[0m" }

        setocd ColorCompletion 1
        setocd MaxMenuLength 'WindowsPowerShellModules'.Length
        $actual = CompletePaths -wordToComplete 'powershell\demos\WindowsPowerShellMod'
        $actual.ListItemText.LastIndexOf([char]27) | Should -BeGreaterThan 0

        $actualTextStart = $actual.ListItemText.IndexOf('m') + 1
        $startFinalEscapeSequence = $actual.ListItemText.LastIndexOf([char]27)
        $actualText = $actual.ListItemText.Substring($actualTextStart, $startFinalEscapeSequence - $actualTextStart)

        $actualText | Should -Be 'WindowsPowerShellModules'
        $actual.ListItemText.Length | Should -BeGreaterThan $cde.MaxMenuLength

        setocd ColorCompletion 0
      }

      It 'colourises output only if option set' {
        function Format-ColorizedFilename () { ($script:colorized = $true).ToString() }

        function InvokeCompletion() {
          $script:colorized = $false
          $null = CompletePaths -wordToComplete './pow/s/.SDK'
        }

        setocd ColorCompletion $true
        InvokeCompletion
        $colorized | Should -BeTrue

        setocd ColorCompletion $false
        InvokeCompletion
        $colorized | Should -BeFalse
      }

      It 'returns $null result if no completions available' {
        $actual = CompletePaths -wordToComplete 'zzzzzzzzz'
        $actual | Should -Be $null
      }

      It 'uses the "force" switch when the command being completed does not have one' {
        $git = Get-Item powershell/.git/
        $git.Attributes = "Hidden"
        $actual = CompletePaths -wordToComplete 'pow/.git' -commandName 'Get-Date' | Select -Expand ListItemText
        $actual | Should -Be @('.git', '.github')
      }

      It 'truncates the list of available completions' {
        $x = $cde.MaxCompletions
        $cde.MaxCompletions = 5
        $actual = CompletePaths -wordToComplete 'powershell/src/System.Management.Automation/'
        $actual | Should -HaveCount 5
        $cde.MaxCompletions = $x
      }
    }

    Describe 'Stack expansion' {
      It 'expands the undo stack' {
        Set-LocationEx powershell
        Set-LocationEx src
        $actual = CompleteStack -wordToComplete '' -commandName 'Undo'
        $actual.Count | Should -BeGreaterThan 1
      }

      It 'expands the redo stack' {
        Set-LocationEx powershell
        Set-LocationEx src
        cd- 2
        $actual = CompleteStack -wordToComplete '' -commandName 'Redo'
        $actual.Count | Should -BeGreaterThan 1
      }

      It 'uses index completion when menu completion is on' {
        Set-LocationEx powershell
        Set-LocationEx src
        $cde.IndexedCompletion = $true
        $actual = CompleteStack -wordToComplete '' -commandName 'Undo'
        $actual[0].CompletionText | Should -Be 1
      }

      It 'uses the full path when menu completion is off' {
        Set-LocationEx powershell
        Set-LocationEx src
        $cde.IndexedCompletion = $false
        $actual = CompleteStack -wordToComplete '' -commandName 'Undo'
        $actual[0].CompletionText | Should -BeLike "TestDrive:${/}powershell"
      }

      It 'uses the full path when only one completion is available' {
        Set-LocationEx powershell
        $cde.IndexedCompletion = $true
        $actual = CompleteStack -wordToComplete '' -commandName 'Undo'
        $actual[0].CompletionText | Should -BeLike "testdrive:${/}"
      }

      It 'returns $null result if no completions available' {
        dirsc
        $actual = CompleteStack -wordToComplete '' -commandName 'Undo'
        $actual | Should -Be $null
      }

      It 'puts parens around tooltip when name and path are the same' -Skip:(!$IsWindows) {
        Set-Location $PSScriptRoot
        cd (Get-Location).Drive.Root
        cd-
        $actual = CompleteStack -wordToComplete '' -commandName 'Redo'
        $actual.ToolTip | Should -BeLike '1. (*)'
      }
    }

    Describe 'Ancestor expansion' {
      It 'expands ancestors' {
        Set-Location p*\src\Sys*\Format*\common\Utilities
        $actual = CompleteAncestors -wordToComplete ''
        $actual.Count | Should -BeGreaterThan 5
      }

      It 'uses index completion when menu completion is on' {
        Set-Location ./powershell/demos/Apache
        $cde.IndexedCompletion = $true
        $actual = CompleteAncestors -wordToComplete ''
        $actual[0].CompletionText | Should -Be 1
      }

      It 'uses the full path when menu completion is off' {
        Set-Location ./powershell/demos/Apache
        $cde.IndexedCompletion = $false
        $actual = CompleteAncestors -wordToComplete ''
        $actual[0].CompletionText | Should -BeLike "*powershell${/}demos"
      }

      It 'can complete against a more than one path segment' {
        Set-Location ./powershell/demos/Apache
        $actual = CompleteAncestors -wordToComplete 'll/de'
        $actual | Should -HaveCount 1
        $actual[0].CompletionText | Should -BeLike "*powershell${/}demos"
      }

      It 'can match against a previously completed full path' {
        Set-Location ./powershell/demos/Apache
        $target = CompleteAncestors -wordToComplete 'demos'
        $actual = CompleteAncestors -wordToComplete $target[0].CompletionText
        $actual[0].CompletionText | Should -BeLike $target[0].CompletionText
      }

      It 'returns $null result if no completions available' {
        cd $PSScriptRoot # escape TestDrive
        cd $PWD.Drive.Root
        $actual = CompleteAncestors -wordToComplete ''
        $actual | Should -Be $null
      }
    }

    Describe 'Set-CdExtrasOption' {
      It 'Setting a completion option extends existing completions' {
        $pathCompletions = $cde.PathCompletions
        $originalCount = $pathCompletions.Count
        $originalCount | Should -BeGreaterThan 1
        setocd PathCompletions xxx

        $cde.PathCompletions.Count | Should -Be ($originalCount + 1)
      }

      It 'Setting a completion option does not duplicate existing completions' {
        setocd FileCompletions xxx
        $fileCompletions = $cde.fileCompletions
        $originalCount = $fileCompletions.Count
        $originalCount | Should -BeGreaterThan 0
        setocd FileCompletions xxx

        $cde.FileCompletions.Count | Should -Be $originalCount
      }
    }

    Describe 'core' {
      It 'uses a custom logger if given' {
        $logger = {
          $script:message = $args
        }

        $global:cde | Add-Member -MemberType ScriptMethod -Name _logger -Value $logger
        WriteLog "test"

        $message | Should -Be "test"
      }
    }
  }
}
