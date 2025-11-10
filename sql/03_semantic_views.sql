/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * Module: 03_semantic_views.sql
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
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
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC.sfe_query_performance (Semantic View)
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC.sfe_cost_analysis (Semantic View)
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC.sfe_warehouse_operations (Semantic View)
 * 
 * Prerequisites:
 *   - 00_config.sql and 01_scaffolding.sql must be run first
 *   - Configured role must have access to SNOWFLAKE.ACCOUNT_USAGE views
 * 
 * Author: M. Whitaker (inspired by Kaitlyn Wells @snowflake)
 * Modified: 2025-11-07
 * Version: 3.1
 * License: Apache 2.0
 * 
 * Usage:
 *   This module is called by deploy_all.sql or can be run standalone
 *   after setting configuration variables and creating scaffolding.
 ******************************************************************************/

USE ROLE SYSADMIN;
USE SNOWFLAKE_EXAMPLE.SEMANTIC;

-- ============================================================================
-- SEMANTIC VIEW: sfe_query_performance
-- ============================================================================
-- Purpose: Analyze query execution, identify slow queries, errors, and optimization opportunities
-- Data Sources: QUERY_HISTORY, QUERY_ATTRIBUTION_HISTORY
-- Key Metrics: Execution time, spilling, cache efficiency, error rates

CREATE OR REPLACE SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC.sfe_query_performance
TABLES (
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY,
    SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY
)
FACTS (
  QUERY_HISTORY.BYTES_SCANNED as BYTES_SCANNED comment='The total number of bytes scanned by the query.',
  QUERY_HISTORY.BYTES_SPILLED_TO_LOCAL_STORAGE as BYTES_SPILLED_TO_LOCAL_STORAGE comment='Memory spillage to local storage indicating memory pressure. Synonyms: local spill, disk spill.',
  QUERY_HISTORY.BYTES_SPILLED_TO_REMOTE_STORAGE as BYTES_SPILLED_TO_REMOTE_STORAGE comment='Memory spillage to remote storage indicating severe memory pressure. Synonyms: remote spill, S3 spill.',
  QUERY_HISTORY.COMPILATION_TIME as COMPILATION_TIME comment='Query compilation time in milliseconds. Synonyms: parse time, planning time.',
  QUERY_HISTORY.EXECUTION_TIME as EXECUTION_TIME comment='Query execution time in milliseconds. Synonyms: runtime, run time, processing time.',
  QUERY_HISTORY.TOTAL_ELAPSED_TIME as TOTAL_ELAPSED_TIME comment='Total query duration in milliseconds. Synonyms: duration, total time, wall time.',
  QUERY_HISTORY.QUEUED_OVERLOAD_TIME as QUEUED_OVERLOAD_TIME comment='Queue wait time due to load in milliseconds. Synonyms: wait time, queue time.',
  QUERY_HISTORY.QUEUED_PROVISIONING_TIME as QUEUED_PROVISIONING_TIME comment='Queue wait time for provisioning in milliseconds. Synonyms: startup wait, cold start time.',
  QUERY_HISTORY.ROWS_PRODUCED as ROWS_PRODUCED comment='Number of rows returned. Synonyms: result rows, output rows, rows returned.',
  QUERY_HISTORY.PARTITIONS_SCANNED as PARTITIONS_SCANNED comment='Number of micro-partitions scanned. Synonyms: partitions read, micro-partitions.',
  QUERY_HISTORY.PARTITIONS_TOTAL as PARTITIONS_TOTAL comment='Total partitions in queried tables.',
  QUERY_HISTORY.PERCENTAGE_SCANNED_FROM_CACHE as PERCENTAGE_SCANNED_FROM_CACHE comment='Cache hit rate percentage. Synonyms: cache hit, cache efficiency.',
  QUERY_ATTRIBUTION_HISTORY.CREDITS_ATTRIBUTED_COMPUTE as CREDITS_ATTRIBUTED_COMPUTE comment='Compute credits for this query. Synonyms: query cost, compute cost.'
)
DIMENSIONS (
  QUERY_HISTORY.QUERY_ID as QUERY_ID comment='Unique query identifier. Synonyms: query UUID.',
  QUERY_HISTORY.QUERY_TEXT as QUERY_TEXT comment='SQL statement text. Synonyms: SQL, query statement.',
  QUERY_HISTORY.QUERY_TYPE as QUERY_TYPE comment='Query type (SELECT, INSERT, UPDATE, DDL, etc.).',
  QUERY_HISTORY.EXECUTION_STATUS as EXECUTION_STATUS comment='Query status: SUCCESS, FAILED, RUNNING. Synonyms: query status.',
  QUERY_HISTORY.ERROR_CODE as ERROR_CODE comment='Error code for failed queries.',
  QUERY_HISTORY.ERROR_MESSAGE as ERROR_MESSAGE comment='Error description. Synonyms: failure reason.',
  QUERY_HISTORY.START_TIME as START_TIME comment='Query start timestamp. Synonyms: begin time, execution start.',
  QUERY_HISTORY.END_TIME as END_TIME comment='Query end timestamp. Synonyms: completion time, finish time.',
  QUERY_HISTORY.USER_NAME as USER_NAME comment='Executing user. Synonyms: username, query user.',
  QUERY_HISTORY.ROLE_NAME as ROLE_NAME comment='Execution role. Synonyms: query role.',
  QUERY_HISTORY.WAREHOUSE_NAME as WAREHOUSE_NAME comment='Warehouse used (system-managed warehouses excluded). Synonyms: compute cluster, virtual warehouse.',
  QUERY_HISTORY.WAREHOUSE_SIZE as WAREHOUSE_SIZE comment='Warehouse size (X-Small to 6X-Large).',
  QUERY_HISTORY.DATABASE_NAME as DATABASE_NAME comment='Database name. Synonyms: database, db.',
  QUERY_HISTORY.SCHEMA_NAME as SCHEMA_NAME comment='Schema name.'
)
COMMENT = 'DEMO: Sam-the-Snowman - Query performance metrics, errors, and optimization insights. Ask about slow queries, errors, and optimization opportunities. Excludes system-managed warehouses for clarity.'
WITH EXTENSION (CA = '{"verified_queries":[{"name":"Slowest queries today","question":"What were my slowest queries today?","sql":"SELECT query_id, query_text, total_elapsed_time, warehouse_name FROM query_performance WHERE start_time >= CURRENT_DATE() ORDER BY total_elapsed_time DESC LIMIT 10"}]}');

-- ============================================================================
-- SEMANTIC VIEW: sfe_cost_analysis
-- ============================================================================
-- Purpose: Track warehouse credit consumption and identify cost optimization opportunities
-- Data Sources: WAREHOUSE_METERING_HISTORY
-- Key Metrics: Credits used, compute costs, cloud services costs

CREATE OR REPLACE SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC.sfe_cost_analysis
TABLES (
    SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
)
FACTS (
  WAREHOUSE_METERING_HISTORY.CREDITS_USED as CREDITS_USED comment='Total credits consumed. Synonyms: cost, spend, warehouse cost.',
  WAREHOUSE_METERING_HISTORY.CREDITS_USED_COMPUTE as CREDITS_USED_COMPUTE comment='Compute credits. Synonyms: compute cost.',
  WAREHOUSE_METERING_HISTORY.CREDITS_USED_CLOUD_SERVICES as CREDITS_USED_CLOUD_SERVICES comment='Cloud services credits. Synonyms: services cost.'
)
DIMENSIONS (
  WAREHOUSE_METERING_HISTORY.WAREHOUSE_NAME as WAREHOUSE_NAME comment='Warehouse name (system-managed warehouses excluded). Synonyms: compute cluster.',
  WAREHOUSE_METERING_HISTORY.WAREHOUSE_ID as WAREHOUSE_ID comment='Warehouse identifier.',
  WAREHOUSE_METERING_HISTORY.START_TIME as START_TIME comment='Billing period start. Synonyms: period start, metering start.',
  WAREHOUSE_METERING_HISTORY.END_TIME as END_TIME comment='Billing period end. Synonyms: period end, metering end.'
)
COMMENT = 'DEMO: Sam-the-Snowman - Warehouse cost analysis and credit consumption tracking. Ask about costs, spend trends, and expensive warehouses. Excludes system-managed warehouses for clarity.'
WITH EXTENSION (CA = '{"verified_queries":[{"name":"Most expensive warehouses last month","question":"What were my most expensive warehouses last month?","sql":"SELECT warehouse_name, SUM(credits_used) as total_credits FROM cost_analysis WHERE start_time >= DATE_TRUNC(MONTH, DATEADD(MONTH, -1, CURRENT_DATE())) AND start_time < DATE_TRUNC(MONTH, CURRENT_DATE()) GROUP BY warehouse_name ORDER BY total_credits DESC"}]}');

-- ============================================================================
-- SEMANTIC VIEW: sfe_warehouse_operations
-- ============================================================================
-- Purpose: Monitor warehouse utilization, capacity, and identify sizing opportunities
-- Data Sources: WAREHOUSE_LOAD_HISTORY
-- Key Metrics: Concurrency, queue depth, blocked queries

CREATE OR REPLACE SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC.sfe_warehouse_operations
TABLES (
    SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
)
FACTS (
  WAREHOUSE_LOAD_HISTORY.AVG_RUNNING as AVG_RUNNING comment='Average concurrent queries. Synonyms: concurrency, active queries.',
  WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_LOAD as AVG_QUEUED_LOAD comment='Average queued queries. Synonyms: queue depth, waiting queries.',
  WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_PROVISIONING as AVG_QUEUED_PROVISIONING comment='Average provisioning queue. Synonyms: startup queue.',
  WAREHOUSE_LOAD_HISTORY.AVG_BLOCKED as AVG_BLOCKED comment='Average blocked queries. Synonyms: contentions.'
)
DIMENSIONS (
  WAREHOUSE_LOAD_HISTORY.WAREHOUSE_NAME as WAREHOUSE_NAME comment='Warehouse name (system-managed warehouses excluded). Synonyms: compute cluster.',
  WAREHOUSE_LOAD_HISTORY.WAREHOUSE_ID as WAREHOUSE_ID comment='Warehouse identifier.',
  WAREHOUSE_LOAD_HISTORY.START_TIME as START_TIME comment='Measurement period start. Synonyms: load start time.',
  WAREHOUSE_LOAD_HISTORY.END_TIME as END_TIME comment='Measurement period end. Synonyms: load end time.'
)
COMMENT = 'DEMO: Sam-the-Snowman - Warehouse utilization and capacity planning metrics. Ask about warehouse sizing, queue times, and utilization patterns. Excludes system-managed warehouses for clarity.'
WITH EXTENSION (CA = '{"verified_queries":[{"name":"Warehouses with high queues","question":"Which warehouses have the most queued queries?","sql":"SELECT warehouse_name, AVG(avg_queued_load) as avg_queue_depth FROM warehouse_operations WHERE start_time >= DATEADD(DAY, -7, CURRENT_TIMESTAMP()) GROUP BY warehouse_name HAVING avg_queue_depth > 0 ORDER BY avg_queue_depth DESC"}]}');

-- Semantic views complete

