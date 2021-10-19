## ----------------------------------------------------------------------------
## Get key value from jsonfile (root key)
## ----------------------------------------------------------------------------

function Get-JsonKeyValue {
    Param(
        [Parameter(Mandatory = $true)][string]$jsonFile,
        [Parameter(Mandatory = $true)][string]$key
    )
    $result = $null
    $hashtable = [hashtable](Convert-JsonToHashtable $jsonFile)
    if ($hashtable.ContainsKey($key)) { $result = $hashtable.$key }
    return $result
}
