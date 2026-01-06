# Semantic View Expansion Guide

## Overview

Sam-the-Snowman ships with three best-practice semantic views covering query performance, cost analysis, and warehouse operations. This guide shows you how to **expand** the agent's capabilities by creating additional semantic views for new analytical domains using Snowflake's AI-assisted generator.

**Key principle**: Keep your existing Git-based workflow while leveraging the AI generator as a **discovery and prototyping tool** for new domains.

---

## When to Expand

Consider adding a new semantic view when:

| Use Case | Example Domains |
|----------|----------------|
| **New operational area** | Storage metrics, pipe monitoring, task orchestration |
| **Compliance requirements** | Login history, data access auditing, role analysis |
| **Pipeline monitoring** | Snowpipe reliability, stream lag, dynamic table refresh |
| **Advanced analytics** | Replication monitoring, external function usage, UDF performance |

---

## The Hybrid Workflow

### Step 1: AI-Assisted Discovery (Snowsight UI)

Use the AI generator to rapidly prototype a new view and discover patterns in your data:

1. Sign in to Snowsight
2. Navigate to **AI & ML** → **Cortex Analyst**
3. Select **Create new** → **Create new Semantic View**
4. Follow the wizard:
   - **Description**: Describe the analytical domain (e.g., "Monitor Snowpipe ingestion reliability and file processing")
   - **Example queries**: Provide 3-5 SQL queries showing common patterns
   - **Tables**: Select source tables (e.g., `SNOWFLAKE.ACCOUNT_USAGE.PIPE_USAGE_HISTORY`)
   - **Columns**: Choose relevant columns (recommend ≤50 for performance)
   - **Sample values**: Enable to improve Cortex Analyst accuracy
   - **AI descriptions**: Enable to generate baseline documentation

5. Review AI-generated suggestions:
   - Relationships between tables
   - Verified query suggestions based on query history
   - Synonym recommendations
   - Column descriptions

### Step 2: Export to YAML

Once the AI generator completes:

1. In Snowsight, open the semantic view
2. Click **More options** → **Export YAML**
3. Save the YAML file locally (e.g., `snowpipe_monitoring.yaml`)

### Step 3: Convert to SQL for Version Control

Transform the YAML into SQL DDL that integrates with your Git workflow:

```sql
-- Use Snowflake's conversion function
SELECT SNOWFLAKE.CORE.SEMANTIC_MODEL_TO_DDL(
  PARSE_JSON($$
    <paste YAML content here>
  $$)
);
```

This generates a `CREATE SEMANTIC VIEW` statement compatible with your existing deployment scripts.

### Step 4: Refine and Productionize

Edit the generated SQL to match Sam-the-Snowman standards:

#### Required Refinements

1. **Add SFE_ prefix** for demo safety:
   ```sql
   CREATE OR REPLACE SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_PIPE_MONITORING
   ```

2. **Add demo comment**:
   ```sql
   COMMENT = 'DEMO: Sam-the-Snowman - Snowpipe ingestion monitoring and reliability analysis.'
   ```

3. **Enhance column comments with contextual information**:
   ```sql
   -- In FACTS and DIMENSIONS, add rich descriptions
   PIPE_USAGE_HISTORY.CREDITS_USED as CREDITS_USED
     comment='Snowpipe credits consumed. High values relative to BYTES_INSERTED suggest inefficient file sizing. Synonyms: ingestion cost, pipe cost.',
   ```

4. **Add best-practice header**:
   ```sql
   /*******************************************************************************
    * DEMO PROJECT: Sam-the-Snowman
    * Module: 03_semantic_views.sql (extended)
    *
    * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
    ******************************************************************************/
   ```

5. **Validate verified queries** - ensure they match your use cases

#### 📋 Recommended Enhancements

Based on Sam-the-Snowman's best practices:

- **Expand synonyms**: Add natural language variations users might ask
- **Add context to comments**: Explain when values indicate problems
- **Strategic filtering**: Exclude irrelevant data (e.g., system objects)
- **Sample values in comments**: Include representative examples within comment text (e.g., "Warehouse size (X-Small, Small, Medium, Large)")
  - **Note**: SQL DDL does not support `sample_values=[]` syntax; embed examples in comment strings
- **Multiple verified queries**: Show common use cases (3-5 queries)

### Step 5: Integrate into Deployment

Add your new view to the deployment workflow:

1. **Append to `sql/03_semantic_views.sql`**:
   ```sql
   -- ============================================================================
   -- SEMANTIC VIEW: sfe_pipe_monitoring
   -- ============================================================================
   CREATE OR REPLACE SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_PIPE_MONITORING
   TABLES (...)
   FACTS (...)
   DIMENSIONS (...)
   ...
   ```

2. **Update the agent** in `sql/05_agent.sql`:
   ```sql
   DEFINE TOOL sfe_pipe_monitoring
     ENDPOINT = 'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_PIPE_MONITORING'
     ENABLED = true
     DESCRIPTION = 'Analyze Snowpipe ingestion patterns...';
   ```

3. **Add routing keywords** to orchestration instructions:
   ```sql
   INSTRUCTIONS $$
     ...
     - pipe_monitoring: triggered by pipe, snowpipe, ingestion, file processing
   $$
   ```

4. **Test the integration**:
   ```sql
   -- Redeploy
   EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/03_semantic_views.sql';
   EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/05_agent.sql';

   -- Validate
   SHOW SEMANTIC VIEWS IN SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS;
   ```

5. **Update documentation**:
   - Add the new view to `docs/03-ARCHITECTURE.md` semantic views table
   - Document sample questions in the architecture guide
   - Update `README.md` if the new domain is a major feature

---

## Example: Adding Pipe Monitoring

Let's walk through a complete example of adding Snowpipe monitoring.

### Initial AI Generator Setup

**Description entered**:
```
Monitor Snowpipe ingestion reliability, file processing rates,
error patterns, and credit consumption for data loading pipelines.
```

**Example SQL queries provided**:
```sql
-- Query 1: Pipes with highest credit consumption
SELECT pipe_name, SUM(credits_used) as total_credits
FROM SNOWFLAKE.ACCOUNT_USAGE.PIPE_USAGE_HISTORY
WHERE start_time >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY pipe_name
ORDER BY total_credits DESC;

-- Query 2: File processing errors
SELECT pipe_name, error_message, COUNT(*) as error_count
FROM SNOWFLAKE.ACCOUNT_USAGE.COPY_HISTORY
WHERE status = 'LOAD_FAILED'
  AND pipe_name IS NOT NULL
GROUP BY pipe_name, error_message
ORDER BY error_count DESC;

-- Query 3: Ingestion latency by pipe
SELECT pipe_name,
       AVG(DATEDIFF('second', last_received_message_timestamp, last_load_time)) as avg_latency_sec
FROM SNOWFLAKE.ACCOUNT_USAGE.PIPE_USAGE_HISTORY
WHERE start_time >= DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY pipe_name;
```

**Tables selected**:
- `SNOWFLAKE.ACCOUNT_USAGE.PIPE_USAGE_HISTORY`
- `SNOWFLAKE.ACCOUNT_USAGE.COPY_HISTORY`

### AI-Generated Output

The generator produces:
- Relationship between PIPE_USAGE_HISTORY and COPY_HISTORY (via `pipe_name`)
- Verified queries based on examples + query history patterns
- Sample values for `pipe_name` column
- AI-generated descriptions for metrics

### Refined SQL (Production-Ready)

```sql
-- ============================================================================
-- SEMANTIC VIEW: sfe_pipe_monitoring
-- ============================================================================
-- Purpose: Monitor Snowpipe ingestion reliability and performance
-- Data Sources: PIPE_USAGE_HISTORY, COPY_HISTORY
-- Key Metrics: File processing rates, errors, latency, credit consumption
--
-- Best Practices Implemented:
-- ✓ Sample values in comments for pipe names
-- ✓ Expanded synonyms for ingestion terminology
-- ✓ Rich contextual descriptions for interpreting ingestion metrics
-- ✓ Multiple verified queries for common Snowpipe scenarios
-- ✓ Relationship between usage and error tracking

CREATE OR REPLACE SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_PIPE_MONITORING
TABLES (
    SNOWFLAKE.ACCOUNT_USAGE.PIPE_USAGE_HISTORY,
    SNOWFLAKE.ACCOUNT_USAGE.COPY_HISTORY
)
FACTS (
  PIPE_USAGE_HISTORY.CREDITS_USED as CREDITS_USED
    comment='Snowpipe credits consumed for continuous file ingestion. Synonyms: ingestion cost, pipe cost, loading cost.',
  PIPE_USAGE_HISTORY.FILES_INSERTED as FILES_INSERTED
    comment='Number of files successfully loaded. Synonyms: files loaded, ingested files, processed files.',
  PIPE_USAGE_HISTORY.BYTES_INSERTED as BYTES_INSERTED
    comment='Total bytes successfully loaded. Synonyms: data ingested, bytes loaded, volume processed.',
  COPY_HISTORY.ROW_COUNT as ROWS_LOADED
    comment='Rows loaded from staged files. Synonyms: records inserted, rows ingested.',
  COPY_HISTORY.ERROR_COUNT as ERROR_COUNT
    comment='Number of errors during file loading. Non-zero indicates data quality issues. Synonyms: load errors, ingestion errors.'
)
DIMENSIONS (
  PIPE_USAGE_HISTORY.PIPE_NAME as PIPE_NAME
    comment='Snowpipe object name (e.g., MY_S3_PIPE, EVENT_STREAM_PIPE, CDC_PIPE). Synonyms: pipe, ingestion pipe.',
  PIPE_USAGE_HISTORY.START_TIME as START_TIME
    comment='Measurement period start. Synonyms: period start, ingestion start.',
  COPY_HISTORY.FILE_NAME as FILE_NAME
    comment='Staged file path loaded by pipe. Synonyms: source file, staged file.',
  COPY_HISTORY.STATUS as STATUS
    comment='Load status for each file (LOADED, LOAD_FAILED, PARTIALLY_LOADED). Synonyms: load status, ingestion status.',
  COPY_HISTORY.ERROR_MESSAGE as ERROR_MESSAGE
    comment='Detailed error description for failed loads. Synonyms: failure reason, error details.'
)
COMMENT = 'DEMO: Sam-the-Snowman - Snowpipe ingestion monitoring, error tracking, and cost analysis.'
WITH EXTENSION (CA = '{
  "verified_queries": [
    {
      "name": "Most expensive pipes last month",
      "question": "Which Snowpipes consumed the most credits?",
      "sql": "SELECT pipe_name, SUM(credits_used) as total_credits FROM sfe_pipe_monitoring WHERE start_time >= DATEADD(''day'', -30, CURRENT_TIMESTAMP()) GROUP BY pipe_name ORDER BY total_credits DESC LIMIT 10"
    },
    {
      "name": "Pipes with errors",
      "question": "Show me pipes with load failures",
      "sql": "SELECT pipe_name, error_message, COUNT(*) as failure_count FROM sfe_pipe_monitoring WHERE status = ''LOAD_FAILED'' AND start_time >= DATEADD(''day'', -7, CURRENT_TIMESTAMP()) GROUP BY pipe_name, error_message ORDER BY failure_count DESC"
    }
  ]
}');
```

### Agent Integration

Update `sql/05_agent.sql`:

```sql
-- Add tool definition
DEFINE TOOL sfe_pipe_monitoring
  ENDPOINT = 'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_PIPE_MONITORING'
  ENABLED = true
  DESCRIPTION = 'Analyze Snowpipe ingestion patterns, file processing errors, and loading costs';

-- Update orchestration instructions
INSTRUCTIONS $$
  You are Sam-the-Snowman, a Snowflake operations assistant...

  Use these tools based on user intent:
  - sfe_query_performance: slow queries, errors, spilling, optimization
  - sfe_cost_analysis: credits, spend, expensive warehouses
  - sfe_warehouse_operations: sizing, queues, utilization
  - sfe_pipe_monitoring: snowpipe, ingestion, file loading, pipe errors  -- NEW!
  - snowflake_knowledge_ext_documentation: best practices, how-to questions
  - cortex_email_tool: send reports to stakeholders
$$;
```

---

## Best Practices Summary

### DO

- **Use AI generator for discovery** - let it find patterns in your query history
- **Export to YAML** - capture the AI-generated structure
- **Convert to SQL** - maintain Git-based version control
- **Refine with domain expertise** - enhance AI output with business context
- **Add comprehensive synonyms** - cover natural language variations
- **Include sample values** - improve Cortex Analyst accuracy
- **Write rich contextual descriptions** - explain what metrics mean and when values indicate problems in comments
- **Test verified queries** - ensure they work and demonstrate value

### DON'T

- **Don't abandon Git workflow** - UI-only authoring breaks automation
- **Don't skip refinement** - AI output needs human curation
- **Don't ignore naming conventions** - use `SFE_` prefix and demo comments
- **Don't over-expand** - start with 3-5 views, add incrementally
- **Don't skip testing** - verify agent routing and query accuracy
- **Don't forget documentation** - update architecture guide and README

---

## Troubleshooting

### AI Generator Issues

**Problem**: Generator creates relationships that don't match your data

**Solution**:
- Review join keys in source tables
- Manually specify the correct relationship in SQL
- Use `DESCRIBE TABLE` to verify column types match

---

**Problem**: Verified queries are generic or irrelevant

**Solution**:
- Provide more specific example queries during setup
- Your query history may lack relevant patterns
- Manually write 3-5 queries demonstrating key use cases

---

**Problem**: AI-generated descriptions are vague

**Solution**:
- Use AI output as starting point only
- Enhance with domain expertise and business context
- Add "Synonyms:" section to each comment
- Explain when values indicate problems (e.g., "Non-zero indicates...")

---

### Integration Issues

**Problem**: Agent doesn't route to new view

**Solution**:
- Check tool definition in `sql/05_agent.sql`
- Verify routing keywords in orchestration instructions
- Test with explicit keywords (e.g., "using the pipe_monitoring view")
- Redeploy agent: re-run `sql/05_agent.sql`

---

**Problem**: View queries fail with "insufficient privileges"

**Solution**:
```sql
-- Grant SYSADMIN access to source tables
USE ROLE ACCOUNTADMIN;
GRANT SELECT ON SNOWFLAKE.ACCOUNT_USAGE.PIPE_USAGE_HISTORY TO ROLE SYSADMIN;
GRANT SELECT ON SNOWFLAKE.ACCOUNT_USAGE.COPY_HISTORY TO ROLE SYSADMIN;
```

---

## Next Steps

After successfully adding your first custom semantic view:

1. **Iterate on existing views** - refine synonyms based on user feedback
2. **Add complementary domains** - storage, tasks, replication
3. **Share patterns** - document discoveries for your team
4. **Monitor usage** - use `SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY` to see which views are most valuable

---

## Related Documentation

| Guide | Purpose |
|-------|---------|
| `docs/03-ARCHITECTURE.md` | How semantic views integrate with the agent |
| `docs/05-ROLE-BASED-ACCESS.md` | Granting access to new views |
| `docs/06-TESTING.md` | Testing new semantic views |
| [Snowflake Semantic Views Docs](https://docs.snowflake.com/en/user-guide/views-semantic) | Official reference |
| [AI-Assisted Generator](https://docs.snowflake.com/en/user-guide/views-semantic/ui#using-the-ai-assisted-generator-to-create-a-semantic-view) | UI workflow details |

---

**Pro Tip**: Start with the AI generator to rapidly explore new domains, but always productionize through SQL to maintain your Git-based, auditable, reproducible deployment workflow. The best approach combines AI discovery with human refinement and version control discipline.
