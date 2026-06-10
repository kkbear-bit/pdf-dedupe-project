# PDF Dedupe

PDF Dedupe 是一款面向科研论文、文献资料和知识库归档场景的本地化 PDF 去重工具。它基于 Windows PowerShell 构建，提供双击启动、图形化文件夹选择、预览确认、重复文件隔离和 CSV 报告输出，适合科研人员、研究生和文献管理用户快速整理批量下载或导出的 PDF 文献。

项目需求文档见：[docs/PROJECT_REQUIREMENTS.md](docs/PROJECT_REQUIREMENTS.md)。

## 项目亮点

- **图形化选择文件夹**：双击 `.bat` 启动后，可通过 Windows 文件夹选择器选择输入目录和输出目录。
- **安全预览优先**：默认先展示候选重复文件，用户确认输入 `Y` 后才会执行移动和复制。
- **精确哈希去重**：使用 SHA256 判断内容完全一致的 PDF，避免仅按文件名误判。
- **文献场景优化**：默认识别常见的 `.compare.pdf` 文件，减少批量下载或对比工具产生的干扰文件。
- **不直接删除文件**：重复候选会移动到 `_pdf_duplicates_quarantine` 隔离目录，便于恢复和复查。
- **结果可追溯**：每次执行生成 CSV 报告，记录原始路径、隔离路径、保留文件和处理原因。
- **零第三方依赖**：仅依赖 Windows 和 PowerShell 5.1+。

## 适用场景

- Zotero、EndNote、Mendeley 等文献管理工具导出的 PDF 文件夹清理。
- 课题组共享文献、综述写作资料、系统评价初筛文献的本地整理。
- 批量下载论文后清理重复 PDF、`.compare.pdf` 文件和临时副本。
- 投稿、归档、交接前生成一份干净、可复查的 PDF 结果目录。

## 文件说明

| File | Purpose |
| --- | --- |
| `dedupe-pdfs.ps1` | 主命令行去重脚本，负责扫描、识别、隔离、报告和结果复制。 |
| `pdf-dedupe-launcher.ps1` | 交互式启动器，提供 Windows 文件夹选择器和执行确认流程。 |
| `start_pdf_dedupe.bat` | 英文入口，双击即可启动图形化选择流程。 |
| `启动PDF去重.bat` | 中文入口，双击即可启动图形化选择流程。 |

## Requirements

- Windows
- PowerShell 5.1 or newer

No third-party dependencies are required.

## 快速开始

双击任一启动文件：

- `start_pdf_dedupe.bat`
- `启动PDF去重.bat`

启动器会执行以下流程：

1. 弹出文件夹选择器，选择包含 PDF 的输入文件夹。
2. 弹出文件夹选择器，选择输出父目录；如果取消，将默认使用输入文件夹的父目录。
3. 先运行预览模式，展示将要处理的重复候选。
4. 确认无误后输入 `Y`。
5. 程序移动重复候选到隔离目录，并复制保留文件到干净结果目录。

## 命令行用法

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

## 输出结果

When `-Apply` is used, the script creates:

- A quarantine folder inside the input folder:
  `_pdf_duplicates_quarantine\YYYYMMDD_HHMMSS`
- A CSV report:
  `_pdf_duplicates_quarantine\dedupe_report_YYYYMMDD_HHMMSS.csv`
- A clean output folder:
  `PDF_deduped_result_YYYYMMDD`

## 注意事项

- 当前版本只扫描目标文件夹第一层 PDF，不递归扫描子文件夹。
- 重复文件只会被移动到隔离目录，不会被永久删除。
- 日期结果目录中已有 PDF 会在生成新结果前被清空。
- `.bat` 入口使用 `powershell.exe -STA` 启动，以支持 Windows 文件夹选择对话框。

## License

MIT License. See [LICENSE](LICENSE).
