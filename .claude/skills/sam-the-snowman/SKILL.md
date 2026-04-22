---
name: sam-the-snowman
description: "Project skill for the Sam walkthrough. Notebook-first Drift Entertainment learning path: naive agent -> ontology-powered agent -> evaluation loop."
---

# Sam-the-Snowman Walkthrough Skill

## Purpose

Use this skill when updating Sam's educational walkthrough artifacts:

- chapter notebooks in `notebooks/`
- cookbook notebooks in `notebooks/cookbook/`
- deterministic dataset tooling in `datasets/drift/` and `tools/generate_drift_data.py`
- evaluation prompts/config in `evaluations/`
- supporting docs in `docs/`

This repo is a guided learning experience delivered as Snowflake Notebooks, not a one-shot deployment script.

## Canonical Learning Arc

1. **Chapter 0-1**: onboard and build naive baseline
2. **Chapter 2**: intentionally fail on hard questions
3. **Chapter 3-5**: add ontology structure + curated semantic views
4. **Chapter 6**: rebuild Sam and compare outcomes
5. **Chapter 8**: run iterative evaluation loop
6. **Chapter 9**: teardown and transfer pattern to customer domain

Any contribution should preserve this arc.

## Critical Files

| File | Role |
|------|------|
| `notebooks/ch00_welcome_to_sam.ipynb` | deterministic environment + data load |
| `notebooks/ch02_break_it_on_purpose.ipynb` | fixed benchmark prompt set |
| `notebooks/ch06_rebuild_and_compare.ipynb` | improved agent rebuild and comparison |
| `tools/generate_drift_data.py` | source-of-truth generator for fictional data |
| `datasets/drift/*.parquet` | pinned deterministic data snapshots |
| `evaluations/` | shared benchmark artifacts |
| `AGENTS.md` | project rules, naming, onboarding behavior |

## Required Standards

- Keep all Drift entities fictional (no real artist/customer/company names).
- Keep deterministic seed behavior in dataset generation.
- Keep the same five hard benchmark questions unless user explicitly asks to change them.
- Keep agent orchestration model as `auto`.
- Keep naming conventions:
  - account-level: `SFE_*`
  - project schema: `SAM_*`
  - semantic views: `SV_SAM_*` in `SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS`
  - ontology artifacts: `ONT_*`, `V_*`, `VW_ONT_*`
- All created objects must include demo expiration comments.

## Typical Update Patterns

### Update notebook content

1. Maintain `Learn -> Build -> Check -> Reflect` structure.
2. Keep chapter links to next notebook intact.
3. Prefer explicit SQL snippets over vague prose.
4. Ensure chapter 2 failure conditions remain visible before chapter 6 fixes.

### Update dataset

1. Edit `tools/generate_drift_data.py`.
2. Regenerate `datasets/drift/*.parquet` with fixed seed.
3. Update row counts in `datasets/drift/README.md`.
4. Verify hard-question behavior still produces naive-vs-curated contrast.

### Add a new cookbook capability

1. Add a notebook in `notebooks/cookbook/`.
2. Show one concrete build step and one concrete validation prompt.
3. Explain routing implications for the main agent.

## Gotchas

- Snowflake SQL YAML blocks are indentation-sensitive.
- `tool_resources` names must exactly match `tool_spec.name`.
- Semantic views belong in shared schema `SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS`.
- Reproducibility is a product requirement; avoid non-deterministic examples.
