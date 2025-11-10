# Modular Deployment Architecture

**Status:** Active  
**Version:** 3.1.0  
**Author:** M. Whitaker

---

## Overview

Sam-the-Snowman uses a modular deployment architecture that breaks the deployment into focused, reusable components. This approach makes it easier to:

- **Find examples** - Each module focuses on a specific Snowflake feature (semantic views, agents, etc.)
- **Troubleshoot issues** - Run individual modules to isolate problems
- **Learn incrementally** - Study one concept at a time
- **Reuse patterns** - Copy module patterns for your own projects

---

## Module Structure

### Master Deployment Script

**`deploy_all.sql`** - Orchestrates all modules in the correct order (located in project root)
- Executes modules sequentially using standard Snowflake SQL statements
- Safe to run multiple times (idempotent)
- Recommended workflow: open `deploy_all.sql` in Snowsight (Git + Worksheets integration), update the configuration block, and run the entire script at once.

### Module 00: Stage Mount (`sql/00_config.sql`)

**Purpose:** Ensure the Git repository is available as a Snowflake stage

**What it does:**
- Creates (or reuses) the shared demo database and `DEPLOY` schema
- Creates the `SFE_GITHUB_API_INTEGRATION` (idempotent)
- Creates the Git repository stage `SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO`
- Fetches the latest branch contents and lists available SQL modules

**Key learning:** How Snowsight workspaces surface Git repositories as Snowflake stages

**Usage:** Run when deploy_all.sql reports the repository stage is missing (no edits required)

---

### Module 01: Scaffolding (`sql/01_scaffolding.sql`)

**Purpose:** Create database and schema infrastructure

**What it does:**
- Creates `SNOWFLAKE_EXAMPLE` database and functional schemas (`deploy`, `integrations`, `semantic`)
- Creates `SNOWFLAKE_INTELLIGENCE` database and `AGENTS` schema
- Transfers `SNOWFLAKE_INTELLIGENCE` ownership to configured role
- Grants privileges to configured role
- Initializes deployment logging table

**Key learning:** Database architecture, ownership management, privilege grants

**Objects created:**
- `SNOWFLAKE_EXAMPLE` database
- `SNOWFLAKE_EXAMPLE.deploy` schema
- `SNOWFLAKE_EXAMPLE.integrations` schema
- `SNOWFLAKE_EXAMPLE.semantic` schema
- `SNOWFLAKE_INTELLIGENCE` database (or updates ownership if exists)
- `SNOWFLAKE_INTELLIGENCE.AGENTS` schema
- Temporary `deployment_log` table

---

### Module 02: Email Integration (`sql/02_email_integration.sql`)

**Purpose:** Set up email notification capabilities

**What it does:**
- Creates `SFE_EMAIL_INTEGRATION` notification integration
- Creates `sfe_send_email` stored procedure with SQL injection protection
- Auto-detects the current user's email address and tests the integration

**Key learning:** Notification integrations, Python stored procedures, security patterns

**Objects created:**
- `SFE_EMAIL_INTEGRATION` notification integration
- `SNOWFLAKE_EXAMPLE.integrations.sfe_send_email` procedure

**Security highlight:** The stored procedure uses `session.call()` to prevent SQL injection when calling `SYSTEM$SEND_EMAIL`.

---

### Module 03: Semantic Views (`sql/03_semantic_views.sql`)

**Purpose:** Create domain-specific semantic views for Cortex Analyst

**What it does:**
- Creates `sfe_query_performance` semantic view (query analysis)
- Creates `sfe_cost_analysis` semantic view (cost tracking)
- Creates `sfe_warehouse_operations` semantic view (capacity planning)

**Key learning:** ⭐ **Semantic view syntax and design patterns**

**Objects created:**
- `SNOWFLAKE_EXAMPLE.semantic.sfe_query_performance`
- `SNOWFLAKE_EXAMPLE.semantic.sfe_cost_analysis`
- `SNOWFLAKE_EXAMPLE.semantic.sfe_warehouse_operations`

**Why this module is valuable:**
This is the **best reference** for semantic view syntax. Each view demonstrates:
- `TABLES()` - Source table declarations
- `FACTS()` - Numeric measures with comments and synonyms
- `DIMENSIONS()` - Categorical attributes with comments and synonyms
- `COMMENT` - View-level documentation
- `WITH EXTENSION (CA = ...)` - Verified query examples

**Example pattern:**
```sql
CREATE OR REPLACE SEMANTIC VIEW schema.view_name
TABLES (
    SNOWFLAKE.ACCOUNT_USAGE.SOURCE_TABLE
)
FACTS (
  SOURCE_TABLE.METRIC as METRIC comment='Description. Synonyms: alt1, alt2.'
)
DIMENSIONS (
  SOURCE_TABLE.COLUMN as COLUMN comment='Description.'
)
COMMENT = 'Purpose and usage guidance'
WITH EXTENSION (CA = '{"verified_queries":[...]}');
```

---

### Module 04: Marketplace (`sql/04_marketplace.sql`)

**Purpose:** Install Snowflake Documentation from Marketplace

**What it does:**
- Accepts legal terms for marketplace listing
- Creates `snowflake_documentation` database from listing
- Grants imported privileges to configured role

**Key learning:** Marketplace listing installation, imported privileges

**Objects created:**
- `snowflake_documentation` database (marketplace listing)

---

### Module 05: Agent (`sql/05_agent.sql`)

**Purpose:** Create the Sam-the-Snowman AI agent

**What it does:**
- Creates agent in `SNOWFLAKE_INTELLIGENCE.AGENTS`
- Configures agent profile and instructions
- Defines five tools (3 semantic views, 1 Cortex Search, 1 procedure)
- Grants usage to configured role

**Key learning:** ⭐ **Agent configuration and tool integration**

**Objects created:**
- `SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman` agent

**Why this module is valuable:**
This is the **best reference** for agent configuration. It demonstrates:
- Agent profile with `display_name`
- Instruction structure (response, orchestration, sample_questions)
- Tool definitions (cortex_analyst_text_to_sql, cortex_search, generic)
- Tool resource mappings to semantic views and procedures
- Role-based access control

**Example pattern:**
```sql
CREATE OR REPLACE AGENT schema.agent_name
WITH PROFILE = '{ "display_name": "Display Name" }'
COMMENT = 'Purpose description'
FROM SPECIFICATION $$
{
    "models": { "orchestration": "auto" },
    "instructions": {
        "response": "Agent persona and response style",
        "orchestration": "Tool selection logic and rules",
        "sample_questions": [...]
    },
    "tools": [...],
    "tool_resources": {...}
}
$$;
```

---

### Module 06: Validation (`sql/06_validation.sql`)

**Purpose:** Verify deployment success

**What it does:**
- Queries `deployment_log` table
- Displays component status (PASS/MISSING)
- Provides summary counts
- Shows final deployment status

**Key learning:** Deployment validation patterns, temp table usage

**No objects created** - validation only

---

## Usage Patterns

### Pattern 1: Full Deployment (Recommended)

Execute the combined SQL script:

```sql
-- In Snowsight, open and run deploy_all.sql (from project root)
-- This runs all modules in sequence (00_config through 06_validation)
```

For command-line execution you can also use Snow CLI and source each module manually:

```bash
snow sql -f deploy_all.sql
# or run modules individually with "snow sql -f sql/00_config.sql" ...
```

### Pattern 2: Step-by-Step Deployment

Execute modules individually:

```sql
-- 1. Configure
!source sql/00_config.sql

-- 2. Set up infrastructure
!source sql/01_scaffolding.sql

-- 3. Email capabilities
!source sql/02_email_integration.sql

-- 4. Semantic views
!source sql/03_semantic_views.sql

-- 5. Documentation
!source sql/04_marketplace.sql

-- 6. Agent
!source sql/05_agent.sql

-- 7. Verify
!source sql/06_validation.sql
```

### Pattern 3: Selective Re-deployment

Re-run specific modules after changes:

```sql
-- Already deployed but want to update the agent?
!source sql/00_config.sql  -- Ensure variables are set
!source sql/05_agent.sql    -- Recreate agent only

-- Want to update semantic views?
!source sql/00_config.sql        -- Ensure variables are set
!source sql/03_semantic_views.sql -- Recreate views
!source sql/05_agent.sql          -- Update agent to use new views
```

### Pattern 4: Learning and Reference

Use modules as examples:

```sql
-- Want to learn semantic view syntax?
-- Read sql/03_semantic_views.sql

-- Want to learn agent configuration?
-- Read sql/05_agent.sql

-- Want to see email notification setup?
-- Read sql/02_email_integration.sql
```

---

## Troubleshooting

### Module Fails to Execute

**Symptom:** Module shows errors when run individually

**Solution:**
1. Ensure `00_config.sql` was run first (sets variables)
2. Check that previous modules completed successfully
3. Verify you have the required privileges (ACCOUNTADMIN)

### Variables Not Defined Error

**Symptom:** `SQL compilation error: error line N at position N unexpected 'identifier'`

**Solution:** Run `00_config.sql` to recreate the Git repository stage, then rerun `deploy_all.sql` (which sets `role_name`/integration variables before executing modules)

### Deployment Log Not Found

**Symptom:** `Object 'DEPLOYMENT_LOG' does not exist`

**Solution:** Run `01_scaffolding.sql` to create the log table

### Agent Creation Fails

**Symptom:** Agent creation fails with privilege errors

**Solution:**
1. Ensure `01_scaffolding.sql` completed (creates schemas)
2. Ensure `03_semantic_views.sql` completed (agent depends on views)
3. Ensure `04_marketplace.sql` completed (agent uses documentation)

---

## Benefits of Modular Architecture

### For Learning

- **Clear examples:** Each module demonstrates one concept
- **Incremental understanding:** Learn one piece at a time
- **Easy experimentation:** Modify and re-run individual modules

### For Development

- **Faster iteration:** Only redeploy changed modules
- **Easier debugging:** Isolate issues to specific modules
- **Better testing:** Test individual components independently

### For Production

- **Selective deployment:** Skip modules you don't need
- **Clearer audit trail:** Know exactly what each step does
- **Easier maintenance:** Update individual components without full redeployment

---

## Migration from 01_setup.sql

**Old approach (v3.0):**
- Single monolithic `sql/01_setup.sql` script (467 lines)
- All-or-nothing execution
- Difficult to find specific examples
- Hard to debug failures

**New approach (v3.1):**
- 7 focused modules in `sql/` directory (50-150 lines each)
- Master `deploy_all.sql` orchestrator in project root
- Granular execution control
- Easy to find and reference patterns
- Clear failure isolation

**Backward compatibility:**
The deprecated `sql/01_setup_DEPRECATED.sql` is preserved for reference, but all users should migrate to the modular approach.

---

## Best Practices

1. **Always run `sql/00_config.sql` first** when executing individual modules
2. **Use `deploy_all.sql`** for full deployments (located in project root)
3. **Read module headers** in `sql/` directory - they explain purpose, prerequisites, and objects created
4. **Test changes** in a dev environment before modifying modules
5. **Use as reference** - copy patterns from modules for your own projects

---

## Related Documentation

- `README.md` - Project overview and quick start
- `help/AGENT_ARCHITECTURE.md` - Deep dive on semantic views and agent design
- `help/TESTING.md` - Validation and testing procedures
- `help/TROUBLESHOOTING.md` - Common issues and solutions

---

**Next Steps:**

1. Review `deploy_all.sql` (project root) to understand the orchestration
2. Study `sql/03_semantic_views.sql` for semantic view patterns
3. Study `sql/05_agent.sql` for agent configuration patterns
4. Run `deploy_all.sql` to deploy the full system

