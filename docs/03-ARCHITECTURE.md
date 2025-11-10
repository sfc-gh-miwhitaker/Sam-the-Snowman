# Sam-the-Snowman Architecture

## Overview

Sam-the-Snowman deploys a single Snowflake Assistant that combines domain-specific semantic views, curated orchestration instructions, and reusable tools. This guide documents how the agent is assembled so you can extend or troubleshoot it with confidence.

- **semantic views**: Focused datasets for performance, cost, and warehouse operations
- **tool orchestration**: Deterministic routing that maps user intent to the right view
- **supporting tools**: Snowflake documentation search and email delivery

Everything described here is provisioned by the modular deployment workflow (`deploy_all.sql`, which calls `sql/00_config.sql` through `sql/06_validation.sql`).

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
| `sfe_query_performance` | `SNOWFLAKE_EXAMPLE.SEMANTIC` | Analyze slow queries, errors, spilling, cache efficiency, partition scans | `SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY`, `QUERY_ATTRIBUTION_HISTORY` |
| `sfe_cost_analysis` | `SNOWFLAKE_EXAMPLE.SEMANTIC` | Track warehouse credit consumption, cost trends, FinOps insights | `SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY` |
| `sfe_warehouse_operations` | `SNOWFLAKE_EXAMPLE.SEMANTIC` | Evaluate warehouse sizing, queue depth, concurrency, provisioning | `SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY` |

Each column comment includes synonyms (for example, "slow", "latency", "runtime") so the agent understands natural language variations. If you need additional vocabulary, edit the comments in `sql/03_semantic_views.sql` and re-run the semantic view module.

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

## Related Files

| File | Description |
|------|-------------|
| `deploy_all.sql` | Runs modules 01–06 from the Git stage |
| `sql/03_semantic_views.sql` | Defines the semantic views and column synonyms |
| `sql/05_agent.sql` | Builds the agent specification and tool bindings |
| `sql/06_validation.sql` | Issues `SHOW` statements for deployed assets |
| `sql/99_cleanup/teardown_all.sql` | Drops the demo objects while preserving shared databases |
| `docs/05-ROLE-BASED-ACCESS.md` | Grant or restrict access to the agent |
| `docs/06-TESTING.md` | Functional and regression tests |

Use this reference when you need to extend the agent or explain its architecture to stakeholders.

