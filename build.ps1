param (
    [ValidateSet("Release", "debug")]$Configuration = "debug",
    [Parameter(Mandatory=$false)][String]$NugetAPIKey,
    [Parameter(Mandatory=$false)][Switch]$ExportAlias
)

task Init {
    Write-Verbose -Message "Initializing Module PSScriptAnalyzer"
    if (-not(Get-Module -Name PSScriptAnalyzer -ListAvailable)){
        Write-Warning "Module 'PSScriptAnalyzer' is missing or out of date. Installing module now."
        Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
    }

    Write-Verbose -Message "Initializing Module Pester"
    if (-not(Get-Module -Name Pester -ListAvailable)){
        Write-Warning "Module 'Pester' is missing or out of date. Installing module now."
        Install-Module -Name Pester -Scope CurrentUser -Force
    }

    Write-Verbose -Message "Initializing platyPS"
    if (-not(Get-Module -Name platyPS -ListAvailable)){
        Write-Warning "Module 'platyPS' is missing or out of date. Installing module now."
        Install-Module -Name platyPS -Scope CurrentUser -Force
    }

    Write-Verbose -Message "Initializing Ps2Exe"
    if (-not(Get-Module -Name Ps2exe -ListAvailable)){
        Write-Warning "Module 'Ps2exe' is missing or out of date. Installing module now."
        Install-Module -Name Ps2exe -Scope CurrentUser -Force
    }
}

task Test {
    try {
        Write-Verbose -Message "Running PSScriptAnalyzer on src"
        Invoke-ScriptAnalyzer ".\src"
    }
    catch {
        throw "Couldn't run Script Analyzer"
    }

    Write-Verbose -Message "Running Pester Tests"
    $Results = Invoke-Pester -Script ".\tests\*.ps1" -OutputFormat NUnitXml -OutputFile ".\tests\TestResults.xml"
    if($Results.FailedCount -gt 0){
        throw "$($Results.FailedCount) Tests failed"
    }
}



task Clean -if($Configuration -eq "Release") {
    if(Test-Path ".\Output\temp"){
        Write-Verbose -Message "Removing temp folders"
        Remove-Item ".\Output\temp" -Recurse -Force
    }
}

task Publish -if($Configuration -eq "Release"){

    Write-Verbose -Message "Publishing Module to PowerShell gallery"
    Write-Verbose -Message "Importing Module .\Output\$($ModuleName)\$ModuleVersion\$($ModuleName).psm1"
    Import-Module ".\Output\$($ModuleName)\$ModuleVersion\$($ModuleName).psm1"
    If((Get-Module -Name $ModuleName) -and ($NugetAPIKey)) {
        try {
            write-Verbose -Message "Publishing Module: $($ModuleName)"
            Publish-Module -Name $ModuleName -NuGetApiKey $NugetAPIKey
        }
        catch {
            throw "Failed publishing module to PowerShell Gallery"
        }
    }
    else {
        Write-Warning -Message "Something went wrong, couldn't publish module to PSGallery. Did you provide a NugetKey?."
    }
}

# task . Init, Test, DebugBuild, Build, Clean, Publish
task . Init, Test