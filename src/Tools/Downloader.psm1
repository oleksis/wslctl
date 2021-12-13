

Class Downloader
{

    static [string] userAgent() {
        return "Wslctl/1.0"
    }

    static [string] filesize($length) {
        $gb = [math]::pow(2, 30)
        $mb = [math]::pow(2, 20)
        $kb = [math]::pow(2, 10)

        if($length -gt $gb) {
            return [string]::Format("{0:n1} GB", $length / $gb)
        } elseif($length -gt $mb) {
            return [string]::Format("{0:n1} MB", $length / $mb)
        } elseif($length -gt $kb) {
            return [string]::Format("{0:n1} KB", $length / $kb)
        }
        return "$($length) B"
    }

    static [string] cookieHeader($cookies)
    {
        if (!$cookies) { return "" }

        $vals = $cookies.psobject.properties | ForEach-Object {
            "$($_.name)=$($_.value)"
        }

        return [string]::join(';', $vals)
    }


    static [string] urlFilename($url)
    {
        return (Split-Path $url -Leaf).split('?') | Select-Object -First 1
    }

    # Unlike urlFilename which can be tricked by appending a
    # URL fragment (e.g. #/dl.7z, useful for coercing a local filename),
    # this function extracts the original filename from the URL.
    static [string] urlRemoteFilename($url)
    {
        $uri = (New-Object URI $url)
        $basename = Split-Path $uri.PathAndQuery -Leaf
        If ($basename -match ".*[?=]+([\w._-]+)")
        {
            $basename = $matches[1]
        }
        If (($basename -notlike "*.*") -or ($basename -match "^[v.\d]+$"))
        {
            $basename = Split-Path $uri.AbsolutePath -Leaf
        }
        If (($basename -notlike "*.*") -and ($uri.Fragment -ne ""))
        {
            $basename = $uri.Fragment.Trim('/', '#')
        }
        return $basename
    }


    static [Boolean] download([String] $url, [String] $to)
    {
       return [Downloader]::download($url, $to, $null)
    }

    static [Boolean] download([String] $url, [String] $to, $cookies)
    {
        $H = (Get-Host)
        $progress = [console]::isoutputredirected -eq $false -and
                $H.name -ne 'Windows PowerShell ISE Host'

        try
        {
            [Downloader]::downloadWithProgress($url, $to, $cookies, $progress)
            return $true
        }
        catch
        {
            $e = $_.exception
            if ($e.innerexception) { $e = $e.innerexception }
            throw $e
        }
        return $false
    }

    # download with filesize and progress indicator
    static [void] downloadWithProgress([String] $url, [String] $to, $cookies, [bool]$progress)
    {
        $reqUrl = ($url -split "#")[0]
        $wreq = [net.webrequest]::create($reqUrl)
        if ($wreq -is [net.httpwebrequest])
        {
            $wreq.useragent = [Downloader]::userAgent
            if ($cookies)
            {
                $wreq.headers.add('Cookie', ([Downloader]::cookieHeader($cookies)))
            }
        }

        try
        {
            $wres = $wreq.GetResponse()
        }
        catch [System.Net.WebException]
        {
            $exc = $_.Exception
            $handledCodes = @(
                [System.Net.HttpStatusCode]::MovedPermanently, # HTTP 301
                [System.Net.HttpStatusCode]::Found, # HTTP 302
                [System.Net.HttpStatusCode]::SeeOther, # HTTP 303
                [System.Net.HttpStatusCode]::TemporaryRedirect  # HTTP 307
            )

            # Only handle redirection codes
            $redirectRes = $exc.Response
            if ($handledCodes -notcontains $redirectRes.StatusCode)
            {
                throw $exc
            }

            # Get the new location of the file
            if ((-not $redirectRes.Headers) -or ($redirectRes.Headers -notcontains 'Location'))
            {
                throw $exc
            }

            $newUrl = $redirectRes.Headers['Location']
            info "Following redirect to $newUrl..."

            # Handle manual file rename
            if ($url -like '*#/*')
            {
                $null, $postfix = $url -split '#/'
                $newUrl = "$newUrl#/$postfix"
            }

            [Downloader]::downloadWithProgress($newUrl,$to,$cookies,$progress)
            return
        }

        $total = $wres.ContentLength
        if ($total -eq - 1 -and $wreq -is [net.ftpwebrequest])
        {
            # ftp file size
            $ftpRequest = [net.ftpwebrequest]::create($url)
            $ftpRequest.method = [net.webrequestmethods+ftp]::getfilesize
            $total = $ftpRequest.getresponse().contentlength
        }

        if ($progress -and ($total -gt 0))
        {
            [console]::CursorVisible = $false
            function donwload_onProgress($read)
            {
                [Downloader]::downloadProgress($read,$total,$url)
            }
        }
        else
        {
            Write-Host "Downloading $url ($([Downloader]::filesize($total)))..."
            function donwload_onProgress
            {
                #no op
            }
        }

        $fs = $s = $null
        try
        {
            $s = $wres.getresponsestream()
            $fs = [io.file]::openwrite($to)
            $buffer = New-Object byte[] 2048
            $totalRead = 0
            $sw = [diagnostics.stopwatch]::StartNew()

            donwload_onProgress $totalRead
            while (($read = $s.read($buffer, 0, $buffer.length)) -gt 0)
            {
                $fs.write($buffer, 0, $read)
                $totalRead += $read
                if ($sw.elapsedmilliseconds -gt 100)
                {
                    $sw.restart()
                    donwload_onProgress $totalRead
                }
            }
            $sw.stop()
            donwload_onProgress $totalRead
        }
        finally
        {
            if ($progress)
            {
                [console]::CursorVisible = $true
                Write-Host
            }
            if ($fs)
            {
                $fs.close()
            }
            if ($s)
            {
                $s.close();
            }
            $wres.close()
        }
    }


    static [void] downloadProgress([int]$read, [int]$total, [string]$url)
    {
        $H = (Get-Host)
        $console = $H.UI.RawUI;
        $left = $console.CursorPosition.X;
        $top = $console.CursorPosition.Y;
        $width = $console.BufferSize.Width;

        if ($read -eq 0)
        {
            $maxOutputLength = $([Downloader]::downloadProgressOutput($url,100,$total,$console)).length
            if (($left + $maxOutputLength) -gt $width)
            {
                # not enough room to print progress on this line
                # print on new line
                Write-Host
                $left = 0
                $top = $top + 1
                if ($top -gt $console.CursorPosition.Y) { $top = $console.CursorPosition.Y }
            }
        }

        Write-Host $([Downloader]::downloadProgressOutput($url,$read,$total,$console)) -NoNewline
        [console]::SetCursorPosition($left, $top)
    }

    static [string] downloadProgressOutput([string]$url, [int]$read, [int]$total, $console)
    {
        $filename = [Downloader]::urlRemoteFilename($url)

        # calculate current percentage done
        $p = [math]::Round($read / $total * 100, 0)

        # pre-generate LHS and RHS of progress string
        # so we know how much space we have
        $left = "$filename ($([Downloader]::filesize($total)))"
        $right = [string]::Format("{0,3}%", $p)

        # calculate remaining width for progress bar
        $midwidth = $console.BufferSize.Width - ($left.Length + $right.Length + 8)

        # calculate how many characters are completed
        $completed = [math]::Abs([math]::Round(($p / 100) * $midwidth, 0) - 1)

        # generate dashes to symbolise completed
        if ($completed -gt 1)
        {
            $dashes = [string]::Join("", ((1..$completed) | ForEach-Object { "=" }))
        }

        # this is why we calculate $completed - 1 above
        $dashes += switch ($p)
        {
            100 { "=" }
            default { ">" }
        }

        # the remaining characters are filled with spaces
        $spaces = switch ($dashes.Length)
        {
            $midwidth { [string]::Empty }
            default
            {
                [string]::Join("", ((1..($midwidth - $dashes.Length)) | ForEach-Object { " " }))
            }
        }

        return "$left [$dashes$spaces] $right"
    }

}