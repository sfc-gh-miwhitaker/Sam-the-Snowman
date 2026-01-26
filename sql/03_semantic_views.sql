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
 *   ✓ TIME DIMENSIONS for date intelligence ("last week", "yesterday")
 *   ✓ Named FILTERS for reusable query patterns
 *   ✓ VERIFIED_QUERIES (VQRs) aligned with agent sample questions
 *   ✓ Sample values for categorical dimensions
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
 * Version: 6.0
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
-- ✓ TIME DIMENSIONS for date intelligence
-- ✓ Named FILTERS for reusable query patterns
-- ✓ VERIFIED_QUERIES aligned with agent sample questions

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
TIME DIMENSIONS (
    qh.START_TIME,
    qh.END_TIME
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
        WITH SAMPLE_VALUES = ('SELECT', 'INSERT', 'UPDATE', 'DELETE', 'CREATE_TABLE', 'MERGE', 'COPY', 'UNLOAD')
        COMMENT = 'Statement type (SELECT, INSERT, UPDATE, DELETE, CREATE, MERGE, COPY, UNLOAD).',
    qh.execution_status AS EXECUTION_STATUS
        WITH SYNONYMS = ('query status', 'execution result', 'outcome')
        WITH SAMPLE_VALUES = ('SUCCESS', 'FAIL', 'INCIDENT')
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
        WITH SAMPLE_VALUES = ('COMPUTE_WH', 'ANALYTICS_WH', 'ETL_WH', 'TRANSFORM_WH', 'LOADING_WH')
        COMMENT = 'Warehouse that executed the query (e.g., COMPUTE_WH, ANALYTICS_WH). System warehouses filtered.',
    qh.warehouse_size AS WAREHOUSE_SIZE
        WITH SYNONYMS = ('warehouse tier', 'compute size', 'cluster size')
        WITH SAMPLE_VALUES = ('X-Small', 'Small', 'Medium', 'Large', 'X-Large', '2X-Large', '3X-Large', '4X-Large')
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
FILTERS (
    -- System warehouse exclusion (CRITICAL - always apply)
    EXCLUDE_SYSTEM_WAREHOUSES AS (qh.WAREHOUSE_NAME NOT LIKE 'SYSTEM$%')
        WITH SYNONYMS = ('user warehouses only', 'exclude system')
        COMMENT = 'Exclude system-managed warehouses that users cannot control. Always apply this filter.',

    -- Status filters
    SUCCESSFUL_QUERIES AS (qh.EXECUTION_STATUS = 'SUCCESS')
        WITH SYNONYMS = ('completed queries', 'successful only')
        COMMENT = 'Include only successfully completed queries.',
    FAILED_QUERIES AS (qh.EXECUTION_STATUS = 'FAIL')
        WITH SYNONYMS = ('errors only', 'failures only', 'crashed queries')
        COMMENT = 'Include only failed queries for error analysis.',

    -- Performance filters
    QUERIES_WITH_SPILLING AS ((qh.BYTES_SPILLED_TO_LOCAL_STORAGE > 0 OR qh.BYTES_SPILLED_TO_REMOTE_STORAGE > 0))
        WITH SYNONYMS = ('spilled queries', 'memory pressure queries')
        COMMENT = 'Include queries that experienced memory spilling.',
    QUERIES_WITH_REMOTE_SPILLING AS (qh.BYTES_SPILLED_TO_REMOTE_STORAGE > 0)
        WITH SYNONYMS = ('severe spill', 'remote spill queries')
        COMMENT = 'Include queries with severe spilling to remote storage - critical performance issue.',
    QUERIES_WITH_QUEUING AS ((qh.QUEUED_OVERLOAD_TIME > 0 OR qh.QUEUED_PROVISIONING_TIME > 0))
        WITH SYNONYMS = ('queued queries', 'waiting queries')
        COMMENT = 'Include queries that experienced queue wait time.',

    -- Query type filters
    SELECT_QUERIES AS (qh.QUERY_TYPE = 'SELECT')
        WITH SYNONYMS = ('reads only', 'select only')
        COMMENT = 'Include only SELECT queries for read workload analysis.',
    DML_QUERIES AS (qh.QUERY_TYPE IN ('INSERT', 'UPDATE', 'DELETE', 'MERGE'))
        WITH SYNONYMS = ('writes only', 'modification queries')
        COMMENT = 'Include INSERT, UPDATE, DELETE, MERGE for write workload analysis.',

    -- Time filters
    TODAY AS (qh.START_TIME >= CURRENT_DATE())
        WITH SYNONYMS = ('today only', 'todays queries')
        COMMENT = 'Filter for queries from today only.',
    LAST_7_DAYS AS (qh.START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP()))
        WITH SYNONYMS = ('past week', 'this week', 'last week')
        COMMENT = 'Filter for queries from the last 7 days.',
    LAST_30_DAYS AS (qh.START_TIME >= DATEADD(DAY, -30, CURRENT_TIMESTAMP()))
        WITH SYNONYMS = ('past month', 'this month', 'last month')
        COMMENT = 'Filter for queries from the last 30 days.'
)
VERIFIED_QUERIES (
    -- VQR 1: Matches agent sample question "What are my top 10 slowest queries today and how can I optimize them?"
    'Top 10 slowest queries today' AS (
        SELECT
            QUERY_ID,
            QUERY_TEXT,
            TOTAL_ELAPSED_TIME / 1000 AS DURATION_SECONDS,
            EXECUTION_TIME / 1000 AS EXECUTION_SECONDS,
            WAREHOUSE_NAME,
            WAREHOUSE_SIZE,
            USER_NAME,
            BYTES_SPILLED_TO_REMOTE_STORAGE / (1024*1024*1024) AS REMOTE_SPILL_GB,
            PERCENTAGE_SCANNED_FROM_CACHE AS CACHE_HIT_PCT
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE START_TIME >= CURRENT_DATE()
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        ORDER BY TOTAL_ELAPSED_TIME DESC
        LIMIT 10
    ) WITH QUESTION = 'What are my top 10 slowest queries today and how can I optimize them?',

    -- VQR 2: Matches agent sample question "Which queries are spilling to remote storage?"
    'Queries with remote storage spillage' AS (
        SELECT
            QUERY_ID,
            QUERY_TEXT,
            BYTES_SPILLED_TO_REMOTE_STORAGE / (1024*1024*1024) AS REMOTE_SPILL_GB,
            BYTES_SPILLED_TO_LOCAL_STORAGE / (1024*1024*1024) AS LOCAL_SPILL_GB,
            WAREHOUSE_SIZE,
            WAREHOUSE_NAME,
            TOTAL_ELAPSED_TIME / 1000 AS DURATION_SECONDS,
            USER_NAME
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND BYTES_SPILLED_TO_REMOTE_STORAGE > 0
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        ORDER BY BYTES_SPILLED_TO_REMOTE_STORAGE DESC
        LIMIT 20
    ) WITH QUESTION = 'Which queries are spilling to remote storage?',

    -- VQR 3: Matches agent sample question "Show me queries with errors and suggest how to fix them"
    'Queries with errors' AS (
        SELECT
            QUERY_ID,
            QUERY_TEXT,
            ERROR_CODE,
            ERROR_MESSAGE,
            USER_NAME,
            WAREHOUSE_NAME,
            START_TIME
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE EXECUTION_STATUS = 'FAIL'
            AND START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        ORDER BY START_TIME DESC
        LIMIT 20
    ) WITH QUESTION = 'Show me queries with errors and suggest how to fix them',

    -- VQR 4: Matches agent sample question "What are the most common query error codes?"
    'Most common query error codes' AS (
        SELECT
            ERROR_CODE,
            ERROR_MESSAGE,
            COUNT(*) AS FAILURE_COUNT,
            COUNT(DISTINCT USER_NAME) AS AFFECTED_USERS,
            COUNT(DISTINCT WAREHOUSE_NAME) AS AFFECTED_WAREHOUSES
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE EXECUTION_STATUS = 'FAIL'
            AND START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY ERROR_CODE, ERROR_MESSAGE
        ORDER BY FAILURE_COUNT DESC
        LIMIT 10
    ) WITH QUESTION = 'What are the most common query error codes?',

    -- VQR 5: Query performance by warehouse
    'Query performance by warehouse' AS (
        SELECT
            WAREHOUSE_NAME,
            WAREHOUSE_SIZE,
            COUNT(*) AS QUERY_COUNT,
            AVG(TOTAL_ELAPSED_TIME) / 1000 AS AVG_DURATION_SECONDS,
            APPROX_PERCENTILE(TOTAL_ELAPSED_TIME, 0.95) / 1000 AS P95_DURATION_SECONDS,
            SUM(CASE WHEN EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS ERROR_RATE_PCT,
            AVG(PERCENTAGE_SCANNED_FROM_CACHE) AS AVG_CACHE_HIT_PCT
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY WAREHOUSE_NAME, WAREHOUSE_SIZE
        ORDER BY QUERY_COUNT DESC
    ) WITH QUESTION = 'Show average query performance by warehouse',

    -- VQR 6: Queries with poor partition pruning
    'Queries with poor partition pruning' AS (
        SELECT
            QUERY_ID,
            QUERY_TEXT,
            PARTITIONS_SCANNED,
            PARTITIONS_TOTAL,
            ROUND(PARTITIONS_SCANNED * 100.0 / NULLIF(PARTITIONS_TOTAL, 0), 2) AS SCAN_PERCENTAGE,
            WAREHOUSE_NAME,
            DATABASE_NAME,
            TOTAL_ELAPSED_TIME / 1000 AS DURATION_SECONDS
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND PARTITIONS_TOTAL > 100
            AND PARTITIONS_SCANNED > PARTITIONS_TOTAL * 0.5
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        ORDER BY PARTITIONS_SCANNED DESC
        LIMIT 20
    ) WITH QUESTION = 'Which queries have poor partition pruning?',

    -- VQR 7: User query activity
    'Query activity by user' AS (
        SELECT
            USER_NAME,
            COUNT(*) AS QUERY_COUNT,
            SUM(CASE WHEN EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END) AS FAILED_QUERIES,
            AVG(TOTAL_ELAPSED_TIME) / 1000 AS AVG_DURATION_SECONDS,
            SUM(BYTES_SCANNED) / (1024*1024*1024*1024) AS TOTAL_TB_SCANNED
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY USER_NAME
        ORDER BY QUERY_COUNT DESC
        LIMIT 20
    ) WITH QUESTION = 'Who are the most active users?'
)
COMMENT = 'DEMO: Sam-the-Snowman - Query performance analytics. Analyze execution times, identify slow queries, detect memory spilling, evaluate cache efficiency, and track errors. Excludes system-managed warehouses. (Expires: 2026-02-14)';


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
-- ✓ TIME DIMENSIONS for date intelligence
-- ✓ Named FILTERS for time-based cost analysis
-- ✓ VERIFIED_QUERIES for common cost questions

CREATE OR REPLACE SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_COST_ANALYSIS
TABLES (
    wmh AS SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
        PRIMARY KEY (WAREHOUSE_ID, START_TIME)
        COMMENT = 'Hourly credit consumption for all warehouses. Contains compute and cloud services credits. Primary source for cost analysis.'
)
TIME DIMENSIONS (
    wmh.START_TIME,
    wmh.END_TIME
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
        WITH SAMPLE_VALUES = ('COMPUTE_WH', 'ANALYTICS_WH', 'ETL_WH', 'TRANSFORM_WH', 'LOADING_WH')
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
FILTERS (
    -- System warehouse exclusion
    EXCLUDE_SYSTEM_WAREHOUSES AS (wmh.WAREHOUSE_NAME NOT LIKE 'SYSTEM$%')
        WITH SYNONYMS = ('user warehouses only', 'exclude system')
        COMMENT = 'Exclude system-managed warehouses that users cannot control.',

    -- Time filters
    TODAY AS (wmh.START_TIME >= CURRENT_DATE())
        WITH SYNONYMS = ('today only')
        COMMENT = 'Filter for metering data from today only.',
    YESTERDAY AS (DATE(wmh.START_TIME) = DATEADD(DAY, -1, CURRENT_DATE()))
        WITH SYNONYMS = ('yesterday only')
        COMMENT = 'Filter for metering data from yesterday.',
    LAST_7_DAYS AS (wmh.START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP()))
        WITH SYNONYMS = ('past week', 'this week', 'last week')
        COMMENT = 'Filter for metering data from the last 7 days.',
    LAST_30_DAYS AS (wmh.START_TIME >= DATEADD(DAY, -30, CURRENT_TIMESTAMP()))
        WITH SYNONYMS = ('past month', 'this month', 'last month')
        COMMENT = 'Filter for metering data from the last 30 days.',
    CURRENT_MONTH AS (wmh.START_TIME >= DATE_TRUNC('MONTH', CURRENT_DATE()))
        WITH SYNONYMS = ('this month', 'mtd', 'month to date')
        COMMENT = 'Filter for the current calendar month.',
    LAST_MONTH AS ((wmh.START_TIME >= DATE_TRUNC('MONTH', DATEADD('MONTH', -1, CURRENT_DATE())) AND wmh.START_TIME < DATE_TRUNC('MONTH', CURRENT_DATE())))
        WITH SYNONYMS = ('previous month', 'prior month')
        COMMENT = 'Filter for the previous calendar month.',

    -- Activity filter
    WITH_ACTIVITY AS (wmh.CREDITS_USED > 0)
        WITH SYNONYMS = ('active periods', 'with usage')
        COMMENT = 'Filter for periods with actual credit consumption.'
)
VERIFIED_QUERIES (
    -- VQR 1: Matches agent sample question "Which warehouses are costing me the most money this month?"
    'Most expensive warehouses this month' AS (
        SELECT
            WAREHOUSE_NAME,
            SUM(CREDITS_USED) AS TOTAL_CREDITS,
            SUM(CREDITS_USED_COMPUTE) AS COMPUTE_CREDITS,
            SUM(CREDITS_USED_CLOUD_SERVICES) AS CLOUD_SERVICES_CREDITS,
            ROUND(SUM(CREDITS_USED) * 3, 2) AS ESTIMATED_COST_USD
        FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
        WHERE START_TIME >= DATE_TRUNC('MONTH', CURRENT_DATE())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY WAREHOUSE_NAME
        ORDER BY TOTAL_CREDITS DESC
    ) WITH QUESTION = 'Which warehouses are costing me the most money this month?',

    -- VQR 2: Matches agent sample question "What's my daily credit spend trend for the past 30 days?"
    'Daily credit spend trend 30 days' AS (
        SELECT
            DATE(START_TIME) AS USAGE_DATE,
            SUM(CREDITS_USED) AS DAILY_CREDITS,
            ROUND(SUM(CREDITS_USED) * 3, 2) AS DAILY_COST_USD,
            COUNT(DISTINCT WAREHOUSE_NAME) AS ACTIVE_WAREHOUSES
        FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
        WHERE START_TIME >= DATEADD('DAY', -30, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY USAGE_DATE
        ORDER BY USAGE_DATE DESC
    ) WITH QUESTION = 'What is my daily credit spend trend for the past 30 days?',

    -- VQR 3: Cloud services ratio analysis
    'Warehouses with high cloud services costs' AS (
        SELECT
            WAREHOUSE_NAME,
            SUM(CREDITS_USED_COMPUTE) AS COMPUTE_CREDITS,
            SUM(CREDITS_USED_CLOUD_SERVICES) AS SERVICES_CREDITS,
            ROUND(SUM(CREDITS_USED_CLOUD_SERVICES) * 100.0 / NULLIF(SUM(CREDITS_USED_COMPUTE), 0), 2) AS SERVICES_PERCENTAGE
        FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
        WHERE START_TIME >= DATEADD('DAY', -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY WAREHOUSE_NAME
        HAVING SERVICES_PERCENTAGE > 10
        ORDER BY SERVICES_PERCENTAGE DESC
    ) WITH QUESTION = 'Which warehouses have high cloud services costs?',

    -- VQR 4: Hourly cost pattern
    'Hourly cost pattern by warehouse' AS (
        SELECT
            WAREHOUSE_NAME,
            HOUR(START_TIME) AS HOUR_OF_DAY,
            AVG(CREDITS_USED) AS AVG_HOURLY_CREDITS,
            ROUND(AVG(CREDITS_USED) * 3, 2) AS AVG_HOURLY_COST_USD
        FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
        WHERE START_TIME >= DATEADD('DAY', -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY WAREHOUSE_NAME, HOUR_OF_DAY
        ORDER BY WAREHOUSE_NAME, HOUR_OF_DAY
    ) WITH QUESTION = 'What is the hourly cost pattern by warehouse?',

    -- VQR 5: Week-over-week comparison
    'Week over week cost comparison' AS (
        SELECT
            WAREHOUSE_NAME,
            SUM(CASE WHEN START_TIME >= DATEADD('DAY', -7, CURRENT_TIMESTAMP()) THEN CREDITS_USED ELSE 0 END) AS THIS_WEEK_CREDITS,
            SUM(CASE WHEN START_TIME >= DATEADD('DAY', -14, CURRENT_TIMESTAMP()) AND START_TIME < DATEADD('DAY', -7, CURRENT_TIMESTAMP()) THEN CREDITS_USED ELSE 0 END) AS LAST_WEEK_CREDITS,
            ROUND((THIS_WEEK_CREDITS - LAST_WEEK_CREDITS) * 100.0 / NULLIF(LAST_WEEK_CREDITS, 0), 2) AS WEEK_OVER_WEEK_CHANGE_PCT
        FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
        WHERE START_TIME >= DATEADD('DAY', -14, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY WAREHOUSE_NAME
        ORDER BY THIS_WEEK_CREDITS DESC
    ) WITH QUESTION = 'Compare this week costs to last week by warehouse',

    -- VQR 6: Monthly cost breakdown
    'Monthly cost breakdown' AS (
        SELECT
            DATE_TRUNC('MONTH', START_TIME) AS MONTH,
            COUNT(DISTINCT WAREHOUSE_NAME) AS ACTIVE_WAREHOUSES,
            SUM(CREDITS_USED) AS TOTAL_CREDITS,
            ROUND(SUM(CREDITS_USED) * 3, 2) AS TOTAL_COST_USD,
            SUM(CREDITS_USED_COMPUTE) AS COMPUTE_CREDITS,
            SUM(CREDITS_USED_CLOUD_SERVICES) AS CLOUD_SERVICES_CREDITS
        FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
        WHERE START_TIME >= DATEADD('MONTH', -6, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY MONTH
        ORDER BY MONTH DESC
    ) WITH QUESTION = 'Show monthly cost breakdown'
)
COMMENT = 'DEMO: Sam-the-Snowman - Warehouse cost analysis. Track spending by warehouse, identify cost trends, support FinOps. Excludes system-managed warehouses. (Expires: 2026-02-14)';


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
-- ✓ TIME DIMENSIONS for date intelligence
-- ✓ Named FILTERS for capacity analysis
-- ✓ VERIFIED_QUERIES for sizing and operations questions

CREATE OR REPLACE SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_WAREHOUSE_OPERATIONS
TABLES (
    wlh AS SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
        PRIMARY KEY (WAREHOUSE_ID, START_TIME)
        COMMENT = 'Time-series load metrics for warehouses. Captures concurrency, queue depth, and blocked queries. Essential for capacity planning.'
)
TIME DIMENSIONS (
    wlh.START_TIME,
    wlh.END_TIME
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
        WITH SAMPLE_VALUES = ('COMPUTE_WH', 'ANALYTICS_WH', 'ETL_WH', 'TRANSFORM_WH', 'LOADING_WH')
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
FILTERS (
    -- System warehouse exclusion
    EXCLUDE_SYSTEM_WAREHOUSES AS (wlh.WAREHOUSE_NAME NOT LIKE 'SYSTEM$%')
        WITH SYNONYMS = ('user warehouses only', 'exclude system')
        COMMENT = 'Exclude system-managed warehouses that users cannot control.',

    -- Load filters
    WITH_QUEUING AS (wlh.AVG_QUEUED_LOAD > 0)
        WITH SYNONYMS = ('queued only', 'constrained periods')
        COMMENT = 'Include only periods with active queuing for capacity analysis.',
    WITH_BLOCKING AS (wlh.AVG_BLOCKED > 0)
        WITH SYNONYMS = ('blocked only', 'contention periods')
        COMMENT = 'Include only periods with blocked queries for contention analysis.',
    WITH_ACTIVITY AS (wlh.AVG_RUNNING > 0)
        WITH SYNONYMS = ('active periods', 'with load')
        COMMENT = 'Include only periods with running queries.',
    HIGH_LOAD AS (wlh.AVG_RUNNING > 5)
        WITH SYNONYMS = ('busy periods', 'high concurrency')
        COMMENT = 'Include only high-load periods (concurrency > 5).',

    -- Time filters
    TODAY AS (wlh.START_TIME >= CURRENT_DATE())
        WITH SYNONYMS = ('today only')
        COMMENT = 'Filter for load data from today only.',
    LAST_7_DAYS AS (wlh.START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP()))
        WITH SYNONYMS = ('past week', 'this week', 'last week')
        COMMENT = 'Filter for load data from the last 7 days.',
    LAST_30_DAYS AS (wlh.START_TIME >= DATEADD(DAY, -30, CURRENT_TIMESTAMP()))
        WITH SYNONYMS = ('past month', 'this month', 'last month')
        COMMENT = 'Filter for load data from the last 30 days.'
)
VERIFIED_QUERIES (
    -- VQR 1: Matches agent sample question "Are my warehouses properly sized based on queue times?"
    'Warehouse sizing analysis' AS (
        SELECT
            WAREHOUSE_NAME,
            AVG(AVG_RUNNING) AS AVG_CONCURRENCY,
            AVG(AVG_QUEUED_LOAD) AS AVG_QUEUE_DEPTH,
            MAX(AVG_QUEUED_LOAD) AS MAX_QUEUE_DEPTH,
            SUM(CASE WHEN AVG_QUEUED_LOAD > 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS QUEUING_PCT,
            CASE
                WHEN AVG(AVG_QUEUED_LOAD) > 1 THEN 'UNDERSIZED - High queuing, consider upsizing or multi-cluster'
                WHEN AVG(AVG_RUNNING) < 1 AND AVG(AVG_QUEUED_LOAD) = 0 THEN 'OVERSIZED - Low utilization, consider downsizing'
                ELSE 'APPROPRIATE - Good balance of utilization and queuing'
            END AS SIZING_RECOMMENDATION
        FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY WAREHOUSE_NAME
        ORDER BY AVG_QUEUE_DEPTH DESC
    ) WITH QUESTION = 'Are my warehouses properly sized based on queue times?',

    -- VQR 2: Matches agent sample question "Show me warehouse utilization by hour of day"
    'Warehouse utilization by hour' AS (
        SELECT
            WAREHOUSE_NAME,
            HOUR(START_TIME) AS HOUR_OF_DAY,
            AVG(AVG_RUNNING) AS AVG_CONCURRENCY,
            AVG(AVG_QUEUED_LOAD) AS AVG_QUEUE_DEPTH,
            MAX(AVG_RUNNING) AS PEAK_CONCURRENCY
        FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY WAREHOUSE_NAME, HOUR_OF_DAY
        ORDER BY WAREHOUSE_NAME, HOUR_OF_DAY
    ) WITH QUESTION = 'Show me warehouse utilization by hour of day',

    -- VQR 3: Warehouses with queuing issues
    'Warehouses with queuing' AS (
        SELECT
            WAREHOUSE_NAME,
            AVG(AVG_QUEUED_LOAD) AS AVG_QUEUE_DEPTH,
            MAX(AVG_QUEUED_LOAD) AS MAX_QUEUE_DEPTH,
            SUM(CASE WHEN AVG_QUEUED_LOAD > 0 THEN 1 ELSE 0 END) AS PERIODS_WITH_QUEUING,
            COUNT(*) AS TOTAL_PERIODS,
            ROUND(PERIODS_WITH_QUEUING * 100.0 / TOTAL_PERIODS, 2) AS QUEUING_PCT
        FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY WAREHOUSE_NAME
        HAVING AVG_QUEUE_DEPTH > 0
        ORDER BY AVG_QUEUE_DEPTH DESC
    ) WITH QUESTION = 'Which warehouses have the most queued queries?',

    -- VQR 4: Lock contention analysis
    'Lock contention analysis' AS (
        SELECT
            WAREHOUSE_NAME,
            AVG(AVG_BLOCKED) AS AVG_BLOCKED_QUERIES,
            MAX(AVG_BLOCKED) AS MAX_BLOCKED_QUERIES,
            SUM(CASE WHEN AVG_BLOCKED > 0 THEN 1 ELSE 0 END) AS PERIODS_WITH_BLOCKING,
            COUNT(*) AS TOTAL_PERIODS
        FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY WAREHOUSE_NAME
        HAVING AVG_BLOCKED_QUERIES > 0
        ORDER BY AVG_BLOCKED_QUERIES DESC
    ) WITH QUESTION = 'Which warehouses have lock contention issues?',

    -- VQR 5: Cold start impact
    'Cold start impact analysis' AS (
        SELECT
            WAREHOUSE_NAME,
            AVG(AVG_QUEUED_PROVISIONING) AS AVG_PROVISIONING_QUEUE,
            MAX(AVG_QUEUED_PROVISIONING) AS MAX_PROVISIONING_QUEUE,
            SUM(CASE WHEN AVG_QUEUED_PROVISIONING > 0 THEN 1 ELSE 0 END) AS COLD_START_EVENTS
        FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY WAREHOUSE_NAME
        HAVING COLD_START_EVENTS > 0
        ORDER BY COLD_START_EVENTS DESC
    ) WITH QUESTION = 'Which warehouses have provisioning delays?',

    -- VQR 6: Overall utilization summary
    'Warehouse utilization summary' AS (
        SELECT
            WAREHOUSE_NAME,
            AVG(AVG_RUNNING) AS AVG_CONCURRENCY,
            MAX(AVG_RUNNING) AS PEAK_CONCURRENCY,
            AVG(AVG_QUEUED_LOAD) AS AVG_QUEUE_DEPTH,
            AVG(AVG_QUEUED_PROVISIONING) AS AVG_PROVISIONING_QUEUE,
            AVG(AVG_BLOCKED) AS AVG_BLOCKED
        FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY WAREHOUSE_NAME
        ORDER BY AVG_CONCURRENCY DESC
    ) WITH QUESTION = 'Show overall warehouse utilization',

    -- VQR 7: Daily load trend
    'Daily warehouse load trend' AS (
        SELECT
            DATE(START_TIME) AS LOAD_DATE,
            WAREHOUSE_NAME,
            AVG(AVG_RUNNING) AS AVG_CONCURRENCY,
            AVG(AVG_QUEUED_LOAD) AS AVG_QUEUE_DEPTH
        FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -14, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY LOAD_DATE, WAREHOUSE_NAME
        ORDER BY LOAD_DATE DESC, WAREHOUSE_NAME
    ) WITH QUESTION = 'Show daily warehouse load trend'
)
COMMENT = 'DEMO: Sam-the-Snowman - Warehouse utilization and capacity planning. Monitor concurrency, queue depth, and sizing opportunities. Excludes system-managed warehouses. (Expires: 2026-02-14)';


-- Semantic views complete
