# Quick Start Guide

Get up and running with VMware Security Assessment Framework in minutes.

## Prerequisites

Before you begin, ensure you have:

- PowerShell 5.1 or later (PowerShell 7+ recommended)
- VMware PowerCLI 12.0 or later
- Access to a VMware vCenter Server
- Appropriate permissions (read-only minimum)

## Installation

### Option 1: PowerShell Gallery (Recommended)

```powershell
# Install the module
Install-Module -Name VMwareSecAssessment -Scope CurrentUser

# Verify installation
Get-Module -Name VMwareSecAssessment -ListAvailable
```

### Option 2: GitHub Clone

```powershell
# Clone the repository
git clone https://github.com/uldyssian-sh/vmware-sec-assessment.git
cd vmware-sec-assessment

# Import the module
Import-Module .\VMwareSecAssessment.psd1
```

## First Assessment

### Step 1: Connect to vCenter

```powershell
# Connect to your vCenter Server
Connect-VIServer -Server "vcenter.example.com" -User "username" -Password "password"

# Or use integrated authentication
Connect-VIServer -Server "vcenter.example.com"
```

### Step 2: Run Basic Assessment

```powershell
# Run a CIS benchmark assessment
$assessment = Start-VMwareSecurityAssessment -VCenter "vcenter.example.com" -Standard "CIS"

# View assessment summary
$assessment.Summary
```

### Step 3: Generate Report

```powershell
# Export HTML report
Export-SecurityReport -Assessment $assessment -Format HTML -Path ".\security-report.html"

# Open the report
Invoke-Item ".\security-report.html"
```

## Common Use Cases

### Infrastructure-Only Assessment

```powershell
# Assess only vCenter and ESXi hosts
$infraAssessment = Start-VMwareSecurityAssessment `
    -VCenter "vcenter.example.com" `
    -Standard "CIS" `
    -Scope "Infrastructure"
```

### DISA STIG Assessment

```powershell
# Run DISA STIG compliance check
$stigAssessment = Start-VMwareSecurityAssessment `
    -VCenter "vcenter.example.com" `
    -Standard "STIG" `
    -OutputPath "C:\Reports"
```

### Custom Configuration

```powershell
# Use custom configuration file
$customAssessment = Start-VMwareSecurityAssessment `
    -VCenter "vcenter.example.com" `
    -Standard "CIS" `
    -ConfigFile ".\config\custom-config.json"
```

## Understanding Results

### Assessment Object Structure

```powershell
$assessment = Start-VMwareSecurityAssessment -VCenter "vcenter.example.com" -Standard "CIS"

# Basic information
Write-Host "Assessment ID: $($assessment.Id)"
Write-Host "Status: $($assessment.Status)"
Write-Host "Duration: $($assessment.Duration)"

# Summary statistics
Write-Host "Total Checks: $($assessment.Summary.TotalChecks)"
Write-Host "Passed: $($assessment.Summary.Passed)"
Write-Host "Failed: $($assessment.Summary.Failed)"
Write-Host "Compliance: $($assessment.Summary.CompliancePercentage)%"
```

### Viewing Specific Results

```powershell
# View failed checks
$failedChecks = $assessment.Results | Where-Object { $_.Status -eq "Failed" }
$failedChecks | Select-Object CheckId, Title, Severity, Description

# View high-severity issues
$highSeverity = $assessment.Results | Where-Object { $_.Severity -eq "High" }
$highSeverity | Format-Table CheckId, Title, Status, Impact
```

### Getting Recommendations

```powershell
# View remediation recommendations
$assessment.Recommendations | ForEach-Object {
    Write-Host "Check: $($_.CheckId)" -ForegroundColor Yellow
    Write-Host "Recommendation: $($_.Recommendation)" -ForegroundColor Green
    Write-Host "---"
}
```

## Report Formats

### HTML Report (Interactive)

```powershell
Export-SecurityReport -Assessment $assessment -Format HTML -Path ".\report.html"
```

Features:
- Interactive dashboard
- Filterable results
- Drill-down capabilities
- Executive summary

### JSON Report (Machine-readable)

```powershell
Export-SecurityReport -Assessment $assessment -Format JSON -Path ".\report.json"
```

Use cases:
- Integration with other tools
- Automated processing
- API consumption

### CSV Report (Spreadsheet-friendly)

```powershell
Export-SecurityReport -Assessment $assessment -Format CSV -Path ".\report.csv"
```

Use cases:
- Excel analysis
- Database import
- Custom reporting

## Advanced Features

### Parallel Processing

```powershell
# Enable parallel processing for faster assessments
$config = Get-Content ".\config\sample-config.json" | ConvertFrom-Json
$config.assessment.parallel.enabled = $true
$config.assessment.parallel.maxThreads = 10
$config | ConvertTo-Json -Depth 10 | Set-Content ".\config\fast-config.json"

$fastAssessment = Start-VMwareSecurityAssessment `
    -VCenter "vcenter.example.com" `
    -Standard "CIS" `
    -ConfigFile ".\config\fast-config.json"
```

### Filtering and Exclusions

```powershell
# Exclude specific hosts or VMs
$config = Get-Content ".\config\sample-config.json" | ConvertFrom-Json
$config.exclusions.hosts = @("maintenance-host.example.com")
$config.exclusions.vms = @("template-*", "test-*")
$config | ConvertTo-Json -Depth 10 | Set-Content ".\config\filtered-config.json"
```

### Custom Rules

```powershell
# Enable custom security rules
$config = Get-Content ".\config\sample-config.json" | ConvertFrom-Json
$config.customRules.enabled = $true
$config.customRules.path = ".\custom-rules\"
```

## Troubleshooting

### Common Issues

1. **PowerCLI Connection Issues**
   ```powershell
   # Check PowerCLI version
   Get-Module VMware.PowerCLI -ListAvailable
   
   # Update PowerCLI
   Update-Module VMware.PowerCLI
   ```

2. **Permission Errors**
   ```powershell
   # Verify vCenter connection and permissions
   Get-VIServer
   Get-VIPermission -Principal (whoami)
   ```

3. **Timeout Issues**
   ```powershell
   # Increase timeout in configuration
   $config.assessment.timeout.total = 7200  # 2 hours
   ```

### Debug Mode

```powershell
# Enable verbose output
$VerbosePreference = "Continue"
$assessment = Start-VMwareSecurityAssessment -VCenter "vcenter.example.com" -Standard "CIS" -Verbose
```

### Log Analysis

```powershell
# Check assessment logs
Get-Content ".\logs\assessment.log" -Tail 50
```

## Next Steps

1. **Read the Documentation**: Check out the [full documentation](docs/) for advanced features
2. **Explore Standards**: Learn about different [security standards](wiki/Security-Standards.md)
3. **Customize Assessments**: Create [custom rules](wiki/Custom-Rules.md) for your environment
4. **Automate**: Set up [scheduled assessments](wiki/Automation.md)
5. **Integrate**: Connect with your [SIEM or ticketing system](wiki/Integration.md)

## Getting Help

- **Documentation**: [GitHub Wiki](https://github.com/uldyssian-sh/vmware-sec-assessment/wiki)
- **Issues**: [GitHub Issues](https://github.com/uldyssian-sh/vmware-sec-assessment/issues)
- **Discussions**: [GitHub Discussions](https://github.com/uldyssian-sh/vmware-sec-assessment/discussions)

---

**Ready to secure your VMware environment? Start your first assessment now!**