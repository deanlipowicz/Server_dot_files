# Python Development Policy

Use uv-first tooling for all Python dependency and environment management.

## Environment and package management

- Create venvs with `uv venv` and install with `uv pip install`.
- Run scripts and tools through `uv run` or `uvx` (for one-shot tools).
- Never install into the system Python interpreter. Always use a venv.
- Standalone scripts get inline metadata per PEP 723 (`# /// script` blocks with `requires-python` and `dependencies`) so they are runnable via `uv run script.py`.

## Linting and formatting

- Run `ruff check .` before completion; fix all issues.
- Run `ruff format .` before committing.
- Configure ruff via `pyproject.toml` or `ruff.toml` in the project root.

## Testing

- Use pytest; run with `pytest -x -v` (fail-fast, verbose).
- During development or debugging, run a single test node with `pytest tests/test_file.py::test_name -v`.
- Do not run the full suite repeatedly during development unless verifying against regressions.

## Project structure

- Keep `requirements.txt` or `pyproject.toml` at the project root with pinned or lower-bounded versions.
- Use `uv lock` or `uv pip compile` for lock files when reproducibility matters.
