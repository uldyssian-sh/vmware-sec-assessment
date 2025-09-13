@{
    RootModule = 'VMwareSecAssessment.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    Author = 'VMware Security Assessment Team'
    CompanyName = 'Open Source Community'
    Copyright = '(c) 2024 VMware Security Assessment Contributors. All rights reserved.'
    Description = 'Comprehensive security assessment framework for VMware vSphere environments with multi-standard compliance support.'
    
    PowerShellVersion = '5.1'
    
    RequiredModules = @(
        @{
            ModuleName = 'VMware.PowerCLI'
            ModuleVersion = '12.0.0'
        }
    )
    
    FunctionsToExport = @(
        'Start-VMwareSecurityAssessment',
        'Export-SecurityReport',
        'Get-ComplianceStatus',
        'Test-SecurityControl',
        'New-RemediationScript',
        'Import-SecurityStandard',
        'Get-VulnerabilityReport',
        'Set-AssessmentConfiguration'
    )
    
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    PrivateData = @{
        PSData = @{
            Tags = @('VMware', 'Security', 'Compliance', 'CIS', 'STIG', 'Assessment', 'vSphere')
            LicenseUri = 'https://github.com/uldyssian-sh/vmware-sec-assessment/blob/main/LICENSE'
            ProjectUri = 'https://github.com/uldyssian-sh/vmware-sec-assessment'
            IconUri = 'https://raw.githubusercontent.com/uldyssian-sh/vmware-sec-assessment/main/assets/icon.png'
            ReleaseNotes = 'Initial release of VMware Security Assessment Framework'
            Prerelease = ''
            RequireLicenseAcceptance = $false
            ExternalModuleDependencies = @('VMware.PowerCLI')
        }
    }
    
    HelpInfoURI = 'https://github.com/uldyssian-sh/vmware-sec-assessment/wiki'
}