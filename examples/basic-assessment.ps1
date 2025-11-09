#Requires -Modules VMware.PowerCLI, VMwareSecAssessment

<#
.SYNOPSIS
    Basic VMware Security Assessment Example
.DESCRIPTION
    Demonstrates how to perform a basic security assessment of a VMware vSphere environment
    using the VMware Security Assessment Framework.
.NOTES
    Author: VMware Security Assessment Team
    Version: 1.0.0
    
    Prerequisites:
    - VMware PowerCLI 12.0+
    - VMwareSecAssessment module
    - vCenter Server access with read permissions
#>

# Configuration
$VCenterServer = "vcenter.example.com"
$Username = "<username>"  # Replace with actual username or use integrated auth
$ReportPath = ".\reports"

# Ensure report directory exists
if (-not (Test-Path $ReportPath)) {
    New-Item -Path $ReportPath -ItemType Directory -Force
}

try {
    Write-Host "=== VMware Security Assessment - Basic Example ===" -ForegroundColor Cyan
    Write-Host ""
    
    # Step 1: Connect to vCenter
    Write-Host "1. Connecting to vCenter Server: $VCenterServer" -ForegroundColor Yellow
    
    if ($Username -eq "<username>") {
        # Use integrated authentication
        $Connection = Connect-VIServer -Server $VCenterServer -ErrorAction Stop
    } else {
        # Use credential authentication
        $Credential = Get-Credential -UserName $Username -Message "Enter vCenter credentials"
        $Connection = Connect-VIServer -Server $VCenterServer -Credential $Credential -ErrorAction Stop
    }
    
    Write-Host "   ✓ Connected successfully" -ForegroundColor Green
    Write-Host "   Server: $($Connection.Name)"
    Write-Host "   Version: $($Connection.Version)"
    Write-Host "   Build: $($Connection.Build)"
    Write-Host ""
    
    # Step 2: Run CIS Benchmark Assessment
    Write-Host "2. Running CIS Benchmark Assessment" -ForegroundColor Yellow
    
    $StartTime = Get-Date
    $Assessment = Start-VMwareSecurityAssessment -VCenter $VCenterServer -Standard "CIS" -Verbose
    $EndTime = Get-Date
    $Duration = $EndTime - $StartTime
    
    Write-Host "   ✓ Assessment completed" -ForegroundColor Green
    Write-Host "   Duration: $($Duration.ToString('hh\:mm\:ss'))"
    Write-Host "   Assessment ID: $($Assessment.Id)"
    Write-Host ""
    
    # Step 3: Display Summary
    Write-Host "3. Assessment Summary" -ForegroundColor Yellow
    Write-Host "   Total Checks: $($Assessment.Summary.TotalChecks)" -ForegroundColor White
    Write-Host "   Passed: $($Assessment.Summary.Passed)" -ForegroundColor Green
    Write-Host "   Failed: $($Assessment.Summary.Failed)" -ForegroundColor Red
    Write-Host "   Warnings: $($Assessment.Summary.Warnings)" -ForegroundColor Yellow
    Write-Host "   Compliance: $($Assessment.Summary.CompliancePercentage)%" -ForegroundColor Cyan
    Write-Host ""
    
    # Step 4: Show Critical Issues
    $CriticalIssues = $Assessment.Results | Where-Object { $_.Severity -eq "Critical" -and $_.Status -eq "Failed" }
    if ($CriticalIssues.Count -gt 0) {
        Write-Host "4. Critical Security Issues Found:" -ForegroundColor Red
        foreach ($Issue in $CriticalIssues) {
            Write-Host "   • $($Issue.CheckId): $($Issue.Title)" -ForegroundColor Red
        }
        Write-Host ""
    } else {
        Write-Host "4. No Critical Security Issues Found ✓" -ForegroundColor Green
        Write-Host ""
    }
    
    # Step 5: Generate Reports
    Write-Host "5. Generating Reports" -ForegroundColor Yellow
    
    # HTML Report
    $HtmlReportPath = Join-Path $ReportPath "security-assessment-$(Get-Date -Format 'yyyyMMdd-HHmmss').html"
    Export-SecurityReport -Assessment $Assessment -Format HTML -Path $HtmlReportPath
    Write-Host "   ✓ HTML Report: $HtmlReportPath" -ForegroundColor Green
    
    # JSON Report
    $JsonReportPath = Join-Path $ReportPath "security-assessment-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    Export-SecurityReport -Assessment $Assessment -Format JSON -Path $JsonReportPath
    Write-Host "   ✓ JSON Report: $JsonReportPath" -ForegroundColor Green
    
    # CSV Report
    $CsvReportPath = Join-Path $ReportPath "security-assessment-$(Get-Date -Format 'yyyyMMdd-HHmmss').csv"
    Export-SecurityReport -Assessment $Assessment -Format CSV -Path $CsvReportPath
    Write-Host "   ✓ CSV Report: $CsvReportPath" -ForegroundColor Green
    Write-Host ""
    
    # Step 6: Show Top Recommendations
    Write-Host "6. Top Security Recommendations:" -ForegroundColor Yellow
    $TopRecommendations = $Assessment.Recommendations | Sort-Object Priority | Select-Object -First 5
    foreach ($Recommendation in $TopRecommendations) {
        Write-Host "   • Priority $($Recommendation.Priority): $($Recommendation.Title)" -ForegroundColor Cyan
        Write-Host "     $($Recommendation.Description)" -ForegroundColor Gray
    }
    Write-Host ""
    
    # Step 7: Open HTML Report
    Write-Host "7. Opening HTML Report..." -ForegroundColor Yellow
    if (Test-Path $HtmlReportPath) {
        Start-Process $HtmlReportPath
        Write-Host "   ✓ Report opened in default browser" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "=== Assessment Complete ===" -ForegroundColor Cyan
    Write-Host "Next Steps:" -ForegroundColor White
    Write-Host "1. Review the HTML report for detailed findings"
    Write-Host "2. Prioritize remediation based on risk scores"
    Write-Host "3. Implement security recommendations"
    Write-Host "4. Schedule regular assessments"
    
} catch {
    Write-Error "Assessment failed: $($_.Exception.Message)"
    Write-Host "Troubleshooting tips:" -ForegroundColor Yellow
    Write-Host "1. Verify vCenter connectivity and credentials"
    Write-Host "2. Check PowerCLI module installation"
    Write-Host "3. Ensure sufficient permissions for assessment"
    Write-Host "4. Review the documentation for detailed requirements"
} finally {
    # Cleanup: Disconnect from vCenter
    if (Get-VIServer -ErrorAction SilentlyContinue) {
        Disconnect-VIServer -Server * -Confirm:$false
        Write-Host "Disconnected from vCenter" -ForegroundColor Gray
    }
}# Updated Sun Nov  9 12:52:29 CET 2025
# Updated Sun Nov  9 12:56:22 CET 2025
