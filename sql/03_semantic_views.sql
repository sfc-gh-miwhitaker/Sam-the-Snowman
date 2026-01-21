/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * Module: 03_semantic_views.sql
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * PURPOSE:
 *   Create the semantic views that power Sam-the-Snowman's analytics tools.
 *
 * Synopsis:
 *   Creates semantic views for query performance, cost analysis, and warehouse operations.
 *
 * Description:
 *   This module creates three domain-specific semantic views that power
 *   Sam-the-Snowman's analytical capabilities:
 *
 *   1. query_performance - Query execution metrics, errors, and optimization insights
 *   2. cost_analysis - Warehouse credit consumption and cost tracking
 *   3. warehouse_operations - Warehouse utilization and capacity planning
 *
 * BEST PRACTICES DEMONSTRATED:
 *   ✓ Rich descriptions with business context and actionable guidance
 *   ✓ Comprehensive synonyms covering natural language variations
 *   ✓ Sample values for categorical dimensions
 *   ✓ Time dimensions for date/timestamp columns
 *   ✓ Pre-defined metrics for common aggregations
 *   ✓ Named filters for reusable query patterns
 *   ✓ Table relationships for multi-table queries
 *   ✓ Module-specific custom instructions for LLM guidance
 *   ✓ 5+ verified queries per view covering common use cases
 *
 * OBJECTS CREATED:
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_QUERY_PERFORMANCE (Semantic View)
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_COST_ANALYSIS (Semantic View)
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_WAREHOUSE_OPERATIONS (Semantic View)
 *
 * REFERENCE FILES:
 *   Corresponding YAML reference files are in /semantic_models/ directory:
 *   - sv_sam_query_performance.yaml
 *   - sv_sam_cost_analysis.yaml
 *   - sv_sam_warehouse_operations.yaml
 *
 * Prerequisites:
 *   - 01_scaffolding.sql must be run first (deploy_all.sql handles this automatically)
 *   - Configured role must have access to SNOWFLAKE.ACCOUNT_USAGE views
 *
 * Author: SE Community
 * Created: 2025-11-25
 * Expires: 2026-02-14
 * Version: 5.0
 * License: Apache 2.0
 *
 * Usage:
 *   This module is called by deploy_all.sql or can be run standalone
 *   after setting configuration variables and creating scaffolding.
 ******************************************************************************/

USE ROLE SYSADMIN;
USE WAREHOUSE SFE_SAM_SNOWMAN_WH;
USE SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS;

-- ============================================================================
-- SEMANTIC VIEW: SV_SAM_QUERY_PERFORMANCE
-- ============================================================================
-- Purpose: Analyze query execution, identify slow queries, errors, and optimization opportunities
-- Data Sources: QUERY_HISTORY, QUERY_ATTRIBUTION_HISTORY
-- Key Metrics: Execution time, spilling, cache efficiency, error rates
--
-- Best Practices Implemented:
-- ✓ Table relationships for multi-table queries
-- ✓ Time dimensions for date/timestamp columns
-- ✓ Pre-defined metrics for common aggregations
-- ✓ Named filters for reusable query patterns
-- ✓ Sample values in dimension comments
-- ✓ Expanded synonyms covering natural language variations
-- ✓ Rich contextual descriptions explaining metric implications
-- ✓ 7 verified queries demonstrating common use cases
-- ✓ Module-specific custom instructions for LLM guidance
-- ✓ Strategic filtering (excludes system-managed warehouses)

CREATE OR REPLACE SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_QUERY_PERFORMANCE
TABLES (
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        PRIMARY KEY (QUERY_ID)
        COMMENT 'Historical record of all queries executed. Contains execution metrics, resource consumption, and error information. Data has ~45 minute latency.',
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY
        PRIMARY KEY (QUERY_ID)
        COMMENT 'Credit attribution data linking queries to compute costs. Enables cost-per-query analysis.'
)
RELATIONSHIPS (
    QUERY_HISTORY(QUERY_ID) -> QUERY_ATTRIBUTION_HISTORY(QUERY_ID) AS query_to_attribution
        COMMENT 'Links queries to their attributed compute costs.'
)
FACTS (
    -- Data Volume Metrics
    QUERY_HISTORY.BYTES_SCANNED AS BYTES_SCANNED
        COMMENT 'Total bytes scanned. Higher values indicate more data processing. Compare across similar queries for optimization. Synonyms: data scanned, scan volume, bytes read, data processed.',
    QUERY_HISTORY.BYTES_SPILLED_TO_LOCAL_STORAGE AS BYTES_SPILLED_TO_LOCAL_STORAGE
        COMMENT 'Memory spillage to local SSD indicating memory pressure. Non-zero values suggest query needs more memory. Synonyms: local spill, disk spill, SSD spill, memory spill.',
    QUERY_HISTORY.BYTES_SPILLED_TO_REMOTE_STORAGE AS BYTES_SPILLED_TO_REMOTE_STORAGE
        COMMENT 'CRITICAL: Memory spillage to remote cloud storage indicating SEVERE performance degradation. Non-zero values require immediate attention - upsize warehouse or optimize query. Synonyms: remote spill, S3 spill, cloud storage spill, severe spill.',

    -- Timing Metrics
    QUERY_HISTORY.COMPILATION_TIME AS COMPILATION_TIME
        COMMENT 'Query compilation/parsing time (milliseconds). High values (>1000ms) indicate complex query needing simplification. Synonyms: parse time, planning time, compile time.',
    QUERY_HISTORY.EXECUTION_TIME AS EXECUTION_TIME
        COMMENT 'Actual query execution time (milliseconds), excluding queuing. Primary metric for query performance. Synonyms: runtime, run time, processing time, execution duration.',
    QUERY_HISTORY.TOTAL_ELAPSED_TIME AS TOTAL_ELAPSED_TIME
        COMMENT 'Total query duration including compilation, queuing, and execution (milliseconds). This is what users experience. Synonyms: duration, total time, wall time, elapsed time, latency, response time.',
    QUERY_HISTORY.QUEUED_OVERLOAD_TIME AS QUEUED_OVERLOAD_TIME
        COMMENT 'Queue wait due to warehouse load (milliseconds). Non-zero indicates insufficient concurrency - consider multi-cluster. Synonyms: wait time, queue time, overload time, concurrency wait.',
    QUERY_HISTORY.QUEUED_PROVISIONING_TIME AS QUEUED_PROVISIONING_TIME
        COMMENT 'Queue wait for warehouse startup (milliseconds). Occurs during warehouse resume. Consider auto-resume for latency-sensitive workloads. Synonyms: startup wait, cold start time, warmup time.',

    -- Result Metrics
    QUERY_HISTORY.ROWS_PRODUCED AS ROWS_PRODUCED
        COMMENT 'Rows returned by query. Useful for identifying large result sets. Synonyms: result rows, output rows, rows returned, row count.',

    -- Partition Metrics
    QUERY_HISTORY.PARTITIONS_SCANNED AS PARTITIONS_SCANNED
        COMMENT 'Micro-partitions scanned. Compare to PARTITIONS_TOTAL for pruning efficiency. High ratio = poor clustering or missing filters. Synonyms: partitions read, partitions accessed.',
    QUERY_HISTORY.PARTITIONS_TOTAL AS PARTITIONS_TOTAL
        COMMENT 'Total micro-partitions in queried tables. Use with PARTITIONS_SCANNED to calculate pruning efficiency. Synonyms: total partitions, available partitions.',

    -- Cache Metrics
    QUERY_HISTORY.PERCENTAGE_SCANNED_FROM_CACHE AS PERCENTAGE_SCANNED_FROM_CACHE
        COMMENT 'Cache hit rate (0-100%). Higher = better cache utilization and lower costs. Synonyms: cache hit rate, cache hit, cache efficiency, cached percentage.',

    -- Cost Metrics
    QUERY_ATTRIBUTION_HISTORY.CREDITS_ATTRIBUTED_COMPUTE AS CREDITS_ATTRIBUTED_COMPUTE
        COMMENT 'Compute credits consumed by this query. Primary metric for query-level cost analysis. Synonyms: query cost, compute cost, query credits, query spend.'
)
DIMENSIONS (
    QUERY_HISTORY.QUERY_ID AS QUERY_ID
        COMMENT 'Unique query identifier (UUID). Use for profiling and Query Profile lookup. Synonyms: query uuid, query identifier, execution id.'
        UNIQUE,
    QUERY_HISTORY.QUERY_TEXT AS QUERY_TEXT
        COMMENT 'Complete SQL statement. May be truncated for long queries. Synonyms: SQL, query statement, SQL text, statement, code.',
    QUERY_HISTORY.QUERY_TYPE AS QUERY_TYPE
        COMMENT 'Statement type (SELECT, INSERT, UPDATE, DELETE, CREATE, MERGE, COPY, UNLOAD). Synonyms: query category, statement type, operation type.'
        SAMPLE VALUES ('SELECT', 'INSERT', 'UPDATE', 'DELETE', 'CREATE_TABLE', 'CREATE_TABLE_AS_SELECT', 'MERGE', 'COPY'),
    QUERY_HISTORY.EXECUTION_STATUS AS EXECUTION_STATUS
        COMMENT 'Query outcome: SUCCESS (completed), FAIL (errors), INCIDENT (system issues). Synonyms: query status, execution result, outcome.'
        SAMPLE VALUES ('SUCCESS', 'FAIL', 'INCIDENT'),
    QUERY_HISTORY.ERROR_CODE AS ERROR_CODE
        COMMENT 'Numeric error code for failed queries. NULL for successful. Reference Snowflake docs for meanings. Synonyms: failure code, error number.',
    QUERY_HISTORY.ERROR_MESSAGE AS ERROR_MESSAGE
        COMMENT 'Detailed error description for debugging. NULL for successful queries. Synonyms: failure reason, error details, failure message.',
    QUERY_HISTORY.USER_NAME AS USER_NAME
        COMMENT 'User who executed the query. Synonyms: username, query user, executing user, submitted by, who.',
    QUERY_HISTORY.ROLE_NAME AS ROLE_NAME
        COMMENT 'Active role during execution. Determines data access permissions. Synonyms: query role, execution role, active role.',
    QUERY_HISTORY.WAREHOUSE_NAME AS WAREHOUSE_NAME
        COMMENT 'Warehouse that executed the query (e.g., COMPUTE_WH, ANALYTICS_WH). System warehouses filtered. Synonyms: compute cluster, virtual warehouse, compute.'
        SAMPLE VALUES ('COMPUTE_WH', 'ANALYTICS_WH', 'ETL_WH', 'TRANSFORM_WH', 'LOADING_WH'),
    QUERY_HISTORY.WAREHOUSE_SIZE AS WAREHOUSE_SIZE
        COMMENT 'Warehouse T-shirt size. Larger = more compute power + higher cost. Synonyms: warehouse tier, compute size, cluster size.'
        SAMPLE VALUES ('X-Small', 'Small', 'Medium', 'Large', 'X-Large', '2X-Large', '3X-Large'),
    QUERY_HISTORY.DATABASE_NAME AS DATABASE_NAME
        COMMENT 'Primary database accessed. Synonyms: database, db.',
    QUERY_HISTORY.SCHEMA_NAME AS SCHEMA_NAME
        COMMENT 'Primary schema accessed. Synonyms: schema.'
)
TIME DIMENSIONS (
    QUERY_HISTORY.START_TIME AS START_TIME
        COMMENT 'Query start timestamp (UTC). Primary time dimension for trending. Synonyms: begin time, execution start, query time, when.',
    QUERY_HISTORY.END_TIME AS END_TIME
        COMMENT 'Query completion timestamp (UTC). Synonyms: completion time, finish time, completed at.'
)
METRICS (
    -- Volume Metrics
    'QUERY_COUNT' AS COUNT(QUERY_HISTORY.QUERY_ID)
        COMMENT 'Total queries executed. Synonyms: number of queries, total queries, query volume.',

    -- Performance Metrics
    'AVG_EXECUTION_TIME_MS' AS AVG(QUERY_HISTORY.EXECUTION_TIME)
        COMMENT 'Average execution time (ms). Key performance metric. Synonyms: average runtime, mean execution time.',
    'AVG_TOTAL_ELAPSED_TIME_MS' AS AVG(QUERY_HISTORY.TOTAL_ELAPSED_TIME)
        COMMENT 'Average total duration (ms). User-perceived latency. Synonyms: average duration, avg latency.',
    'P95_EXECUTION_TIME_MS' AS APPROX_PERCENTILE(QUERY_HISTORY.EXECUTION_TIME, 0.95)
        COMMENT '95th percentile execution time. Worst-case excluding outliers. Synonyms: p95 latency, tail latency.',

    -- Data Volume Metrics
    'TOTAL_BYTES_SCANNED' AS SUM(QUERY_HISTORY.BYTES_SCANNED)
        COMMENT 'Total bytes scanned across queries. Synonyms: total data scanned.',
    'TOTAL_BYTES_SPILLED' AS SUM(QUERY_HISTORY.BYTES_SPILLED_TO_LOCAL_STORAGE + QUERY_HISTORY.BYTES_SPILLED_TO_REMOTE_STORAGE)
        COMMENT 'Total spill (local + remote). Memory pressure indicator. Synonyms: total spill.',

    -- Quality Metrics
    'ERROR_RATE' AS (100.0 * SUM(CASE WHEN QUERY_HISTORY.EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0))
        COMMENT 'Failure percentage. Key quality metric. Synonyms: failure rate, error percentage.',
    'FAILED_QUERY_COUNT' AS SUM(CASE WHEN QUERY_HISTORY.EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END)
        COMMENT 'Number of failed queries. Synonyms: failures, error count.',

    -- Cache Metrics
    'AVG_CACHE_HIT_RATE' AS AVG(QUERY_HISTORY.PERCENTAGE_SCANNED_FROM_CACHE)
        COMMENT 'Average cache utilization. Synonyms: average cache hit.',

    -- Efficiency Metrics
    'PARTITION_PRUNING_EFFICIENCY' AS (100.0 * (1 - SUM(QUERY_HISTORY.PARTITIONS_SCANNED) / NULLIF(SUM(QUERY_HISTORY.PARTITIONS_TOTAL), 0)))
        COMMENT 'Partition pruning success rate. Higher = better. Synonyms: pruning efficiency.',

    -- Cost Metrics
    'TOTAL_CREDITS_USED' AS SUM(QUERY_ATTRIBUTION_HISTORY.CREDITS_ATTRIBUTED_COMPUTE)
        COMMENT 'Total compute credits consumed. Synonyms: total cost, credits consumed.'
)
FILTERS (
    'EXCLUDE_SYSTEM_WAREHOUSES' AS (QUERY_HISTORY.WAREHOUSE_NAME NOT LIKE 'SYSTEM$%')
        COMMENT 'Exclude system-managed warehouses users cannot control.',
    'SUCCESSFUL_QUERIES' AS (QUERY_HISTORY.EXECUTION_STATUS = 'SUCCESS')
        COMMENT 'Include only successful queries.',
    'FAILED_QUERIES' AS (QUERY_HISTORY.EXECUTION_STATUS = 'FAIL')
        COMMENT 'Include only failed queries for error analysis.',
    'QUERIES_WITH_SPILLING' AS (QUERY_HISTORY.BYTES_SPILLED_TO_LOCAL_STORAGE > 0 OR QUERY_HISTORY.BYTES_SPILLED_TO_REMOTE_STORAGE > 0)
        COMMENT 'Queries with memory spilling.',
    'QUERIES_WITH_REMOTE_SPILLING' AS (QUERY_HISTORY.BYTES_SPILLED_TO_REMOTE_STORAGE > 0)
        COMMENT 'Queries with severe remote spilling.',
    'QUERIES_WITH_QUEUING' AS (QUERY_HISTORY.QUEUED_OVERLOAD_TIME > 0 OR QUERY_HISTORY.QUEUED_PROVISIONING_TIME > 0)
        COMMENT 'Queries that experienced queue wait.',
    'SELECT_QUERIES' AS (QUERY_HISTORY.QUERY_TYPE = 'SELECT')
        COMMENT 'Read workload only.',
    'DML_QUERIES' AS (QUERY_HISTORY.QUERY_TYPE IN ('INSERT', 'UPDATE', 'DELETE', 'MERGE'))
        COMMENT 'Write workload only.',
    'TODAY' AS (QUERY_HISTORY.START_TIME >= CURRENT_DATE())
        COMMENT 'Today only.',
    'LAST_7_DAYS' AS (QUERY_HISTORY.START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP()))
        COMMENT 'Past week.',
    'LAST_30_DAYS' AS (QUERY_HISTORY.START_TIME >= DATEADD(DAY, -30, CURRENT_TIMESTAMP()))
        COMMENT 'Past month.'
)
COMMENT = 'DEMO: Sam-the-Snowman - Query performance analytics. Analyze execution times, identify slow queries, detect memory spilling, evaluate cache efficiency, and track errors. Excludes system-managed warehouses. (Expires: 2026-02-14)'
WITH EXTENSION (CA = '{
  "module_custom_instructions": {
    "sql_generation": "CRITICAL RULES: 1) ALWAYS exclude system warehouses: WHERE WAREHOUSE_NAME NOT LIKE ''SYSTEM$%'' 2) For slow queries use TOTAL_ELAPSED_TIME (user-perceived) 3) For execution time use EXECUTION_TIME (actual processing) 4) Time is milliseconds - divide by 1000 for seconds 5) Use APPROX_PERCENTILE for percentiles 6) Always include QUERY_ID and QUERY_TEXT for top N queries. DATA LATENCY: ACCOUNT_USAGE has ~45 min latency. SPILLING: Local=minor issue, Remote=CRITICAL.",
    "question_categorization": "UNAMBIGUOUS_SQL: slowest queries=ORDER BY TOTAL_ELAPSED_TIME DESC, expensive queries=ORDER BY CREDITS_ATTRIBUTED_COMPUTE DESC, query errors=WHERE EXECUTION_STATUS=''FAIL'', spilling=WHERE BYTES_SPILLED>0. ASK FOR CLARIFICATION: performance issues (too vague)."
  },
  "verified_queries": [
    {
      "name": "Top 10 slowest queries today",
      "question": "What were my slowest queries today?",
      "verified_at": "2025-01-20",
      "verified_by": "SE Community",
      "sql": "SELECT QUERY_ID, QUERY_TEXT, TOTAL_ELAPSED_TIME/1000 AS duration_seconds, WAREHOUSE_NAME, USER_NAME FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY WHERE START_TIME >= CURRENT_DATE() AND WAREHOUSE_NAME NOT LIKE ''SYSTEM$%'' ORDER BY TOTAL_ELAPSED_TIME DESC LIMIT 10"
    },
    {
      "name": "Queries with remote storage spillage",
      "question": "Which queries spilled to remote storage this week?",
      "verified_at": "2025-01-20",
      "verified_by": "SE Community",
      "sql": "SELECT QUERY_ID, QUERY_TEXT, BYTES_SPILLED_TO_REMOTE_STORAGE/(1024*1024*1024) AS remote_spill_gb, WAREHOUSE_SIZE, WAREHOUSE_NAME, TOTAL_ELAPSED_TIME/1000 AS duration_seconds FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP()) AND BYTES_SPILLED_TO_REMOTE_STORAGE > 0 AND WAREHOUSE_NAME NOT LIKE ''SYSTEM$%'' ORDER BY BYTES_SPILLED_TO_REMOTE_STORAGE DESC LIMIT 20"
    },
    {
      "name": "Most common query errors",
      "question": "What are the most common query errors?",
      "verified_at": "2025-01-20",
      "verified_by": "SE Community",
      "sql": "SELECT ERROR_CODE, ERROR_MESSAGE, COUNT(*) AS failure_count, COUNT(DISTINCT USER_NAME) AS affected_users FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY WHERE EXECUTION_STATUS = ''FAIL'' AND START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP()) AND WAREHOUSE_NAME NOT LIKE ''SYSTEM$%'' GROUP BY ERROR_CODE, ERROR_MESSAGE ORDER BY failure_count DESC LIMIT 10"
    },
    {
      "name": "Query performance by warehouse",
      "question": "Show average query performance by warehouse",
      "verified_at": "2025-01-20",
      "verified_by": "SE Community",
      "sql": "SELECT WAREHOUSE_NAME, WAREHOUSE_SIZE, COUNT(*) AS query_count, AVG(TOTAL_ELAPSED_TIME)/1000 AS avg_duration_seconds, APPROX_PERCENTILE(TOTAL_ELAPSED_TIME, 0.95)/1000 AS p95_duration_seconds, SUM(CASE WHEN EXECUTION_STATUS = ''FAIL'' THEN 1 ELSE 0 END)*100.0/COUNT(*) AS error_rate_pct FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP()) AND WAREHOUSE_NAME NOT LIKE ''SYSTEM$%'' GROUP BY WAREHOUSE_NAME, WAREHOUSE_SIZE ORDER BY query_count DESC"
    },
    {
      "name": "Queries with poor partition pruning",
      "question": "Which queries had poor partition pruning efficiency?",
      "verified_at": "2025-01-20",
      "verified_by": "SE Community",
      "sql": "SELECT QUERY_ID, QUERY_TEXT, PARTITIONS_SCANNED, PARTITIONS_TOTAL, ROUND(PARTITIONS_SCANNED*100.0/NULLIF(PARTITIONS_TOTAL, 0), 2) AS scan_percentage, WAREHOUSE_NAME FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP()) AND PARTITIONS_TOTAL > 100 AND PARTITIONS_SCANNED > PARTITIONS_TOTAL*0.5 AND WAREHOUSE_NAME NOT LIKE ''SYSTEM$%'' ORDER BY PARTITIONS_SCANNED DESC LIMIT 20"
    },
    {
      "name": "User query activity",
      "question": "Show query activity by user",
      "verified_at": "2025-01-20",
      "verified_by": "SE Community",
      "sql": "SELECT USER_NAME, COUNT(*) AS query_count, SUM(CASE WHEN EXECUTION_STATUS = ''FAIL'' THEN 1 ELSE 0 END) AS failed_queries, AVG(TOTAL_ELAPSED_TIME)/1000 AS avg_duration_seconds, SUM(BYTES_SCANNED)/(1024*1024*1024) AS total_gb_scanned FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP()) AND WAREHOUSE_NAME NOT LIKE ''SYSTEM$%'' GROUP BY USER_NAME ORDER BY query_count DESC LIMIT 20"
    },
    {
      "name": "Hourly query volume trend",
      "question": "Show query volume by hour for the past week",
      "verified_at": "2025-01-20",
      "verified_by": "SE Community",
      "sql": "SELECT DATE_TRUNC(''HOUR'', START_TIME) AS hour, COUNT(*) AS query_count, AVG(TOTAL_ELAPSED_TIME)/1000 AS avg_duration_seconds, SUM(CASE WHEN EXECUTION_STATUS = ''FAIL'' THEN 1 ELSE 0 END) AS failures FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP()) AND WAREHOUSE_NAME NOT LIKE ''SYSTEM$%'' GROUP BY hour ORDER BY hour DESC"
    }
  ]
}');


-- ============================================================================
-- SEMANTIC VIEW: SV_SAM_COST_ANALYSIS
-- ============================================================================
-- Purpose: Track warehouse credit consumption and identify cost optimization opportunities
-- Data Sources: WAREHOUSE_METERING_HISTORY
-- Key Metrics: Credits used, compute costs, cloud services costs
--
-- Best Practices Implemented:
-- ✓ Time dimensions for date/timestamp columns
-- ✓ Pre-defined metrics for common aggregations
-- ✓ Named filters for reusable query patterns
-- ✓ Comprehensive synonyms for financial terminology
-- ✓ Rich contextual descriptions for cost interpretation
-- ✓ 6 verified queries for common FinOps scenarios
-- ✓ Module-specific custom instructions for LLM guidance
-- ✓ Clear distinction between compute and cloud services costs

CREATE OR REPLACE SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_COST_ANALYSIS
TABLES (
    SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
        PRIMARY KEY (WAREHOUSE_ID, START_TIME)
        COMMENT 'Hourly credit consumption for all warehouses. Contains compute and cloud services credits. Primary source for cost analysis.'
)
FACTS (
    WAREHOUSE_METERING_HISTORY.CREDITS_USED AS CREDITS_USED
        COMMENT 'Total credits consumed (compute + cloud services). Primary cost metric. Multiply by credit price for dollar costs. Synonyms: total cost, spend, warehouse cost, total spend, credits consumed, billing amount, cost, credits.',
    WAREHOUSE_METERING_HISTORY.CREDITS_USED_COMPUTE AS CREDITS_USED_COMPUTE
        COMMENT 'Compute credits for query execution. Typically 90%+ of total. Scales with warehouse size and runtime. Synonyms: compute cost, compute credits, compute spend, execution cost, query cost.',
    WAREHOUSE_METERING_HISTORY.CREDITS_USED_CLOUD_SERVICES AS CREDITS_USED_CLOUD_SERVICES
        COMMENT 'Cloud services credits for metadata operations and caching. Usually <10% of compute. High ratio may indicate inefficient small query patterns. Synonyms: services cost, cloud services spend, metadata cost, overhead cost.'
)
DIMENSIONS (
    WAREHOUSE_METERING_HISTORY.WAREHOUSE_NAME AS WAREHOUSE_NAME
        COMMENT 'Warehouse name (e.g., COMPUTE_WH, ANALYTICS_WH). System warehouses filtered. Synonyms: compute cluster, warehouse, virtual warehouse.'
        SAMPLE VALUES ('COMPUTE_WH', 'ANALYTICS_WH', 'ETL_WH', 'TRANSFORM_WH', 'LOADING_WH'),
    WAREHOUSE_METERING_HISTORY.WAREHOUSE_ID AS WAREHOUSE_ID
        COMMENT 'Unique warehouse ID. Persists across renames for tracking. Synonyms: warehouse uuid.'
        UNIQUE
)
TIME DIMENSIONS (
    WAREHOUSE_METERING_HISTORY.START_TIME AS START_TIME
        COMMENT 'Metering period start (UTC). Hourly intervals. Synonyms: period start, metering start, billing start, when, date.',
    WAREHOUSE_METERING_HISTORY.END_TIME AS END_TIME
        COMMENT 'Metering period end (UTC). Synonyms: period end, metering end.'
)
METRICS (
    'TOTAL_CREDITS' AS SUM(WAREHOUSE_METERING_HISTORY.CREDITS_USED)
        COMMENT 'Sum of all credits. Synonyms: total spend, total cost.',
    'TOTAL_COMPUTE_CREDITS' AS SUM(WAREHOUSE_METERING_HISTORY.CREDITS_USED_COMPUTE)
        COMMENT 'Sum of compute credits. Synonyms: compute total.',
    'TOTAL_CLOUD_SERVICES_CREDITS' AS SUM(WAREHOUSE_METERING_HISTORY.CREDITS_USED_CLOUD_SERVICES)
        COMMENT 'Sum of cloud services credits. Synonyms: services total.',
    'AVG_HOURLY_CREDITS' AS AVG(WAREHOUSE_METERING_HISTORY.CREDITS_USED)
        COMMENT 'Average hourly consumption. Synonyms: average hourly cost.',
    'MAX_HOURLY_CREDITS' AS MAX(WAREHOUSE_METERING_HISTORY.CREDITS_USED)
        COMMENT 'Peak hourly consumption. Synonyms: peak hourly cost.',
    'CLOUD_SERVICES_RATIO' AS (100.0 * SUM(WAREHOUSE_METERING_HISTORY.CREDITS_USED_CLOUD_SERVICES) / NULLIF(SUM(WAREHOUSE_METERING_HISTORY.CREDITS_USED), 0))
        COMMENT 'Cloud services as % of total. High (>10%) may indicate inefficiency. Synonyms: services percentage.',
    'METERING_PERIODS' AS COUNT(*)
        COMMENT 'Active hourly periods. Synonyms: active hours.',
    'DAILY_CREDITS' AS (SUM(WAREHOUSE_METERING_HISTORY.CREDITS_USED) / NULLIF(COUNT(DISTINCT DATE(WAREHOUSE_METERING_HISTORY.START_TIME)), 0))
        COMMENT 'Average daily consumption. Synonyms: daily spend.'
)
FILTERS (
    'EXCLUDE_SYSTEM_WAREHOUSES' AS (WAREHOUSE_METERING_HISTORY.WAREHOUSE_NAME NOT LIKE 'SYSTEM$%')
        COMMENT 'Exclude system-managed warehouses.',
    'TODAY' AS (WAREHOUSE_METERING_HISTORY.START_TIME >= CURRENT_DATE())
        COMMENT 'Today only.',
    'YESTERDAY' AS (DATE(WAREHOUSE_METERING_HISTORY.START_TIME) = DATEADD(DAY, -1, CURRENT_DATE()))
        COMMENT 'Yesterday only.',
    'LAST_7_DAYS' AS (WAREHOUSE_METERING_HISTORY.START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP()))
        COMMENT 'Past week.',
    'LAST_30_DAYS' AS (WAREHOUSE_METERING_HISTORY.START_TIME >= DATEADD(DAY, -30, CURRENT_TIMESTAMP()))
        COMMENT 'Past month.',
    'CURRENT_MONTH' AS (WAREHOUSE_METERING_HISTORY.START_TIME >= DATE_TRUNC('MONTH', CURRENT_DATE()))
        COMMENT 'Current calendar month. Synonyms: mtd.',
    'LAST_MONTH' AS (WAREHOUSE_METERING_HISTORY.START_TIME >= DATE_TRUNC('MONTH', DATEADD('MONTH', -1, CURRENT_DATE())) AND WAREHOUSE_METERING_HISTORY.START_TIME < DATE_TRUNC('MONTH', CURRENT_DATE()))
        COMMENT 'Previous calendar month.',
    'WITH_ACTIVITY' AS (WAREHOUSE_METERING_HISTORY.CREDITS_USED > 0)
        COMMENT 'Periods with consumption.'
)
COMMENT = 'DEMO: Sam-the-Snowman - Warehouse cost analysis. Track spending by warehouse, identify cost trends, support FinOps. Excludes system-managed warehouses. (Expires: 2026-02-14)'
WITH EXTENSION (CA = '{
  "module_custom_instructions": {
    "sql_generation": "CRITICAL RULES: 1) ALWAYS exclude system warehouses: WHERE WAREHOUSE_NAME NOT LIKE ''SYSTEM$%'' 2) Credits are Snowflake billing units - multiply by credit price for dollars 3) For most expensive, ORDER BY CREDITS_USED DESC 4) For trends, GROUP BY date/week/month 5) Always include WAREHOUSE_NAME. PATTERNS: Cost by warehouse=SUM(CREDITS_USED) GROUP BY WAREHOUSE_NAME, Daily spend=SUM GROUP BY DATE(START_TIME), Monthly trend=SUM GROUP BY DATE_TRUNC(''MONTH'', START_TIME).",
    "question_categorization": "UNAMBIGUOUS_SQL: most expensive warehouse=SUM credits GROUP BY warehouse ORDER BY DESC, daily spend=SUM GROUP BY date, monthly cost=SUM GROUP BY month. ASK: cost without time period or granularity."
  },
  "verified_queries": [
    {
      "name": "Most expensive warehouses last month",
      "question": "What were my most expensive warehouses last month?",
      "verified_at": "2025-01-20",
      "verified_by": "SE Community",
      "sql": "SELECT WAREHOUSE_NAME, SUM(CREDITS_USED) AS total_credits, SUM(CREDITS_USED_COMPUTE) AS compute_credits, SUM(CREDITS_USED_CLOUD_SERVICES) AS cloud_services_credits FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY WHERE START_TIME >= DATE_TRUNC(''MONTH'', DATEADD(''MONTH'', -1, CURRENT_DATE())) AND START_TIME < DATE_TRUNC(''MONTH'', CURRENT_DATE()) AND WAREHOUSE_NAME NOT LIKE ''SYSTEM$%'' GROUP BY WAREHOUSE_NAME ORDER BY total_credits DESC"
    },
    {
      "name": "Daily spend trend",
      "question": "Show me daily credit spend for the last 30 days",
      "verified_at": "2025-01-20",
      "verified_by": "SE Community",
      "sql": "SELECT DATE(START_TIME) AS usage_date, SUM(CREDITS_USED) AS daily_credits FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY WHERE START_TIME >= DATEADD(''DAY'', -30, CURRENT_TIMESTAMP()) AND WAREHOUSE_NAME NOT LIKE ''SYSTEM$%'' GROUP BY usage_date ORDER BY usage_date DESC"
    },
    {
      "name": "Cloud services ratio",
      "question": "Which warehouses have high cloud services costs?",
      "verified_at": "2025-01-20",
      "verified_by": "SE Community",
      "sql": "SELECT WAREHOUSE_NAME, SUM(CREDITS_USED_COMPUTE) AS compute_credits, SUM(CREDITS_USED_CLOUD_SERVICES) AS services_credits, ROUND(services_credits*100.0/NULLIF(compute_credits, 0), 2) AS services_percentage FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY WHERE START_TIME >= DATEADD(''DAY'', -7, CURRENT_TIMESTAMP()) AND WAREHOUSE_NAME NOT LIKE ''SYSTEM$%'' GROUP BY WAREHOUSE_NAME HAVING services_percentage > 10 ORDER BY services_percentage DESC"
    },
    {
      "name": "Hourly cost pattern",
      "question": "What is the hourly cost pattern by warehouse?",
      "verified_at": "2025-01-20",
      "verified_by": "SE Community",
      "sql": "SELECT WAREHOUSE_NAME, HOUR(START_TIME) AS hour_of_day, AVG(CREDITS_USED) AS avg_hourly_credits FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY WHERE START_TIME >= DATEADD(''DAY'', -7, CURRENT_TIMESTAMP()) AND WAREHOUSE_NAME NOT LIKE ''SYSTEM$%'' GROUP BY WAREHOUSE_NAME, hour_of_day ORDER BY WAREHOUSE_NAME, hour_of_day"
    },
    {
      "name": "Weekly cost comparison",
      "question": "Compare this week costs to last week by warehouse",
      "verified_at": "2025-01-20",
      "verified_by": "SE Community",
      "sql": "SELECT WAREHOUSE_NAME, SUM(CASE WHEN START_TIME >= DATEADD(''DAY'', -7, CURRENT_TIMESTAMP()) THEN CREDITS_USED ELSE 0 END) AS this_week_credits, SUM(CASE WHEN START_TIME >= DATEADD(''DAY'', -14, CURRENT_TIMESTAMP()) AND START_TIME < DATEADD(''DAY'', -7, CURRENT_TIMESTAMP()) THEN CREDITS_USED ELSE 0 END) AS last_week_credits, ROUND((this_week_credits - last_week_credits)*100.0/NULLIF(last_week_credits, 0), 2) AS wow_change_pct FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY WHERE START_TIME >= DATEADD(''DAY'', -14, CURRENT_TIMESTAMP()) AND WAREHOUSE_NAME NOT LIKE ''SYSTEM$%'' GROUP BY WAREHOUSE_NAME ORDER BY this_week_credits DESC"
    },
    {
      "name": "Monthly cost summary",
      "question": "Show monthly cost breakdown",
      "verified_at": "2025-01-20",
      "verified_by": "SE Community",
      "sql": "SELECT DATE_TRUNC(''MONTH'', START_TIME) AS month, COUNT(DISTINCT WAREHOUSE_NAME) AS active_warehouses, SUM(CREDITS_USED) AS total_credits, SUM(CREDITS_USED_COMPUTE) AS compute_credits, SUM(CREDITS_USED_CLOUD_SERVICES) AS cloud_services_credits FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY WHERE START_TIME >= DATEADD(''MONTH'', -6, CURRENT_TIMESTAMP()) AND WAREHOUSE_NAME NOT LIKE ''SYSTEM$%'' GROUP BY month ORDER BY month DESC"
    }
  ]
}');


-- ============================================================================
-- SEMANTIC VIEW: SV_SAM_WAREHOUSE_OPERATIONS
-- ============================================================================
-- Purpose: Monitor warehouse utilization, capacity, and identify sizing opportunities
-- Data Sources: WAREHOUSE_LOAD_HISTORY
-- Key Metrics: Concurrency, queue depth, blocked queries
--
-- Best Practices Implemented:
-- ✓ Time dimensions for date/timestamp columns
-- ✓ Pre-defined metrics for common aggregations
-- ✓ Named filters for reusable query patterns
-- ✓ Sample values in dimension comments
-- ✓ Expanded synonyms for operations terminology
-- ✓ Rich contextual descriptions for capacity planning
-- ✓ 7 verified queries for common operational scenarios
-- ✓ Module-specific custom instructions for LLM guidance
-- ✓ Clear explanation of queue types and their implications

CREATE OR REPLACE SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_WAREHOUSE_OPERATIONS
TABLES (
    SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
        PRIMARY KEY (WAREHOUSE_ID, START_TIME)
        COMMENT 'Time-series load metrics for warehouses. Captures concurrency, queue depth, and blocked queries. Essential for capacity planning.'
)
FACTS (
    WAREHOUSE_LOAD_HISTORY.AVG_RUNNING AS AVG_RUNNING
        COMMENT 'Average concurrent queries during measurement. High values = good utilization. Very high may need multi-cluster. Synonyms: concurrency, active queries, concurrent queries, running queries, parallel queries, utilization.',
    WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_LOAD AS AVG_QUEUED_LOAD
        COMMENT 'Average queries queued due to capacity. Non-zero = undersized or needs multi-cluster. Users experience wait time. Synonyms: queue depth, waiting queries, queued queries, overload queue, backlog.',
    WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_PROVISIONING AS AVG_QUEUED_PROVISIONING
        COMMENT 'Average queries queued during warehouse startup. Cold start impact. Consider auto-resume or always-on. Synonyms: startup queue, provisioning queue, cold start queue, warmup queue.',
    WAREHOUSE_LOAD_HISTORY.AVG_BLOCKED AS AVG_BLOCKED
        COMMENT 'Average queries blocked by locks. High values = lock contention from concurrent DML. Review transaction patterns. Synonyms: contentions, blocked queries, lock waits, resource conflicts, blocking.'
)
DIMENSIONS (
    WAREHOUSE_LOAD_HISTORY.WAREHOUSE_NAME AS WAREHOUSE_NAME
        COMMENT 'Warehouse name (e.g., COMPUTE_WH, ANALYTICS_WH). System warehouses filtered. Synonyms: compute cluster, warehouse, virtual warehouse.'
        SAMPLE VALUES ('COMPUTE_WH', 'ANALYTICS_WH', 'ETL_WH', 'TRANSFORM_WH', 'LOADING_WH'),
    WAREHOUSE_LOAD_HISTORY.WAREHOUSE_ID AS WAREHOUSE_ID
        COMMENT 'Unique warehouse ID. Persists across renames. Synonyms: warehouse uuid.'
        UNIQUE
)
TIME DIMENSIONS (
    WAREHOUSE_LOAD_HISTORY.START_TIME AS START_TIME
        COMMENT 'Measurement period start (UTC). Regular intervals. Synonyms: load start, measurement start, when, date.',
    WAREHOUSE_LOAD_HISTORY.END_TIME AS END_TIME
        COMMENT 'Measurement period end (UTC). Synonyms: load end, measurement end.'
)
METRICS (
    'MEASUREMENT_COUNT' AS COUNT(*)
        COMMENT 'Number of measurement periods. Sample size for reliability.',
    'AVG_CONCURRENCY' AS AVG(WAREHOUSE_LOAD_HISTORY.AVG_RUNNING)
        COMMENT 'Average concurrency. Key utilization metric. Synonyms: average running.',
    'MAX_CONCURRENCY' AS MAX(WAREHOUSE_LOAD_HISTORY.AVG_RUNNING)
        COMMENT 'Peak concurrency. Synonyms: peak load.',
    'AVG_QUEUE_DEPTH' AS AVG(WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_LOAD)
        COMMENT 'Average queue depth. Non-zero = capacity issues. Synonyms: average queued.',
    'MAX_QUEUE_DEPTH' AS MAX(WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_LOAD)
        COMMENT 'Peak queue depth. Worst-case scenario. Synonyms: peak queue.',
    'AVG_PROVISIONING_QUEUE' AS AVG(WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_PROVISIONING)
        COMMENT 'Average startup queue. Cold start impact. Synonyms: average provisioning wait.',
    'AVG_BLOCKED_COUNT' AS AVG(WAREHOUSE_LOAD_HISTORY.AVG_BLOCKED)
        COMMENT 'Average blocked queries. Lock contention severity. Synonyms: average contentions.',
    'PERIODS_WITH_QUEUING' AS SUM(CASE WHEN WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_LOAD > 0 THEN 1 ELSE 0 END)
        COMMENT 'Periods with active queuing. Synonyms: queuing frequency.',
    'QUEUING_PERCENTAGE' AS (100.0 * SUM(CASE WHEN WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_LOAD > 0 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0))
        COMMENT 'Percentage of time with queuing. Key SLA metric. Synonyms: queue frequency percent.',
    'PERIODS_WITH_BLOCKING' AS SUM(CASE WHEN WAREHOUSE_LOAD_HISTORY.AVG_BLOCKED > 0 THEN 1 ELSE 0 END)
        COMMENT 'Periods with blocked queries. Synonyms: blocking frequency.'
)
FILTERS (
    'EXCLUDE_SYSTEM_WAREHOUSES' AS (WAREHOUSE_LOAD_HISTORY.WAREHOUSE_NAME NOT LIKE 'SYSTEM$%')
        COMMENT 'Exclude system-managed warehouses.',
    'WITH_QUEUING' AS (WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_LOAD > 0)
        COMMENT 'Only periods with queuing.',
    'WITH_BLOCKING' AS (WAREHOUSE_LOAD_HISTORY.AVG_BLOCKED > 0)
        COMMENT 'Only periods with blocking.',
    'WITH_ACTIVITY' AS (WAREHOUSE_LOAD_HISTORY.AVG_RUNNING > 0)
        COMMENT 'Only periods with running queries.',
    'HIGH_LOAD' AS (WAREHOUSE_LOAD_HISTORY.AVG_RUNNING > 5)
        COMMENT 'High concurrency periods.',
    'TODAY' AS (WAREHOUSE_LOAD_HISTORY.START_TIME >= CURRENT_DATE())
        COMMENT 'Today only.',
    'LAST_7_DAYS' AS (WAREHOUSE_LOAD_HISTORY.START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP()))
        COMMENT 'Past week.',
    'LAST_30_DAYS' AS (WAREHOUSE_LOAD_HISTORY.START_TIME >= DATEADD(DAY, -30, CURRENT_TIMESTAMP()))
        COMMENT 'Past month.'
)
COMMENT = 'DEMO: Sam-the-Snowman - Warehouse utilization and capacity planning. Monitor concurrency, queue depth, and sizing opportunities. Excludes system-managed warehouses. (Expires: 2026-02-14)'
WITH EXTENSION (CA = '{
  "module_custom_instructions": {
    "sql_generation": "CRITICAL RULES: 1) ALWAYS exclude system warehouses: WHERE WAREHOUSE_NAME NOT LIKE ''SYSTEM$%'' 2) AVG_RUNNING=concurrency/utilization 3) AVG_QUEUED_LOAD=capacity constraints/undersizing 4) AVG_QUEUED_PROVISIONING=cold start impact 5) AVG_BLOCKED=lock contention. SIZING: High queue=consider upsize/multi-cluster, High blocking=review transactions, Low running with no queue=may be oversized.",
    "question_categorization": "UNAMBIGUOUS_SQL: utilization=AVG(AVG_RUNNING) GROUP BY warehouse, queue times=AVG(AVG_QUEUED_LOAD), blocking=AVG(AVG_BLOCKED). ASK: sizing without specific warehouse."
  },
  "verified_queries": [
    {
      "name": "Warehouses with queuing",
      "question": "Which warehouses have the most queued queries?",
      "verified_at": "2025-01-20",
      "verified_by": "SE Community",
      "sql": "SELECT WAREHOUSE_NAME, AVG(AVG_QUEUED_LOAD) AS avg_queue_depth, MAX(AVG_QUEUED_LOAD) AS max_queue_depth, SUM(CASE WHEN AVG_QUEUED_LOAD > 0 THEN 1 ELSE 0 END) AS periods_with_queuing, COUNT(*) AS total_periods, ROUND(periods_with_queuing*100.0/total_periods, 2) AS queuing_pct FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP()) AND WAREHOUSE_NAME NOT LIKE ''SYSTEM$%'' GROUP BY WAREHOUSE_NAME HAVING avg_queue_depth > 0 ORDER BY avg_queue_depth DESC"
    },
    {
      "name": "Hourly concurrency pattern",
      "question": "Show warehouse concurrency by hour of day",
      "verified_at": "2025-01-20",
      "verified_by": "SE Community",
      "sql": "SELECT WAREHOUSE_NAME, HOUR(START_TIME) AS hour_of_day, AVG(AVG_RUNNING) AS avg_concurrency, AVG(AVG_QUEUED_LOAD) AS avg_queue_depth FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP()) AND WAREHOUSE_NAME NOT LIKE ''SYSTEM$%'' GROUP BY WAREHOUSE_NAME, hour_of_day ORDER BY WAREHOUSE_NAME, hour_of_day"
    },
    {
      "name": "Lock contention analysis",
      "question": "Which warehouses have lock contention issues?",
      "verified_at": "2025-01-20",
      "verified_by": "SE Community",
      "sql": "SELECT WAREHOUSE_NAME, AVG(AVG_BLOCKED) AS avg_blocked_queries, MAX(AVG_BLOCKED) AS max_blocked_queries, SUM(CASE WHEN AVG_BLOCKED > 0 THEN 1 ELSE 0 END) AS periods_with_blocking, COUNT(*) AS total_periods FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP()) AND WAREHOUSE_NAME NOT LIKE ''SYSTEM$%'' GROUP BY WAREHOUSE_NAME HAVING avg_blocked_queries > 0 ORDER BY avg_blocked_queries DESC"
    },
    {
      "name": "Warehouse utilization summary",
      "question": "Show overall warehouse utilization",
      "verified_at": "2025-01-20",
      "verified_by": "SE Community",
      "sql": "SELECT WAREHOUSE_NAME, AVG(AVG_RUNNING) AS avg_concurrency, MAX(AVG_RUNNING) AS peak_concurrency, AVG(AVG_QUEUED_LOAD) AS avg_queue_depth, AVG(AVG_QUEUED_PROVISIONING) AS avg_provisioning_queue, AVG(AVG_BLOCKED) AS avg_blocked FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP()) AND WAREHOUSE_NAME NOT LIKE ''SYSTEM$%'' GROUP BY WAREHOUSE_NAME ORDER BY avg_concurrency DESC"
    },
    {
      "name": "Cold start impact",
      "question": "Which warehouses have provisioning delays?",
      "verified_at": "2025-01-20",
      "verified_by": "SE Community",
      "sql": "SELECT WAREHOUSE_NAME, AVG(AVG_QUEUED_PROVISIONING) AS avg_provisioning_queue, MAX(AVG_QUEUED_PROVISIONING) AS max_provisioning_queue, SUM(CASE WHEN AVG_QUEUED_PROVISIONING > 0 THEN 1 ELSE 0 END) AS cold_start_events FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP()) AND WAREHOUSE_NAME NOT LIKE ''SYSTEM$%'' GROUP BY WAREHOUSE_NAME HAVING cold_start_events > 0 ORDER BY cold_start_events DESC"
    },
    {
      "name": "Sizing recommendations",
      "question": "Which warehouses may need resizing?",
      "verified_at": "2025-01-20",
      "verified_by": "SE Community",
      "sql": "SELECT WAREHOUSE_NAME, AVG(AVG_RUNNING) AS avg_concurrency, AVG(AVG_QUEUED_LOAD) AS avg_queue_depth, CASE WHEN AVG(AVG_QUEUED_LOAD) > 1 THEN ''CONSIDER UPSIZE - High queuing'' WHEN AVG(AVG_RUNNING) < 1 AND AVG(AVG_QUEUED_LOAD) = 0 THEN ''CONSIDER DOWNSIZE - Low utilization'' ELSE ''APPROPRIATE SIZE'' END AS sizing_recommendation FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP()) AND WAREHOUSE_NAME NOT LIKE ''SYSTEM$%'' GROUP BY WAREHOUSE_NAME ORDER BY avg_queue_depth DESC, avg_concurrency DESC"
    },
    {
      "name": "Daily load trend",
      "question": "Show daily warehouse load trend",
      "verified_at": "2025-01-20",
      "verified_by": "SE Community",
      "sql": "SELECT DATE(START_TIME) AS load_date, WAREHOUSE_NAME, AVG(AVG_RUNNING) AS avg_concurrency, AVG(AVG_QUEUED_LOAD) AS avg_queue_depth FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY WHERE START_TIME >= DATEADD(DAY, -14, CURRENT_TIMESTAMP()) AND WAREHOUSE_NAME NOT LIKE ''SYSTEM$%'' GROUP BY load_date, WAREHOUSE_NAME ORDER BY load_date DESC, WAREHOUSE_NAME"
    }
  ]
}');


-- Semantic views complete
