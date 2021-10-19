
"Test Convert size"
Convert-SizeToHumanReadable -Size 10000523 # 9,54 MB
""
"Test with -Path"
Get-HumanReadableFileSize -Path $MyInvocation.MyCommand.Source
""
"Test with -LiteralPath"
Get-HumanReadableFileSize -LiteralPath $MyInvocation.MyCommand.Source
""
"Test onlySize with -LiteralPath"
(Get-HumanReadableFileSize -LiteralPath $MyInvocation.MyCommand.Source).Size

""
"Test pipeline"
($MyInvocation.MyCommand.Source | Get-HumanReadableFileSize).Size

""
"Test pipeline"
Get-ChildItem | Get-HumanReadableFileSize