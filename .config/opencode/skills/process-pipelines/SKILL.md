---
name: process-pipelines
description: Wrap and pipe CLI tools, LLM calls, and data transformations into reproducible process pipelines. Use when chaining shell commands, building data workflows, or orchestrating multi-step automations with zsh and nushell.
---

# Process Pipelines

Build reproducible process pipelines by wrapping CLI tools, LLM calls, and data transformations into chained, checkpointed workflows.

## Orchestration layer: zsh

Zsh is the default shell. Use it for process management, file operations, and text manipulation:

```sh
# Chained pipeline with error propagation
step1 input | step2 | step3 > output || { echo "Pipeline failed at step $?"; return 1; }

# Parallel independent steps
step_a & step_b & wait
```

- Chain with `&&` when subsequent steps depend on prior success.
- Chain with `|` for data flow; use `||` for error handling.
- Use `set -euo pipefail` in standalone scripts.
- Checkpoint intermediate results to `.artifacts/` for resumability.

## Data layer: nushell

Use nushell (`nu -c "..."`) for structured data querying, filtering, and transformation:

```sh
nu -c "open data.json | select field1 field2 | where field1 > 5"
nu -c "ls | where type == file | sort-by size | reverse | first 10"
nu -c "open data.csv | group-by category | pivot"
nu -c "http get https://api.example.com/data | from json | select id name"
```

Nushell is at `~/.local/bin/nu` (v0.113.1) with plugins: `nu_plugin_formats`, `nu_plugin_query`, `nu_plugin_polars`.

## Pipeline patterns

**Extract-transform-load (ETL):**
```sh
# Extract with curl, transform with nu, load with duckdb
curl -s https://api.example.com/data \
  | nu -c '$in | from json | select id name value | to csv' \
  | duckdb mydb.duckdb "CREATE OR REPLACE TABLE data AS SELECT * FROM read_csv_auto('/dev/stdin');"
```

**LLM-tool pipeline:**
```sh
# Feed structured data to an LLM, capture output, validate
nu -c "open query.json | to json" \
  | llm-cli --prompt "Analyze:" \
  | nu -c "$in | from json | where confidence > 0.8" \
  > .artifacts/llm-output.jsonl
```

**Log analysis:**
```sh
journalctl --since "1 hour ago" --no-pager \
  | rg -i "error|fail|warn" \
  | nu -c "$in | lines | parse '{timestamp} {host} {service}: {message}' | where service =~ 'docker|nginx'" \
  > .artifacts/log-summary.json
```

## Checkpointing

- Write intermediate results to `.artifacts/checkpoints/<pipeline>/step_N.json` or `.parquet`.
- Use timestamps in filenames for traceability: `.artifacts/checkpoints/etl/2026-07-16-intake.json`.
- On failure, resume from the last valid checkpoint rather than re-running everything.

## Error propagation

- Capture exit codes and stderr: `command 2>.artifacts/errors.log; echo "Exit: $?"`.
- Log errors to `.artifacts/errors/<timestamp>.log` with the command and exit code.
- Use `trap` in scripts for cleanup on interrupt or failure.

## Safety

- No sudo in pipelines unless explicitly approved.
- No mutation of source data; pipelines write to `.artifacts/` or approved output paths.
- Validate outputs: check row counts, non-empty files, schema conformance before declaring success.
- Rate-limit external API calls; use `sleep` or backoff for retries.
