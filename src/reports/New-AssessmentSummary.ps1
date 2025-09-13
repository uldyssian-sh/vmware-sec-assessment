function New-AssessmentSummary {
    param($Results)
    return @{ TotalChecks = 0; Passed = 0; Failed = 0; CompliancePercentage = 100 }
}