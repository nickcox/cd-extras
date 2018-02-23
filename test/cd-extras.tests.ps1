import-module pester -MinimumVersion 4.0
. "$PSScriptRoot\..\cd-extras\public\Core.ps1"

Describe "Path expansion" {
    Context "scenario 1" {
        In "testdrive:" {
            mkdir "namespace"
            mkdir "namespace/namespace.subnamespace"
            mkdir "namespace/namespace.somethingelse"
            mkdir "namespace/something"
           
            It "Should expand by path endings" {
                $p = Expand-Path "n/.subna"
                $p.fullname | Should -Be ((get-item "testdrive:").fullname + "namespace\namespace.subnamespace")
            }
            It "Should expand shorthand paths" {
                $p = Expand-Path "n/s"
                $p.fullname | Should -Be ((get-item "testdrive:").fullname + "namespace\something")
            }           
        }
    }
    
}