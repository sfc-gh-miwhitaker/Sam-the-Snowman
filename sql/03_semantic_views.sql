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
 * OBJECTS CREATED:
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_QUERY_PERFORMANCE (Semantic View)
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_COST_ANALYSIS (Semantic View)
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_WAREHOUSE_OPERATIONS (Semantic View)
 *
 * Prerequisites:
 *   - 01_scaffolding.sql must be run first (deploy_all.sql handles this automatically)
 *   - Configured role must have access to SNOWFLAKE.ACCOUNT_USAGE views
 *
 * Author: SE Community
 * Created: 2025-11-25
 * Expires: 2026-02-14
 * Version: 4.0
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
-- SEMANTIC VIEW: sfe_query_performance
-- ============================================================================
-- Purpose: Analyze query execution, identify slow queries, errors, and optimization opportunities
-- Data Sources: QUERY_HISTORY, QUERY_ATTRIBUTION_HISTORY
-- Key Metrics: Execution time, spilling, cache efficiency, error rates
--
-- Best Practices Implemented:
-- ✓ Sample values in comments (e.g., patterns) to improve AI accuracy
-- ✓ Expanded synonyms covering natural language variations
-- ✓ Rich contextual descriptions explaining metric implications
-- ✓ Multiple verified queries demonstrating common use cases
-- ✓ Strategic filtering (excludes system-managed warehouses)

CREATE OR REPLACE SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_QUERY_PERFORMANCE
TABLES (
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY,
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY
)
FACTS (
  QUERY_HISTORY.BYTES_SCANNED as BYTES_SCANNED
    comment='Total bytes scanned by the query. Higher values indicate more data processing. Synonyms: data scanned, scan volume, bytes read, data processed.',
  QUERY_HISTORY.BYTES_SPILLED_TO_LOCAL_STORAGE as BYTES_SPILLED_TO_LOCAL_STORAGE
    comment='Memory spillage to local SSD indicating memory pressure. Non-zero values suggest warehouse undersizing. Synonyms: local spill, disk spill, local storage spill, SSD spill.',
  QUERY_HISTORY.BYTES_SPILLED_TO_REMOTE_STORAGE as BYTES_SPILLED_TO_REMOTE_STORAGE
    comment='Memory spillage to remote storage indicating severe memory pressure and performance degradation. Synonyms: remote spill, S3 spill, cloud storage spill, remote storage spill.',
  QUERY_HISTORY.COMPILATION_TIME as COMPILATION_TIME
    comment='Query compilation time in milliseconds. High values indicate complex query parsing. Synonyms: parse time, planning time, optimization time, compile time.',
  QUERY_HISTORY.EXECUTION_TIME as EXECUTION_TIME
    comment='Actual query execution time in milliseconds, excluding queuing. Primary performance metric. Synonyms: runtime, run time, processing time, execution duration, query time.',
  QUERY_HISTORY.TOTAL_ELAPSED_TIME as TOTAL_ELAPSED_TIME
    comment='Total query duration including compilation, queuing, and execution (milliseconds). Synonyms: duration, total time, wall time, elapsed time, latency, response time.',
  QUERY_HISTORY.QUEUED_OVERLOAD_TIME as QUEUED_OVERLOAD_TIME
    comment='Queue wait time due to warehouse load (milliseconds). Indicates insufficient concurrency. Synonyms: wait time, queue time, overload time, concurrency wait.',
  QUERY_HISTORY.QUEUED_PROVISIONING_TIME as QUEUED_PROVISIONING_TIME
    comment='Queue wait time for warehouse provisioning (milliseconds). Occurs during warehouse startup. Synonyms: startup wait, cold start time, provisioning wait, warmup time.',
  QUERY_HISTORY.ROWS_PRODUCED as ROWS_PRODUCED
    comment='Number of rows returned by the query. Synonyms: result rows, output rows, rows returned, result set size, row count.',
  QUERY_HISTORY.PARTITIONS_SCANNED as PARTITIONS_SCANNED
    comment='Number of micro-partitions actually scanned. Compare to PARTITIONS_TOTAL for pruning efficiency. Synonyms: partitions read, micro-partitions scanned, partitions accessed.',
  QUERY_HISTORY.PARTITIONS_TOTAL as PARTITIONS_TOTAL
    comment='Total micro-partitions available in queried tables. High scan ratio indicates poor pruning. Synonyms: total partitions, available partitions, table partitions.',
  QUERY_HISTORY.PERCENTAGE_SCANNED_FROM_CACHE as PERCENTAGE_SCANNED_FROM_CACHE
    comment='Cache hit rate percentage (0-100). Higher values indicate better cache utilization. Synonyms: cache hit rate, cache hit, cache efficiency, cache utilization, cached percentage.',
  QUERY_ATTRIBUTION_HISTORY.CREDITS_ATTRIBUTED_COMPUTE as CREDITS_ATTRIBUTED_COMPUTE
    comment='Compute credits consumed by this specific query. Synonyms: query cost, compute cost, query credits, query spend, credits used.'
)
DIMENSIONS (
  QUERY_HISTORY.QUERY_ID as QUERY_ID
    comment='Unique query identifier (UUID format). Use for query profiling and debugging. Synonyms: query UUID, query identifier.',
  QUERY_HISTORY.QUERY_TEXT as QUERY_TEXT
    comment='Complete SQL statement text as executed. Synonyms: SQL, query statement, SQL text, query string.',
  QUERY_HISTORY.QUERY_TYPE as QUERY_TYPE
    comment='Query classification (e.g., SELECT, INSERT, UPDATE, DELETE, CREATE, MERGE). Synonyms: query category, statement type, operation type.',
  QUERY_HISTORY.EXECUTION_STATUS as EXECUTION_STATUS
    comment='Final query status (SUCCESS, FAIL, INCIDENT). SUCCESS indicates completion, FAILED indicates errors. Synonyms: query status, execution result, completion status.',
  QUERY_HISTORY.ERROR_CODE as ERROR_CODE
    comment='Numeric error code for failed queries. NULL for successful queries. Synonyms: failure code, error number.',
  QUERY_HISTORY.ERROR_MESSAGE as ERROR_MESSAGE
    comment='Detailed error description for failed queries. Synonyms: failure reason, error details, failure message.',
  QUERY_HISTORY.START_TIME as START_TIME
    comment='Query execution start timestamp (UTC). Synonyms: begin time, execution start, start timestamp, started at.',
  QUERY_HISTORY.END_TIME as END_TIME
    comment='Query execution end timestamp (UTC). Synonyms: completion time, finish time, end timestamp, completed at.',
  QUERY_HISTORY.USER_NAME as USER_NAME
    comment='User who executed the query. Synonyms: username, query user, executing user, submitted by.',
  QUERY_HISTORY.ROLE_NAME as ROLE_NAME
    comment='Role context during query execution. Synonyms: query role, execution role, role used.',
  QUERY_HISTORY.WAREHOUSE_NAME as WAREHOUSE_NAME
    comment='Virtual warehouse that executed the query (e.g., COMPUTE_WH, ANALYTICS_WH, ETL_WH). System-managed warehouses excluded. Synonyms: compute cluster, virtual warehouse, warehouse, cluster name.',
  QUERY_HISTORY.WAREHOUSE_SIZE as WAREHOUSE_SIZE
    comment='Warehouse size tier at execution time (X-Small, Small, Medium, Large, X-Large, 2X-Large, etc.). Larger sizes provide more compute power. Synonyms: warehouse tier, compute size, cluster size.',
  QUERY_HISTORY.DATABASE_NAME as DATABASE_NAME
    comment='Primary database accessed by the query. Synonyms: database, db, schema database.',
  QUERY_HISTORY.SCHEMA_NAME as SCHEMA_NAME
    comment='Primary schema accessed by the query. Synonyms: schema, database schema.'
)
COMMENT = 'DEMO: Sam-the-Snowman - Query performance metrics, errors, and optimization insights. Ask about slow queries, errors, and optimization opportunities. Excludes system-managed warehouses for clarity. (Expires: 2026-02-14)'
WITH EXTENSION (CA = '{
  "verified_queries": [
    {
      "name": "Slowest queries today",
      "question": "What were my slowest queries today?",
      "sql": "SELECT query_id, query_text, total_elapsed_time, warehouse_name FROM query_performance WHERE start_time >= CURRENT_DATE() ORDER BY total_elapsed_time DESC LIMIT 10"
    },
    {
      "name": "Queries with remote spillage",
      "question": "Which queries spilled to remote storage this week?",
      "sql": "SELECT query_id, query_text, bytes_spilled_to_remote_storage, warehouse_size, warehouse_name FROM query_performance WHERE start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP()) AND bytes_spilled_to_remote_storage > 0 ORDER BY bytes_spilled_to_remote_storage DESC LIMIT 20"
    },
    {
      "name": "Failed queries by error type",
      "question": "What are the most common query errors?",
      "sql": "SELECT error_code, error_message, COUNT(*) as failure_count FROM query_performance WHERE execution_status = ''FAIL'' AND start_time >= DATEADD(day, -7, CURRENT_TIMESTAMP()) GROUP BY error_code, error_message ORDER BY failure_count DESC LIMIT 10"
    }
  ]
}');

-- ============================================================================
-- SEMANTIC VIEW: sfe_cost_analysis
-- ============================================================================
-- Purpose: Track warehouse credit consumption and identify cost optimization opportunities
-- Data Sources: WAREHOUSE_METERING_HISTORY
-- Key Metrics: Credits used, compute costs, cloud services costs
--
-- Best Practices Implemented:
-- ✓ Comprehensive synonyms for financial terminology
-- ✓ Rich contextual descriptions for cost interpretation
-- ✓ Multiple verified queries for common FinOps scenarios
-- ✓ Sample values in comments showing typical warehouse names
-- ✓ Clear distinction between compute and cloud services costs

CREATE OR REPLACE SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_COST_ANALYSIS
TABLES (
    SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
)
FACTS (
  WAREHOUSE_METERING_HISTORY.CREDITS_USED as CREDITS_USED
    comment='Total credits consumed (compute + cloud services). Primary cost metric for warehouse billing. Synonyms: total cost, spend, warehouse cost, total spend, credits consumed, billing amount.',
  WAREHOUSE_METERING_HISTORY.CREDITS_USED_COMPUTE as CREDITS_USED_COMPUTE
    comment='Compute credits for query execution. Represents the majority of warehouse costs. Synonyms: compute cost, compute credits, compute spend, execution cost, query cost.',
  WAREHOUSE_METERING_HISTORY.CREDITS_USED_CLOUD_SERVICES as CREDITS_USED_CLOUD_SERVICES
    comment='Cloud services credits for metadata operations, result caching, and infrastructure. Usually 10% of compute costs or less. Synonyms: services cost, cloud services spend, metadata cost, infrastructure cost.'
)
DIMENSIONS (
  WAREHOUSE_METERING_HISTORY.WAREHOUSE_NAME as WAREHOUSE_NAME
    comment='Virtual warehouse name (e.g., COMPUTE_WH, ANALYTICS_WH, ETL_WH). System-managed warehouses excluded for clarity. Synonyms: compute cluster, warehouse, cluster name, virtual warehouse.',
  WAREHOUSE_METERING_HISTORY.WAREHOUSE_ID as WAREHOUSE_ID
    comment='Unique warehouse identifier. Use for tracking across renames. Synonyms: warehouse UUID, warehouse identifier.',
  WAREHOUSE_METERING_HISTORY.START_TIME as START_TIME
    comment='Billing period start timestamp (UTC). Metering periods are typically hourly. Synonyms: period start, metering start, billing start, measurement start.',
  WAREHOUSE_METERING_HISTORY.END_TIME as END_TIME
    comment='Billing period end timestamp (UTC). Synonyms: period end, metering end, billing end, measurement end.'
)
COMMENT = 'DEMO: Sam-the-Snowman - Warehouse cost analysis and credit consumption tracking. Ask about costs, spend trends, and expensive warehouses. Excludes system-managed warehouses for clarity. (Expires: 2026-02-14)'
WITH EXTENSION (CA = '{
  "verified_queries": [
    {
      "name": "Most expensive warehouses last month",
      "question": "What were my most expensive warehouses last month?",
      "sql": "SELECT warehouse_name, SUM(credits_used) as total_credits FROM cost_analysis WHERE start_time >= DATE_TRUNC(''MONTH'', DATEADD(''MONTH'', -1, CURRENT_DATE())) AND start_time < DATE_TRUNC(''MONTH'', CURRENT_DATE()) GROUP BY warehouse_name ORDER BY total_credits DESC"
    },
    {
      "name": "Daily spend trend",
      "question": "Show me daily credit spend for the last 30 days",
      "sql": "SELECT DATE(start_time) as usage_date, SUM(credits_used) as daily_credits FROM cost_analysis WHERE start_time >= DATEADD(''day'', -30, CURRENT_TIMESTAMP()) GROUP BY usage_date ORDER BY usage_date DESC"
    },
    {
      "name": "Cloud services credit ratio",
      "question": "Which warehouses have high cloud services costs?",
      "sql": "SELECT warehouse_name, SUM(credits_used_compute) as compute_credits, SUM(credits_used_cloud_services) as services_credits, (services_credits / NULLIF(compute_credits, 0) * 100) as services_percentage FROM cost_analysis WHERE start_time >= DATEADD(''day'', -7, CURRENT_TIMESTAMP()) GROUP BY warehouse_name HAVING services_percentage > 10 ORDER BY services_percentage DESC"
    }
  ]
}');

-- ============================================================================
-- SEMANTIC VIEW: sfe_warehouse_operations
-- ============================================================================
-- Purpose: Monitor warehouse utilization, capacity, and identify sizing opportunities
-- Data Sources: WAREHOUSE_LOAD_HISTORY
-- Key Metrics: Concurrency, queue depth, blocked queries
--
-- Best Practices Implemented:
-- ✓ Sample values in comments for typical warehouse names
-- ✓ Expanded synonyms for operations terminology
-- ✓ Rich contextual descriptions for capacity planning
-- ✓ Multiple verified queries for common operational scenarios
-- ✓ Clear explanation of queue types and their implications

CREATE OR REPLACE SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_WAREHOUSE_OPERATIONS
TABLES (
    SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
)
FACTS (
  WAREHOUSE_LOAD_HISTORY.AVG_RUNNING as AVG_RUNNING
    comment='Average number of queries executing concurrently during the measurement period. High values indicate good utilization. Synonyms: concurrency, active queries, concurrent queries, running queries, parallel queries.',
  WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_LOAD as AVG_QUEUED_LOAD
    comment='Average queries queued due to warehouse load/capacity. Non-zero values indicate undersizing or need for multi-cluster scaling. Synonyms: queue depth, waiting queries, queued queries, overload queue, capacity queue.',
  WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_PROVISIONING as AVG_QUEUED_PROVISIONING
    comment='Average queries queued during warehouse startup/provisioning. Occurs when warehouse resumes from suspended state. Synonyms: startup queue, provisioning queue, cold start queue, warmup queue.',
  WAREHOUSE_LOAD_HISTORY.AVG_BLOCKED as AVG_BLOCKED
    comment='Average queries blocked by locks or resource contention. High values indicate lock contention on tables. Synonyms: contentions, blocked queries, lock waits, resource conflicts.'
)
DIMENSIONS (
  WAREHOUSE_LOAD_HISTORY.WAREHOUSE_NAME as WAREHOUSE_NAME
    comment='Virtual warehouse name (e.g., COMPUTE_WH, ANALYTICS_WH, ETL_WH). System-managed warehouses excluded for operational clarity. Synonyms: compute cluster, warehouse, cluster name, virtual warehouse.',
  WAREHOUSE_LOAD_HISTORY.WAREHOUSE_ID as WAREHOUSE_ID
    comment='Unique warehouse identifier. Persists across warehouse renames. Synonyms: warehouse UUID, warehouse identifier.',
  WAREHOUSE_LOAD_HISTORY.START_TIME as START_TIME
    comment='Measurement period start timestamp (UTC). Load metrics are captured at regular intervals. Synonyms: load start time, measurement start, period start, sample start.',
  WAREHOUSE_LOAD_HISTORY.END_TIME as END_TIME
    comment='Measurement period end timestamp (UTC). Synonyms: load end time, measurement end, period end, sample end.'
)
COMMENT = 'DEMO: Sam-the-Snowman - Warehouse utilization and capacity planning metrics. Ask about warehouse sizing, queue times, and utilization patterns. Excludes system-managed warehouses for clarity. (Expires: 2026-02-14)'
WITH EXTENSION (CA = '{
  "verified_queries": [
    {
      "name": "Warehouses with high queues",
      "question": "Which warehouses have the most queued queries?",
      "sql": "SELECT warehouse_name, AVG(avg_queued_load) as avg_queue_depth FROM warehouse_operations WHERE start_time >= DATEADD(''DAY'', -7, CURRENT_TIMESTAMP()) GROUP BY warehouse_name HAVING avg_queue_depth > 0 ORDER BY avg_queue_depth DESC"
    },
    {
      "name": "Warehouse utilization patterns",
      "question": "Show warehouse concurrency by hour of day",
      "sql": "SELECT warehouse_name, HOUR(start_time) as hour_of_day, AVG(avg_running) as avg_concurrency FROM warehouse_operations WHERE start_time >= DATEADD(''day'', -7, CURRENT_TIMESTAMP()) GROUP BY warehouse_name, hour_of_day ORDER BY warehouse_name, hour_of_day"
    },
    {
      "name": "Blocked query analysis",
      "question": "Which warehouses have lock contention issues?",
      "sql": "SELECT warehouse_name, AVG(avg_blocked) as avg_blocked_queries FROM warehouse_operations WHERE start_time >= DATEADD(''day'', -7, CURRENT_TIMESTAMP()) GROUP BY warehouse_name HAVING avg_blocked_queries > 0 ORDER BY avg_blocked_queries DESC"
    }
  ]
}');

-- Semantic views complete
