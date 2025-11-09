#Requires -Version 5.1

<#
.SYNOPSIS
    Development Environment Setup Script for VMware Security Assessment Framework
.DESCRIPTION
    This script sets up a complete development environment for contributing to the
    VMware Security Assessment Framework project.
.PARAMETER InstallPowerCLI
    Install VMware PowerCLI module
.PARAMETER InstallDevTools
    Install development tools (Pester, PSScriptAnalyzer, etc.)
.PARAMETER SetupGitHooks
    Configure Git hooks for code quality
.PARAMETER CreateTestConfig
    Create sample test configuration files
.EXAMPLE
    .\setup-dev-environment.ps1 -InstallPowerCLI -InstallDevTools -SetupGitHooks
.NOTES
    Author: VMware Security Assessment Team
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [switch]$InstallPowerCLI,
    [switch]$InstallDevTools,
    [switch]$SetupGitHooks,
    [switch]$CreateTestConfig,
    [switch]$All
)

# If -All is specified, enable all options
if ($All) {
    $InstallPowerCLI = $true
    $InstallDevTools = $true
    $SetupGitHooks = $true
    $CreateTestConfig = $true
}

# Colors for output
$Colors = @{
    Success = 'Green'
    Warning = 'Yellow'
    Error = 'Red'
    Info = 'Cyan'
    Header = 'Magenta'
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = 'White'
    )
    Write-Host $Message -ForegroundColor $Colors[$Color]
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-ModuleIfMissing {
    param(
        [string]$ModuleName,
        [string]$MinimumVersion = $null
    )
    
    Write-ColorOutput "Checking for module: $ModuleName" -Color Info
    
    $module = Get-Module -Name $ModuleName -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1
    
    if (-not $module) {
        Write-ColorOutput "Installing $ModuleName..." -Color Warning
        Install-Module -Name $ModuleName -Scope CurrentUser -Force -AllowClobber
        Write-ColorOutput "✓ $ModuleName installed successfully" -Color Success
    } elseif ($MinimumVersion -and $module.Version -lt [Version]$MinimumVersion) {
        Write-ColorOutput "Updating $ModuleName to minimum version $MinimumVersion..." -Color Warning
        Update-Module -Name $ModuleName -Force
        Write-ColorOutput "✓ $ModuleName updated successfully" -Color Success
    } else {
        Write-ColorOutput "✓ $ModuleName is already installed (v$($module.Version))" -Color Success
    }
}

# Main setup process
Write-ColorOutput "=== VMware Security Assessment Framework - Development Setup ===" -Color Header
Write-ColorOutput ""

# Check PowerShell version
$psVersion = $PSVersionTable.PSVersion
Write-ColorOutput "PowerShell Version: $psVersion" -Color Info

if ($psVersion.Major -lt 5 -or ($psVersion.Major -eq 5 -and $psVersion.Minor -lt 1)) {
    Write-ColorOutput "ERROR: PowerShell 5.1 or later is required" -Color Error
    exit 1
}

# Set PowerShell Gallery as trusted
Write-ColorOutput "Configuring PowerShell Gallery..." -Color Info
if ((Get-PSRepository -Name PSGallery).InstallationPolicy -ne 'Trusted') {
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Write-ColorOutput "✓ PowerShell Gallery set as trusted" -Color Success
} else {
    Write-ColorOutput "✓ PowerShell Gallery already trusted" -Color Success
}

# Install VMware PowerCLI
if ($InstallPowerCLI) {
    Write-ColorOutput "`n--- Installing VMware PowerCLI ---" -Color Header
    Install-ModuleIfMissing -ModuleName "VMware.PowerCLI" -MinimumVersion "12.0.0"
    
    # Configure PowerCLI settings
    Write-ColorOutput "Configuring PowerCLI settings..." -Color Info
    try {
        Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false -Scope User | Out-Null
        Set-PowerCLIConfiguration -ParticipateInCEIP $false -Confirm:$false -Scope User | Out-Null
        Write-ColorOutput "✓ PowerCLI configured successfully" -Color Success
    } catch {
        Write-ColorOutput "Warning: Could not configure PowerCLI settings" -Color Warning
    }
}

# Install development tools
if ($InstallDevTools) {
    Write-ColorOutput "`n--- Installing Development Tools ---" -Color Header
    
    $DevModules = @(
        @{ Name = "Pester"; MinVersion = "5.0.0" },
        @{ Name = "PSScriptAnalyzer"; MinVersion = "1.20.0" },
        @{ Name = "platyPS"; MinVersion = "0.14.0" },
        @{ Name = "PowerShellGet"; MinVersion = "2.2.0" },
        @{ Name = "PackageManagement"; MinVersion = "1.4.0" }
    )
    
    foreach ($module in $DevModules) {
        Install-ModuleIfMissing -ModuleName $module.Name -MinimumVersion $module.MinVersion
    }
}

# Setup Git hooks
if ($SetupGitHooks) {
    Write-ColorOutput "`n--- Setting up Git Hooks ---" -Color Header
    
    $gitHooksPath = ".git/hooks"
    if (Test-Path $gitHooksPath) {
        # Pre-commit hook for code quality
        $preCommitHook = @"
#!/bin/sh
# Pre-commit hook for VMware Security Assessment Framework

echo "Running pre-commit checks..."

# Run PSScriptAnalyzer
echo "Running PSScriptAnalyzer..."
powershell -Command "
    `$results = Invoke-ScriptAnalyzer -Path . -Recurse -Severity Error
    if (`$results) {
        Write-Host 'PSScriptAnalyzer found errors:' -ForegroundColor Red
        `$results | Format-Table -AutoSize
        exit 1
    }
    Write-Host 'PSScriptAnalyzer: No errors found' -ForegroundColor Green
"

if [ $? -ne 0 ]; then
    echo "Pre-commit checks failed. Commit aborted."
    exit 1
fi

echo "Pre-commit checks passed."
"@
        
        $preCommitPath = Join-Path $gitHooksPath "pre-commit"
        Set-Content -Path $preCommitPath -Value $preCommitHook -Encoding UTF8
        
        # Make executable on Unix-like systems
        if ($IsLinux -or $IsMacOS) {
            chmod +x $preCommitPath
        }
        
        Write-ColorOutput "✓ Git pre-commit hook installed" -Color Success
    } else {
        Write-ColorOutput "Warning: Not in a Git repository - skipping Git hooks setup" -Color Warning
    }
}

# Create test configuration
if ($CreateTestConfig) {
    Write-ColorOutput "`n--- Creating Test Configuration ---" -Color Header
    
    # Create test directories
    $testDirs = @("tests/fixtures", "tests/data", "config/test")
    foreach ($dir in $testDirs) {
        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Write-ColorOutput "✓ Created directory: $dir" -Color Success
        }
    }
    
    # Create test configuration file
    $testConfig = @{
        testEnvironment = @{
            vCenter = @{
                server = "test-vcenter.example.com"
                username = "test-user"
                skipCertificateCheck = $true
            }
            assessment = @{
                timeout = 60
                maxRetries = 2
                parallel = $false
            }
        }
        mockData = @{
            enabled = $true
            dataPath = "./tests/data"
        }
    }
    
    $testConfigPath = "config/test/test-config.json"
    $testConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $testConfigPath -Encoding UTF8
    Write-ColorOutput "✓ Created test configuration: $testConfigPath" -Color Success
    
    # Create sample test data
    $sampleTestData = @{
        sampleHosts = @(
            @{ name = "esxi-01.example.com"; version = "8.0.0"; build = "20513097" },
            @{ name = "esxi-02.example.com"; version = "8.0.0"; build = "20513097" }
        )
        sampleVMs = @(
            @{ name = "test-vm-01"; powerState = "poweredOn"; guestOS = "windows2019srv_64Guest" },
            @{ name = "test-vm-02"; powerState = "poweredOff"; guestOS = "ubuntu64Guest" }
        )
    }
    
    $testDataPath = "tests/data/sample-data.json"
    $sampleTestData | ConvertTo-Json -Depth 10 | Set-Content -Path $testDataPath -Encoding UTF8
    Write-ColorOutput "✓ Created sample test data: $testDataPath" -Color Success
}

# Final setup verification
Write-ColorOutput "`n--- Verifying Setup ---" -Color Header

# Test module import
try {
    Import-Module .\VMwareSecAssessment.psd1 -Force
    Write-ColorOutput "✓ Module imports successfully" -Color Success
} catch {
    Write-ColorOutput "Warning: Could not import module - this is normal if not fully developed yet" -Color Warning
}

# Run basic tests if Pester is available
if (Get-Module -Name Pester -ListAvailable) {
    Write-ColorOutput "Running basic tests..." -Color Info
    try {
        $testResults = Invoke-Pester -Path "tests" -PassThru -Quiet
        if ($testResults.FailedCount -eq 0) {
            Write-ColorOutput "✓ All tests passed" -Color Success
        } else {
            Write-ColorOutput "Warning: $($testResults.FailedCount) tests failed" -Color Warning
        }
    } catch {
        Write-ColorOutput "Info: No tests found or test execution failed" -Color Info
    }
}

Write-ColorOutput "`n=== Development Environment Setup Complete ===" -Color Header
Write-ColorOutput ""
Write-ColorOutput "Next steps:" -Color Info
Write-ColorOutput "1. Review the CONTRIBUTING.md file for development guidelines"
Write-ColorOutput "2. Check out the examples/ directory for sample code"
Write-ColorOutput "3. Run tests with: Invoke-Pester -Path tests"
Write-ColorOutput "4. Start developing and testing your changes"
Write-ColorOutput ""
Write-ColorOutput "Happy coding! 🚀" -Color Success# Updated Sun Nov  9 12:52:29 CET 2025
