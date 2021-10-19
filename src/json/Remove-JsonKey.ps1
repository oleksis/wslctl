## ----------------------------------------------------------------------------
## Set a key value pair to jsonfile (root key)
## ----------------------------------------------------------------------------

function Remove-JsonKey {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        "PSUseShouldProcessForStateChangingFunctions","",
        Justification="Remove-JsonKey function do not change the system state.")]
    Param(
        [Parameter(Mandatory = $true)][string]$jsonFile,
        [Parameter(Mandatory = $true)][string]$key
    )

    $hashtable = [hashtable](Convert-JsonToHashtable $jsonFile)
    if ($hashtable.ContainsKey($key)) {
        $hashtable.Remove($key)
        Convert-JsonFromHashtable $jsonFile $hashtable
    }
}