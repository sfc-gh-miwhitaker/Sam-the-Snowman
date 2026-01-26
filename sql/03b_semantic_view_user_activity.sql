/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * Module: 03b_semantic_view_user_activity.sql
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * PURPOSE:
 *   Create a semantic view for user activity analysis - answering questions like
 *   "Who's using the most credits?" and "Which users are most active?"
 *
 * Synopsis:
 *   Creates semantic view for user-level query activity and cost attribution.
 *
 * Description:
 *   This module creates a user-centric semantic view that enables Sam-the-Snowman
 *   to answer questions about user behavior:
 *
 *   - Who are the most active users?
 *   - Which users are consuming the most credits?
 *   - What's the error rate by user?
 *   - User activity trends over time
 *
 * OBJECTS CREATED:
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_USER_ACTIVITY (Semantic View)
 *
 * Prerequisites:
 *   - 01_scaffolding.sql must be run first
 *   - 03_semantic_views.sql should be run first
 *   - Configured role must have access to SNOWFLAKE.ACCOUNT_USAGE views
 *
 * Author: SE Community
 * Created: 2025-01-26
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
-- SEMANTIC VIEW: SV_SAM_USER_ACTIVITY
-- ============================================================================
-- Purpose: Analyze user-level query activity, costs, and patterns
-- Data Sources: QUERY_HISTORY, QUERY_ATTRIBUTION_HISTORY
-- Key Metrics: Queries per user, credits per user, error rates
--
-- Best Practices Implemented:
-- ✓ Table relationships for cost-per-user analysis
-- ✓ Pre-defined metrics for user activity
-- ✓ Comprehensive synonyms for user-related queries
-- ✓ TIME DIMENSIONS for temporal analysis
-- ✓ Named FILTERS for activity-based segmentation
-- ✓ VERIFIED_QUERIES for common user questions

CREATE OR REPLACE SEMANTIC VIEW SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_USER_ACTIVITY
TABLES (
    qh AS SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        PRIMARY KEY (QUERY_ID)
        COMMENT = 'Historical record of all queries executed. Used for user activity analysis with ~45 minute latency.',
    qah AS SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY
        PRIMARY KEY (QUERY_ID)
        COMMENT = 'Credit attribution data for cost-per-user analysis.'
)
RELATIONSHIPS (
    qh(QUERY_ID) REFERENCES qah
)
TIME DIMENSIONS (
    qh.START_TIME,
    qh.END_TIME
)
FACTS (
    -- Timing Metrics
    qh.execution_time AS EXECUTION_TIME
        WITH SYNONYMS = ('runtime', 'processing time', 'query time')
        COMMENT = 'Query execution time in milliseconds.',
    qh.total_elapsed_time AS TOTAL_ELAPSED_TIME
        WITH SYNONYMS = ('duration', 'total time', 'latency', 'response time')
        COMMENT = 'Total query duration including all phases (milliseconds).',

    -- Data Volume
    qh.bytes_scanned AS BYTES_SCANNED
        WITH SYNONYMS = ('data scanned', 'bytes read', 'data processed')
        COMMENT = 'Total bytes scanned by the query.',
    qh.bytes_spilled_to_remote_storage AS BYTES_SPILLED_TO_REMOTE_STORAGE
        WITH SYNONYMS = ('remote spill', 'memory overflow')
        COMMENT = 'Bytes spilled to remote storage - indicates memory pressure.',

    -- Cost
    qah.credits_attributed_compute AS CREDITS_ATTRIBUTED_COMPUTE
        WITH SYNONYMS = ('query cost', 'credits used', 'compute cost', 'spend')
        COMMENT = 'Compute credits consumed by this query.'
)
DIMENSIONS (
    qh.query_id AS QUERY_ID
        WITH SYNONYMS = ('query identifier', 'execution id')
        COMMENT = 'Unique query identifier.',
    qh.user_name AS USER_NAME
        WITH SYNONYMS = ('username', 'user', 'who', 'person', 'account')
        COMMENT = 'User who executed the query. Primary dimension for user analysis.',
    qh.role_name AS ROLE_NAME
        WITH SYNONYMS = ('role', 'active role', 'execution role')
        COMMENT = 'Role used during query execution.',
    qh.warehouse_name AS WAREHOUSE_NAME
        WITH SYNONYMS = ('warehouse', 'compute', 'cluster')
        WITH SAMPLE_VALUES = ('COMPUTE_WH', 'ANALYTICS_WH', 'ETL_WH', 'TRANSFORM_WH')
        COMMENT = 'Warehouse that executed the query.',
    qh.database_name AS DATABASE_NAME
        WITH SYNONYMS = ('database', 'db')
        COMMENT = 'Primary database accessed.',
    qh.query_type AS QUERY_TYPE
        WITH SYNONYMS = ('statement type', 'operation type')
        WITH SAMPLE_VALUES = ('SELECT', 'INSERT', 'UPDATE', 'DELETE', 'CREATE_TABLE', 'MERGE')
        COMMENT = 'Type of SQL statement executed.',
    qh.execution_status AS EXECUTION_STATUS
        WITH SYNONYMS = ('status', 'result', 'outcome')
        WITH SAMPLE_VALUES = ('SUCCESS', 'FAIL', 'INCIDENT')
        COMMENT = 'Query execution outcome.',
    qh.start_time AS START_TIME
        WITH SYNONYMS = ('query time', 'when', 'timestamp')
        COMMENT = 'Query start timestamp (UTC).',
    qh.end_time AS END_TIME
        WITH SYNONYMS = ('completion time', 'finished')
        COMMENT = 'Query completion timestamp (UTC).'
)
METRICS (
    -- Activity Metrics
    qh.query_count AS COUNT(qh.query_id),
    qh.unique_users AS COUNT(DISTINCT qh.user_name),
    qh.active_days AS COUNT(DISTINCT DATE(qh.start_time)),

    -- Performance Metrics
    qh.avg_execution_time_ms AS AVG(qh.execution_time),
    qh.avg_duration_ms AS AVG(qh.total_elapsed_time),
    qh.p95_duration_ms AS APPROX_PERCENTILE(qh.total_elapsed_time, 0.95),

    -- Data Metrics
    qh.total_bytes_scanned AS SUM(qh.bytes_scanned),
    qh.total_tb_scanned AS (SUM(qh.bytes_scanned) / (1024.0*1024*1024*1024)),

    -- Quality Metrics
    qh.failed_query_count AS SUM(CASE WHEN qh.execution_status = 'FAIL' THEN 1 ELSE 0 END),
    qh.error_rate AS (100.0 * SUM(CASE WHEN qh.execution_status = 'FAIL' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)),

    -- Cost Metrics
    qah.total_credits AS SUM(qah.credits_attributed_compute),
    qah.avg_credits_per_query AS AVG(qah.credits_attributed_compute)
)
FILTERS (
    -- System exclusion
    EXCLUDE_SYSTEM_WAREHOUSES AS (qh.WAREHOUSE_NAME NOT LIKE 'SYSTEM$%')
        WITH SYNONYMS = ('user warehouses only', 'exclude system')
        COMMENT = 'Exclude system-managed warehouses.',

    -- Status filters
    SUCCESSFUL_QUERIES AS (qh.EXECUTION_STATUS = 'SUCCESS')
        WITH SYNONYMS = ('successful only', 'completed')
        COMMENT = 'Include only successful queries.',
    FAILED_QUERIES AS (qh.EXECUTION_STATUS = 'FAIL')
        WITH SYNONYMS = ('errors only', 'failures')
        COMMENT = 'Include only failed queries.',

    -- Activity filters
    HIGH_ACTIVITY_USERS AS (qh.USER_NAME IN (
        SELECT USER_NAME FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
        GROUP BY USER_NAME HAVING COUNT(*) > 100
    ))
        WITH SYNONYMS = ('power users', 'heavy users')
        COMMENT = 'Users with more than 100 queries in 7 days.',

    -- Query type filters
    SELECT_QUERIES AS (qh.QUERY_TYPE = 'SELECT')
        WITH SYNONYMS = ('reads only')
        COMMENT = 'Include only SELECT queries.',
    DML_QUERIES AS (qh.QUERY_TYPE IN ('INSERT', 'UPDATE', 'DELETE', 'MERGE'))
        WITH SYNONYMS = ('writes only', 'modifications')
        COMMENT = 'Include only DML queries.',

    -- Time filters
    TODAY AS (qh.START_TIME >= CURRENT_DATE())
        WITH SYNONYMS = ('today only')
        COMMENT = 'Filter for queries from today.',
    LAST_7_DAYS AS (qh.START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP()))
        WITH SYNONYMS = ('past week', 'this week')
        COMMENT = 'Filter for queries from the last 7 days.',
    LAST_30_DAYS AS (qh.START_TIME >= DATEADD(DAY, -30, CURRENT_TIMESTAMP()))
        WITH SYNONYMS = ('past month', 'this month')
        COMMENT = 'Filter for queries from the last 30 days.'
)
VERIFIED_QUERIES (
    -- VQR 1: Primary question - Who's using the most credits?
    'Users by credit consumption' AS (
        SELECT
            qh.USER_NAME,
            COUNT(*) AS QUERY_COUNT,
            SUM(qah.CREDITS_ATTRIBUTED_COMPUTE) AS TOTAL_CREDITS,
            ROUND(SUM(qah.CREDITS_ATTRIBUTED_COMPUTE) * 3, 2) AS ESTIMATED_COST_USD,
            AVG(qah.CREDITS_ATTRIBUTED_COMPUTE) AS AVG_CREDITS_PER_QUERY,
            SUM(qh.BYTES_SCANNED) / (1024*1024*1024*1024) AS TOTAL_TB_SCANNED
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY qh
        LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY qah
            ON qh.QUERY_ID = qah.QUERY_ID
        WHERE qh.START_TIME >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())
            AND qh.WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY qh.USER_NAME
        ORDER BY TOTAL_CREDITS DESC NULLS LAST
        LIMIT 20
    ) WITH QUESTION = 'Who is using the most credits?',

    -- VQR 2: Most active users
    'Most active users' AS (
        SELECT
            USER_NAME,
            COUNT(*) AS QUERY_COUNT,
            COUNT(DISTINCT DATE(START_TIME)) AS ACTIVE_DAYS,
            AVG(TOTAL_ELAPSED_TIME) / 1000 AS AVG_DURATION_SECONDS,
            SUM(CASE WHEN EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END) AS FAILED_QUERIES,
            ROUND(SUM(CASE WHEN EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS ERROR_RATE_PCT
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY USER_NAME
        ORDER BY QUERY_COUNT DESC
        LIMIT 20
    ) WITH QUESTION = 'Who are the most active users?',

    -- VQR 3: Users with high error rates
    'Users with high error rates' AS (
        SELECT
            USER_NAME,
            COUNT(*) AS TOTAL_QUERIES,
            SUM(CASE WHEN EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END) AS FAILED_QUERIES,
            ROUND(SUM(CASE WHEN EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS ERROR_RATE_PCT
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY USER_NAME
        HAVING TOTAL_QUERIES >= 10 AND ERROR_RATE_PCT > 5
        ORDER BY ERROR_RATE_PCT DESC
    ) WITH QUESTION = 'Which users have high error rates?',

    -- VQR 4: User activity by day
    'User activity trend' AS (
        SELECT
            DATE(START_TIME) AS ACTIVITY_DATE,
            COUNT(DISTINCT USER_NAME) AS ACTIVE_USERS,
            COUNT(*) AS TOTAL_QUERIES,
            SUM(CASE WHEN EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END) AS FAILED_QUERIES
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY ACTIVITY_DATE
        ORDER BY ACTIVITY_DATE DESC
    ) WITH QUESTION = 'Show user activity trend over time',

    -- VQR 5: User query patterns by type
    'User query patterns' AS (
        SELECT
            USER_NAME,
            QUERY_TYPE,
            COUNT(*) AS QUERY_COUNT,
            AVG(TOTAL_ELAPSED_TIME) / 1000 AS AVG_DURATION_SECONDS
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY USER_NAME, QUERY_TYPE
        ORDER BY USER_NAME, QUERY_COUNT DESC
    ) WITH QUESTION = 'What types of queries do users run?',

    -- VQR 6: User warehouse preferences
    'User warehouse usage' AS (
        SELECT
            USER_NAME,
            WAREHOUSE_NAME,
            COUNT(*) AS QUERY_COUNT,
            AVG(TOTAL_ELAPSED_TIME) / 1000 AS AVG_DURATION_SECONDS
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        GROUP BY USER_NAME, WAREHOUSE_NAME
        ORDER BY USER_NAME, QUERY_COUNT DESC
    ) WITH QUESTION = 'Which warehouses do users prefer?',

    -- VQR 7: Users with expensive queries
    'Users with expensive queries' AS (
        SELECT
            qh.USER_NAME,
            COUNT(*) AS EXPENSIVE_QUERY_COUNT,
            SUM(qah.CREDITS_ATTRIBUTED_COMPUTE) AS TOTAL_CREDITS_FROM_EXPENSIVE,
            AVG(qh.TOTAL_ELAPSED_TIME) / 1000 AS AVG_DURATION_SECONDS
        FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY qh
        LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY qah
            ON qh.QUERY_ID = qah.QUERY_ID
        WHERE qh.START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND qh.WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
            AND qah.CREDITS_ATTRIBUTED_COMPUTE > 0.1
        GROUP BY qh.USER_NAME
        ORDER BY TOTAL_CREDITS_FROM_EXPENSIVE DESC NULLS LAST
        LIMIT 20
    ) WITH QUESTION = 'Which users run expensive queries?'
)
COMMENT = 'DEMO: Sam-the-Snowman - User activity analysis. Track query patterns, credit consumption, and error rates by user. Excludes system-managed warehouses. (Expires: 2026-02-14)';


-- User activity semantic view complete
