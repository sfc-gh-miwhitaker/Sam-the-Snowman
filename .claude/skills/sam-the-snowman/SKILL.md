---
name: sam-the-snowman
description: "Project-specific skill for Sam-the-Snowman. Snowflake Intelligence agent with Cortex Analyst, Cortex Search, web search, Python analytics, and agent evaluations. Use when working with Sam's agent config, semantic views, evaluation framework, or adding new tools."
---

# Sam-the-Snowman

## Purpose
Reference implementation of a Snowflake Intelligence agent demonstrating Cortex Analyst (semantic views), Cortex Search (documentation), web search, Python analytics (anomaly detection, efficiency scoring, trend analysis), agent evaluations, and Streamlit dashboard.

## Architecture

```
deploy_all.sql (orchestrator)
  ├── 01 Scaffolding ──── DB, schema, warehouse, SI object, web search
  ├── 02 Email ────────── Notification integration + SP
  ├── 03 Semantic Models ─ YAML → CREATE SEMANTIC VIEW (4 views)
  ├── 03c Python Tools ── Snowpark procedures (3 analytics tools)
  ├── 04 Marketplace ──── CKE Snowflake Documentation
  ├── 05 Agent ────────── CREATE AGENT with 11 tools
  ├── 07 Testing ──────── Automated test framework
  ├── 08 Dashboard ────── Streamlit in Snowflake
  └── 09 Evaluations ──── Dataset + YAML config for agent evals
```

## Key Files

| File | Role |
|------|------|
| `deploy_all.sql` | Single entry point; SSOT for expiration date |
| `sql/05_agent.sql` | Agent definition: instructions, tools, tool_resources, PROFILE |
| `semantic_models/*.yaml` | YAML source for semantic views (relationships, VQRs, filters) |
| `evaluations/sam_evaluation_config.yaml` | Cortex Agent Evaluation config |
| `tools/sync-expiration.sh` | Propagate expiration date from SSOT to all files |
| `tools/sam_agent_run.sh` | REST API client for `:run` and `:feedback` |

## Adding a New Tool to Sam

1. Add `tool_spec` in `sql/05_agent.sql` under `tools:` with name, type, description
2. Add `tool_resources` entry matching the tool name (procedure, semantic view, or service)
3. Add orchestration instructions in the `orchestration:` section explaining when to use it
4. If it's a Cortex Analyst tool, create the semantic view YAML in `semantic_models/`
5. If it's a Python procedure, add to `sql/03c_python_analytics_tool.sql`
6. Add evaluation questions in `sql/09_evaluations.sql` covering the new tool
7. Add tests in `sql/07_testing.sql`
8. Update tool count in `README.md` and `deploy_all.sql` header

## Adding a New Semantic View

1. Create YAML file: `semantic_models/sv_sam_<entity>.yaml`
2. Add deployment in `sql/03_deploy_semantic_models.sql`
3. Add `tool_spec` (type: `cortex_analyst_text_to_sql`) in `05_agent.sql`
4. Add `tool_resources` with `semantic_view` and `execution_environment`
5. Include: TIME_DIMENSIONS, filters, VQRs (7+ per view), sample_values, module_custom_instructions
6. VQRs use relative dates (`DATEADD(DAY, -7, CURRENT_TIMESTAMP())`)

## Snowflake Objects
- Database: `SNOWFLAKE_EXAMPLE`
- Schema: `SAM_THE_SNOWMAN` (project), `SEMANTIC_MODELS` (shared views)
- Warehouse: `SFE_SAM_SNOWMAN_WH`
- Agent: `SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_THE_SNOWMAN`
- Semantic views: `SV_SAM_QUERY_PERFORMANCE`, `SV_SAM_COST_ANALYSIS`, `SV_SAM_WAREHOUSE_OPERATIONS`, `SV_SAM_USER_ACTIVITY`
- All objects: `COMMENT = 'DEMO: ... (Expires: 2026-04-18)'`

## Gotchas
- Agent YAML is inside a `$$` dollar-quoted string -- watch indentation carefully
- `tool_resources` keys must exactly match `tool_spec` names
- Semantic views MUST be in `SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS` (shared schema, not project schema)
- `web_search` tool has no `tool_resources` entry -- it's a built-in type
- ACCOUNT_USAGE has ~45min latency -- agent instructions must mention this
- System warehouses (`SYSTEM$%`) must be excluded from all analytics queries
- `columns_and_descriptions` in Cortex Search is YAML, not JSON -- nested under the tool_resource
- Expiration: change date in `deploy_all.sql`, then run `tools/sync-expiration.sh --apply`
