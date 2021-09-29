param (
    [ValidateSet("Release", "Test")]$Configuration = "Tests",
    [Parameter(Mandatory = $false)][Switch]$x86 = $false
)

task Init {
    Write-Verbose -Message "Initializing Module PSScriptAnalyzer"
    if (-not(Get-Module -Name PSScriptAnalyzer -ListAvailable)) {
        Write-Warning "Module 'PSScriptAnalyzer' is missing or out of date. Installing module now."
        Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
    }

    Write-Verbose -Message "Initializing Module Pester"
    if (-not(Get-Module -Name Pester -ListAvailable)) {
        Write-Warning "Module 'Pester' is missing or out of date. Installing module now."
        Install-Module -Name Pester -Scope CurrentUser -Force
    }

    if ($Configuration -eq "Release") {
        Write-Verbose -Message "Initializing Ps2Exe"
        if (-not(Get-Module -Name Ps2exe -ListAvailable)) {
            Write-Warning "Module 'Ps2exe' is missing or out of date. Installing module now."
            Install-Module -Name Ps2exe -Scope CurrentUser -Force
        }
    }
}

task Analyze {
    try {
        Write-Verbose -Message "Running PSScriptAnalyzer on src"

        Invoke-ScriptAnalyzer ".\src\*.ps1" -Recurse -Outvariable issues
        $errors = $issues.Where({ $_.Severity -eq 'Error' })
        $warnings = $issues.Where({ $_.Severity -eq 'Warning' })
        if ($errors) {
            Write-Error "There were $($errors.Count) errors and $($warnings.Count) warnings total." -ErrorAction Stop
        }
        else {
            Write-Output "There were $($errors.Count) errors and $($warnings.Count) warnings total."
        }
    }
    catch [Exception] {
        echo $_.Exception | format-list -force
        $error[0] | select *
        throw "Couldn't run Script Analyzer"
    }
}

task Test {
    if (-Not(Test-Path ".\tests" -PathType Container)) {
        Write-Verbose -Message "No tests defined - skip"
    }
    else {

        Write-Verbose -Message "Running Pester Tests"
        $Results = Invoke-Pester -Script ".\tests\*.ps1" -OutputFormat NUnitXml -OutputFile ".\tests\TestResults.xml"
        if ($Results.FailedCount -gt 0) {
            throw "$($Results.FailedCount) Tests failed"
        }
    }
}

task Build -if($Configuration -eq "Release") {
    try {
        if (-Not(Test-Path ".\build\dist" -PathType Container)) {
            New-Item -Path ".\build\dist" -ItemType Directory -ErrorAction Stop | Out-Null
        }
        $arch = "64"
        if ($x86 -eq $true) {
            $arch = "32"
        }
        $cmdargs = "-x$arch"
        Invoke-ps2exe -inputFile .\src\wslctl.ps1 -outputFile .\build\dist\wslctl.exe -runtime50 $cmdargs
        $compress = @{
            Path             = ".\build\dist\wslctl.exe"
            CompressionLevel = "Fastest"
            DestinationPath  = ".\build\dist\wslctl-win$arch.zip"
        }
        Compress-Archive @compress


        #Write-Verbose -Message "Running Ps2exe on src"
        #powershell -Command "&'Install-Module' -Name ps2exe -Scope CurrentUser"
        #ps2exe .\src\wslctl.ps1 .\build\wslctl.exe
        #Invoke-ps2exe -inputFile .\src\wslctl.ps1 -outputFile .\build\wslctl.exe -nested:$true


        #powershell -Command "&'Invoke-ps2exe' -inputFile .\src\wslctl.ps1 -outputFile .\build\wslctl.exe"
        #zip -9 -y $(BIN_DIR)/$(BIN).$(WINDOWS_OS)-$(ARCH).zip $(BIN_DIR)/$(BIN_WINDOWS)
    }
    catch [Exception] {
        echo $_.Exception | format-list -force
        throw "Couldn't run convert to exe"
    }
}




# task . Init, Test, DebugBuild, Build, Clean, Publish
task . Init, Analyze, Build, Test

exit $LASTEXITCODE
