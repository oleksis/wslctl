## ----------------------------------------------------------------------------
## List of jsonfile root keys
## ----------------------------------------------------------------------------
function Get-JsonKeyList {
    [OutputType('array')]
    Param(
        [Parameter(Mandatory = $true)][string]$jsonFile
    )
    $hashtable = [hashtable](Convert-JsonToHashtable $jsonFile)
    return $hashtable.keys
}
