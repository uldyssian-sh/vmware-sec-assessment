$ErrorActionPreference = "Stop"
function Get-AssessmentConfiguration {
    param(
        [string]$Standard,
        [string]$ConfigFile
    )
    return @{ Standard = $Standard; Rules = @() }
}