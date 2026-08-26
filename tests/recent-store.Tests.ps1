Describe 'coordinated recent store processes' {
  BeforeAll {
    $powerShellCommand = if ($PSEdition -eq 'Core') { 'pwsh' } else { 'powershell' }
    $null = Get-Command $powerShellCommand -CommandType Application -ErrorAction Stop
    $modulePath = (Resolve-Path "$PSScriptRoot/../cd-extras/cd-extras.psd1").Path
    $childScript = (Resolve-Path "$PSScriptRoot/recent-store.process.ps1").Path

    function StartStoreChild(
      [string] $operation,
      [string] $targetPath,
      [string] $readyPath,
      [string] $continuePath
    ) {
      $childNumber = $script:children.Count + 1
      $stdout = Join-Path $script:testRoot "child-$childNumber.stdout.log"
      $stderr = Join-Path $script:testRoot "child-$childNumber.stderr.log"
      $arguments = @(
        '-NoLogo'
        '-NoProfile'
        '-File'
        $childScript
        '-ModulePath'
        $modulePath
        '-StorePath'
        $script:storeFile
        '-Operation'
        $operation
        '-TargetPath'
        $targetPath
      )
      if ($readyPath) { $arguments += '-ReadyPath', $readyPath, '-ContinuePath', $continuePath }

      $process = Start-Process -FilePath $powerShellCommand -ArgumentList $arguments -PassThru `
        -RedirectStandardOutput $stdout -RedirectStandardError $stderr
      # Start-Process can lose access to ExitCode on Windows when output is redirected unless
      # the process handle is read before the child exits.
      $null = $process.Handle
      $child = [pscustomobject]@{ Process = $process; Stdout = $stdout; Stderr = $stderr }
      $script:children += $child
      $child
    }

    function WaitForFile([string] $path, [string] $description) {
      $deadline = [DateTime]::UtcNow.AddSeconds(10)
      while (!(Test-Path -LiteralPath $path)) {
        if ([DateTime]::UtcNow -ge $deadline) {
          throw "Timed out waiting for $description at '$path'.`n$(StoreDiagnostics)"
        }
        Start-Sleep -Milliseconds 20
      }
    }

    function CompleteStoreChild($child) {
      if (!$child.Process.WaitForExit(10000)) {
        $child.Process.Kill()
        throw "Child process $($child.Process.Id) did not exit within 10 seconds.`n$(StoreDiagnostics)"
      }
      $child.Process.WaitForExit()

      $stdout = if (Test-Path -LiteralPath $child.Stdout) { Get-Content -Raw $child.Stdout }
      $stderr = if (Test-Path -LiteralPath $child.Stderr) { Get-Content -Raw $child.Stderr }
      $diagnostics = "stdout:`n$stdout`nstderr:`n$stderr"
      $child.Process.ExitCode | Should -Be 0 -Because $diagnostics
      [pscustomobject]@{ Stdout = $stdout; Stderr = $stderr }
    }

    function StoreDiagnostics() {
      $csv = if (Test-Path -LiteralPath $script:storeFile) { Get-Content -Raw $script:storeFile }
      $logs = $script:children.ForEach{
        "child $($_.Process.Id) stdout:`n$(if (Test-Path $_.Stdout) { Get-Content -Raw $_.Stdout })`n" +
        "child $($_.Process.Id) stderr:`n$(if (Test-Path $_.Stderr) { Get-Content -Raw $_.Stderr })"
      }
      "CSV:`n$csv`n$($logs -join "`n")"
    }
  }

  BeforeEach {
    $script:testRoot = Join-Path ([IO.Path]::GetTempPath()) "cd-extras-test-$([guid]::NewGuid())"
    $null = New-Item -ItemType Directory -Path $script:testRoot
    $script:storeFile = Join-Path $script:testRoot 'recent.csv'
    $script:firstTarget = (New-Item -ItemType Directory -Path (Join-Path $script:testRoot first)).FullName
    $script:secondTarget = (New-Item -ItemType Directory -Path (Join-Path $script:testRoot second)).FullName
    $script:children = @()
  }

  AfterEach {
    foreach ($child in $script:children) {
      if (!$child.Process.HasExited) { $child.Process.Kill() }
      $child.Process.Dispose()
    }
    Remove-Item -LiteralPath $script:testRoot -Recurse -Force -ErrorAction Ignore
  }

  It 'retains different directories entered by processes released together' {
    $readyOne = Join-Path $script:testRoot 'one.ready'
    $readyTwo = Join-Path $script:testRoot 'two.ready'
    $continue = Join-Path $script:testRoot 'continue'
    $first = StartStoreChild Enter $script:firstTarget $readyOne $continue
    $second = StartStoreChild Enter $script:secondTarget $readyTwo $continue
    WaitForFile $readyOne 'first child readiness'
    WaitForFile $readyTwo 'second child readiness'

    $null = New-Item -ItemType File -Path $continue
    $null = CompleteStoreChild $first
    $null = CompleteStoreChild $second

    $paths = @(Import-Csv -LiteralPath $script:storeFile).Path
    $paths | Should -Contain $script:firstTarget -Because (StoreDiagnostics)
    $paths | Should -Contain $script:secondTarget -Because (StoreDiagnostics)
  }

  It 'retains both increments when processes enter the same directory together' {
    $readyOne = Join-Path $script:testRoot 'one.ready'
    $readyTwo = Join-Path $script:testRoot 'two.ready'
    $continue = Join-Path $script:testRoot 'continue'
    $first = StartStoreChild Enter $script:firstTarget $readyOne $continue
    $second = StartStoreChild Enter $script:firstTarget $readyTwo $continue
    WaitForFile $readyOne 'first child readiness'
    WaitForFile $readyTwo 'second child readiness'

    $null = New-Item -ItemType File -Path $continue
    $null = CompleteStoreChild $first
    $null = CompleteStoreChild $second

    $entry = Import-Csv -LiteralPath $script:storeFile | Where-Object Path -eq $script:firstTarget
    [int]$entry.EnterCount | Should -Be 2 -Because (StoreDiagnostics)
  }

  It 'retains an enter and bookmark released together' {
    $readyOne = Join-Path $script:testRoot 'one.ready'
    $readyTwo = Join-Path $script:testRoot 'two.ready'
    $continue = Join-Path $script:testRoot 'continue'
    $enter = StartStoreChild Enter $script:firstTarget $readyOne $continue
    $mark = StartStoreChild Mark $script:secondTarget $readyTwo $continue
    WaitForFile $readyOne 'enter child readiness'
    WaitForFile $readyTwo 'bookmark child readiness'

    $null = New-Item -ItemType File -Path $continue
    $null = CompleteStoreChild $enter
    $null = CompleteStoreChild $mark

    $entries = @(Import-Csv -LiteralPath $script:storeFile)
    $entries.Path | Should -Contain $script:firstTarget -Because (StoreDiagnostics)
    ($entries | Where-Object Path -eq $script:secondTarget).Favour |
    Should -Be 'True' -Because (StoreDiagnostics)
  }

  It 'makes a reader wait while another process holds the datastore lock' {
    $seed = StartStoreChild Enter $script:firstTarget
    $null = CompleteStoreChild $seed
    $holderReady = Join-Path $script:testRoot 'holder.ready'
    $releaseHolder = Join-Path $script:testRoot 'release-holder'
    $readerReady = Join-Path $script:testRoot 'reader.ready'
    $startReader = Join-Path $script:testRoot 'start-reader'
    $holder = StartStoreChild HoldLock $script:firstTarget $holderReady $releaseHolder
    WaitForFile $holderReady 'lock holder readiness'
    $reader = StartStoreChild Count $script:firstTarget $readerReady $startReader
    WaitForFile $readerReady 'reader readiness'

    $null = New-Item -ItemType File -Path $startReader
    $reader.Process.WaitForExit(250) | Should -BeFalse -Because 'the datastore lock is still held'
    $null = New-Item -ItemType File -Path $releaseHolder
    $null = CompleteStoreChild $holder
    $readerOutput = CompleteStoreChild $reader

    $readerOutput.Stdout.Trim() | Should -Be '1' -Because (StoreDiagnostics)
  }

  It 'persists a completed entry when the child immediately removes the module' {
    $writer = StartStoreChild EnterAndRemoveModule $script:firstTarget
    $null = CompleteStoreChild $writer
    $reader = StartStoreChild Count $script:firstTarget
    $readerOutput = CompleteStoreChild $reader

    $readerOutput.Stdout.Trim() | Should -Be '1' -Because (StoreDiagnostics)
  }

  It 'applies enter, remove and later enter operations in completion order' {
    $firstWriter = StartStoreChild Enter $script:firstTarget
    $null = CompleteStoreChild $firstWriter
    $remover = StartStoreChild Remove $script:firstTarget
    $null = CompleteStoreChild $remover
    Test-Path -LiteralPath $script:storeFile | Should -BeFalse -Because (StoreDiagnostics)

    $secondWriter = StartStoreChild Enter $script:firstTarget
    $null = CompleteStoreChild $secondWriter

    $entry = Import-Csv -LiteralPath $script:storeFile
    $entry.Path | Should -Be $script:firstTarget -Because (StoreDiagnostics)
    [int]$entry.EnterCount | Should -Be 1 -Because (StoreDiagnostics)
  }
}
