BeforeAll {
    # Import the module
    $ModulePath = Join-Path $PSScriptRoot "..\..\VMwareSecAssessment.psd1"
    Import-Module $ModulePath -Force
    
    # Mock VMware PowerCLI functions
    Mock Get-VIServer { return @{ Name = "vcenter.example.com"; IsConnected = $true } }
    Mock Connect-VIServer { return @{ Name = "vcenter.example.com"; IsConnected = $true } }
}

Describe "Start-VMwareSecurityAssessment" {
    Context "Parameter Validation" {
        It "Should require VCenter parameter" {
            { Start-VMwareSecurityAssessment -Standard "CIS" } | Should -Throw
        }
        
        It "Should require Standard parameter" {
            { Start-VMwareSecurityAssessment -VCenter "vcenter.example.com" } | Should -Throw
        }
        
        It "Should accept valid Standard values" {
            $ValidStandards = @('CIS', 'STIG', 'NIST', 'Custom')
            foreach ($Standard in $ValidStandards) {
                { Start-VMwareSecurityAssessment -VCenter "vcenter.example.com" -Standard $Standard -WhatIf } | Should -Not -Throw
            }
        }
        
        It "Should reject invalid Standard values" {
            { Start-VMwareSecurityAssessment -VCenter "vcenter.example.com" -Standard "InvalidStandard" } | Should -Throw
        }
        
        It "Should accept valid Scope values" {
            $ValidScopes = @('Full', 'Infrastructure', 'VirtualMachines', 'Network')
            foreach ($Scope in $ValidScopes) {
                { Start-VMwareSecurityAssessment -VCenter "vcenter.example.com" -Standard "CIS" -Scope $Scope -WhatIf } | Should -Not -Throw
            }
        }
    }
    
    Context "Function Execution" {
        BeforeEach {
            Mock Get-AssessmentConfiguration { return @{ Standard = "CIS"; Rules = @() } }
            Mock Invoke-InfrastructureAssessment { return @() }
            Mock Invoke-VirtualMachineAssessment { return @() }
            Mock Invoke-NetworkAssessment { return @() }
            Mock New-AssessmentSummary { return @{ TotalChecks = 0; Passed = 0; Failed = 0 } }
            Mock New-SecurityRecommendations { return @() }
        }
        
        It "Should return assessment object with required properties" {
            $Result = Start-VMwareSecurityAssessment -VCenter "vcenter.example.com" -Standard "CIS"
            
            $Result | Should -Not -BeNullOrEmpty
            $Result.Id | Should -Not -BeNullOrEmpty
            $Result.VCenter | Should -Be "vcenter.example.com"
            $Result.Standard | Should -Be "CIS"
            $Result.Status | Should -Be "Completed"
        }
        
        It "Should execute full assessment by default" {
            Start-VMwareSecurityAssessment -VCenter "vcenter.example.com" -Standard "CIS"
            
            Assert-MockCalled Invoke-InfrastructureAssessment -Times 1
            Assert-MockCalled Invoke-VirtualMachineAssessment -Times 1
            Assert-MockCalled Invoke-NetworkAssessment -Times 1
        }
        
        It "Should execute only infrastructure assessment when scope is Infrastructure" {
            Start-VMwareSecurityAssessment -VCenter "vcenter.example.com" -Standard "CIS" -Scope "Infrastructure"
            
            Assert-MockCalled Invoke-InfrastructureAssessment -Times 1
            Assert-MockCalled Invoke-VirtualMachineAssessment -Times 0
            Assert-MockCalled Invoke-NetworkAssessment -Times 0
        }
        
        It "Should handle assessment failures gracefully" {
            Mock Invoke-InfrastructureAssessment { throw "Assessment failed" }
            
            $Result = Start-VMwareSecurityAssessment -VCenter "vcenter.example.com" -Standard "CIS" -Scope "Infrastructure"
            
            $Result.Status | Should -Be "Failed"
            $Result.Error | Should -Be "Assessment failed"
        }
    }
    
    Context "vCenter Connection Validation" {
        It "Should validate vCenter connection before assessment" {
            Mock Get-VIServer { return $null }
            
            { Start-VMwareSecurityAssessment -VCenter "invalid.vcenter.com" -Standard "CIS" } | Should -Throw "*Not connected to vCenter*"
        }
    }
}