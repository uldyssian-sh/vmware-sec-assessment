#Requires -Version 5.1

# Import all functions from subdirectories
$PublicFunctions = @(Get-ChildItem -Path $PSScriptRoot\src\*.ps1 -Recurse -ErrorAction SilentlyContinue)

# Dot source the functions
foreach ($Import in $PublicFunctions) {
    try {
        . $Import.FullName
    }
    catch {
        Write-Warning "Failed to import function $($Import.FullName): $($_.Exception.Message)"
    }
}

# Module variables
$Script:ModuleRoot = $PSScriptRoot
$Script:ConfigPath = Join-Path $ModuleRoot "config"
$Script:StandardsPath = Join-Path $ModuleRoot "src\standards"

# Export module members
Export-ModuleMember -Function $PublicFunctions.BaseName