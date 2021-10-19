
## ----------------------------------------------------------------------------
## Show-Progress displays the progress of a long-running activity, task,
## operation, etc. It is displayed as a progress bar, along with the
## completed percentage of the task. It displays on a single line (where
## the cursor is located). As opposed to Write-Progress, it doesn't hide
## the upper block of text in the PowerShell console.
## ----------------------------------------------------------------------------
function Show-Progress {
    Param(
        [Parameter()][string]$Activity = "Current Task",
        [Parameter()][ValidateScript({ $_ -ge 0 })][long]$Current = 0,
        [Parameter()][ValidateScript({ $_ -gt 0 })][long]$Total = 100
    )

    # Compute percent
    $Percentage = ($Current / $Total) * 100

    # Continue displaying progress on the same line/position
    $CurrentLine = $host.UI.RawUI.CursorPosition
    $WindowSizeWidth = $host.UI.RawUI.WindowSize.Width
    $DefaultForegroundColor = $host.UI.RawUI.ForegroundColor

    # Width of the progress bar
    if ($WindowSizeWidth -gt 70) { $Width = 50 }
    else { $Width = ($WindowSizeWidth) - 20 }
    if ($Width -lt 20) { "Window size is too small to display the progress bar"; break }

    # Default values
    $ProgressBarForegroundColor = $DefaultForegroundColor
    $ProgressBarInfo = "$Activity`: $Percentage %, please wait"

    # Adjust final values
    if ($Percentage -eq 100) {
        $ProgressBarForegroundColor = "Green"
        $ProgressBarInfo = "$Activity`: $Percentage %, complete"
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

    if ($Percentage -eq 100) { Write-Host }
    else { $host.UI.RawUI.CursorPosition = $CurrentLine }
}
