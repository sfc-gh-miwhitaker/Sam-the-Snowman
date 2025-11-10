# Testing & Validation
**Sam-the-Snowman - Deployment Validation Procedures**
This guide provides comprehensive testing procedures to validate your Sam-the-Snowman deployment.

---

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Deployment Validation](#deployment-validation)
3. [Functional Testing](#functional-testing)
4. [Performance Benchmarks](#performance-benchmarks)
5. [Email Integration Testing](#email-integration-testing)
6. [User Access Testing](#user-access-testing)
7. [Rollback Procedures](#rollback-procedures)
8. [Success Criteria](#success-criteria)

---

## Pre-Deployment Checklist

Before running `deploy_all.sql` (or the individual modules in `sql/00_config.sql` through `sql/06_validation.sql`), verify all prerequisites are met:

### ✓ Account Prerequisites

- [ ] `ACCOUNTADMIN` role access confirmed
- [ ] Snowflake Cortex features available in your region
- [ ] Network access to Snowflake Marketplace enabled
- [ ] Email domain allow-listed for notification integrations

**Validation Queries:**

```sql
-- 1. Verify you have ACCOUNTADMIN access
USE ROLE ACCOUNTADMIN;
SELECT CURRENT_ROLE() as role;
-- Expected: ACCOUNTADMIN

-- 2. Verify Cortex features are available
SHOW DATABASE ROLES IN DATABASE SNOWFLAKE LIKE 'CORTEX%';
-- Expected: CORTEX_USER role visible

-- 3. Check account region
SELECT CURRENT_REGION(), CURRENT_ACCOUNT();
-- Verify region supports Cortex: https://docs.snowflake.com/en/user-guide/snowflake-cortex/overview
```

### ✓ Configuration Review

- [ ] Updated configuration variables in `sql/00_config.sql`
- [ ] Confirmed the target warehouse exists and is accessible
- [ ] Replaced the placeholder email address in the test call (`sql/02_email_integration.sql`)
- [ ] Understand all objects that will be created

**Validation Queries:**

```sql
-- Verify target warehouse exists
SHOW WAREHOUSES LIKE 'COMPUTE_WH';
-- Expected: At least one warehouse visible

-- Check if warehouse is accessible
USE WAREHOUSE COMPUTE_WH;
SELECT CURRENT_WAREHOUSE();
-- Expected: COMPUTE_WH
```

### ✓ Environment Readiness

- [ ] Sufficient credits available in account
- [ ] `SNOWFLAKE_EXAMPLE` database will be used (created if not exists)
- [ ] Backup of any existing configurations completed

**Validation Queries:**

```sql
-- Check for existing databases (OK if SNOWFLAKE_EXAMPLE exists)
SHOW DATABASES LIKE 'SNOWFLAKE_EXAMPLE';
-- Note: SNOWFLAKE_EXAMPLE is shared across demos - OK if exists

SHOW DATABASES LIKE 'snowflake_documentation';
-- Expected: No results (if deploying fresh)
```

---

## Deployment Validation

After executing the setup script, validate that all components were created successfully.

### Step 1: Verify Databases Created

```sql
USE ROLE SYSADMIN;

-- Check SNOWFLAKE_EXAMPLE database
SHOW DATABASES LIKE 'SNOWFLAKE_EXAMPLE';
-- ✓ PASS: Database exists

-- Check snowflake_documentation database
SHOW DATABASES LIKE 'snowflake_documentation';
-- ✓ PASS: Database exists (marketplace import)
```

**Success Criteria:** Both databases visible with proper ownership.

---

### Step 2: Verify Schemas Created

```sql
USE ROLE SYSADMIN;

-- Check tools schema in SNOWFLAKE_EXAMPLE
SHOW SCHEMAS IN DATABASE SNOWFLAKE_EXAMPLE;
-- ✓ PASS: Should include 'TOOLS'

-- Check agents schema in SNOWFLAKE_INTELLIGENCE (Snowflake requirement for agents)
SHOW SCHEMAS IN DATABASE SNOWFLAKE_INTELLIGENCE;
-- ✓ PASS: Should include 'AGENTS'
```

**Expected Output:**
| name | database_name | owner |
|------|---------------|-------|
| AGENTS | SNOWFLAKE_INTELLIGENCE | SYSADMIN |
| TOOLS | SNOWFLAKE_INTELLIGENCE | SYSADMIN |

---

### Step 3: Verify GitHub Integration

```sql
USE ROLE SYSADMIN;
USE SCHEMA SNOWFLAKE_EXAMPLE.tools;

SHOW GIT REPOSITORIES;
-- ✓ PASS: SAM_THE_SNOWMAN_REPO visible

USE ROLE ACCOUNTADMIN;
SHOW API INTEGRATIONS LIKE 'SFE_GITHUB_API_INTEGRATION';
-- ✓ PASS: Integration visible and ENABLED
```

**Success Criteria:** Git integration objects exist and are enabled (update prefixes/origin before deployment if cloning your own repository).

---

### Step 4: Verify Semantic Views

```sql
USE ROLE SYSADMIN;

-- Check semantic views exist
SHOW SEMANTIC VIEWS IN SCHEMA SNOWFLAKE_EXAMPLE.tools;
-- ✓ PASS: query_performance, cost_analysis, warehouse_operations visible

-- Test query_performance data access
SELECT COUNT(*) as row_count
FROM SNOWFLAKE_EXAMPLE.tools.query_performance;
-- ✓ PASS: Query executes without error (count may vary)

-- Test cost_analysis data access
SELECT COUNT(*) as row_count
FROM SNOWFLAKE_EXAMPLE.tools.cost_analysis;
-- ✓ PASS: Query executes without error (count may vary)

-- Test warehouse_operations data access
SELECT COUNT(*) as row_count
FROM SNOWFLAKE_EXAMPLE.tools.warehouse_operations;
-- ✓ PASS: Query executes without error (count may vary)

-- Verify query_performance has recent data
SELECT 
    MAX(START_TIME) as most_recent_query,
    COUNT(*) as total_queries
FROM SNOWFLAKE_EXAMPLE.tools.query_performance;
-- ✓ PASS: most_recent_query shows recent timestamp
```

**Success Criteria:** All three semantic views exist, are accessible, and return data.

---

### Step 5: Verify Notification Integration

```sql
USE ROLE ACCOUNTADMIN;

-- Check email integration exists
SHOW NOTIFICATION INTEGRATIONS LIKE 'SFE_EMAIL_INTEGRATION';
-- ✓ PASS: SFE_EMAIL_INTEGRATION visible with ENABLED = TRUE
```

**Expected Output:**
| name | type | enabled |
|------|------|---------|
| SFE_EMAIL_INTEGRATION | EMAIL | true |

---

### Step 6: Verify Stored Procedure

```sql
USE ROLE SYSADMIN;

-- Check send_email procedure exists
SHOW PROCEDURES LIKE 'send_email' IN SCHEMA SNOWFLAKE_EXAMPLE.tools;
-- ✓ PASS: send_email(VARCHAR, VARCHAR, VARCHAR) visible

-- Describe the procedure
DESC PROCEDURE SNOWFLAKE_EXAMPLE.tools.send_email(VARCHAR, VARCHAR, VARCHAR);
-- ✓ PASS: Procedure details returned
```

**Success Criteria:** Stored procedure exists and is callable.

---

### Step 7: Verify Agent Created

```sql
USE ROLE SYSADMIN;

-- Check agent exists (Snowflake requires SNOWFLAKE_INTELLIGENCE.AGENTS)
SHOW AGENTS IN SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS;
-- ✓ PASS: sam_the_snowman visible

-- Get agent details
DESC AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman;
-- ✓ PASS: Agent specification returned
```

**Expected Output:** Agent appears with comment “AI-powered Snowflake Assistant…” and tools list referencing the three semantic views, Cortex Search, and email procedure.

---

### Step 8: Verify Grants

```sql
USE ROLE ACCOUNTADMIN;

-- Confirm the configured deployment role (from sql/00_config.sql) has access
SHOW GRANTS TO ROLE SYSADMIN;  -- replace if you customized role_name

-- Check database and schema grants
SHOW GRANTS ON DATABASE SNOWFLAKE_EXAMPLE;
SHOW GRANTS ON SCHEMA SNOWFLAKE_EXAMPLE.tools;
SHOW GRANTS ON DATABASE SNOWFLAKE_INTELLIGENCE;
SHOW GRANTS ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS;
SHOW GRANTS ON DATABASE snowflake_documentation;

-- Check agent grants
SHOW GRANTS ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman;
```

**Success Criteria:** Only the configured role (and any additional roles you granted) have USAGE on the databases, schemas, documentation, and agent.

---

## Functional Testing

Test the agent's core functionality with progressively complex queries.

### Test 1: Basic Agent Response

**Test Query:** "What is my account name?"

**How to Test:**
1. Navigate to Snowsight UI
2. Go to **AI & ML > Agents**
3. Select `sam_the_snowman`
4. Ask the following questions and validate the responses

**Expected Behavior:**
- Agent responds within 5-10 seconds
- Agent returns your Snowflake account name
- No error messages

**✓ PASS Criteria:** Agent responds correctly with account information.

---

### Test 2: Query History Analysis

**Test Query:** "What were my top 5 slowest queries today?"

**Expected Behavior:**
- Agent queries the semantic view
- Returns list of queries with execution times
- Provides query IDs and elapsed time metrics

**Validation Query:**
```sql
-- Manually verify agent's response
SELECT 
    QUERY_ID,
    TOTAL_ELAPSED_TIME / 1000 as seconds,
    QUERY_TEXT
FROM SNOWFLAKE_EXAMPLE.tools.query_performance
WHERE START_TIME >= CURRENT_DATE()
ORDER BY TOTAL_ELAPSED_TIME DESC
LIMIT 5;
```

**✓ PASS Criteria:** Agent response matches manual query results.

---

### Test 3: Warehouse Analysis

**Test Query:** "Which warehouses should be upgraded to Gen 2?"

**Expected Behavior:**
- Agent analyzes warehouse configurations
- References Snowflake documentation for Gen 2 features
- Provides specific warehouse recommendations

**✓ PASS Criteria:** Agent provides actionable recommendations with reasoning.

---

### Test 4: Error Troubleshooting

**Test Query:** "Show me queries with compilation errors and how to fix them"

**Expected Behavior:**
- Agent identifies queries with error codes
- Provides error messages
- Searches documentation for solutions

**Validation Query:**
```sql
-- Verify error queries exist
SELECT 
    QUERY_ID,
    ERROR_CODE,
    ERROR_MESSAGE
FROM SNOWFLAKE_EXAMPLE.tools.query_performance
WHERE ERROR_CODE IS NOT NULL
    AND START_TIME >= DATEADD(day, -7, CURRENT_DATE())
LIMIT 10;
```

**✓ PASS Criteria:** Agent identifies errors and provides relevant guidance.

---

### Test 5: Documentation Search

**Test Query:** "How do I configure Query Acceleration Service?"

**Expected Behavior:**
- Agent searches Snowflake documentation corpus
- Returns relevant documentation snippets
- Provides links to official documentation

**✓ PASS Criteria:** Agent returns accurate documentation references.

---

### Test 6: Complex Analysis

**Test Query:** "Based on my top 10 slowest queries, can you provide ways to optimize them?"

**Expected Behavior:**
- Agent identifies slowest queries from semantic view
- Analyzes query patterns (bytes scanned, partitions, etc.)
- Searches documentation for optimization techniques
- Provides specific recommendations

**Expected Response Time:** 15-30 seconds (complex multi-tool query)

**✓ PASS Criteria:** Agent provides comprehensive optimization recommendations.

---

## Performance Benchmarks

Measure agent performance against expected baselines.

### Benchmark 1: Simple Query Response Time

**Test:** "What is my account name?"

| Metric | Target | Acceptable | Needs Investigation |
|--------|--------|------------|---------------------|
| Response Time | < 5 sec | 5-10 sec | > 10 sec |
| Tokens Generated | 50-100 | 100-200 | > 200 |

**Measurement:**
```sql
-- Check recent agent query times
SELECT 
    QUERY_TEXT,
    TOTAL_ELAPSED_TIME / 1000 as seconds
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE QUERY_TAG LIKE '%cortex-agent%'
    AND START_TIME >= DATEADD(minute, -10, CURRENT_TIMESTAMP())
ORDER BY START_TIME DESC;
```

---

### Benchmark 2: Semantic View Query Response Time

**Test:** "Show me my slowest queries today"

| Metric | Target | Acceptable | Needs Investigation |
|--------|--------|------------|---------------------|
| Response Time | < 10 sec | 10-20 sec | > 20 sec |
| Data Scanned | < 100MB | 100-500MB | > 500MB |

---

### Benchmark 3: Documentation Search Response Time

**Test:** "How do I enable clustering?"

| Metric | Target | Acceptable | Needs Investigation |
|--------|--------|------------|---------------------|
| Response Time | < 8 sec | 8-15 sec | > 15 sec |
| Results Returned | 3-5 docs | 5-10 docs | > 10 docs |

---

### Benchmark 4: Complex Multi-Tool Query

**Test:** "Based on my top 10 slowest queries, can you provide ways to optimize them?"

| Metric | Target | Acceptable | Needs Investigation |
|--------|--------|------------|---------------------|
| Response Time | < 20 sec | 20-40 sec | > 40 sec |
| Tools Used | 2-3 | 3-4 | > 4 |

---

## Email Integration Testing

Validate email notification functionality.

### Test 1: Direct Stored Procedure Call

```sql
USE ROLE SYSADMIN;

-- Test email procedure directly
CALL SNOWFLAKE_EXAMPLE.tools.send_email(
    'your.email@domain.com',
    'Snowflake Intelligence - Direct Test',
    '<h1>Direct Test</h1><p>This email was sent directly via stored procedure.</p><p>Timestamp: ' || CURRENT_TIMESTAMP()::VARCHAR || '</p>'
);
```

**✓ PASS Criteria:**
- Procedure executes without error
- Email received within 2-5 minutes
- HTML formatting preserved

---

### Test 2: Agent-Triggered Email

**Test Query:** "Send email to me summarizing the top 3 slowest queries today"

**Expected Behavior:**
- Agent analyzes queries
- Formats results as HTML
- Calls email procedure
- Confirms email sent

**✓ PASS Criteria:**
- Agent confirms email sent
- Email received with query summary
- Email content is well-formatted and accurate

---

### Test 3: Email Error Handling

```sql
-- Test with invalid email format
CALL SNOWFLAKE_EXAMPLE.tools.send_email(
    'invalid-email-format',
    'Test Subject',
    '<p>Test body</p>'
);
```

**Expected Behavior:**
- Procedure returns error message
- Error is handled gracefully
- No system crash

**✓ PASS Criteria:** Error handled with clear message.

---

## User Access Testing

Verify that only authorized roles can access the agent.

### Test 1: Configured Deployment Role (default SYSADMIN)

```sql
-- Activate the role defined in sql/00_config.sql (default SYSADMIN)
USE ROLE SYSADMIN;

-- Verify agent is visible
SHOW AGENTS IN SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS;
-- ✓ PASS: sam_the_snowman visible

-- (Optional) Run a simple query in Snowsight as SYSADMIN
-- Question: "What is my current warehouse?"
-- ✓ PASS: Agent responds
```

### Test 2: Non-Privileged Role Cannot Access

```sql
USE ROLE PUBLIC;

SHOW AGENTS IN SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS;
-- ✓ PASS: No rows (agent hidden)

-- Attempt to describe agent (should fail)
DESC AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman;
-- ✓ PASS: SQL access control error
```

### Test 3: Grant Access to a Custom Role

```sql
USE ROLE ACCOUNTADMIN;

-- Create test role
CREATE ROLE IF NOT EXISTS test_agent_user;

-- Grant required access
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE test_agent_user;
GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE test_agent_user;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.tools TO ROLE test_agent_user;
GRANT USAGE ON DATABASE SNOWFLAKE_INTELLIGENCE TO ROLE test_agent_user;
GRANT USAGE ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS TO ROLE test_agent_user;
GRANT IMPORTED PRIVILEGES ON DATABASE snowflake_documentation TO ROLE test_agent_user;
GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman TO ROLE test_agent_user;
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE test_agent_user;

-- Test as new role
USE ROLE test_agent_user;
SHOW AGENTS IN SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS;
-- ✓ PASS: Agent accessible
```

---

## Rollback Procedures

If deployment fails or issues are detected, follow these rollback steps.

### Scenario 1: Partial Deployment Failure

**If deployment fails mid-script:**

1. Identify where failure occurred (check error message)
2. Use diagnostic queries to see what was created:
   ```sql
   SHOW DATABASES LIKE 'snowflake%';
   SHOW AGENTS IN ACCOUNT;
   SHOW NOTIFICATION INTEGRATIONS;
   ```
3. Execute relevant sections of `sql/99_cleanup/teardown_all.sql` to remove partial deployment
4. Fix configuration issue
5. Re-run complete `deploy_all.sql`

---

### Scenario 2: Agent Not Working Properly

**If agent is deployed but not functioning:**

1. Do NOT immediately tear down
2. Use troubleshooting guide to diagnose issue
3. Check logs:
   ```sql
   SELECT *
   FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY())
   WHERE QUERY_TAG LIKE '%cortex-agent%'
   ORDER BY START_TIME DESC;
   ```
4. If configuration error, drop and recreate agent only:
   ```sql
   DROP AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman;
   -- Then rerun sql/05_agent.sql (or deploy_all.sql) with corrected specification
   ```

---

### Scenario 3: Complete Rollback Required

**If deployment must be completely removed:**

1. Review `sql/99_cleanup/teardown_all.sql` thoroughly
2. Execute teardown script as ACCOUNTADMIN
3. Verify complete removal with validation queries in teardown script
4. Document lessons learned
5. When ready, re-deploy with corrections

---

## Success Criteria

Use this checklist to confirm successful deployment:

### ✅ Deployment Success Checklist

- [ ] All databases created (SNOWFLAKE_EXAMPLE, snowflake_documentation)
- [ ] All schemas created (agents, tools)
- [ ] Semantic view accessible and returning data
- [ ] Stored procedure executable
- [ ] Notification integration enabled
- [ ] Agent created and visible
- [ ] PUBLIC role can access agent
- [ ] Agent responds to basic queries < 10 seconds
- [ ] Agent can analyze query history
- [ ] Agent can search documentation
- [ ] Email integration sends test email successfully
- [ ] Agent can trigger email notifications
- [ ] Performance benchmarks meet acceptable thresholds
- [ ] No errors in recent query history

### ✅ Production Readiness Checklist

- [ ] All functional tests pass
- [ ] Performance benchmarks acceptable
- [ ] User access tested and working
- [ ] Email notifications reliable
- [ ] Troubleshooting guide reviewed
- [ ] Rollback procedures documented and tested
- [ ] Monitoring queries documented
- [ ] Team trained on agent usage
- [ ] Escalation procedures established
- [ ] Cost monitoring in place

---

## Continuous Testing

After successful deployment, implement ongoing testing:

### Daily Health Check

```sql
-- Run daily to verify agent health
SELECT 
    'Agent Query Count' as metric,
    COUNT(*) as value,
    CASE WHEN COUNT(*) > 0 THEN 'HEALTHY' ELSE 'CHECK REQUIRED' END as status
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE QUERY_TAG LIKE '%cortex-agent%'
    AND START_TIME >= DATEADD(day, -1, CURRENT_TIMESTAMP());
```

### Weekly Performance Review

```sql
-- Review weekly performance trends
SELECT 
    DATE_TRUNC('day', START_TIME) as day,
    COUNT(*) as queries,
    AVG(TOTAL_ELAPSED_TIME) / 1000 as avg_seconds,
    SUM(CREDITS_USED_CLOUD_SERVICES) as credits
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE QUERY_TAG LIKE '%cortex-agent%'
    AND START_TIME >= DATEADD(week, -1, CURRENT_TIMESTAMP())
GROUP BY 1
ORDER BY 1;
```

---

## Support and Feedback

If you encounter issues during testing:

1. Consult the `TROUBLESHOOTING.md` guide
2. Review Snowflake documentation
3. Share findings in project issues or Snowflake Community

**Remember:** This is community-supported software. Thorough testing in your environment is critical before production use.

