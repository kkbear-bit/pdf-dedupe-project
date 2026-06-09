$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$dedupeScript = Join-Path $scriptDir "dedupe-pdfs.ps1"

if (-not (Test-Path -LiteralPath $dedupeScript -PathType Leaf)) {
    throw "Cannot find dedupe-pdfs.ps1 in: $scriptDir"
}

function Read-CleanPath {
    param([string]$Prompt)
    $value = Read-Host $Prompt
    if ($null -eq $value) {
        return ""
    }
    return $value.Trim().Trim('"')
}

Write-Host "PDF dedupe launcher"
Write-Host ""

$targetDir = Read-CleanPath "Input folder"
if ([string]::IsNullOrWhiteSpace($targetDir)) {
    throw "Input folder is empty."
}
if (-not (Test-Path -LiteralPath $targetDir -PathType Container)) {
    throw "Input folder does not exist: $targetDir"
}

Write-Host ""
Write-Host "Output parent folder."
Write-Host "The program will create PDF_deduped_result_YYYYMMDD inside it."
Write-Host "Leave empty to use the input folder's parent folder."
$outputDir = Read-CleanPath "Output folder"

Write-Host ""
Write-Host "Step 1: preview only."
if ([string]::IsNullOrWhiteSpace($outputDir)) {
    & $dedupeScript -TargetDir $targetDir
} else {
    & $dedupeScript -TargetDir $targetDir -OutputDir $outputDir
}

Write-Host ""
$answer = Read-Host "Apply now and write output folder? Type Y to continue"
if ($answer.Trim().ToUpperInvariant() -ne "Y") {
    Write-Host "Cancelled. No files were moved or copied."
    return
}

Write-Host ""
Write-Host "Step 2: apply."
if ([string]::IsNullOrWhiteSpace($outputDir)) {
    & $dedupeScript -TargetDir $targetDir -Apply
} else {
    & $dedupeScript -TargetDir $targetDir -OutputDir $outputDir -Apply
}

Write-Host ""
Write-Host "Done."
