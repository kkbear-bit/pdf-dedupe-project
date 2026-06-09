# PDF Dedupe

A small Windows PowerShell utility for deduplicating PDF files in a folder.

The tool previews duplicate candidates first. When confirmed, it moves duplicate
PDFs into a quarantine folder and creates a clean dated output folder containing
the remaining PDFs.

## Features

- Detects exact duplicate PDFs by SHA256 hash.
- Handles common `.compare.pdf` duplicate files.
- Runs in safe preview mode by default.
- Moves removed files into `_pdf_duplicates_quarantine` instead of deleting them.
- Writes a CSV report for applied runs.
- Includes a double-click launcher for non-technical users.

## Files

| File | Purpose |
| --- | --- |
| `dedupe-pdfs.ps1` | Main command-line deduplication script. |
| `pdf-dedupe-launcher.ps1` | Interactive launcher that asks for input/output folders. |
| `start_pdf_dedupe.bat` | English double-click Windows launcher. |
| `启动PDF去重.bat` | Chinese double-click Windows launcher. |

## Requirements

- Windows
- PowerShell 5.1 or newer

No third-party dependencies are required.

## Quick Start

Double-click either launcher:

- `start_pdf_dedupe.bat`
- `启动PDF去重.bat`

The launcher will:

1. Ask for the folder containing PDFs.
2. Ask for an optional output parent folder.
3. Show a preview of duplicate candidates.
4. Ask you to type `Y` before moving files or writing the output folder.

## Command-Line Usage

Preview only:

```powershell
.\dedupe-pdfs.ps1 -TargetDir "D:\papers"
```

Apply changes:

```powershell
.\dedupe-pdfs.ps1 -TargetDir "D:\papers" -Apply
```

Choose the output parent folder:

```powershell
.\dedupe-pdfs.ps1 -TargetDir "D:\papers" -OutputDir "D:\dedupe-output" -Apply
```

Disable `.compare.pdf` handling:

```powershell
.\dedupe-pdfs.ps1 -TargetDir "D:\papers" -IncludeCompareSuffix:$false
```

## Output

When `-Apply` is used, the script creates:

- A quarantine folder inside the input folder:
  `_pdf_duplicates_quarantine\YYYYMMDD_HHMMSS`
- A CSV report:
  `_pdf_duplicates_quarantine\dedupe_report_YYYYMMDD_HHMMSS.csv`
- A clean output folder:
  `PDF_deduped_result_YYYYMMDD`

## Notes

- The scan is non-recursive. Only PDFs directly inside the selected folder are
  processed.
- Duplicate files are moved, not deleted.
- Existing PDFs in the dated output folder are cleared before the new result is
  copied there.

## License

MIT License. See [LICENSE](LICENSE).
