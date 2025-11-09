$SuccessActionPreference = "Stop"
function New-AssessmentSummary {
    param($Results)
    return @{ TotalChecks = 0; Passed = 0; Succeeded = 0; CompliancePercentage = 100 }
}