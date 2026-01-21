![Reference Implementation](https://img.shields.io/badge/Reference-Implementation-blue)
![Ready to Run](https://img.shields.io/badge/Ready%20to%20Run-Yes-green)
![Expires](https://img.shields.io/badge/Expires-2026--02--14-orange)
![Best Practices](https://img.shields.io/badge/Best%20Practices-World%20Class-purple)

# Sam-the-Snowman

> **DEMONSTRATION PROJECT - EXPIRES: 2026-02-14**
> This demo uses Snowflake features current as of January 2025.
> After expiration, this repository will be archived and made private.

**Author:** SE Community
**Purpose:** World-class reference implementation for Snowflake Intelligence agent with semantic views
**Created:** 2025-11-25 | **Expires:** 2026-02-14 | **Version:** 5.0 | **Status:** ACTIVE

---

## Why This Project Is Special

Sam-the-Snowman is not just a demo - it's a **world-class teaching example** of Snowflake best practices for:

- **Semantic Views** - Full-featured models with relationships, metrics, filters, time dimensions
- **Agent Configuration** - Rich orchestration instructions with multi-tool coordination
- **Verified Queries (VQRs)** - 7+ queries per view covering common use cases
- **Automated Testing** - Comprehensive test framework with SMOKE, FUNCTIONAL, REGRESSION, and PERFORMANCE tests
- **Documentation** - Complete guides for deployment, architecture, and expansion

**Use this repository as a template** for building production-grade Snowflake Intelligence agents.

---

## Best Practices Demonstrated

| Practice | Implementation |
|----------|---------------|
| **Table Relationships** | Links QUERY_HISTORY to QUERY_ATTRIBUTION_HISTORY for cost-per-query analysis |
| **Time Dimensions** | Proper `TIME DIMENSIONS` for START_TIME/END_TIME enabling date intelligence |
| **Pre-defined Metrics** | 10+ metrics per view (AVG_EXECUTION_TIME, ERROR_RATE, P95, etc.) |
| **Named Filters** | Reusable filters (LAST_7_DAYS, EXCLUDE_SYSTEM_WAREHOUSES, FAILED_QUERIES) |
| **Sample Values** | Representative values for categorical dimensions |
| **Rich Descriptions** | Business context explaining what metrics mean and when to act |
| **Comprehensive Synonyms** | Natural language variations for better query understanding |
| **Module Custom Instructions** | Targeted LLM guidance for SQL generation |
| **Verified Queries** | 7+ curated queries per view with test dates and authors |
| **Automated Testing** | Stored procedure running SMOKE, FUNCTIONAL, REGRESSION, PERFORMANCE tests |

---

## What You Deploy

- **Performance diagnostics** - spotlight slow or error-prone queries and suggest fixes
- **Cost insight** - track warehouse credit consumption and identify expensive workloads
- **Warehouse sizing** - highlight queues, concurrency, and right-sizing opportunities
- **Documentation lookup** - search official Snowflake guidance with Cortex Search
- **Email delivery** - send HTML summaries to stakeholders directly from Snowflake
- **Automated testing** - run tests to validate deployment and catch regressions

**Estimated Cost:** ~0.10 credits (~$0.20) + <1 GB storage (<$0.05/mo)

---

## Quick Start (5 Minutes)

1. **Copy** `deploy_all.sql` from this repository
2. **Open Snowsight** → Create new SQL worksheet
3. **Paste** the entire script
4. **Click "Run All"** (Cmd/Ctrl+Shift+Enter)
5. **Navigate to AI & ML → Agents** → Select `Sam-the-Snowman`

See `QUICKSTART.md` for detailed instructions.

---

## Repository Layout

```
Sam-the-Snowman/
├── README.md                           ← Project overview (you are here)
├── QUICKSTART.md                       ← 5-minute deployment guide
├── deploy_all.sql                      ← Single-script deployment
│
├── semantic_models/                    ← YAML reference files (best practice examples)
│   ├── sv_sam_query_performance.yaml   ← Complete semantic model with all features
│   ├── sv_sam_cost_analysis.yaml       ← Cost tracking semantic model
│   └── sv_sam_warehouse_operations.yaml← Capacity planning semantic model
│
├── sql/
│   ├── 01_scaffolding.sql              ← Database, schema, grants
│   ├── 02_email_integration.sql        ← Email notification setup
│   ├── 03_semantic_views.sql           ← Semantic views (SQL DDL)
│   ├── 04_marketplace.sql              ← Snowflake Documentation install
│   ├── 05_agent.sql                    ← Agent with enhanced routing
│   ├── 06_validation.sql               ← Deployment verification
│   ├── 07_testing.sql                  ← Automated test framework
│   └── 99_cleanup/teardown_all.sql     ← Clean removal
│
├── docs/                               ← Detailed guides (01-08)
└── diagrams/                           ← Architecture diagrams (Mermaid)
```

---

## Semantic Model Reference Files

The `/semantic_models/` directory contains **YAML reference files** that demonstrate world-class semantic model structure:

```yaml
# Example from sv_sam_query_performance.yaml
metrics:
  - name: ERROR_RATE
    description: "Percentage of queries that failed. Key quality metric."
    expr: 100.0 * SUM(CASE WHEN EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)

filters:
  - name: QUERIES_WITH_REMOTE_SPILLING
    description: "Include queries with severe spilling to remote storage."
    expr: BYTES_SPILLED_TO_REMOTE_STORAGE > 0

module_custom_instructions:
  sql_generation: |-
    CRITICAL: Always exclude system warehouses: WHERE WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
```

**Use these YAML files as templates** when building your own semantic views.

---

## Running Tests

After deployment, validate your installation:

```sql
-- Run all tests
CALL SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_RUN_TESTS();

-- View test summary
SELECT * FROM SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.V_TEST_SUMMARY;

-- View failed tests only
SELECT * FROM SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS WHERE STATUS = 'FAIL';
```

Test categories:
- **SMOKE** - Basic structure validation (views exist, agent exists)
- **FUNCTIONAL** - VQR execution (all verified queries run successfully)
- **REGRESSION** - Edge cases (system warehouse filtering, NULL handling)
- **PERFORMANCE** - Query timing benchmarks (<30 seconds)

---

## Components Created

| Component | Location | Purpose |
|-----------|----------|---------|
| Agent | `SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_THE_SNOWMAN` | Orchestrates tools |
| Semantic views | `SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_*` | Performance, cost, operations |
| Test framework | `SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_RUN_TESTS()` | Automated validation |
| Email procedure | `SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SFE_SEND_EMAIL()` | HTML email delivery |
| Demo warehouse | `SFE_SAM_SNOWMAN_WH` | X-Small compute |

---

## Documentation Map

| Guide | When to use |
|-------|-------------|
| `QUICKSTART.md` | Minimal deployment steps |
| `docs/01-QUICKSTART.md` | Expanded walkthrough |
| `docs/02-DEPLOYMENT.md` | Pre-flight checklist |
| `docs/03-ARCHITECTURE.md` | How components fit together |
| `docs/04-ADVANCED-DEPLOYMENT.md` | CLI deployment |
| `docs/05-ROLE-BASED-ACCESS.md` | Access control |
| `docs/06-TESTING.md` | Test procedures |
| `docs/07-TROUBLESHOOTING.md` | Common issues |
| `docs/08-SEMANTIC-VIEW-EXPANSION.md` | Adding new domains |

---

## Cleanup

```sql
USE ROLE ACCOUNTADMIN;
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/99_cleanup/teardown_all.sql';
```

---

## Expiration & Archival

**This demo expires on 2026-02-14.** Fork before expiration to keep your copy.

---

## Support & Contributing

- Report issues in the repository issue tracker
- Run tests before submitting PRs: `CALL SP_RUN_TESTS()`
- Follow existing patterns for semantic views and VQRs

**Author:** SE Community | **License:** Apache 2.0 | **Version:** 5.0
