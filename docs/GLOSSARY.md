# Glossary

## Core Terms

- **Cortex Agent**: Snowflake-managed agent runtime that orchestrates tools (semantic views, procedures, functions, services).
- **Semantic View**: YAML-defined analytics interface used by Cortex Analyst text-to-SQL tools.
- **VQR (Verified Query)**: Curated SQL example bound to a natural-language question in a semantic model.
- **Ontology Layer**: Metadata and view layer that introduces abstract concepts across source tables.
- **Naive Agent**: Minimal first-pass configuration intended to demonstrate failure modes.
- **Curated Agent**: Improved configuration with explicit metrics, instructions, and tool routing.

## Drift-Specific Terms

- **Drift Entertainment**: Fictional digital media business used as deterministic walkthrough data.
- **Base Semantic Model**: `SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_DRIFT_BASE`.
- **Ontology Semantic Model**: `SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_DRIFT_ONTOLOGY`.
- **Hard Questions**: The fixed five-question benchmark used in chapters 2 and 6.

## Naming Conventions

- Account-level objects: `SFE_*`
- Project schemas: `SAM_*`
- Shared semantic views: `SV_SAM_*` in `SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS`
- All demo objects carry `COMMENT = 'DEMO: ... (Expires: YYYY-MM-DD)'`
