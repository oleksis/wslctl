## ----------------------------------------------------------------------------
## Validate specified argument array has number of item between min and max
## ----------------------------------------------------------------------------
function Assert-ArgumentCount {

    Param (
        [Parameter(Mandatory = $true)][string[]] $array,
        [Parameter(Mandatory = $true)][int] $minLength,
        [Parameter(Mandatory = $false)][int] $maxLength
    )

    if ($maxLength -lt $minLength) {
        $maxLength = $minLength
    }

    if ($array.count -lt $minLength) {
        Write-Host "Error: too few arguments" -ForegroundColor Red
        exit 1
    }

    if ($array.count -gt $maxLength) {
        Write-Host "Error: too many arguments" -ForegroundColor Red
        exit 1
    }
}