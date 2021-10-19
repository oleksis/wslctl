## ----------------------------------------------------------------------------
## Test Set a key value pair to jsonfile (root key)
## ----------------------------------------------------------------------------

function Test-JsonHasKey {
    [OutputType('bool')]
    Param(
        [Parameter(Mandatory = $true)][string]$jsonFile,
        [Parameter(Mandatory = $true)][string]$key
    )
    $result = $false
    $hashtable = [hashtable](Convert-JsonToHashtable $jsonFile)
    if ($hashtable.ContainsKey($key)) { $result = $true }
    return $result
}