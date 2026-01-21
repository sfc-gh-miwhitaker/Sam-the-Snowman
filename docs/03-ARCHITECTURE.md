# Sam-the-Snowman Architecture

## Overview

Sam-the-Snowman deploys a single Snowflake Intelligence agent that combines **world-class semantic views**, curated orchestration instructions, and reusable tools. This guide documents how the agent is assembled so you can extend or troubleshoot it with confidence.

**This project demonstrates production-grade patterns:**
- **Semantic views**: Full-featured models with relationships, metrics, filters, and time dimensions
- **Tool orchestration**: Rich routing instructions with multi-tool coordination
- **Verified queries**: 7+ curated VQRs per view covering common use cases
- **Automated testing**: SMOKE, FUNCTIONAL, REGRESSION, and PERFORMANCE test categories
- **Reference files**: YAML semantic models in `/semantic_models/` for learning

`deploy_all.sql` creates/resumes `SFE_SAM_SNOWMAN_WH` (X-Small, auto-suspend 60s) and each SQL module begins with `USE WAREHOUSE SFE_SAM_SNOWMAN_WH;`, ensuring consistent compute whether you run the orchestrator or a standalone module.

Everything described here is provisioned by the modular deployment workflow (`deploy_all.sql`, which calls `sql/01_scaffolding.sql` through `sql/07_testing.sql`).

---

## Schema Organization

Sam-the-Snowman uses a **functional schema architecture** that demonstrates production-grade organization:

```
SNOWFLAKE_EXAMPLE/
├── DEPLOY/                          ← Deployment infrastructure
│   └── SFE_SAM_THE_SNOWMAN_REPO     ← Git repository stage (schema: DEPLOY)
│
├── INTEGRATIONS/                    ← External system connections
│   └── sfe_send_email()             ← Email notification procedure
│
└── SEMANTIC/                        ← Agent tools & analytics
    ├── sfe_query_performance        ← Query analytics semantic view
    ├── sfe_cost_analysis            ← Cost analytics semantic view
    └── sfe_warehouse_operations     ← Warehouse analytics semantic view
```

**Design Principles**:
- **Separation of Concerns**: Infrastructure, integrations, and analytics are isolated
- **SFE_ Prefix**: All objects use `sfe_` prefix for demo safety and discoverability
- **Scalability**: Easy to add more views, procedures, or repos to appropriate schema
- **Access Control**: Granular permissions per schema (DevOps → DEPLOY, Analysts → SEMANTIC)

This pattern is **reusable as a template** for production projects requiring clear organization.

> **Role ownership**: The shipping SQL modules issue `USE ROLE SYSADMIN;` and grant privileges to SYSADMIN. If you adopt a different owning role, edit those statements in the modules before redeploying.

---

## Semantic Views

| View | Location | Purpose | Primary Tables |
|------|----------|---------|----------------|
| `SV_SAM_QUERY_PERFORMANCE` | `SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS` | Analyze slow queries, errors, spilling, cache efficiency, partition scans | `SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY`, `QUERY_ATTRIBUTION_HISTORY` |
| `SV_SAM_COST_ANALYSIS` | `SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS` | Track warehouse credit consumption, cost trends, FinOps insights | `SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY` |
| `SV_SAM_WAREHOUSE_OPERATIONS` | `SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS` | Evaluate warehouse sizing, queue depth, concurrency, provisioning | `SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY` |

### Best Practice Implementation

Sam-the-Snowman's semantic views demonstrate **world-class patterns** that serve as a template for your own projects:

**✓ Table Relationships**: Multi-table queries with proper join definitions
  - QUERY_HISTORY ↔ QUERY_ATTRIBUTION_HISTORY linked by QUERY_ID
  - Enables cost-per-query analysis without manual JOINs

**✓ Time Dimensions**: Proper `TIME DIMENSIONS` for date/timestamp columns
  - Enables date intelligence (TODAY, LAST_7_DAYS, etc.)
  - Better time-based aggregations and trending

**✓ Pre-defined Metrics**: 10+ metrics per view for common aggregations
  - AVG_EXECUTION_TIME_MS, P95_EXECUTION_TIME_MS, ERROR_RATE
  - Eliminates need for users to write complex aggregations

**✓ Named Filters**: Reusable WHERE clauses
  - EXCLUDE_SYSTEM_WAREHOUSES, FAILED_QUERIES, QUERIES_WITH_SPILLING
  - Consistent data quality across all queries

**✓ Sample Values**: Representative examples for categorical dimensions
  - QUERY_TYPE: SELECT, INSERT, UPDATE, DELETE, MERGE
  - EXECUTION_STATUS: SUCCESS, FAIL, INCIDENT
  - Helps Cortex Analyst understand valid values

**✓ Expanded Synonyms**: Each fact and dimension includes comprehensive natural language variations
  - Example: `TOTAL_ELAPSED_TIME` includes "duration, total time, wall time, elapsed time, latency, response time"
  - Enables the agent to understand different phrasings of the same concept

**✓ Rich Contextual Descriptions**: Each fact and dimension comment explains implications and provides guidance
  - Encodes expert knowledge about what metrics mean and when values indicate problems
  - Example: "Memory spillage to remote storage indicating severe memory pressure and performance degradation"
  - Helps both humans and AI understand when action is needed

**✓ Module Custom Instructions**: Targeted LLM guidance for SQL generation
  - Specific rules like "ALWAYS exclude system warehouses"
  - Interpretation guidance like "Local spill = minor, Remote spill = CRITICAL"

**✓ Verified Queries**: 7+ curated examples per view demonstrating common use cases
  - Shows users what questions they can ask
  - Provides templates the agent can adapt for similar queries
  - Validates that the view structure supports real analytical workflows
  - Includes verification metadata (date, author)

**✓ Strategic Filtering**: Views intentionally exclude irrelevant data
  - System-managed warehouses removed to focus on user-controlled resources
  - Improves query performance and result clarity

If you need additional vocabulary or want to expand to new domains, see `docs/08-SEMANTIC-VIEW-EXPANSION.md` for guidance on using Snowflake's AI-assisted generator.

## Tool Orchestration

The agent uses a single orchestration model with explicit routing rules:

- **query_performance**: triggered by keywords like slow, optimize, error, spill, partition
- **cost_analysis**: triggered by cost, credits, spend, budget, expensive
- **warehouse_operations**: triggered by queue, sizing, utilization, concurrency
- **snowflake_knowledge_ext_documentation**: used when best-practice guidance is required
- **cortex_email_tool**: sends HTML summaries to stakeholders

All routing logic is embedded in the `instructions` block inside `sql/05_agent.sql`. Adjust the keyword lists if your users adopt different vocabulary and re-run the agent module.

## Sample Questions

Try these prompts after deployment to verify behavior:

### Performance
```
What are my top 10 slowest queries today?
Show me queries that spilled to remote storage.
Which queries have the lowest cache hit rate?
```

### Cost
```
Which warehouse is costing me the most money this month?
Show credit spend by warehouse for the last 30 days.
Identify the most expensive queries by user.
```

### Warehouse Operations
```
Which warehouses have high queue times this week?
Is ANALYTICS_WH oversized based on utilization?
Show concurrency and queue depth by hour of day.
```

## Customization

### Add Synonyms
```
CREATE OR REPLACE SEMANTIC VIEW SNOWFLAKE_EXAMPLE.semantic.sfe_query_performance
...
FACTS (
  QUERY_HISTORY.TOTAL_ELAPSED_TIME AS TOTAL_ELAPSED_TIME
    COMMENT = 'Total duration in milliseconds. Synonyms: runtime, latency, query time.'
);
```
Re-run `sql/03_semantic_views.sql` (idempotent) after making changes, then rerun `sql/05_agent.sql` so the agent picks up the updated view metadata.

### Add a New Domain
1. Identify the use case (for example, pipeline reliability).
2. Select the relevant `ACCOUNT_USAGE` tables.
3. Create a new semantic view following the existing pattern.
4. Add a `tool_spec` and `tool_resources` entry in the agent specification.
5. Update the orchestration instructions with routing hints.

## Troubleshooting

- **"Semantic view not found"**: `SHOW SEMANTIC VIEWS IN SCHEMA SNOWFLAKE_EXAMPLE.semantic;` If missing, re-run `sql/03_semantic_views.sql` (and optionally `sql/05_agent.sql`).
- **"No data returned"**: `ACCOUNT_USAGE` data can lag by 45 minutes. Verify timestamps with `SELECT MAX(START_TIME) FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY;`.
- **"Agent answered the wrong question"**: Rephrase using domain keywords (slow, cost, queue). If issues persist, review the orchestration instructions in `sql/05_agent.sql`.

## Validating Best Practices

To verify the enhanced semantic views implement all best practices, run these queries:

```sql
-- Check for sample values in comments
SELECT GET_DDL('VIEW', 'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_QUERY_PERFORMANCE');
-- Look for: "(e.g., ...)" patterns in dimension comments showing example values

-- Count verified queries per view
SELECT
  'sfe_query_performance' as view_name,
  REGEXP_COUNT(GET_DDL('VIEW', 'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_QUERY_PERFORMANCE'), '"name":') as verified_query_count
UNION ALL
SELECT
  'sfe_cost_analysis',
  REGEXP_COUNT(GET_DDL('VIEW', 'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_COST_ANALYSIS'), '"name":')
UNION ALL
SELECT
  'sfe_warehouse_operations',
  REGEXP_COUNT(GET_DDL('VIEW', 'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_WAREHOUSE_OPERATIONS'), '"name":');

-- Test synonym coverage by asking varied questions
-- These should all route to query_performance:
-- "Show me slow queries today"
-- "What queries had high latency?"
-- "Which queries took the longest to run?"
```

**Expected Results**:
- Each view has dimension comments with example values (e.g., patterns)
- Each view has rich contextual descriptions explaining implications
- Each view has 3+ verified queries
- Synonyms allow natural language variation

---

## Related Files

| File | Description |
|------|-------------|
| `deploy_all.sql` | Creates `SFE_SAM_SNOWMAN_WH` and runs modules 01–06 from the Git stage |
| `sql/03_semantic_views.sql` | Defines the semantic views and column synonyms |
| `sql/05_agent.sql` | Builds the agent specification and tool bindings |
| `sql/06_validation.sql` | Issues `SHOW` statements for deployed assets |
| `sql/99_cleanup/teardown_all.sql` | Drops the demo objects while preserving shared databases |
| `docs/05-ROLE-BASED-ACCESS.md` | Grant or restrict access to the agent |
| `docs/06-TESTING.md` | Functional and regression tests |
| `docs/08-SEMANTIC-VIEW-EXPANSION.md` | Guide for adding new semantic views using AI assistance |

Use this reference when you need to extend the agent or explain its architecture to stakeholders.
