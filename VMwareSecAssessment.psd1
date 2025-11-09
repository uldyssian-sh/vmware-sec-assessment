@{
    RootModule = 'VMwareSecAssessment.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'VMware Security Assessment Team'
    CompanyName = 'Open Source Community'
    Copyright = '(c) 2024 VMware Security Assessment Contributors. All rights reserved.'
    Description = 'Comprehensive security assessment framework for VMware vSphere environments with multi-standard compliance support.'
    
    PowerShellVersion = '5.1'
    
    FunctionsToExport = @(
        'Start-VMwareSecurityAssessment',
        'Export-SecurityReport',
        'Get-AssessmentConfiguration',
        'Invoke-InfrastructureAssessment',
        'Invoke-VirtualMachineAssessment',
        'Invoke-NetworkAssessment',
        'New-AssessmentSummary',
        'New-SecurityRecommendations'
    )
    
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    PrivateData = @{
        PSData = @{
            Tags = @('VMware', 'Security', 'Compliance', 'CIS', 'STIG', 'Assessment', 'vSphere')
            LicenseUri = 'https://opensource.org/licenses/MIT'
            ProjectUri = 'https://github.com/uldyssian-sh/vmware-sec-assessment'
            ReleaseNotes = 'Initial release of VMware Security Assessment Framework'
        }
    }
}# Updated 20251109_123821
