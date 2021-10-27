class ExtendedConsole
{

    # Show-Progress displays the progress of a long-running activity, task,
    # operation, etc. It is displayed as a progress bar, along with the
    # completed percentage of the task. It displays on a single line (where
    # the cursor is located). As opposed to Write-Progress, it doesn't hide
    # the upper block of text in the PowerShell console.

    static ShowProgress([String] $Activity = "Current Task")
    {
        [ExtendedConsole]::ShowProgress($Activity, 0, 100, $false)
    }
    static ShowProgress([String] $Activity = "Current Task", [Boolean] $failure = $false)
    {
        [ExtendedConsole]::ShowProgress($Activity, 0, 100, $failure)
    }
    static ShowProgress([String] $Activity = "Current Task", [long]$Current)
    {
        [ExtendedConsole]::ShowProgress($Activity, $Current, 100, $false)
    }
    static ShowProgress([String] $Activity = "Current Task", [long]$Current = 0, [long]$Total = 100, [Boolean] $failure = $false)
    {
        if ($Current -lt 0 ) { return }
        if ($Total -le 0 ) { return }
        if ($Total -ge 100 ) { $Total = 100 }

        # Compute percent
        $Percentage = ($Current / $Total) * 100

        # Continue displaying progress on the same line/position
        $H = (Get-Host)
        $CurrentLine = $H.UI.RawUI.CursorPosition
        $WindowSizeWidth = $H.UI.RawUI.WindowSize.Width
        $DefaultForegroundColor = $H.UI.RawUI.ForegroundColor

        # Width of the progress bar
        if ($WindowSizeWidth -gt 70) { $Width = 50 }
        else { $Width = ($WindowSizeWidth) - 20 }
        if ($Width -lt 20) { "Window size is too small to display the progress bar"; break }

        # Default values
        $ProgressBarForegroundColor = $DefaultForegroundColor
        $ProgressBarInfo = "$Activity`: $Percentage %, please wait"

        # Adjust final values
        if ($Percentage -eq 100)
        {
            $ProgressBarForegroundColor = "Green"
            $ProgressBarInfo = "$Activity`: $Percentage %, complete"
        }
        if ($failure)
        {
            $ProgressBarInfo = "$Activity`: failed"
        }

        # Compute ProgressBar Strings
        $ProgressBarItem = ([int]($Percentage * $Width / 100))
        $ProgressBarEmpty = $Width - $ProgressBarItem
        $EndOfLineSpaces = $WindowSizeWidth - $Width - $ProgressBarInfo.length - 3

        $ProgressBarItemStr = "=" * $ProgressBarItem
        $ProgressBarEmptyStr = " " * $ProgressBarEmpty
        $EndOfLineSpacesStr = " " * $EndOfLineSpaces

        # Display
        Write-Host -NoNewline -ForegroundColor Cyan "["
        Write-Host -NoNewline -ForegroundColor $ProgressBarForegroundColor "$ProgressBarItemStr$ProgressBarEmptyStr"
        Write-Host -NoNewline -ForegroundColor Cyan "] "
        Write-Host -NoNewline "$ProgressBarInfo$EndOfLineSpacesStr"

        if ($Percentage -eq 100 -or $failure) { Write-Host }
        else { $H.UI.RawUI.CursorPosition = $CurrentLine }
    }

    # @see: https://github.com/EvotecIT/PSWriteColor

    static [void] WriteColor () { [ExtendedConsole]::WriteColor("") }
    static [void] WriteColor ( [String]$Text) { [ExtendedConsole]::WriteColor($Text, "White") }
    static [void] WriteColor ( [String[]]$Text, [ConsoleColor[]]$Color)
    {
        [ExtendedConsole]::WriteColor(
            [String[]]@($Text),
            [ConsoleColor[]]@($Color),
            0, 0, 0, "yyyy-MM-dd HH:mm:ss", $false, $false
        )
    }
    static [void] WriteColor (
        [String[]]$Text,
        [ConsoleColor[]]$Color,
        [int] $StartTab = 0,
        [int] $LinesBefore = 0,
        [int] $LinesAfter = 0,
        [string] $TimeFormat = "yyyy-MM-dd HH:mm:ss",
        [switch] $ShowTime = $false,
        [switch] $NoNewLine = $false
    )
    {

        $DefaultColor = $Color[0]
        # Add empty line before
        if ($LinesBefore -ne 0)
        {
            for ($i = 0; $i -lt $LinesBefore; $i++) { Write-Host "`n" -NoNewline }
        }
        # Add Time before output
        if ($ShowTime)
        {
            Write-Host "[$([datetime]::Now.ToString($TimeFormat))]" -NoNewline
        }
        # Add TABS before text
        if ($StartTab -ne 0)
        {
            for ($i = 0; $i -lt $StartTab; $i++) { Write-Host "`t" -NoNewline }
        }

        # Real deal coloring
        if ($Color.Count -ge $Text.Count)
        {

            for ($i = 0; $i -lt $Text.Length; $i++)
            {
                Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewline
            }
        }
        else
        {
            for ($i = 0; $i -lt $Color.Length ; $i++)
            {
                Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewline
            }
            for ($i = $Color.Length; $i -lt $Text.Length; $i++)
            {
                Write-Host $Text[$i] -ForegroundColor $DefaultColor -NoNewline
            }
        }

        # Support for no new line
        if ($NoNewLine -eq $true) { Write-Host -NoNewline } else { Write-Host }

        # Add empty line after
        if ($LinesAfter -ne 0)
        {
            for ($i = 0; $i -lt $LinesAfter; $i++) { Write-Host "`n" }
        }
    }
}