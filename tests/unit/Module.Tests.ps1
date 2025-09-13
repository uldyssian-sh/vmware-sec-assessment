BeforeAll {
    $ModulePath = Join-Path $PSScriptRoot "..\..\VMwareSecAssessment.psd1"
}

Describe "VMwareSecAssessment Module" {
    Context "Module Structure" {
        It "Should have a valid module manifest" {
            Test-Path $ModulePath | Should -Be $true
        }
        
        It "Should import without errors" {
            { Import-Module $ModulePath -Force } | Should -Not -Throw
        }
    }
}