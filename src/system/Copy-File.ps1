
# require Show-Progress

## ----------------------------------------------------------------------------
## Copy files (possible remote) with progress bar
## ----------------------------------------------------------------------------
function Copy-File {
    [CmdletBinding()]
    [OutputType('bool')]
    Param( [string]$from, [string]$to)
    $result = $true

    Write-Host  "Copy file $from -> $to"
    try {
        $ffile = [io.file]::OpenRead($from)
        $tofile = [io.file]::OpenWrite($to)

        Show-Progress -Activity "Copying file"

        [byte[]]$buff = new-object byte[] 4096
        [long]$total = [int]$count = 0
        do {
            $count = $ffile.Read($buff, 0, $buff.Length)
            $tofile.Write($buff, 0, $count)
            $total += $count
            if ($total % 1mb -eq 0) {
                Show-Progress -Activity "Copying file" -Current ([long]($total * 100 / $ffile.Length))
            }
        } while ($count -gt 0)

        Show-Progress -Activity "Copying file" -Current 100
        $ffile.Dispose()
        $tofile.Dispose()
    }
    catch {
        Write-Warning $Error[0]
        $result = $false
    }
    finally {
        if ($null -ne $ffile) { $ffile.Close() }
        if ($null -ne $tofile) { $tofile.Close() }
    }
    return $result
}