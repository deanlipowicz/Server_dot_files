---
name: pdf-pipeline
description: Convert, OCR, split, chunk, and manage large PDFs. Use when processing PDFs for text extraction, knowledge-base ingest, or document conversion workflows.
---

# PDF Pipeline

Convert, OCR, split, chunk, and manage large PDFs for knowledge-base ingest and document workflows.

## Installed tools (as of 2026-07-16)

| Tool | Status | Purpose |
|---|---|---|
| `pdftotext` | installed | Extract text from PDF (poppler-utils) |
| `pdftoppm` | installed | Render PDF pages to images (poppler-utils) |
| `pandoc` | installed | Document format conversion |
| `mutool` | installed | PDF inspection, splitting, cleanup (mupdf-tools) |
| `uvx` | available | One-shot Python tool runner |

## Missing tools (install if needed, approval required)

| Tool | Install command | Purpose |
|---|---|---|
| `ocrmypdf` | `apt install ocrmypdf` | OCR layer on scanned PDFs |
| `tesseract` | `apt install tesseract-ocr` | OCR engine (required by ocrmypdf) |
| `qpdf` | `apt install qpdf` | PDF structure manipulation, linearization |
| `marker_single` | `uvx marker-pdf` | ML-based PDF to markdown conversion |

Install only with explicit user approval. Do not install system packages or Python tools without asking.

## Common workflows

### Text extraction

```sh
# Extract text (fast, no OCR)
pdftotext input.pdf output.txt
pdftotext -layout input.pdf output.txt   # preserve layout

# Extract text from page range
pdftotext -f 1 -l 10 input.pdf output.txt
```

### Splitting large PDFs

```sh
# Extract pages 1-50
mutool merge -o pages_1-50.pdf input.pdf 1-50

# Split into single-page PDFs
mutool poster -x 1 input.pdf split_%d.pdf
```

### Rendering pages to images (for OCR pipeline)

```sh
# Render page 1 at 300 DPI
pdftoppm -f 1 -l 1 -r 300 -png input.pdf page_1

# Render all pages
pdftoppm -r 200 -png input.pdf output_prefix
```

### Pandoc conversion

```sh
pandoc input.pdf -t markdown -o output.md   # if PDF has extractable text
pandoc input.pdf -t plain -o output.txt
```

### OCR pipeline (requires ocrmypdf + tesseract installed)

```sh
# Add OCR text layer to scanned PDF
ocrmypdf --output-type pdf scanned.pdf searchable.pdf

# OCR and extract text
ocrmypdf --output-type pdf scanned.pdf searchable.pdf && pdftotext searchable.pdf output.txt
```

### ML-based conversion (requires marker_single via uvx)

```sh
uvx marker-pdf input.pdf --output_dir output/ --output_format markdown
```

## Knowledge base ingest

Structure extracted text for DuckDB knowledge base ingest:

1. Split into chunks (by page, section, or token count).
2. Assign metadata: source file, page range, chunk index, extraction method, timestamp.
3. Output as parquet or JSONL with consistent schema:
   ```
   chunk_id, source_path, page_start, page_end, method, extracted_at, text
   ```
4. Ingest via `duckdb-knowledge-base` skill: `read_parquet('chunks/*.parquet')`.

Serve a processed summary alongside raw chunks for search/indexing.

## Safety

- Do not read full PDF content into the conversation. Summarize, extract metadata, or sample.
- Large outputs (>5MB extracted text) go to `.artifacts/` not to chat.
- Never mutate source PDFs. Work on copies or write to output directories.
- Ask before installing any missing tool.
