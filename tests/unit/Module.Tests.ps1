# VMware Security Assessment Module Tests
# This file contains comprehensive tests for the VMware Security Assessment PowerShell module

BeforeAll {
    $ModuleRoot = Split-Path -Parent $PSScriptRoot | Split-Path -Parent
    $ModuleName = 'VMwareSecAssessment'
    $ManifestPath = Join-Path $ModuleRoot "$ModuleName.psd1"
    $ModulePath = Join-Path $ModuleRoot "$ModuleName.psm1"
}

Describe "VMwareSecAssessment Module Structure" {
    Context "Module Files" {
        It "Should have module manifest" {
            $ManifestPath | Should -Exist
        }
        
        It "Should have module file" {
            $ModulePath | Should -Exist
        }
        
        It "Should have valid module manifest" {
            { Test-ModuleManifest -Path $ManifestPath -ErrorAction Stop } | Should -Not -Throw
        }
    }
    
    Context "Module Manifest Content" {
        BeforeAll {
            $Manifest = Test-ModuleManifest -Path $ManifestPath -ErrorAction SilentlyContinue
        }
        
        It "Should have correct module version format" {
            $Manifest.Version | Should -Match '^\d+\.\d+\.\d+$'
        }
        
        It "Should have required metadata" {
            $Manifest.Author | Should -Not -BeNullOrEmpty
            $Manifest.Description | Should -Not -BeNullOrEmpty
            $Manifest.Copyright | Should -Not -BeNullOrEmpty
        }
        
        It "Should export expected functions" {
            $ExpectedFunctions = @(
                'Start-VMwareSecurityAssessment',
                'Export-SecurityReport',
                'Get-AssessmentConfiguration',
                'Invoke-InfrastructureAssessment',
                'Invoke-VirtualMachineAssessment',
                'Invoke-NetworkAssessment',
                'New-AssessmentSummary',
                'New-SecurityRecommendations'
            )
            
            foreach ($Function in $ExpectedFunctions) {
                $Manifest.ExportedFunctions.Keys | Should -Contain $Function
            }
        }
    }
    
    Context "Directory Structure" {
        It "Should have src directory" {
            Join-Path $ModuleRoot "src" | Should -Exist
        }
        
        It "Should have core functions directory" {
            Join-Path $ModuleRoot "src\core" | Should -Exist
        }
        
        It "Should have reports functions directory" {
            Join-Path $ModuleRoot "src\reports" | Should -Exist
        }
        
        It "Should have config directory" {
            Join-Path $ModuleRoot "config" | Should -Exist
        }
        
        It "Should have docs directory" {
            Join-Path $ModuleRoot "docs" | Should -Exist
        }
        
        It "Should have examples directory" {
            Join-Path $ModuleRoot "examples" | Should -Exist
        }
    }
}

Describe "VMwareSecAssessment Core Functions" {
    BeforeAll {
        Import-Module $ManifestPath -Force -ErrorAction SilentlyContinue
    }
    
    Context "Function Availability" {
        It "Should load Start-VMwareSecurityAssessment function" {
            Get-Command Start-VMwareSecurityAssessment -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
        
        It "Should have proper parameter validation for Start-VMwareSecurityAssessment" {
            $Command = Get-Command Start-VMwareSecurityAssessment -ErrorAction SilentlyContinue
            $Command.Parameters.VCenter.Attributes.Mandatory | Should -Be $true
            $Command.Parameters.Standard.Attributes.ValidValues | Should -Contain 'CIS'
            $Command.Parameters.Standard.Attributes.ValidValues | Should -Contain 'STIG'
        }
    }
    
    AfterAll {
        Remove-Module $ModuleName -Force -ErrorAction SilentlyContinue
    }
}

Describe "VMwareSecAssessment Configuration" {
    Context "Sample Configuration" {
        It "Should have sample configuration file" {
            Join-Path $ModuleRoot "config\sample-config.json" | Should -Exist
        }
        
        It "Should have valid JSON in sample configuration" {
            $ConfigPath = Join-Path $ModuleRoot "config\sample-config.json"
            { Get-Content $ConfigPath | ConvertFrom-Json } | Should -Not -Throw
        }
    }
}

Describe "VMwareSecAssessment Documentation" {
    Context "Required Documentation Files" {
        It "Should have README.md" {
            Join-Path $ModuleRoot "README.md" | Should -Exist
        }
        
        It "Should have LICENSE" {
            Join-Path $ModuleRoot "LICENSE" | Should -Exist
        }
        
        It "Should have CONTRIBUTING.md" {
            Join-Path $ModuleRoot "CONTRIBUTING.md" | Should -Exist
        }
        
        It "Should have CODE_OF_CONDUCT.md" {
            Join-Path $ModuleRoot "CODE_OF_CONDUCT.md" | Should -Exist
        }
    }
    
    Context "Documentation Content" {
        It "Should have non-empty README" {
            $ReadmePath = Join-Path $ModuleRoot "README.md"
            (Get-Content $ReadmePath).Count | Should -BeGreaterThan 10
        }
    }
}# Updated 20251109_123821
