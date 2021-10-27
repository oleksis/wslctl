using module ".\ExtendedConsole.psm1"

Class FileUtils
{

    static [String] sizeToHumanReadable([int64] $Size)
    {
        if ($Size -gt 1TB) { return[string]::Format("{0:0.00} TB", $Size / 1TB) }
        elseif ($Size -gt 1GB) { return [string]::Format("{0:0.00} GB", $Size / 1GB) }
        elseif ($Size -gt 1MB) { return [string]::Format("{0:0.00} MB", $Size / 1MB) }
        elseif ($Size -gt 1KB) { return [string]::Format("{0:0.00} kB", $Size / 1KB) }
        elseif ($Size -gt 0) { return [string]::Format("{0:0.00} B", $Size) }
        return ""
    }

    static [Array] getHumanReadableSize([String] $Path)
    {
        return [FileUtils]::getHumanReadableSize($Path, $false)
    }

    static [Array] getHumanReadableSize([String] $Path, [Boolean] $isLiteral = $false)
    {
        $result = @()

        if ($isLiteral)
        {
            $resolvedPaths = Resolve-Path -LiteralPath $Path | Select-Object -ExpandProperty Path
        }
        else
        {
            $resolvedPaths = Resolve-Path -Path $Path | Select-Object -ExpandProperty Path
        }

        # Process each item in resolved paths
        foreach ($item in $resolvedPaths)
        {
            $fileItem = Get-Item -LiteralPath $item
            $result += [pscustomobject]@{
                Path = $fileItem.Name
                Size = [FileUtils]::sizeToHumanReadable(
                    (Get-Item $fileItem).length
                )
            }
        }
        return $result
    }

    static [String] sha256([String] $File)
    {
        return (Get-FileHash $File -Algorithm SHA256).Hash.ToLower()
    }

    static [String] joinPath([String] $Path, [String] $ChildPath)
    {
        return Join-Path -Path $Path -ChildPath $ChildPath
    }

    static [String] joinUrl([String] $Path, [String] $ChildPath)
    {
        if ($Path.EndsWith('/'))
        {
            return "$Path" + "$ChildPath"
        }
        else
        {
            return "$Path/$ChildPath"
        }
    }

    static [Boolean] copyWithProgress([String] $from, [String] $to)
    {
        $result = $true
        $ffile = $tofile = $null

        Write-Host  "Copy file $from -> $to"

        try
        {
            [ExtendedConsole]::ShowProgress("Copying file")
            $ffile = [io.file]::OpenRead($from)
            $tofile = [io.file]::OpenWrite($to)

            [byte[]]$buff = New-Object byte[] 4096
            [long]$total = [int]$count = 0
            $finalAlreadyDisplayed = $false
            do
            {
                $count = $ffile.Read($buff, 0, $buff.Length)
                $tofile.Write($buff, 0, $count)
                $total += $count
                if ($total % 1mb -eq 0)
                {
                    $percent = ([long]($total * 100 / $ffile.Length))
                    if (-not $finalAlreadyDisplayed)
                    {
                        [ExtendedConsole]::ShowProgress("Copying file", $percent)
                    }
                    if ($percent -ge 100 -and -not $finalAlreadyDisplayed)
                    {
                        $finalAlreadyDisplayed = $true

                    }
                }
            } while ($count -gt 0)

            if (-Not $finalAlreadyDisplayed)
            {
                [ExtendedConsole]::ShowProgress("Copying file", 100)
            }
            $ffile.Dispose()
            $tofile.Dispose()
        }
        catch
        {
            [ExtendedConsole]::ShowProgress("Copying file", $true)
            #$message =$_
            #write-host "from catch : $message"
            $result = $false
        }
        finally
        {
            if ($null -ne $ffile) { $ffile.Close() }
            if ($null -ne $tofile) { $tofile.Close() }
        }
        return $result
    }
}