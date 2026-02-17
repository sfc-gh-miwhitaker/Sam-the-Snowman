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
 *   ✓ Pre-defined metrics for common aggregations
 *   ✓ Table relationships for multi-table queries
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
 * Expires: 2026-03-19
 * Version: 5.2
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
-- ✓ Pre-defined metrics for common aggregations
-- ✓ Expanded synonyms covering natural language variations
-- ✓ Rich contextual descriptions explaining metric implications

CREATE OR REPLACE SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_QUERY_PERFORMANCE
TABLES (
    qh AS SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        PRIMARY KEY (QUERY_ID)
        COMMENT = 'Historical record of all queries executed. Contains execution metrics, resource consumption, and error information. Data has ~45 minute latency.',
    qah AS SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY
        PRIMARY KEY (QUERY_ID)
        COMMENT = 'Credit attribution data linking queries to compute costs. Enables cost-per-query analysis.'
)
RELATIONSHIPS (
    qh(QUERY_ID) REFERENCES qah
)
FACTS (
    -- Data Volume Metrics
    qh.bytes_scanned AS BYTES_SCANNED
        WITH SYNONYMS = ('data scanned', 'scan volume', 'bytes read', 'data processed')
        COMMENT = 'Total bytes scanned. Higher values indicate more data processing. Compare across similar queries for optimization.',
    qh.bytes_spilled_to_local_storage AS BYTES_SPILLED_TO_LOCAL_STORAGE
        WITH SYNONYMS = ('local spill', 'disk spill', 'SSD spill', 'memory spill')
        COMMENT = 'Memory spillage to local SSD indicating memory pressure. Non-zero values suggest query needs more memory.',
    qh.bytes_spilled_to_remote_storage AS BYTES_SPILLED_TO_REMOTE_STORAGE
        WITH SYNONYMS = ('remote spill', 'S3 spill', 'cloud storage spill', 'severe spill')
        COMMENT = 'CRITICAL: Memory spillage to remote cloud storage indicating SEVERE performance degradation. Non-zero values require immediate attention - upsize warehouse or optimize query.',

    -- Timing Metrics
    qh.compilation_time AS COMPILATION_TIME
        WITH SYNONYMS = ('parse time', 'planning time', 'compile time')
        COMMENT = 'Query compilation/parsing time (milliseconds). High values (>1000ms) indicate complex query needing simplification.',
    qh.execution_time AS EXECUTION_TIME
        WITH SYNONYMS = ('runtime', 'run time', 'processing time', 'execution duration')
        COMMENT = 'Actual query execution time (milliseconds), excluding queuing. Primary metric for query performance.',
    qh.total_elapsed_time AS TOTAL_ELAPSED_TIME
        WITH SYNONYMS = ('duration', 'total time', 'wall time', 'elapsed time', 'latency', 'response time')
        COMMENT = 'Total query duration including compilation, queuing, and execution (milliseconds). This is what users experience.',
    qh.queued_overload_time AS QUEUED_OVERLOAD_TIME
        WITH SYNONYMS = ('wait time', 'queue time', 'overload time', 'concurrency wait')
        COMMENT = 'Queue wait due to warehouse load (milliseconds). Non-zero indicates insufficient concurrency - consider multi-cluster.',
    qh.queued_provisioning_time AS QUEUED_PROVISIONING_TIME
        WITH SYNONYMS = ('startup wait', 'cold start time', 'warmup time')
        COMMENT = 'Queue wait for warehouse startup (milliseconds). Occurs during warehouse resume. Consider auto-resume for latency-sensitive workloads.',

    -- Result Metrics
    qh.rows_produced AS ROWS_PRODUCED
        WITH SYNONYMS = ('result rows', 'output rows', 'rows returned', 'row count')
        COMMENT = 'Rows returned by query. Useful for identifying large result sets.',

    -- Partition Metrics
    qh.partitions_scanned AS PARTITIONS_SCANNED
        WITH SYNONYMS = ('partitions read', 'partitions accessed')
        COMMENT = 'Micro-partitions scanned. Compare to PARTITIONS_TOTAL for pruning efficiency. High ratio = poor clustering or missing filters.',
    qh.partitions_total AS PARTITIONS_TOTAL
        WITH SYNONYMS = ('total partitions', 'available partitions')
        COMMENT = 'Total micro-partitions in queried tables. Use with PARTITIONS_SCANNED to calculate pruning efficiency.',

    -- Cache Metrics
    qh.percentage_scanned_from_cache AS PERCENTAGE_SCANNED_FROM_CACHE
        WITH SYNONYMS = ('cache hit rate', 'cache hit', 'cache efficiency', 'cached percentage')
        COMMENT = 'Cache hit rate (0-100%). Higher = better cache utilization and lower costs.',

    -- Cost Metrics
    qah.credits_attributed_compute AS CREDITS_ATTRIBUTED_COMPUTE
        WITH SYNONYMS = ('query cost', 'compute cost', 'query credits', 'query spend')
        COMMENT = 'Compute credits consumed by this query. Primary metric for query-level cost analysis.'
)
DIMENSIONS (
    qh.query_id AS QUERY_ID
        WITH SYNONYMS = ('query uuid', 'query identifier', 'execution id')
        COMMENT = 'Unique query identifier (UUID). Use for profiling and Query Profile lookup.',
    qh.query_text AS QUERY_TEXT
        WITH SYNONYMS = ('SQL', 'query statement', 'SQL text', 'statement', 'code')
        COMMENT = 'Complete SQL statement. May be truncated for long queries.',
    qh.query_type AS QUERY_TYPE
        WITH SYNONYMS = ('query category', 'statement type', 'operation type')
        COMMENT = 'Statement type (SELECT, INSERT, UPDATE, DELETE, CREATE, MERGE, COPY, UNLOAD).',
    qh.execution_status AS EXECUTION_STATUS
        WITH SYNONYMS = ('query status', 'execution result', 'outcome')
        COMMENT = 'Query outcome: SUCCESS (completed), FAIL (errors), INCIDENT (system issues).',
    qh.error_code AS ERROR_CODE
        WITH SYNONYMS = ('failure code', 'error number')
        COMMENT = 'Numeric error code for failed queries. NULL for successful. Reference Snowflake docs for meanings.',
    qh.error_message AS ERROR_MESSAGE
        WITH SYNONYMS = ('failure reason', 'error details', 'failure message')
        COMMENT = 'Detailed error description for debugging. NULL for successful queries.',
    qh.user_name AS USER_NAME
        WITH SYNONYMS = ('username', 'query user', 'executing user', 'submitted by', 'who')
        COMMENT = 'User who executed the query.',
    qh.role_name AS ROLE_NAME
        WITH SYNONYMS = ('query role', 'execution role', 'active role')
        COMMENT = 'Active role during execution. Determines data access permissions.',
    qh.warehouse_name AS WAREHOUSE_NAME
        WITH SYNONYMS = ('compute cluster', 'virtual warehouse', 'compute')
        COMMENT = 'Warehouse that executed the query (e.g., COMPUTE_WH, ANALYTICS_WH). System warehouses filtered.',
    qh.warehouse_size AS WAREHOUSE_SIZE
        WITH SYNONYMS = ('warehouse tier', 'compute size', 'cluster size')
        COMMENT = 'Warehouse T-shirt size. Larger = more compute power + higher cost.',
    qh.database_name AS DATABASE_NAME
        WITH SYNONYMS = ('database', 'db')
        COMMENT = 'Primary database accessed.',
    qh.schema_name AS SCHEMA_NAME
        WITH SYNONYMS = ('schema')
        COMMENT = 'Primary schema accessed.',
    qh.start_time AS START_TIME
        WITH SYNONYMS = ('begin time', 'execution start', 'query time', 'when')
        COMMENT = 'Query start timestamp (UTC). Primary time dimension for trending.',
    qh.end_time AS END_TIME
        WITH SYNONYMS = ('completion time', 'finish time', 'completed at')
        COMMENT = 'Query completion timestamp (UTC).'
)
METRICS (
    -- Volume Metrics
    qh.query_count AS COUNT(qh.query_id),

    -- Performance Metrics
    qh.avg_execution_time_ms AS AVG(qh.execution_time),
    qh.avg_total_elapsed_time_ms AS AVG(qh.total_elapsed_time),
    qh.p95_execution_time_ms AS APPROX_PERCENTILE(qh.execution_time, 0.95),

    -- Data Volume Metrics
    qh.total_bytes_scanned AS SUM(qh.bytes_scanned),
    qh.total_bytes_spilled AS SUM(qh.bytes_spilled_to_local_storage + qh.bytes_spilled_to_remote_storage),

    -- Quality Metrics
    qh.error_rate AS (100.0 * SUM(CASE WHEN qh.execution_status = 'FAIL' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)),
    qh.failed_query_count AS SUM(CASE WHEN qh.execution_status = 'FAIL' THEN 1 ELSE 0 END),

    -- Cache Metrics
    qh.avg_cache_hit_rate AS AVG(qh.percentage_scanned_from_cache),

    -- Efficiency Metrics
    qh.partition_pruning_efficiency AS (100.0 * (1 - SUM(qh.partitions_scanned) / NULLIF(SUM(qh.partitions_total), 0))),

    -- Cost Metrics
    qah.total_credits_used AS SUM(qah.credits_attributed_compute)
)
COMMENT = 'DEMO: Sam-the-Snowman - Query performance analytics. Analyze execution times, identify slow queries, detect memory spilling, evaluate cache efficiency, and track errors. Excludes system-managed warehouses. (Expires: 2026-03-19)';


-- ============================================================================
-- SEMANTIC VIEW: SV_SAM_COST_ANALYSIS
-- ============================================================================
-- Purpose: Track warehouse credit consumption and identify cost optimization opportunities
-- Data Sources: WAREHOUSE_METERING_HISTORY
-- Key Metrics: Credits used, compute costs, cloud services costs
--
-- Best Practices Implemented:
-- ✓ Pre-defined metrics for common aggregations
-- ✓ Comprehensive synonyms for financial terminology
-- ✓ Rich contextual descriptions for cost interpretation
-- ✓ Clear distinction between compute and cloud services costs

CREATE OR REPLACE SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_COST_ANALYSIS
TABLES (
    wmh AS SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
        PRIMARY KEY (WAREHOUSE_ID, START_TIME)
        COMMENT = 'Hourly credit consumption for all warehouses. Contains compute and cloud services credits. Primary source for cost analysis.'
)
FACTS (
    wmh.credits_used AS CREDITS_USED
        WITH SYNONYMS = ('total cost', 'spend', 'warehouse cost', 'total spend', 'credits consumed', 'billing amount', 'cost', 'credits')
        COMMENT = 'Total credits consumed (compute + cloud services). Primary cost metric. Multiply by credit price for dollar costs.',
    wmh.credits_used_compute AS CREDITS_USED_COMPUTE
        WITH SYNONYMS = ('compute cost', 'compute credits', 'compute spend', 'execution cost', 'query cost')
        COMMENT = 'Compute credits for query execution. Typically 90%+ of total. Scales with warehouse size and runtime.',
    wmh.credits_used_cloud_services AS CREDITS_USED_CLOUD_SERVICES
        WITH SYNONYMS = ('services cost', 'cloud services spend', 'metadata cost', 'overhead cost')
        COMMENT = 'Cloud services credits for metadata operations and caching. Usually <10% of compute. High ratio may indicate inefficient small query patterns.'
)
DIMENSIONS (
    wmh.warehouse_name AS WAREHOUSE_NAME
        WITH SYNONYMS = ('compute cluster', 'warehouse', 'virtual warehouse')
        COMMENT = 'Warehouse name (e.g., COMPUTE_WH, ANALYTICS_WH). System warehouses filtered.',
    wmh.warehouse_id AS WAREHOUSE_ID
        WITH SYNONYMS = ('warehouse uuid')
        COMMENT = 'Unique warehouse ID. Persists across renames for tracking.',
    wmh.start_time AS START_TIME
        WITH SYNONYMS = ('period start', 'metering start', 'billing start', 'when', 'date')
        COMMENT = 'Metering period start (UTC). Hourly intervals.',
    wmh.end_time AS END_TIME
        WITH SYNONYMS = ('period end', 'metering end')
        COMMENT = 'Metering period end (UTC).'
)
METRICS (
    wmh.total_credits AS SUM(wmh.credits_used),
    wmh.total_compute_credits AS SUM(wmh.credits_used_compute),
    wmh.total_cloud_services_credits AS SUM(wmh.credits_used_cloud_services),
    wmh.avg_hourly_credits AS AVG(wmh.credits_used),
    wmh.max_hourly_credits AS MAX(wmh.credits_used),
    wmh.cloud_services_ratio AS (100.0 * SUM(wmh.credits_used_cloud_services) / NULLIF(SUM(wmh.credits_used), 0)),
    wmh.metering_periods AS COUNT(*),
    wmh.daily_credits AS (SUM(wmh.credits_used) / NULLIF(COUNT(DISTINCT DATE(wmh.start_time)), 0))
)
COMMENT = 'DEMO: Sam-the-Snowman - Warehouse cost analysis. Track spending by warehouse, identify cost trends, support FinOps. Excludes system-managed warehouses. (Expires: 2026-03-19)';


-- ============================================================================
-- SEMANTIC VIEW: SV_SAM_WAREHOUSE_OPERATIONS
-- ============================================================================
-- Purpose: Monitor warehouse utilization, capacity, and identify sizing opportunities
-- Data Sources: WAREHOUSE_LOAD_HISTORY
-- Key Metrics: Concurrency, queue depth, blocked queries
--
-- Best Practices Implemented:
-- ✓ Pre-defined metrics for common aggregations
-- ✓ Expanded synonyms for operations terminology
-- ✓ Rich contextual descriptions for capacity planning
-- ✓ Clear explanation of queue types and their implications

CREATE OR REPLACE SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_WAREHOUSE_OPERATIONS
TABLES (
    wlh AS SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
        PRIMARY KEY (WAREHOUSE_ID, START_TIME)
        COMMENT = 'Time-series load metrics for warehouses. Captures concurrency, queue depth, and blocked queries. Essential for capacity planning.'
)
FACTS (
    wlh.avg_running AS AVG_RUNNING
        WITH SYNONYMS = ('concurrency', 'active queries', 'concurrent queries', 'running queries', 'parallel queries', 'utilization')
        COMMENT = 'Average concurrent queries during measurement. High values = good utilization. Very high may need multi-cluster.',
    wlh.avg_queued_load AS AVG_QUEUED_LOAD
        WITH SYNONYMS = ('queue depth', 'waiting queries', 'queued queries', 'overload queue', 'backlog')
        COMMENT = 'Average queries queued due to capacity. Non-zero = undersized or needs multi-cluster. Users experience wait time.',
    wlh.avg_queued_provisioning AS AVG_QUEUED_PROVISIONING
        WITH SYNONYMS = ('startup queue', 'provisioning queue', 'cold start queue', 'warmup queue')
        COMMENT = 'Average queries queued during warehouse startup. Cold start impact. Consider auto-resume or always-on.',
    wlh.avg_blocked AS AVG_BLOCKED
        WITH SYNONYMS = ('contentions', 'blocked queries', 'lock waits', 'resource conflicts', 'blocking')
        COMMENT = 'Average queries blocked by locks. High values = lock contention from concurrent DML. Review transaction patterns.'
)
DIMENSIONS (
    wlh.warehouse_name AS WAREHOUSE_NAME
        WITH SYNONYMS = ('compute cluster', 'warehouse', 'virtual warehouse')
        COMMENT = 'Warehouse name (e.g., COMPUTE_WH, ANALYTICS_WH). System warehouses filtered.',
    wlh.warehouse_id AS WAREHOUSE_ID
        WITH SYNONYMS = ('warehouse uuid')
        COMMENT = 'Unique warehouse ID. Persists across renames.',
    wlh.start_time AS START_TIME
        WITH SYNONYMS = ('load start', 'measurement start', 'when', 'date')
        COMMENT = 'Measurement period start (UTC). Regular intervals.',
    wlh.end_time AS END_TIME
        WITH SYNONYMS = ('load end', 'measurement end')
        COMMENT = 'Measurement period end (UTC).'
)
METRICS (
    wlh.measurement_count AS COUNT(*),
    wlh.avg_concurrency AS AVG(wlh.avg_running),
    wlh.max_concurrency AS MAX(wlh.avg_running),
    wlh.avg_queue_depth AS AVG(wlh.avg_queued_load),
    wlh.max_queue_depth AS MAX(wlh.avg_queued_load),
    wlh.avg_provisioning_queue AS AVG(wlh.avg_queued_provisioning),
    wlh.avg_blocked_count AS AVG(wlh.avg_blocked),
    wlh.periods_with_queuing AS SUM(CASE WHEN wlh.avg_queued_load > 0 THEN 1 ELSE 0 END),
    wlh.queuing_percentage AS (100.0 * SUM(CASE WHEN wlh.avg_queued_load > 0 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)),
    wlh.periods_with_blocking AS SUM(CASE WHEN wlh.avg_blocked > 0 THEN 1 ELSE 0 END)
)
COMMENT = 'DEMO: Sam-the-Snowman - Warehouse utilization and capacity planning. Monitor concurrency, queue depth, and sizing opportunities. Excludes system-managed warehouses. (Expires: 2026-03-19)';


-- Semantic views complete
