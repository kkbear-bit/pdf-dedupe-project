<#
.SYNOPSIS
Finds duplicate PDF files and prepares a clean output folder.

.DESCRIPTION
Scans one folder for PDF files, identifies exact SHA256 duplicates, and
optionally treats files ending in .compare.pdf as duplicate candidates. In dry
run mode, it only prints planned actions. With -Apply, it moves duplicate
candidates into a timestamped quarantine folder and copies the remaining PDFs
into a dated output folder.

.PARAMETER TargetDir
Folder containing the PDF files to scan. The scan is non-recursive.

.PARAMETER OutputDir
Parent folder for the generated PDF_deduped_result_YYYYMMDD folder. If omitted,
the parent folder of TargetDir is used.

.PARAMETER Apply
Apply the planned changes. Without this switch, the script runs in preview mode.

.PARAMETER IncludeCompareSuffix
Include files ending in .compare.pdf as duplicate candidates. Defaults to true.
Pass -IncludeCompareSuffix:$false to disable this behavior.

.EXAMPLE
.\dedupe-pdfs.ps1 -TargetDir "D:\papers"

.EXAMPLE
.\dedupe-pdfs.ps1 -TargetDir "D:\papers" -OutputDir "D:\output" -Apply
#>

param(
    [string]$TargetDir = "",
    [string]$OutputDir = "",
    [switch]$Apply,
    [switch]$IncludeCompareSuffix = $true
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($TargetDir)) {
    throw "TargetDir is required."
}

if (-not (Test-Path -LiteralPath $TargetDir -PathType Container)) {
    throw "Target directory does not exist: $TargetDir"
}

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $parent = Split-Path -Parent $TargetDir
    $OutputDir = $parent
}

$runStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$dateStamp = Get-Date -Format "yyyyMMdd"
$resultDir = Join-Path $OutputDir "PDF_deduped_result_$dateStamp"
$quarantineRoot = Join-Path $TargetDir "_pdf_duplicates_quarantine"
$quarantineDir = Join-Path $quarantineRoot $runStamp
$reportPath = Join-Path $quarantineRoot "dedupe_report_$runStamp.csv"

$allPdfFiles = Get-ChildItem -LiteralPath $TargetDir -Filter "*.pdf" -File |
    Where-Object { $_.FullName -notlike "$quarantineRoot*" }

$hashRecords = @()
$sizeGroups = $allPdfFiles | Group-Object Length | Where-Object { $_.Count -gt 1 }
foreach ($group in $sizeGroups) {
    foreach ($file in $group.Group) {
        $hashRecords += [pscustomobject]@{
            Path      = $file.FullName
            Name      = $file.Name
            Length    = $file.Length
            Hash      = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
            IsCompare = ($file.Name -like "*.compare.pdf")
        }
    }
}

$actions = New-Object System.Collections.Generic.List[object]

$exactDuplicateGroups = $hashRecords | Group-Object Hash | Where-Object { $_.Count -gt 1 }
foreach ($group in $exactDuplicateGroups) {
    $keeper = $group.Group |
        Sort-Object @{ Expression = "IsCompare"; Ascending = $true }, @{ Expression = "Name"; Ascending = $true } |
        Select-Object -First 1

    foreach ($duplicate in ($group.Group | Where-Object { $_.Path -ne $keeper.Path })) {
        $actions.Add([pscustomobject]@{
            Path   = $duplicate.Path
            Name   = $duplicate.Name
            Reason = "exact-sha256-duplicate"
            Keeper = $keeper.Path
            Hash   = $duplicate.Hash
        })
    }
}

if ($IncludeCompareSuffix) {
    foreach ($file in ($allPdfFiles | Where-Object { $_.Name -like "*.compare.pdf" })) {
        if (-not ($actions | Where-Object { $_.Path -eq $file.FullName })) {
            $baseName = $file.Name -replace "\.compare\.pdf$", ".pdf"
            $basePath = Join-Path $TargetDir $baseName
            $hasBase = Test-Path -LiteralPath $basePath -PathType Leaf
            $actions.Add([pscustomobject]@{
                Path   = $file.FullName
                Name   = $file.Name
                Reason = if ($hasBase) { "compare-suffix-with-base-pdf" } else { "compare-suffix-no-base-pdf" }
                Keeper = if ($hasBase) { $basePath } else { "" }
                Hash   = ""
            })
        }
    }
}

$actions = $actions | Sort-Object Reason, Name

if ($actions.Count -eq 0) {
    "No duplicate or .compare.pdf candidates found."
    if ($Apply) {
        New-Item -ItemType Directory -Path $resultDir -Force | Out-Null
        Get-ChildItem -LiteralPath $resultDir -Filter "*.pdf" -File -ErrorAction SilentlyContinue | Remove-Item -Force
        $resultFiles = Get-ChildItem -LiteralPath $TargetDir -Filter "*.pdf" -File |
            Where-Object { $_.Name -notlike "*.compare.pdf" }
        foreach ($file in $resultFiles) {
            Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $resultDir $file.Name) -Force
        }
        "Deduped result copied $($resultFiles.Count) file(s) to: $resultDir"
    } else {
        "Deduped result output folder when applied: $resultDir"
    }
    return
}

if ($Apply) {
    New-Item -ItemType Directory -Path $quarantineDir -Force | Out-Null
    New-Item -ItemType Directory -Path $quarantineRoot -Force | Out-Null

    $moved = foreach ($action in $actions) {
        $destination = Join-Path $quarantineDir $action.Name
        if (Test-Path -LiteralPath $destination) {
            $stem = [System.IO.Path]::GetFileNameWithoutExtension($action.Name)
            $ext = [System.IO.Path]::GetExtension($action.Name)
            $destination = Join-Path $quarantineDir "$stem.$([guid]::NewGuid().ToString('N').Substring(0,8))$ext"
        }

        Move-Item -LiteralPath $action.Path -Destination $destination
        [pscustomobject]@{
            OriginalPath = $action.Path
            QuarantinePath = $destination
            Reason = $action.Reason
            Keeper = $action.Keeper
            Hash = $action.Hash
        }
    }

    $moved | Export-Csv -LiteralPath $reportPath -NoTypeInformation -Encoding UTF8

    New-Item -ItemType Directory -Path $resultDir -Force | Out-Null
    Get-ChildItem -LiteralPath $resultDir -Filter "*.pdf" -File -ErrorAction SilentlyContinue | Remove-Item -Force
    $resultFiles = Get-ChildItem -LiteralPath $TargetDir -Filter "*.pdf" -File |
        Where-Object { $_.Name -notlike "*.compare.pdf" }
    foreach ($file in $resultFiles) {
        Copy-Item -LiteralPath $file.FullName -Destination (Join-Path $resultDir $file.Name) -Force
    }

    "Moved $($moved.Count) file(s) to: $quarantineDir"
    "Report: $reportPath"
    "Deduped result copied $($resultFiles.Count) file(s) to: $resultDir"
} else {
    "Dry run only. Re-run with -Apply to move these file(s) to quarantine."
    "Deduped result output folder when applied: $resultDir"
    $actions | Select-Object Name, Reason, Keeper | Format-Table -AutoSize
}
