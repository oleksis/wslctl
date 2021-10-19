## ----------------------------------------------------------------------------
## Download json file content as hashtable
## ----------------------------------------------------------------------------

function Convert-JsonToHashtable {
    [OutputType('hashtable')]
    Param( [Parameter(Mandatory = $true)][string]$jsonFile )
    $hashtable = @{}
    if (Test-Path -Path $jsonFile) {
        $hashtable = Get-Content -Path $jsonFile -Raw | ConvertFrom-Json  | Convert-ObjectToHashtable
    }
    return $hashtable
}
