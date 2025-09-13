BeforeAll {
    $ModulePath = Join-Path $PSScriptRoot "..\..\VMwareSecAssessment.psd1"
}

Describe "Start-VMwareSecurityAssessment" {
    Context "Function Exists" {
        It "Should be defined in module" {
            $ModulePath | Should -Exist
        }
    }
}