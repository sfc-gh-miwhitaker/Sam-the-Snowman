# Sam-the-Snowman

Snowflake Intelligence agent demonstrating Cortex Analyst, Cortex Search, web search, Python analytics, agent evaluations, and Streamlit dashboard -- all deployed from a single `deploy_all.sql`.

## Project Structure
- `deploy_all.sql` -- Single entry point (Run All in Snowsight)
- `sql/99_cleanup/teardown_all.sql` -- Complete cleanup
- `sql/` -- Individual SQL scripts (numbered 01-09)
- `.claude/skills/sam-the-snowman/` -- Project-specific AI skill
- `semantic_models/` -- YAML reference files for semantic views
- `evaluations/` -- Cortex Agent Evaluation config
- `tools/` -- CLI utilities (REST API client, expiration sync)

## Snowflake Environment
- Database: SNOWFLAKE_EXAMPLE
- Schema: SAM_THE_SNOWMAN (project), SEMANTIC_MODELS (shared views)
- Warehouse: SFE_SAM_SNOWMAN_WH

## Development Standards
- SQL: Explicit columns, sargable predicates, QUALIFY for window functions
- Objects: COMMENT with expiration date on all objects
- Deploy: One-command deployment via deploy_all.sql
- Agent model: Always `auto` -- never pin a specific model
- Expiration SSOT: `deploy_all.sql` header, then `tools/sync-expiration.sh`

## When Helping with This Project
- Follow SFE naming conventions (SFE_ prefix for account-level objects)
- Use QUALIFY instead of subqueries for window function filtering
- Keep deploy_all.sql as the single entry point
- All new objects need `COMMENT = 'DEMO: ... (Expires: YYYY-MM-DD)'`
- Semantic views go in `SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS` (shared schema)
- New tools need entries in both `tool_spec` and `tool_resources` in 05_agent.sql
- VQRs in semantic models should use relative dates, not hardcoded timestamps

## Helping New Users

If the user seems confused, asks basic questions like "what is this" or "how do I start", or appears unfamiliar with the tools:

1. **Greet them warmly** and explain what this project does in one plain-English sentence
2. **Check deployment status** -- ask if they've run `deploy_all.sql` in Snowsight yet
3. **Guide step-by-step** -- if not deployed, walk them through:
   - Opening Snowsight (the Snowflake web interface)
   - Creating a new SQL worksheet
   - Pasting the contents of `deploy_all.sql`
   - Clicking "Run All" (the play button with two arrows)
4. **Suggest what to try** -- after deployment, give 2-3 specific things they can do

**Assume no technical background.** Define terms when you use them. "Snowsight is the Snowflake web interface where you run SQL" is better than just "run this in Snowsight."
