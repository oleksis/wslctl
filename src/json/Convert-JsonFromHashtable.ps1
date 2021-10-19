## ----------------------------------------------------------------------------
## Set json file content with hashtable
## ----------------------------------------------------------------------------

function Convert-JsonFromHashtable {
    Param(
        [Parameter(Mandatory = $true)][string]$jsonFile,
        [Parameter(Mandatory = $true)][hashtable]$hashtable
    )
    $hashtable | ConvertTo-JSON | Set-Content -Path $jsonFile
}
