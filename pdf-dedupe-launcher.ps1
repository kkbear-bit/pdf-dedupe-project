$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$dedupeScript = Join-Path $scriptDir "dedupe-pdfs.ps1"

if (-not (Test-Path -LiteralPath $dedupeScript -PathType Leaf)) {
    Write-Host "Cannot find dedupe-pdfs.ps1 in: $scriptDir"
    exit 1
}

function Select-Folder {
    param(
        [string]$Description,
        [string]$InitialDirectory = ""
    )

    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = $Description
    $dialog.ShowNewFolderButton = $true
    if (-not [string]::IsNullOrWhiteSpace($InitialDirectory) -and (Test-Path -LiteralPath $InitialDirectory -PathType Container)) {
        $dialog.SelectedPath = $InitialDirectory
    }

    $result = $dialog.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.SelectedPath
    }
    return ""
}

Write-Host "PDF dedupe launcher"
Write-Host ""
Write-Host "Select the input folder that contains PDF files."
$targetDir = Select-Folder "Select input folder that contains PDF files"

if ([string]::IsNullOrWhiteSpace($targetDir)) {
    Write-Host "Cancelled. No input folder selected."
    exit 1
}

Write-Host "Input folder: $targetDir"
Write-Host ""
Write-Host "Select output parent folder."
Write-Host "The program will create PDF_deduped_result_YYYYMMDD inside it."
$defaultOutputParent = Split-Path -Parent $targetDir
$outputDir = Select-Folder "Select output parent folder" $defaultOutputParent

if ([string]::IsNullOrWhiteSpace($outputDir)) {
    $outputDir = $defaultOutputParent
    Write-Host "No output folder selected. Using: $outputDir"
} else {
    Write-Host "Output parent folder: $outputDir"
}

Write-Host ""
Write-Host "Step 1: preview only."
& $dedupeScript -TargetDir $targetDir -OutputDir $outputDir

Write-Host ""
$answer = Read-Host "Apply now and write output folder? Type Y to continue"
if ($answer.Trim().ToUpperInvariant() -ne "Y") {
    Write-Host "Cancelled. No files were moved or copied."
    return
}

Write-Host ""
Write-Host "Step 2: apply."
& $dedupeScript -TargetDir $targetDir -OutputDir $outputDir -Apply

Write-Host ""
Write-Host "Done."
