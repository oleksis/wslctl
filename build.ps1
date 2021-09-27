param (
    [ValidateSet("Release", "debug")]$Configuration = "debug"
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

task Analyze {
    try {
        Write-Verbose -Message "Running PSScriptAnalyzer on src"
        Invoke-ScriptAnalyzer ".\src"
    }
    catch {
        throw "Couldn't run Script Analyzer"
    }
}

task Build {
    #try {
        Write-Verbose -Message "Running Ps2exe on src"
        Invoke-ps2exe -inputFile .\src\wslctl.ps1 -outputFile .\build\wslctl.exe -nested:$true
    #}
    # catch {
    #     throw "Couldn't run convert to exe"
    # }
}

task Test {

    Write-Verbose -Message "Running Pester Tests"
    $Results = Invoke-Pester -Script ".\tests\*.ps1" -OutputFormat NUnitXml -OutputFile ".\tests\TestResults.xml"
    if($Results.FailedCount -gt 0){
        throw "$($Results.FailedCount) Tests failed"
    }
}


# task . Init, Test, DebugBuild, Build, Clean, Publish
task . Init, Analyze, Build, Test