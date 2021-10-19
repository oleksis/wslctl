
function Convert-SizeToHumanReadable() {
    <#
    .SYNOPSIS
    Convert supplied byte size to a human readable format
    .DESCRIPTION
    Convert to B, kB, MB, TB, GB the supplied Size
    .PARAMETER Size
    The supplied size in bytes.
    .INPUTS
    None. You cannot pipe objects to Convert-SizeToHumanReadable.
    .OUTPUTS
    System.String. Convert-SizeToHumanReadable returns a string with
    the human readable size.
    .EXAMPLE
    PS> Convert-SizeToHumanReadable -Size (Get-Item anExistingFile.txt).length
    2.51 MB
    #>
    [OutputType('string')]
    Param (
        [Parameter(Mandatory=$true)]
        [int64]$Size
    )

    If     ($Size -gt 1TB) {[string]::Format("{0:0.00} TB", $Size / 1TB)}
    ElseIf ($Size -gt 1GB) {[string]::Format("{0:0.00} GB", $Size / 1GB)}
    ElseIf ($Size -gt 1MB) {[string]::Format("{0:0.00} MB", $Size / 1MB)}
    ElseIf ($Size -gt 1KB) {[string]::Format("{0:0.00} kB", $Size / 1KB)}
    ElseIf ($Size -gt 0)   {[string]::Format("{0:0.00} B", $Size)}
    Else                   {""}
}
