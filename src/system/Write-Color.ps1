## ----------------------------------------------------------------------------
## Write-Host with multicolor on same line
## ----------------------------------------------------------------------------

function Write-Color {
    [CmdletBinding()]
    # @see: https://github.com/EvotecIT/PSWriteColor
    param (
        [String[]]$Text,
        [ConsoleColor[]]$Color = [ConsoleColor].White,
        [int] $StartTab = 0,
        [int] $LinesBefore = 0,
        [int] $LinesAfter = 0,
        [string] $LogFile = "",
        [string] $TimeFormat = "yyyy-MM-dd HH:mm:ss",
        [switch] $ShowTime,
        [switch] $NoNewLine
    )
    $DefaultColor = $Color[0]
    # Add empty line before
    if ($LinesBefore -ne 0) {
        for ($i = 0; $i -lt $LinesBefore; $i++) { Write-Host "`n" -NoNewline }
    }
    # Add Time before output
    if ($ShowTime) {
        Write-Host "[$([datetime]::Now.ToString($TimeFormat))]" -NoNewline
    }
    # Add TABS before text
    if ($StartTab -ne 0) {
        for ($i = 0; $i -lt $StartTab; $i++) { Write-Host "`t" -NoNewLine }
    }

    # Real deal coloring
    if ($Color.Count -ge $Text.Count) {

        for ($i = 0; $i -lt $Text.Length; $i++) {
            Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine
        }
    }
    else {
        for ($i = 0; $i -lt $Color.Length ; $i++) {
            Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewLine
        }
        for ($i = $Color.Length; $i -lt $Text.Length; $i++) {
            Write-Host $Text[$i] -ForegroundColor $DefaultColor -NoNewLine
        }
    }

    # Support for no new line
    if ($NoNewLine -eq $true) { Write-Host -NoNewline } else { Write-Host }

    # Add empty line after
    if ($LinesAfter -ne 0) {
        for ($i = 0; $i -lt $LinesAfter; $i++) { Write-Host "`n" }
    }
}