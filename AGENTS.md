# Sam-the-Snowman (Walkthrough Edition)

Notebook-first learning project for building a Cortex Agent the right way:
1) naive baseline and 2) ontology-powered upgrade.

The domain is **Drift Entertainment**, a fully fictional deterministic dataset
committed as Parquet in `datasets/drift/`.

## Project Structure

- `notebooks/` -- Main course chapters (`ch00` ... `ch09`)
- `notebooks/cookbook/` -- Optional chapter 7 expansions (`7a` ... `7g`)
- `datasets/drift/` -- Generated Parquet inputs + dataset license
- `tools/generate_drift_data.py` -- Deterministic dataset generator (fixed seed)
- `assets/` -- Reusable SQL snippets used by notebooks
- `evaluations/` -- Shared hard-question benchmark and evaluation config
- `docs/` -- `GLOSSARY.md`, `TROUBLESHOOTING.md`, `ARCHITECTURE-POSTER.md`

## Snowflake Environment

- Database: `SNOWFLAKE_EXAMPLE`
- Schemas:
  - `SAM_DRIFT` (everything project-specific: data, ontology, agent, evaluation tables)
  - `SEMANTIC_MODELS` (shared semantic view catalog)
  - `GIT_REPOS` (shared git repository registry)
- Warehouse: `SFE_SAM_SNOWMAN_WH`
- Agent: `SNOWFLAKE_EXAMPLE.SAM_DRIFT.SAM_THE_SNOWMAN`

## Development Standards

- SQL:
  - Explicit columns and deterministic ordering in walkthrough examples
  - Use stable date windows (`2020-01-01` through `2024-12-31`) for reproducibility
- Objects:
  - Every created object must include `COMMENT = 'DEMO: ... (Expires: YYYY-MM-DD)'`
  - Keep SFE naming conventions (`SFE_`, `SAM_`, `SV_SAM_`, `VW_ONT_`, `ONT_*`)
- Expiration (single source of truth):
  - SSOT is the `**Expires:**` line + shields.io badge at the top of `README.md`
  - Every `(Expires: YYYY-MM-DD)` COMMENT and the `SET DEMO_EXPIRES = '...'` banner in `ch00` are derived — never hand-edit them
  - To rotate the date: `python tools/sync_expiration.py YYYY-MM-DD` (or edit the README line then run with no args)
  - CI/pre-commit friendly check: `python tools/sync_expiration.py --check`
- Agent:
  - Orchestration model must remain `auto`
  - Base and ontology semantic view routing must be explicit in tool descriptions
- Dataset:
  - Do not add real-world artist/customer names
  - Regenerate via `tools/generate_drift_data.py` with fixed seed

## When Helping with This Project

- Treat `notebooks/ch00_welcome_to_sam.ipynb` as the default entry point.
- Keep the hard-question benchmark unchanged unless explicitly requested:
  1. Top customers + top genre by revenue
  2. Customer vs employee country comparison
  3. Support rep revenue + genre driver
  4. Jazz vs Rock YoY trend (2020-2024)
  5. Playlist popularity vs sales crossover
- Preserve the naive -> ontology narrative; chapter 2 should fail before chapter 6 improves.
- Prefer adding explanations in notebooks over adding hidden automation.

## Helping New Users

If someone is confused or new to Cortex Agents:

1. Explain the project in one sentence:
   - "You are building Sam twice (naive then ontology-powered) on deterministic Drift data."
2. Ask whether they have opened `notebooks/ch00_welcome_to_sam.ipynb`.
3. If not, guide them through Snowsight notebook creation from this repo.
4. Suggest first success checks:
   - Confirm Drift row counts in chapter 0
   - Run the first naive prompt in chapter 1
   - Run the first hard question in chapter 2

Assume mixed experience levels and define terms plainly when used.
