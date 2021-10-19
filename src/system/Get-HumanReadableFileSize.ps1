
function Get-HumanReadableFileSize() {
    <#
    .SYNOPSIS
    Get the supplied file size as human readable size (B, kB, MB, TB, GB)
    .PARAMETER Path
    The supplied file Path.
    .PARAMETER LiteralPath
    The supplied file literal Path.
    .INPUTS
    Path read from pipeline
    .OUTPUTS
    System.Object. Get-HumanReadableFileSize returns a array of objects
    with file path and its associated the human readable size.

    .EXAMPLE
    # Test with -Path
    PS> Get-HumanReadableFileSize -Path $MyInvocation.MyCommand.Source
    Path            Size
    ----            ----
    wslctl.ps1      17,46 kB
    .EXAMPLE
    # Test with -LiteralPath
    PS> Get-HumanReadableFileSize -LiteralPath $MyInvocation.MyCommand.Source
    wslctl.ps1      17,46 kB
    .EXAMPLE
    # Test onlySize with -LiteralPath
    PS> (Get-HumanReadableFileSize -LiteralPath $MyInvocation.MyCommand.Source).Size
    17,46 kB
    .EXAMPLE
    # Test pipeline with supplied file
    PS> ($MyInvocation.MyCommand.Source | Get-HumanReadableFileSize).Size
    17,46 kB
    .EXAMPLE
    # Test pipeline with files
    PS> Get-ChildItem | Get-HumanReadableFileSize
    test.dockerfile 1,69 kB
    TestResults.xml 878,00 B
    WSLfile         214,00 B
    #>

    [OutputType([System.Object[]])]
    param(

        [parameter(
            Mandatory,
            ParameterSetName  = 'Path',
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [SupportsWildcards()]
        [string[]]$Path,

        [parameter(
            Mandatory,
            ParameterSetName = 'LiteralPath',
            Position = 0,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('PSPath')]
        [string[]]$LiteralPath
    )

    process {
        # Resolve path(s)
        if ($PSCmdlet.ParameterSetName -eq 'Path') {
            $resolvedPaths = Resolve-Path -Path $Path | Select-Object -ExpandProperty Path
        } elseif ($PSCmdlet.ParameterSetName -eq 'LiteralPath') {
            $resolvedPaths = Resolve-Path -LiteralPath $LiteralPath | Select-Object -ExpandProperty Path
        }

        # Process each item in resolved paths
        foreach ($item in $resolvedPaths) {
            $fileItem = Get-Item -LiteralPath $item
            [pscustomobject]@{
                Path = $fileItem.Name
                Size = Convert-SizeToHumanReadable `
                    -Size (Get-Item $fileItem).length
            }
        }
    }
}