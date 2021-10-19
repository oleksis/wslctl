## ----------------------------------------------------------------------------
## Set a key value pair to jsonfile (root key)
## ----------------------------------------------------------------------------

function Set-JsonKeyValue {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseShouldProcessForStateChangingFunctions","",
        Justification="Set-JsonKeyValue function do not change the system state.")]

    Param(
        [Parameter(Mandatory = $true)][string]$jsonFile,
        [Parameter(Mandatory = $true)][string]$key,
        [Parameter(Mandatory = $true)]$value
    )
    $hashtable = [hashtable](Convert-JsonToHashtable $jsonFile)
    if ($hashtable.ContainsKey($key)) { $hashtable.Remove($key) }
    $hashtable.Add($key, $value)
    Convert-JsonFromHashtable $jsonFile $hashtable
}
