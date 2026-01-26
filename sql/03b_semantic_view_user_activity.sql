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
 * Version: 6.1
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
-- ✓ Rich contextual descriptions

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
        COMMENT = 'Warehouse that executed the query. Example values: COMPUTE_WH, ANALYTICS_WH, ETL_WH.',
    qh.database_name AS DATABASE_NAME
        WITH SYNONYMS = ('database', 'db')
        COMMENT = 'Primary database accessed.',
    qh.query_type AS QUERY_TYPE
        WITH SYNONYMS = ('statement type', 'operation type')
        COMMENT = 'Type of SQL statement executed. Example values: SELECT, INSERT, UPDATE, DELETE, CREATE_TABLE, MERGE.',
    qh.execution_status AS EXECUTION_STATUS
        WITH SYNONYMS = ('status', 'result', 'outcome')
        COMMENT = 'Query execution outcome. Values: SUCCESS, FAIL, INCIDENT.',
    qh.start_time AS START_TIME
        WITH SYNONYMS = ('query time', 'when', 'timestamp', 'date')
        COMMENT = 'Query start timestamp (UTC). Use for time-based filtering.',
    qh.end_time AS END_TIME
        WITH SYNONYMS = ('completion time', 'finished')
        COMMENT = 'Query completion timestamp (UTC).'
)
METRICS (
    -- Activity Metrics
    qh.query_count AS COUNT(qh.query_id)
        WITH SYNONYMS = ('total queries', 'number of queries', 'query volume')
        COMMENT = 'Total count of queries executed.',
    qh.unique_users AS COUNT(DISTINCT qh.user_name)
        WITH SYNONYMS = ('user count', 'distinct users', 'active users')
        COMMENT = 'Number of unique users who executed queries.',
    qh.active_days AS COUNT(DISTINCT DATE(qh.start_time))
        WITH SYNONYMS = ('days active', 'distinct days')
        COMMENT = 'Number of distinct days with query activity.',

    -- Performance Metrics
    qh.avg_execution_time_ms AS AVG(qh.execution_time)
        WITH SYNONYMS = ('average runtime', 'mean execution time')
        COMMENT = 'Average query execution time in milliseconds.',
    qh.avg_duration_ms AS AVG(qh.total_elapsed_time)
        WITH SYNONYMS = ('average duration', 'mean latency')
        COMMENT = 'Average total query duration in milliseconds.',
    qh.p95_duration_ms AS APPROX_PERCENTILE(qh.total_elapsed_time, 0.95)
        WITH SYNONYMS = ('95th percentile', 'p95 latency')
        COMMENT = '95th percentile query duration - excludes outliers.',

    -- Data Metrics
    qh.total_bytes_scanned AS SUM(qh.bytes_scanned)
        WITH SYNONYMS = ('data volume', 'bytes processed')
        COMMENT = 'Total bytes scanned across all queries.',
    qh.total_tb_scanned AS (SUM(qh.bytes_scanned) / (1024.0*1024*1024*1024))
        WITH SYNONYMS = ('terabytes scanned', 'TB processed')
        COMMENT = 'Total terabytes scanned across all queries.',

    -- Quality Metrics
    qh.failed_query_count AS SUM(CASE WHEN qh.execution_status = 'FAIL' THEN 1 ELSE 0 END)
        WITH SYNONYMS = ('errors', 'failures', 'failed queries')
        COMMENT = 'Number of queries that failed.',
    qh.error_rate AS (100.0 * SUM(CASE WHEN qh.execution_status = 'FAIL' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0))
        WITH SYNONYMS = ('failure rate', 'error percentage')
        COMMENT = 'Percentage of queries that failed.',

    -- Cost Metrics
    qah.total_credits AS SUM(qah.credits_attributed_compute)
        WITH SYNONYMS = ('credit consumption', 'total cost', 'compute credits')
        COMMENT = 'Total compute credits consumed.',
    qah.avg_credits_per_query AS AVG(qah.credits_attributed_compute)
        WITH SYNONYMS = ('cost per query', 'average credits')
        COMMENT = 'Average credits consumed per query.'
)
COMMENT = 'DEMO: Sam-the-Snowman - User activity analysis. Track query patterns, credit consumption, and error rates by user. Excludes system-managed warehouses. (Expires: 2026-02-14)';


-- User activity semantic view complete
