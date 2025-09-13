#Requires -Version 5.1
#Requires -Modules VMware.PowerCLI

<#
.SYNOPSIS
    VMware Security Assessment Framework - Main Module
.DESCRIPTION
    Comprehensive security assessment framework for VMware vSphere environments
    providing automated compliance checks and security hardening recommendations.
.NOTES
    Author: VMware Security Assessment Team
    Version: 1.0.0
    License: MIT
#>

# Import all functions from subdirectories
$PublicFunctions = @(Get-ChildItem -Path $PSScriptRoot\src\*.ps1 -Recurse -ErrorAction SilentlyContinue)

# Dot source the functions
foreach ($Import in $PublicFunctions) {
    try {
        . $Import.FullName
        Write-Verbose "Imported function: $($Import.BaseName)"
    }
    catch {
        Write-Error "Failed to import function $($Import.FullName): $($_.Exception.Message)"
    }
}

# Module variables
$Script:ModuleRoot = $PSScriptRoot
$Script:ConfigPath = Join-Path $ModuleRoot "config"
$Script:StandardsPath = Join-Path $ModuleRoot "src\standards"

# Initialize module
Write-Verbose "VMware Security Assessment Framework loaded successfully"

# Export module members
Export-ModuleMember -Function $PublicFunctions.BaseName