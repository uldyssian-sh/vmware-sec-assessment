Describe "VMwareSecAssessment Module" {
    It "Should have module files" {
        "VMwareSecAssessment.psd1" | Should -Exist
        "VMwareSecAssessment.psm1" | Should -Exist
    }
}