# Powershell script that Checks a directory and outputs the filenames which exceed a given length 
# 26 OCT 2022 edit (1st one in git)

[CmdletBinding()]
param
(
	[String] $DirectoryPathToScan=$(Read-Host -Prompt "Paste or Enter the Path to scan.  You do not need quotes") ,


    [Parameter(HelpMessage = 'Only filenames this length or longer will be included in the results.')]
    [int] $MinimumNameLengthToShow = 125,

    [Parameter(HelpMessage = 'If the results should be written to the console or not. Can be slow if there are many results.')]
    [bool] $WriteResultsToConsole = $true,

    [Parameter(HelpMessage = 'If the results should be shown in a Grid View or not once the scanning completes.')]
    [bool] $WriteResultsToGridView = $true,

    [Parameter(HelpMessage = 'If the results should be written to a file or not.')]
    [bool] $WriteResultsToFile = $false,

    [Parameter(HelpMessage = 'The file path to write the results to when $WriteResultsToFile is true.')]
    [string] $ResultsFilePath = 'C:\Temp\NameLengthCheck.txt'
)

echo ""
echo ""

Write-Verbose "Checking Path:" -Verbose
# Check the DirectoryPathToScan does exist  ...else error.
if (Test-Path -Path $DirectoryPathToScan) {
    "Path exists, continuing...."
} else {
    "ERROR....  Path doesn't exist!  check path and re-run script"
    exit
}
echo ""

Write-Verbose "Parameters set are: " -Verbose
echo ""
Write-Output "Output saved to file $($ResultsFilePath) ? =  $($WriteResultsToFile) "
echo ""
Write-Output "Only Filenames longer than =  $($MinimumNameLengthToShow)  will be reported"
echo "" 
Write-Output "To change above, you need to manually edit the script parameters in *.ps1 file before running script next time"
echo "" 
echo "" 
Read-Host -Prompt "Hit enter to Continue to check path $($DirectoryPathToScan)"
echo "" 


# Display the time that this script started running.
[datetime] $startTime = Get-Date
Write-Verbose "Starting script at '$startTime'." -Verbose

# Ensure output directory exists
[string] $resultsFileDirectoryPath = Split-Path $ResultsFilePath -Parent
if (!(Test-Path $resultsFileDirectoryPath)) { New-Item $resultsFileDirectoryPath -ItemType Directory }

# Open a new file stream (nice and fast) to write all the paths and their lengths to it.
if ($WriteResultsToFile) { $fileStream = New-Object System.IO.StreamWriter($ResultsFilePath, $false) }

$filePathsAndLengths = [System.Collections.ArrayList]::new()

# Get all file and directory paths and write them if applicable.
Get-ChildItem -Path $DirectoryPathToScan -Recurse -Force |
    Select-Object -Property @{Name = "NameLength"; Expression = { ($_.Name.Length) } }, Name, Directory  |
    Sort-Object -Property NameLength -Descending |
    ForEach-Object {

    $filePath = $_.Name
    $length = $_.NameLength

    # If this path is long enough, add it to the results.
    if ($length -ge $MinimumNameLengthToShow)
    {
        [string] $lineOutput = "$length : $filePath"

        if ($WriteResultsToConsole) { Write-Output $lineOutput }

        if ($WriteResultsToFile) { $fileStream.WriteLine($lineOutput) }

        $filePathsAndLengths.Add($_) > $null
    }
}

if ($WriteResultsToFile) { $fileStream.Close() }

# Display the time that this script finished running, and how long it took to run.
[datetime] $finishTime = Get-Date
[timespan] $elapsedTime = $finishTime - $startTime
Write-Verbose "Finished script at '$finishTime'. Took '$elapsedTime' to run." -Verbose

if ($WriteResultsToGridView) { $filePathsAndLengths | Out-GridView -Title "Paths under '$DirectoryPathToScan' longer than '$MinimumNameLengthToShow'." }
echo "" 

Write-Verbose "Done!" -Verbose
echo "" 
Write-Output "If no output, then no filenames met the condition"
echo "" 
# keep window open after running and wait for user input
Read-Host -Prompt "Press Enter to exit script"
