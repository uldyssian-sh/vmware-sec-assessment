# Integration Tests for VMware Security Assessment
# These tests require a live vCenter environment for full validation

BeforeAll {
    $ModuleRoot = Split-Path -Parent $PSScriptRoot | Split-Path -Parent
    $ModuleName = 'VMwareSecAssessment'
    $ManifestPath = Join-Path $ModuleRoot "$ModuleName.psd1"
    
    # Import module
    Import-Module $ManifestPath -Force -ErrorAction SilentlyContinue
    
    # Test environment variables
    $TestVCenter = $env:TEST_VCENTER
    $TestCredential = $env:TEST_CREDENTIAL
}

Describe "VMware Security Assessment Integration Tests" -Tag "Integration" {
    Context "Environment Setup" {
        It "Should have test environment configured" {
            if (-not $TestVCenter) {
                Set-ItResult -Skipped -Because "TEST_VCENTER environment variable not set"
            }
            $TestVCenter | Should -Not -BeNullOrEmpty
        }
        
        It "Should be able to connect to PowerCLI" {
            { Get-Module -Name VMware.PowerCLI -ListAvailable } | Should -Not -Throw
        }
    }
    
    Context "Assessment Execution" -Skip:(-not $TestVCenter) {
        BeforeAll {
            if ($TestVCenter) {
                # Connect to vCenter for testing
                try {
                    Connect-VIServer -Server $TestVCenter -ErrorAction Stop
                } catch {
                    Write-Warning "Could not connect to test vCenter: $_"
                }
            }
        }
        
        It "Should execute CIS assessment without errors" {
            if (Get-VIServer -ErrorAction SilentlyContinue) {
                { Start-VMwareSecurityAssessment -VCenter $TestVCenter -Standard "CIS" -Scope "Infrastructure" } | Should -Not -Throw
            } else {
                Set-ItResult -Skipped -Because "No vCenter connection available"
            }
        }
        
        It "Should generate assessment report" {
            if (Get-VIServer -ErrorAction SilentlyContinue) {
                $Assessment = Start-VMwareSecurityAssessment -VCenter $TestVCenter -Standard "CIS" -Scope "Infrastructure"
                $Assessment | Should -Not -BeNullOrEmpty
                $Assessment.Status | Should -Be "Completed"
                $Assessment.Results | Should -Not -BeNullOrEmpty
            } else {
                Set-ItResult -Skipped -Because "No vCenter connection available"
            }
        }
        
        AfterAll {
            # Disconnect from vCenter
            if (Get-VIServer -ErrorAction SilentlyContinue) {
                Disconnect-VIServer -Server * -Confirm:$false -ErrorAction SilentlyContinue
            }
        }
    }
}

Describe "VMware Security Assessment Mock Tests" {
    Context "Function Parameter Validation" {
        It "Should validate VCenter parameter" {
            { Start-VMwareSecurityAssessment -VCenter "" -Standard "CIS" } | Should -Throw
        }
        
        It "Should validate Standard parameter" {
            { Start-VMwareSecurityAssessment -VCenter "test.local" -Standard "InvalidStandard" } | Should -Throw
        }
        
        It "Should validate Scope parameter" {
            { Start-VMwareSecurityAssessment -VCenter "test.local" -Standard "CIS" -Scope "InvalidScope" } | Should -Throw
        }
    }
    
    Context "Configuration Loading" {
        It "Should load default configuration" {
            { Get-AssessmentConfiguration -Standard "CIS" } | Should -Not -Throw
        }
        
        It "Should handle missing configuration gracefully" {
            { Get-AssessmentConfiguration -Standard "NonExistent" } | Should -Not -Throw
        }
    }
}

AfterAll {
    # Cleanup
    Remove-Module $ModuleName -Force -ErrorAction SilentlyContinue
}# Updated 20251109_123821
# Updated Sun Nov  9 12:52:29 CET 2025
# Updated Sun Nov  9 12:56:22 CET 2025
