/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * Module: 03_deploy_semantic_models.sql
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * PURPOSE:
 *   Deploy semantic views using SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML()
 *   with inline YAML specifications. This provides full feature support:
 *   - TIME_DIMENSIONS for date intelligence
 *   - FILTERS for reusable query patterns
 *   - VERIFIED_QUERIES (VQRs) for accuracy
 *   - sample_values for categorical dimensions
 *
 * Synopsis:
 *   Each semantic model is defined inline using $$-quoted YAML and deployed
 *   via SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(). Dimensions, facts, metrics,
 *   and filters are nested inside table definitions per the semantic view
 *   YAML spec. Only cross-table derived metrics go at the view level.
 *
 * OBJECTS CREATED:
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_QUERY_PERFORMANCE
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_COST_ANALYSIS
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_WAREHOUSE_OPERATIONS
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_USER_ACTIVITY
 *
 * Prerequisites:
 *   - 01_scaffolding.sql must be run first
 *   - Configured role must have access to SNOWFLAKE.ACCOUNT_USAGE views
 *
 * Author: SE Community
 * Created: 2025-01-26
 * Expires: 2026-04-18
 * Version: 8.0
 * License: Apache 2.0
 *
 * Usage:
 *   This module is called by deploy_all.sql or can be run standalone.
 ******************************************************************************/

USE ROLE SYSADMIN;
USE WAREHOUSE SFE_SAM_SNOWMAN_WH;

-- ============================================================================
-- 1. QUERY PERFORMANCE
-- ============================================================================

CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
    'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS',
    $$
name: SV_SAM_QUERY_PERFORMANCE
description: >-
  Query performance analytics for Snowflake workloads. Analyze execution times,
  identify slow queries, detect memory spilling, evaluate cache efficiency,
  and track query errors.

tables:
  - name: QUERY_HISTORY
    description: >-
      Historical record of all queries executed in the Snowflake account.
      Data is available with approximately 45-minute latency from ACCOUNT_USAGE.
    base_table:
      database: SNOWFLAKE
      schema: ACCOUNT_USAGE
      table: QUERY_HISTORY
    primary_key:
      columns:
        - QUERY_ID

    dimensions:
      - name: QUERY_ID
        description: Unique identifier for each query execution (UUID format).
        synonyms:
          - query uuid
          - query identifier
          - execution id
        expr: QUERY_HISTORY.QUERY_ID
        data_type: TEXT
        unique: true

      - name: QUERY_TEXT
        description: >-
          Complete SQL statement text as executed. May be truncated for very
          long queries.
        synonyms:
          - SQL
          - query statement
          - SQL text
          - query string
          - statement
          - code
        expr: QUERY_HISTORY.QUERY_TEXT
        data_type: TEXT

      - name: QUERY_TYPE
        description: >-
          Classification of the SQL statement type (SELECT, INSERT, UPDATE,
          DELETE, CREATE, MERGE, etc.).
        synonyms:
          - query category
          - statement type
          - operation type
          - SQL type
        expr: QUERY_HISTORY.QUERY_TYPE
        data_type: TEXT
        sample_values:
          - SELECT
          - INSERT
          - UPDATE
          - DELETE
          - CREATE_TABLE
          - CREATE_TABLE_AS_SELECT
          - MERGE
          - COPY
          - UNLOAD

      - name: EXECUTION_STATUS
        description: >-
          Final outcome of query execution. SUCCESS indicates completion,
          FAIL indicates errors, INCIDENT indicates system-level issues.
        synonyms:
          - query status
          - execution result
          - completion status
          - outcome
          - result
        expr: QUERY_HISTORY.EXECUTION_STATUS
        data_type: TEXT
        sample_values:
          - SUCCESS
          - FAIL
          - INCIDENT

      - name: ERROR_CODE
        description: Numeric error code for failed queries. NULL for successful queries.
        synonyms:
          - failure code
          - error number
          - error id
        expr: QUERY_HISTORY.ERROR_CODE
        data_type: NUMBER

      - name: ERROR_MESSAGE
        description: >-
          Detailed error description for failed queries. NULL for successful queries.
        synonyms:
          - failure reason
          - error details
          - failure message
          - error description
        expr: QUERY_HISTORY.ERROR_MESSAGE
        data_type: TEXT

      - name: USER_NAME
        description: Login name of the user who executed the query.
        synonyms:
          - username
          - query user
          - executing user
          - submitted by
          - user
          - who
        expr: QUERY_HISTORY.USER_NAME
        data_type: TEXT

      - name: ROLE_NAME
        description: Active role context during query execution.
        synonyms:
          - query role
          - execution role
          - role used
          - role
          - active role
        expr: QUERY_HISTORY.ROLE_NAME
        data_type: TEXT

      - name: WAREHOUSE_NAME
        description: >-
          Virtual warehouse that executed the query. System-managed warehouses
          like SYSTEM$STREAMLIT_NOTEBOOK_WH are excluded via filters.
        synonyms:
          - compute cluster
          - virtual warehouse
          - warehouse
          - cluster name
          - compute
        expr: QUERY_HISTORY.WAREHOUSE_NAME
        data_type: TEXT
        sample_values:
          - COMPUTE_WH
          - ANALYTICS_WH
          - ETL_WH
          - TRANSFORM_WH
          - LOADING_WH

      - name: WAREHOUSE_SIZE
        description: T-shirt size tier of the warehouse at execution time.
        synonyms:
          - warehouse tier
          - compute size
          - cluster size
          - size
        expr: QUERY_HISTORY.WAREHOUSE_SIZE
        data_type: TEXT
        sample_values:
          - X-Small
          - Small
          - Medium
          - Large
          - X-Large
          - 2X-Large
          - 3X-Large
          - 4X-Large

      - name: DATABASE_NAME
        description: Primary database accessed by the query.
        synonyms:
          - database
          - db
          - schema database
        expr: QUERY_HISTORY.DATABASE_NAME
        data_type: TEXT

      - name: SCHEMA_NAME
        description: Primary schema accessed by the query.
        synonyms:
          - schema
          - database schema
        expr: QUERY_HISTORY.SCHEMA_NAME
        data_type: TEXT

    time_dimensions:
      - name: START_TIME
        description: >-
          Timestamp when query execution began (UTC). Primary time dimension
          for performance trending and historical analysis.
        synonyms:
          - begin time
          - execution start
          - start timestamp
          - started at
          - query time
          - when
        expr: QUERY_HISTORY.START_TIME
        data_type: TIMESTAMP_LTZ

      - name: END_TIME
        description: Timestamp when query execution completed (UTC).
        synonyms:
          - completion time
          - finish time
          - end timestamp
          - completed at
          - finished at
        expr: QUERY_HISTORY.END_TIME
        data_type: TIMESTAMP_LTZ

    facts:
      - name: BYTES_SCANNED
        description: >-
          Total bytes scanned by the query. Compare across similar queries
          to identify optimization opportunities.
        synonyms:
          - data scanned
          - scan volume
          - bytes read
          - data processed
          - data read
        expr: QUERY_HISTORY.BYTES_SCANNED
        data_type: NUMBER

      - name: BYTES_SPILLED_TO_LOCAL_STORAGE
        description: >-
          Memory spillage to local SSD storage. Non-zero values suggest the
          query needs more memory than available on current warehouse size.
        synonyms:
          - local spill
          - disk spill
          - local storage spill
          - SSD spill
          - memory spill
        expr: QUERY_HISTORY.BYTES_SPILLED_TO_LOCAL_STORAGE
        data_type: NUMBER

      - name: BYTES_SPILLED_TO_REMOTE_STORAGE
        description: >-
          Memory spillage to remote cloud storage indicating SEVERE memory
          pressure and significant performance degradation.
        synonyms:
          - remote spill
          - S3 spill
          - cloud storage spill
          - remote storage spill
          - severe spill
        expr: QUERY_HISTORY.BYTES_SPILLED_TO_REMOTE_STORAGE
        data_type: NUMBER

      - name: COMPILATION_TIME
        description: >-
          Query compilation/parsing time in milliseconds. High values (>1000ms)
          indicate complex query structure.
        synonyms:
          - parse time
          - planning time
          - optimization time
          - compile time
        expr: QUERY_HISTORY.COMPILATION_TIME
        data_type: NUMBER

      - name: EXECUTION_TIME
        description: >-
          Actual query execution time in milliseconds, excluding queuing and
          compilation.
        synonyms:
          - runtime
          - run time
          - processing time
          - execution duration
          - query time
        expr: QUERY_HISTORY.EXECUTION_TIME
        data_type: NUMBER

      - name: TOTAL_ELAPSED_TIME
        description: >-
          Total query duration including compilation, queuing, and execution
          (milliseconds). This is what users experience as "query time."
        synonyms:
          - duration
          - total time
          - wall time
          - elapsed time
          - latency
          - response time
          - end to end time
        expr: QUERY_HISTORY.TOTAL_ELAPSED_TIME
        data_type: NUMBER

      - name: QUEUED_OVERLOAD_TIME
        description: >-
          Queue wait time due to warehouse load/capacity (milliseconds).
          Non-zero values indicate insufficient warehouse concurrency.
        synonyms:
          - wait time
          - queue time
          - overload time
          - concurrency wait
          - waiting time
        expr: QUERY_HISTORY.QUEUED_OVERLOAD_TIME
        data_type: NUMBER

      - name: QUEUED_PROVISIONING_TIME
        description: >-
          Queue wait time for warehouse startup/provisioning (milliseconds).
        synonyms:
          - startup wait
          - cold start time
          - provisioning wait
          - warmup time
          - resume time
        expr: QUERY_HISTORY.QUEUED_PROVISIONING_TIME
        data_type: NUMBER

      - name: ROWS_PRODUCED
        description: Number of rows returned by the query.
        synonyms:
          - result rows
          - output rows
          - rows returned
          - result set size
          - row count
        expr: QUERY_HISTORY.ROWS_PRODUCED
        data_type: NUMBER

      - name: PARTITIONS_SCANNED
        description: >-
          Number of micro-partitions actually scanned. Compare to
          PARTITIONS_TOTAL for pruning efficiency.
        synonyms:
          - partitions read
          - micro-partitions scanned
          - partitions accessed
        expr: QUERY_HISTORY.PARTITIONS_SCANNED
        data_type: NUMBER

      - name: PARTITIONS_TOTAL
        description: Total micro-partitions available in queried tables.
        synonyms:
          - total partitions
          - available partitions
          - table partitions
        expr: QUERY_HISTORY.PARTITIONS_TOTAL
        data_type: NUMBER

      - name: PERCENTAGE_SCANNED_FROM_CACHE
        description: >-
          Percentage (0-100) of data served from cache. Higher values indicate
          better cache utilization and lower costs.
        synonyms:
          - cache hit rate
          - cache hit
          - cache efficiency
          - cache utilization
          - cached percentage
        expr: QUERY_HISTORY.PERCENTAGE_SCANNED_FROM_CACHE
        data_type: NUMBER

    metrics:
      - name: QUERY_COUNT
        description: Total number of queries executed.
        synonyms:
          - number of queries
          - total queries
          - query volume
          - how many queries
        expr: COUNT(QUERY_HISTORY.QUERY_ID)

      - name: AVG_EXECUTION_TIME_MS
        description: Average query execution time in milliseconds.
        synonyms:
          - average runtime
          - mean execution time
          - avg query time
          - typical execution time
        expr: AVG(QUERY_HISTORY.EXECUTION_TIME)

      - name: AVG_TOTAL_ELAPSED_TIME_MS
        description: >-
          Average total query duration including all phases. Represents
          typical user-perceived latency.
        synonyms:
          - average duration
          - mean elapsed time
          - avg latency
          - typical response time
        expr: AVG(QUERY_HISTORY.TOTAL_ELAPSED_TIME)

      - name: P95_EXECUTION_TIME_MS
        description: 95th percentile execution time, excluding outliers.
        synonyms:
          - 95th percentile runtime
          - p95 latency
          - tail latency
        expr: APPROX_PERCENTILE(QUERY_HISTORY.EXECUTION_TIME, 0.95)

      - name: TOTAL_BYTES_SCANNED
        description: Sum of all bytes scanned across queries.
        synonyms:
          - total data scanned
          - total scan volume
        expr: SUM(QUERY_HISTORY.BYTES_SCANNED)

      - name: TOTAL_BYTES_SPILLED
        description: >-
          Total bytes spilled to any storage (local + remote). Key indicator
          of memory pressure across workload.
        synonyms:
          - total spill
          - memory pressure total
        expr: SUM(QUERY_HISTORY.BYTES_SPILLED_TO_LOCAL_STORAGE + QUERY_HISTORY.BYTES_SPILLED_TO_REMOTE_STORAGE)

      - name: FAILED_QUERY_COUNT
        description: Number of failed queries.
        synonyms:
          - failures
          - error count
          - failed queries
        expr: SUM(CASE WHEN QUERY_HISTORY.EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END)

      - name: ERROR_RATE
        description: Percentage of queries that failed.
        synonyms:
          - failure rate
          - error percentage
          - failure percentage
        expr: 100.0 * SUM(CASE WHEN QUERY_HISTORY.EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)

      - name: AVG_CACHE_HIT_RATE
        description: Average cache utilization percentage across queries.
        synonyms:
          - average cache hit
          - mean cache rate
        expr: AVG(QUERY_HISTORY.PERCENTAGE_SCANNED_FROM_CACHE)

      - name: PARTITION_PRUNING_EFFICIENCY
        description: >-
          Percentage of partitions successfully pruned. Higher is better.
        synonyms:
          - pruning efficiency
          - partition efficiency
        expr: 100.0 * (1 - SUM(QUERY_HISTORY.PARTITIONS_SCANNED) / NULLIF(SUM(QUERY_HISTORY.PARTITIONS_TOTAL), 0))

    filters:
      - name: EXCLUDE_SYSTEM_WAREHOUSES
        description: Exclude system-managed warehouses.
        synonyms:
          - user warehouses only
          - exclude system
        expr: QUERY_HISTORY.WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'

      - name: SUCCESSFUL_QUERIES
        description: Include only successfully completed queries.
        synonyms:
          - completed queries
          - successful only
        expr: QUERY_HISTORY.EXECUTION_STATUS = 'SUCCESS'

      - name: FAILED_QUERIES
        description: Include only failed queries for error analysis.
        synonyms:
          - errors only
          - failures only
        expr: QUERY_HISTORY.EXECUTION_STATUS = 'FAIL'

      - name: QUERIES_WITH_SPILLING
        description: Include queries that experienced memory spilling.
        synonyms:
          - spilled queries
          - memory pressure queries
        expr: (QUERY_HISTORY.BYTES_SPILLED_TO_LOCAL_STORAGE > 0 OR QUERY_HISTORY.BYTES_SPILLED_TO_REMOTE_STORAGE > 0)

      - name: QUERIES_WITH_REMOTE_SPILLING
        description: Include queries with severe spilling to remote storage.
        synonyms:
          - severe spill
          - remote spill queries
        expr: QUERY_HISTORY.BYTES_SPILLED_TO_REMOTE_STORAGE > 0

      - name: QUERIES_WITH_QUEUING
        description: Include queries that experienced queue wait time.
        synonyms:
          - queued queries
          - waiting queries
        expr: (QUERY_HISTORY.QUEUED_OVERLOAD_TIME > 0 OR QUERY_HISTORY.QUEUED_PROVISIONING_TIME > 0)

      - name: SELECT_QUERIES
        description: Include only SELECT queries.
        synonyms:
          - reads only
          - select only
        expr: QUERY_HISTORY.QUERY_TYPE = 'SELECT'

      - name: DML_QUERIES
        description: Include INSERT, UPDATE, DELETE, MERGE.
        synonyms:
          - writes only
          - modification queries
        expr: QUERY_HISTORY.QUERY_TYPE IN ('INSERT', 'UPDATE', 'DELETE', 'MERGE')

      - name: TODAY
        description: Filter for queries from today only.
        synonyms:
          - today only
          - today's queries
        expr: QUERY_HISTORY.START_TIME >= CURRENT_DATE()

      - name: LAST_7_DAYS
        description: Filter for queries from the last 7 days.
        synonyms:
          - past week
          - this week
          - last week
        expr: QUERY_HISTORY.START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())

      - name: LAST_30_DAYS
        description: Filter for queries from the last 30 days.
        synonyms:
          - past month
          - this month
          - last month
        expr: QUERY_HISTORY.START_TIME >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())

  - name: QUERY_ATTRIBUTION_HISTORY
    description: >-
      Credit attribution data linking queries to their compute costs.
      Enables cost-per-query analysis and chargeback reporting.
    base_table:
      database: SNOWFLAKE
      schema: ACCOUNT_USAGE
      table: QUERY_ATTRIBUTION_HISTORY
    primary_key:
      columns:
        - QUERY_ID

    facts:
      - name: CREDITS_ATTRIBUTED_COMPUTE
        description: >-
          Compute credits consumed by this specific query. Primary metric
          for query-level cost analysis and chargeback.
        synonyms:
          - query cost
          - compute cost
          - query credits
          - query spend
          - credits used
        expr: QUERY_ATTRIBUTION_HISTORY.CREDITS_ATTRIBUTED_COMPUTE
        data_type: NUMBER

    metrics:
      - name: TOTAL_CREDITS_USED
        description: Sum of compute credits consumed by queries.
        synonyms:
          - total cost
          - total spend
          - credits consumed
        expr: SUM(QUERY_ATTRIBUTION_HISTORY.CREDITS_ATTRIBUTED_COMPUTE)

relationships:
  - name: query_to_attribution
    left_table: QUERY_HISTORY
    right_table: QUERY_ATTRIBUTION_HISTORY
    relationship_columns:
      - left_column: QUERY_ID
        right_column: QUERY_ID

verified_queries:
  - name: "Top 10 slowest queries today"
    question: "What were my slowest queries today?"
    verified_at: 1737400640
    verified_by: SE Community
    sql: |-
      SELECT
        QUERY_ID,
        QUERY_TEXT,
        TOTAL_ELAPSED_TIME / 1000 AS duration_seconds,
        WAREHOUSE_NAME,
        USER_NAME
      FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
      WHERE START_TIME >= CURRENT_DATE()
        AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      ORDER BY TOTAL_ELAPSED_TIME DESC
      LIMIT 10

  - name: "Queries with remote storage spillage"
    question: "Which queries spilled to remote storage this week?"
    verified_at: 1737400640
    verified_by: SE Community
    sql: |-
      SELECT
        QUERY_ID,
        QUERY_TEXT,
        BYTES_SPILLED_TO_REMOTE_STORAGE / (1024*1024*1024) AS remote_spill_gb,
        WAREHOUSE_SIZE,
        WAREHOUSE_NAME,
        TOTAL_ELAPSED_TIME / 1000 AS duration_seconds
      FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
      WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
        AND BYTES_SPILLED_TO_REMOTE_STORAGE > 0
        AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      ORDER BY BYTES_SPILLED_TO_REMOTE_STORAGE DESC
      LIMIT 20

  - name: "Most common query errors"
    question: "What are the most common query errors?"
    verified_at: 1737400640
    verified_by: SE Community
    sql: |-
      SELECT
        ERROR_CODE,
        ERROR_MESSAGE,
        COUNT(*) AS failure_count,
        COUNT(DISTINCT USER_NAME) AS affected_users
      FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
      WHERE EXECUTION_STATUS = 'FAIL'
        AND START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
        AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      GROUP BY ERROR_CODE, ERROR_MESSAGE
      ORDER BY failure_count DESC
      LIMIT 10

  - name: "Query performance by warehouse"
    question: "Show average query performance by warehouse"
    verified_at: 1737400640
    verified_by: SE Community
    sql: |-
      SELECT
        WAREHOUSE_NAME,
        WAREHOUSE_SIZE,
        COUNT(*) AS query_count,
        AVG(TOTAL_ELAPSED_TIME) / 1000 AS avg_duration_seconds,
        APPROX_PERCENTILE(TOTAL_ELAPSED_TIME, 0.95) / 1000 AS p95_duration_seconds,
        SUM(CASE WHEN EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS error_rate_pct
      FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
      WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
        AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      GROUP BY WAREHOUSE_NAME, WAREHOUSE_SIZE
      ORDER BY query_count DESC

  - name: "Queries with poor partition pruning"
    question: "Which queries had poor partition pruning efficiency?"
    verified_at: 1737400640
    verified_by: SE Community
    sql: |-
      SELECT
        QUERY_ID,
        QUERY_TEXT,
        PARTITIONS_SCANNED,
        PARTITIONS_TOTAL,
        ROUND(PARTITIONS_SCANNED * 100.0 / NULLIF(PARTITIONS_TOTAL, 0), 2) AS scan_percentage,
        WAREHOUSE_NAME
      FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
      WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
        AND PARTITIONS_TOTAL > 100
        AND PARTITIONS_SCANNED > PARTITIONS_TOTAL * 0.5
        AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      ORDER BY PARTITIONS_SCANNED DESC
      LIMIT 20

  - name: "User query activity summary"
    question: "Show query activity by user"
    verified_at: 1737400640
    verified_by: SE Community
    sql: |-
      SELECT
        USER_NAME,
        COUNT(*) AS query_count,
        SUM(CASE WHEN EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END) AS failed_queries,
        AVG(TOTAL_ELAPSED_TIME) / 1000 AS avg_duration_seconds,
        SUM(BYTES_SCANNED) / (1024*1024*1024) AS total_gb_scanned
      FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
      WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
        AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      GROUP BY USER_NAME
      ORDER BY query_count DESC
      LIMIT 20

  - name: "Hourly query volume trend"
    question: "Show query volume by hour for the past week"
    verified_at: 1737400640
    verified_by: SE Community
    sql: |-
      SELECT
        DATE_TRUNC('HOUR', START_TIME) AS hour,
        COUNT(*) AS query_count,
        AVG(TOTAL_ELAPSED_TIME) / 1000 AS avg_duration_seconds,
        SUM(CASE WHEN EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END) AS failures
      FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
      WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
        AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      GROUP BY DATE_TRUNC('HOUR', START_TIME)
      ORDER BY hour DESC
    $$
);

-- ============================================================================
-- 2. COST ANALYSIS
-- ============================================================================

CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
    'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS',
    $$
name: SV_SAM_COST_ANALYSIS
description: >-
  Warehouse cost analysis and credit consumption tracking. Monitor spending
  by warehouse, identify cost trends, and support FinOps initiatives.

tables:
  - name: WAREHOUSE_METERING_HISTORY
    description: >-
      Hourly credit consumption data for all virtual warehouses. Primary
      source for warehouse-level cost analysis.
    base_table:
      database: SNOWFLAKE
      schema: ACCOUNT_USAGE
      table: WAREHOUSE_METERING_HISTORY
    primary_key:
      columns:
        - WAREHOUSE_ID
        - START_TIME

    dimensions:
      - name: WAREHOUSE_NAME
        description: >-
          Virtual warehouse name. System-managed warehouses are excluded
          via filters.
        synonyms:
          - compute cluster
          - warehouse
          - cluster name
          - virtual warehouse
          - compute
        expr: WAREHOUSE_METERING_HISTORY.WAREHOUSE_NAME
        data_type: TEXT
        sample_values:
          - COMPUTE_WH
          - ANALYTICS_WH
          - ETL_WH
          - TRANSFORM_WH
          - LOADING_WH

      - name: WAREHOUSE_ID
        description: >-
          Unique warehouse identifier. Persists across warehouse renames.
        synonyms:
          - warehouse uuid
          - warehouse identifier
        expr: WAREHOUSE_METERING_HISTORY.WAREHOUSE_ID
        data_type: NUMBER
        unique: true

    time_dimensions:
      - name: START_TIME
        description: Start of the hourly metering period (UTC).
        synonyms:
          - period start
          - metering start
          - billing start
          - measurement start
          - when
          - date
          - time
        expr: WAREHOUSE_METERING_HISTORY.START_TIME
        data_type: TIMESTAMP_LTZ

      - name: END_TIME
        description: End of the hourly metering period (UTC).
        synonyms:
          - period end
          - metering end
          - billing end
          - measurement end
        expr: WAREHOUSE_METERING_HISTORY.END_TIME
        data_type: TIMESTAMP_LTZ

    facts:
      - name: CREDITS_USED
        description: >-
          Total credits consumed during the metering period (compute + cloud
          services). Multiply by your credit price for dollar costs.
        synonyms:
          - total cost
          - spend
          - warehouse cost
          - total spend
          - credits consumed
          - billing amount
          - cost
          - credits
        expr: WAREHOUSE_METERING_HISTORY.CREDITS_USED
        data_type: NUMBER

      - name: CREDITS_USED_COMPUTE
        description: >-
          Compute credits for query execution. Typically 90%+ of total.
        synonyms:
          - compute cost
          - compute credits
          - compute spend
          - execution cost
          - query cost
        expr: WAREHOUSE_METERING_HISTORY.CREDITS_USED_COMPUTE
        data_type: NUMBER

      - name: CREDITS_USED_CLOUD_SERVICES
        description: >-
          Cloud services credits for metadata operations and infrastructure.
          Usually 10% of compute or less.
        synonyms:
          - services cost
          - cloud services spend
          - metadata cost
          - infrastructure cost
          - overhead cost
        expr: WAREHOUSE_METERING_HISTORY.CREDITS_USED_CLOUD_SERVICES
        data_type: NUMBER

    metrics:
      - name: TOTAL_CREDITS
        description: Sum of all credits consumed.
        synonyms:
          - total spend
          - total cost
          - credits total
          - all credits
        expr: SUM(WAREHOUSE_METERING_HISTORY.CREDITS_USED)

      - name: TOTAL_COMPUTE_CREDITS
        description: Sum of compute credits consumed.
        synonyms:
          - compute total
          - total compute cost
        expr: SUM(WAREHOUSE_METERING_HISTORY.CREDITS_USED_COMPUTE)

      - name: TOTAL_CLOUD_SERVICES_CREDITS
        description: Sum of cloud services credits consumed.
        synonyms:
          - services total
          - cloud services total
        expr: SUM(WAREHOUSE_METERING_HISTORY.CREDITS_USED_CLOUD_SERVICES)

      - name: AVG_HOURLY_CREDITS
        description: Average credits consumed per hour.
        synonyms:
          - average hourly cost
          - hourly average
          - typical hourly spend
        expr: AVG(WAREHOUSE_METERING_HISTORY.CREDITS_USED)

      - name: MAX_HOURLY_CREDITS
        description: Maximum credits consumed in any single hour.
        synonyms:
          - peak hourly cost
          - max hourly spend
        expr: MAX(WAREHOUSE_METERING_HISTORY.CREDITS_USED)

      - name: CLOUD_SERVICES_RATIO
        description: >-
          Cloud services credits as percentage of total. High values (>10%)
          may indicate inefficient query patterns.
        synonyms:
          - services percentage
          - overhead ratio
        expr: 100.0 * SUM(WAREHOUSE_METERING_HISTORY.CREDITS_USED_CLOUD_SERVICES) / NULLIF(SUM(WAREHOUSE_METERING_HISTORY.CREDITS_USED), 0)

      - name: METERING_PERIODS
        description: Count of hourly metering periods with activity.
        synonyms:
          - active hours
          - usage periods
        expr: COUNT(*)

      - name: DAILY_CREDITS
        description: Average daily credit consumption.
        synonyms:
          - daily spend
          - per day cost
        expr: SUM(WAREHOUSE_METERING_HISTORY.CREDITS_USED) / NULLIF(COUNT(DISTINCT DATE(WAREHOUSE_METERING_HISTORY.START_TIME)), 0)

    filters:
      - name: EXCLUDE_SYSTEM_WAREHOUSES
        description: Exclude system-managed warehouses.
        synonyms:
          - user warehouses only
          - exclude system
        expr: WAREHOUSE_METERING_HISTORY.WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'

      - name: TODAY
        description: Filter for metering data from today only.
        synonyms:
          - today only
        expr: WAREHOUSE_METERING_HISTORY.START_TIME >= CURRENT_DATE()

      - name: YESTERDAY
        description: Filter for metering data from yesterday.
        synonyms:
          - yesterday only
        expr: DATE(WAREHOUSE_METERING_HISTORY.START_TIME) = DATEADD(DAY, -1, CURRENT_DATE())

      - name: LAST_7_DAYS
        description: Filter for metering data from the last 7 days.
        synonyms:
          - past week
          - this week
          - last week
        expr: WAREHOUSE_METERING_HISTORY.START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())

      - name: LAST_30_DAYS
        description: Filter for metering data from the last 30 days.
        synonyms:
          - past month
          - this month
          - last month
        expr: WAREHOUSE_METERING_HISTORY.START_TIME >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())

      - name: CURRENT_MONTH
        description: Filter for the current calendar month.
        synonyms:
          - this month
          - current month
          - mtd
        expr: WAREHOUSE_METERING_HISTORY.START_TIME >= DATE_TRUNC('MONTH', CURRENT_DATE())

      - name: LAST_MONTH
        description: Filter for the previous calendar month.
        synonyms:
          - previous month
          - prior month
        expr: |-
          WAREHOUSE_METERING_HISTORY.START_TIME >= DATE_TRUNC('MONTH', DATEADD('MONTH', -1, CURRENT_DATE()))
          AND WAREHOUSE_METERING_HISTORY.START_TIME < DATE_TRUNC('MONTH', CURRENT_DATE())

      - name: WITH_ACTIVITY
        description: Filter for periods with actual credit consumption.
        synonyms:
          - active periods
          - with usage
        expr: WAREHOUSE_METERING_HISTORY.CREDITS_USED > 0

verified_queries:
  - name: "Most expensive warehouses last month"
    question: "What were my most expensive warehouses last month?"
    verified_at: 1737400640
    verified_by: SE Community
    sql: |-
      SELECT
        WAREHOUSE_NAME,
        SUM(CREDITS_USED) AS total_credits,
        SUM(CREDITS_USED_COMPUTE) AS compute_credits,
        SUM(CREDITS_USED_CLOUD_SERVICES) AS cloud_services_credits
      FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
      WHERE START_TIME >= DATE_TRUNC('MONTH', DATEADD('MONTH', -1, CURRENT_DATE()))
        AND START_TIME < DATE_TRUNC('MONTH', CURRENT_DATE())
        AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      GROUP BY WAREHOUSE_NAME
      ORDER BY total_credits DESC

  - name: "Daily spend trend 30 days"
    question: "Show me daily credit spend for the last 30 days"
    verified_at: 1737400640
    verified_by: SE Community
    sql: |-
      SELECT
        DATE(START_TIME) AS usage_date,
        SUM(CREDITS_USED) AS daily_credits
      FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
      WHERE START_TIME >= DATEADD('DAY', -30, CURRENT_TIMESTAMP())
        AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      GROUP BY usage_date
      ORDER BY usage_date DESC

  - name: "Cloud services ratio analysis"
    question: "Which warehouses have high cloud services costs?"
    verified_at: 1737400640
    verified_by: SE Community
    sql: |-
      SELECT
        WAREHOUSE_NAME,
        SUM(CREDITS_USED_COMPUTE) AS compute_credits,
        SUM(CREDITS_USED_CLOUD_SERVICES) AS services_credits,
        ROUND(services_credits * 100.0 / NULLIF(compute_credits, 0), 2) AS services_percentage
      FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
      WHERE START_TIME >= DATEADD('DAY', -7, CURRENT_TIMESTAMP())
        AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      GROUP BY WAREHOUSE_NAME
      HAVING services_percentage > 10
      ORDER BY services_percentage DESC

  - name: "Hourly cost pattern"
    question: "What is the hourly cost pattern by warehouse?"
    verified_at: 1737400640
    verified_by: SE Community
    sql: |-
      SELECT
        WAREHOUSE_NAME,
        HOUR(START_TIME) AS hour_of_day,
        AVG(CREDITS_USED) AS avg_hourly_credits
      FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
      WHERE START_TIME >= DATEADD('DAY', -7, CURRENT_TIMESTAMP())
        AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      GROUP BY WAREHOUSE_NAME, hour_of_day
      ORDER BY WAREHOUSE_NAME, hour_of_day

  - name: "Weekly cost comparison"
    question: "Compare this week's costs to last week by warehouse"
    verified_at: 1737400640
    verified_by: SE Community
    sql: |-
      SELECT
        WAREHOUSE_NAME,
        SUM(CASE WHEN START_TIME >= DATEADD('DAY', -7, CURRENT_TIMESTAMP()) THEN CREDITS_USED ELSE 0 END) AS this_week_credits,
        SUM(CASE WHEN START_TIME >= DATEADD('DAY', -14, CURRENT_TIMESTAMP()) AND START_TIME < DATEADD('DAY', -7, CURRENT_TIMESTAMP()) THEN CREDITS_USED ELSE 0 END) AS last_week_credits,
        ROUND((this_week_credits - last_week_credits) * 100.0 / NULLIF(last_week_credits, 0), 2) AS week_over_week_change_pct
      FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
      WHERE START_TIME >= DATEADD('DAY', -14, CURRENT_TIMESTAMP())
        AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      GROUP BY WAREHOUSE_NAME
      ORDER BY this_week_credits DESC

  - name: "Monthly cost summary"
    question: "Show monthly cost breakdown"
    verified_at: 1737400640
    verified_by: SE Community
    sql: |-
      SELECT
        DATE_TRUNC('MONTH', START_TIME) AS month,
        COUNT(DISTINCT WAREHOUSE_NAME) AS active_warehouses,
        SUM(CREDITS_USED) AS total_credits,
        SUM(CREDITS_USED_COMPUTE) AS compute_credits,
        SUM(CREDITS_USED_CLOUD_SERVICES) AS cloud_services_credits
      FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
      WHERE START_TIME >= DATEADD('MONTH', -6, CURRENT_TIMESTAMP())
        AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      GROUP BY month
      ORDER BY month DESC
    $$
);

-- ============================================================================
-- 3. WAREHOUSE OPERATIONS
-- ============================================================================

CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
    'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS',
    $$
name: SV_SAM_WAREHOUSE_OPERATIONS
description: >-
  Warehouse utilization and capacity planning metrics. Monitor concurrency,
  queue depth, provisioning delays, and lock contention.

tables:
  - name: WAREHOUSE_LOAD_HISTORY
    description: >-
      Time-series load metrics for all virtual warehouses. Captures
      concurrent query counts, queue depths, and blocked query counts.
    base_table:
      database: SNOWFLAKE
      schema: ACCOUNT_USAGE
      table: WAREHOUSE_LOAD_HISTORY
    primary_key:
      columns:
        - WAREHOUSE_ID
        - START_TIME

    dimensions:
      - name: WAREHOUSE_NAME
        description: >-
          Virtual warehouse name. System-managed warehouses are excluded
          via filters.
        synonyms:
          - compute cluster
          - warehouse
          - cluster name
          - virtual warehouse
          - compute
        expr: WAREHOUSE_LOAD_HISTORY.WAREHOUSE_NAME
        data_type: TEXT
        sample_values:
          - COMPUTE_WH
          - ANALYTICS_WH
          - ETL_WH
          - TRANSFORM_WH
          - LOADING_WH

      - name: WAREHOUSE_ID
        description: Unique warehouse identifier. Persists across renames.
        synonyms:
          - warehouse uuid
          - warehouse identifier
        expr: WAREHOUSE_LOAD_HISTORY.WAREHOUSE_ID
        data_type: NUMBER
        unique: true

    time_dimensions:
      - name: START_TIME
        description: Start of the load measurement period (UTC).
        synonyms:
          - load start time
          - measurement start
          - period start
          - sample start
          - when
          - date
          - time
        expr: WAREHOUSE_LOAD_HISTORY.START_TIME
        data_type: TIMESTAMP_LTZ

      - name: END_TIME
        description: End of the load measurement period (UTC).
        synonyms:
          - load end time
          - measurement end
          - period end
          - sample end
        expr: WAREHOUSE_LOAD_HISTORY.END_TIME
        data_type: TIMESTAMP_LTZ

    facts:
      - name: AVG_RUNNING
        description: >-
          Average number of queries executing concurrently during the
          measurement period.
        synonyms:
          - concurrency
          - active queries
          - concurrent queries
          - running queries
          - parallel queries
          - utilization
        expr: WAREHOUSE_LOAD_HISTORY.AVG_RUNNING
        data_type: NUMBER

      - name: AVG_QUEUED_LOAD
        description: >-
          Average queries queued due to warehouse load/capacity constraints.
          Non-zero values indicate the warehouse is undersized.
        synonyms:
          - queue depth
          - waiting queries
          - queued queries
          - overload queue
          - capacity queue
          - backlog
        expr: WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_LOAD
        data_type: NUMBER

      - name: AVG_QUEUED_PROVISIONING
        description: >-
          Average queries queued during warehouse startup/provisioning.
        synonyms:
          - startup queue
          - provisioning queue
          - cold start queue
          - warmup queue
          - resume queue
        expr: WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_PROVISIONING
        data_type: NUMBER

      - name: AVG_BLOCKED
        description: >-
          Average queries blocked by locks or resource contention.
        synonyms:
          - contentions
          - blocked queries
          - lock waits
          - resource conflicts
          - locked queries
          - blocking
        expr: WAREHOUSE_LOAD_HISTORY.AVG_BLOCKED
        data_type: NUMBER

    metrics:
      - name: MEASUREMENT_COUNT
        description: Number of measurement periods.
        synonyms:
          - samples
          - periods
        expr: COUNT(*)

      - name: AVG_CONCURRENCY
        description: Average concurrent query count. Key utilization metric.
        synonyms:
          - average running
          - mean concurrency
          - typical load
        expr: AVG(WAREHOUSE_LOAD_HISTORY.AVG_RUNNING)

      - name: MAX_CONCURRENCY
        description: Peak concurrent query count.
        synonyms:
          - peak concurrency
          - max running
          - peak load
        expr: MAX(WAREHOUSE_LOAD_HISTORY.AVG_RUNNING)

      - name: AVG_QUEUE_DEPTH
        description: Average queue depth due to load constraints.
        synonyms:
          - average queued
          - mean queue
          - typical backlog
        expr: AVG(WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_LOAD)

      - name: MAX_QUEUE_DEPTH
        description: Peak queue depth.
        synonyms:
          - peak queue
          - max queued
          - worst backlog
        expr: MAX(WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_LOAD)

      - name: AVG_PROVISIONING_QUEUE
        description: Average provisioning queue depth.
        synonyms:
          - average startup queue
          - mean provisioning wait
        expr: AVG(WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_PROVISIONING)

      - name: AVG_BLOCKED_COUNT
        description: Average blocked query count.
        synonyms:
          - average blocked
          - mean contentions
        expr: AVG(WAREHOUSE_LOAD_HISTORY.AVG_BLOCKED)

      - name: PERIODS_WITH_QUEUING
        description: Count of measurement periods with any queuing.
        synonyms:
          - queuing frequency
          - constrained periods
        expr: SUM(CASE WHEN WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_LOAD > 0 THEN 1 ELSE 0 END)

      - name: QUEUING_PERCENTAGE
        description: Percentage of time with active queuing. Key SLA metric.
        synonyms:
          - queue frequency percent
          - constrained time percent
        expr: 100.0 * SUM(CASE WHEN WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_LOAD > 0 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)

      - name: PERIODS_WITH_BLOCKING
        description: Count of measurement periods with blocked queries.
        synonyms:
          - blocking frequency
          - contention periods
        expr: SUM(CASE WHEN WAREHOUSE_LOAD_HISTORY.AVG_BLOCKED > 0 THEN 1 ELSE 0 END)

    filters:
      - name: EXCLUDE_SYSTEM_WAREHOUSES
        description: Exclude system-managed warehouses.
        synonyms:
          - user warehouses only
          - exclude system
        expr: WAREHOUSE_LOAD_HISTORY.WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'

      - name: WITH_QUEUING
        description: Include only periods with active queuing.
        synonyms:
          - queued only
          - constrained periods
        expr: WAREHOUSE_LOAD_HISTORY.AVG_QUEUED_LOAD > 0

      - name: WITH_BLOCKING
        description: Include only periods with blocked queries.
        synonyms:
          - blocked only
          - contention periods
        expr: WAREHOUSE_LOAD_HISTORY.AVG_BLOCKED > 0

      - name: WITH_ACTIVITY
        description: Include only periods with running queries.
        synonyms:
          - active periods
          - with load
        expr: WAREHOUSE_LOAD_HISTORY.AVG_RUNNING > 0

      - name: HIGH_LOAD
        description: Include only high-load periods (concurrency > 5).
        synonyms:
          - busy periods
          - high concurrency
        expr: WAREHOUSE_LOAD_HISTORY.AVG_RUNNING > 5

      - name: TODAY
        description: Filter for load data from today only.
        synonyms:
          - today only
        expr: WAREHOUSE_LOAD_HISTORY.START_TIME >= CURRENT_DATE()

      - name: LAST_7_DAYS
        description: Filter for load data from the last 7 days.
        synonyms:
          - past week
          - this week
          - last week
        expr: WAREHOUSE_LOAD_HISTORY.START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())

      - name: LAST_30_DAYS
        description: Filter for load data from the last 30 days.
        synonyms:
          - past month
          - this month
          - last month
        expr: WAREHOUSE_LOAD_HISTORY.START_TIME >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())

verified_queries:
  - name: "Warehouses with queuing"
    question: "Which warehouses have the most queued queries?"
    verified_at: 1737400640
    verified_by: SE Community
    sql: |-
      SELECT
        WAREHOUSE_NAME,
        AVG(AVG_QUEUED_LOAD) AS avg_queue_depth,
        MAX(AVG_QUEUED_LOAD) AS max_queue_depth,
        SUM(CASE WHEN AVG_QUEUED_LOAD > 0 THEN 1 ELSE 0 END) AS periods_with_queuing,
        COUNT(*) AS total_periods,
        ROUND(periods_with_queuing * 100.0 / total_periods, 2) AS queuing_pct
      FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
      WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
        AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      GROUP BY WAREHOUSE_NAME
      HAVING avg_queue_depth > 0
      ORDER BY avg_queue_depth DESC

  - name: "Hourly concurrency pattern"
    question: "Show warehouse concurrency by hour of day"
    verified_at: 1737400640
    verified_by: SE Community
    sql: |-
      SELECT
        WAREHOUSE_NAME,
        HOUR(START_TIME) AS hour_of_day,
        AVG(AVG_RUNNING) AS avg_concurrency,
        AVG(AVG_QUEUED_LOAD) AS avg_queue_depth
      FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
      WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
        AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      GROUP BY WAREHOUSE_NAME, hour_of_day
      ORDER BY WAREHOUSE_NAME, hour_of_day

  - name: "Lock contention analysis"
    question: "Which warehouses have lock contention issues?"
    verified_at: 1737400640
    verified_by: SE Community
    sql: |-
      SELECT
        WAREHOUSE_NAME,
        AVG(AVG_BLOCKED) AS avg_blocked_queries,
        MAX(AVG_BLOCKED) AS max_blocked_queries,
        SUM(CASE WHEN AVG_BLOCKED > 0 THEN 1 ELSE 0 END) AS periods_with_blocking,
        COUNT(*) AS total_periods
      FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
      WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
        AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      GROUP BY WAREHOUSE_NAME
      HAVING avg_blocked_queries > 0
      ORDER BY avg_blocked_queries DESC

  - name: "Warehouse utilization summary"
    question: "Show overall warehouse utilization"
    verified_at: 1737400640
    verified_by: SE Community
    sql: |-
      SELECT
        WAREHOUSE_NAME,
        AVG(AVG_RUNNING) AS avg_concurrency,
        MAX(AVG_RUNNING) AS peak_concurrency,
        AVG(AVG_QUEUED_LOAD) AS avg_queue_depth,
        AVG(AVG_QUEUED_PROVISIONING) AS avg_provisioning_queue,
        AVG(AVG_BLOCKED) AS avg_blocked
      FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
      WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
        AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      GROUP BY WAREHOUSE_NAME
      ORDER BY avg_concurrency DESC

  - name: "Cold start impact"
    question: "Which warehouses have provisioning delays?"
    verified_at: 1737400640
    verified_by: SE Community
    sql: |-
      SELECT
        WAREHOUSE_NAME,
        AVG(AVG_QUEUED_PROVISIONING) AS avg_provisioning_queue,
        MAX(AVG_QUEUED_PROVISIONING) AS max_provisioning_queue,
        SUM(CASE WHEN AVG_QUEUED_PROVISIONING > 0 THEN 1 ELSE 0 END) AS cold_start_events
      FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
      WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
        AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      GROUP BY WAREHOUSE_NAME
      HAVING cold_start_events > 0
      ORDER BY cold_start_events DESC

  - name: "Sizing recommendation indicators"
    question: "Which warehouses may need resizing?"
    verified_at: 1737400640
    verified_by: SE Community
    sql: |-
      SELECT
        WAREHOUSE_NAME,
        AVG(AVG_RUNNING) AS avg_concurrency,
        AVG(AVG_QUEUED_LOAD) AS avg_queue_depth,
        CASE
          WHEN AVG(AVG_QUEUED_LOAD) > 1 THEN 'CONSIDER UPSIZE - High queuing'
          WHEN AVG(AVG_RUNNING) < 1 AND AVG(AVG_QUEUED_LOAD) = 0 THEN 'CONSIDER DOWNSIZE - Low utilization'
          ELSE 'APPROPRIATE SIZE'
        END AS sizing_recommendation
      FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
      WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
        AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      GROUP BY WAREHOUSE_NAME
      ORDER BY avg_queue_depth DESC, avg_concurrency DESC

  - name: "Daily load trend"
    question: "Show daily warehouse load trend"
    verified_at: 1737400640
    verified_by: SE Community
    sql: |-
      SELECT
        DATE(START_TIME) AS load_date,
        WAREHOUSE_NAME,
        AVG(AVG_RUNNING) AS avg_concurrency,
        AVG(AVG_QUEUED_LOAD) AS avg_queue_depth
      FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
      WHERE START_TIME >= DATEADD(DAY, -14, CURRENT_TIMESTAMP())
        AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      GROUP BY load_date, WAREHOUSE_NAME
      ORDER BY load_date DESC, WAREHOUSE_NAME
    $$
);

-- ============================================================================
-- 4. USER ACTIVITY
-- ============================================================================

CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
    'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS',
    $$
name: SV_SAM_USER_ACTIVITY
description: >-
  User activity analysis for Snowflake workloads. Track query patterns,
  credit consumption, and error rates by user.

tables:
  - name: QUERY_HISTORY
    description: >-
      Historical record of all queries executed in the Snowflake account.
      Used for user activity analysis with approximately 45-minute latency.
    base_table:
      database: SNOWFLAKE
      schema: ACCOUNT_USAGE
      table: QUERY_HISTORY
    primary_key:
      columns:
        - QUERY_ID

    dimensions:
      - name: QUERY_ID
        description: Unique identifier for each query execution.
        synonyms:
          - query uuid
          - query identifier
          - execution id
        expr: QUERY_HISTORY.QUERY_ID
        data_type: TEXT
        unique: true

      - name: USER_NAME
        description: >-
          User who executed the query. Primary dimension for user activity
          analysis, chargeback, and behavior tracking.
        synonyms:
          - username
          - user
          - who
          - person
          - account
          - executor
          - analyst
        expr: QUERY_HISTORY.USER_NAME
        data_type: TEXT

      - name: ROLE_NAME
        description: Role used during query execution.
        synonyms:
          - role
          - active role
          - execution role
          - security role
        expr: QUERY_HISTORY.ROLE_NAME
        data_type: TEXT

      - name: WAREHOUSE_NAME
        description: Warehouse that executed the query.
        synonyms:
          - warehouse
          - compute
          - cluster
          - virtual warehouse
        expr: QUERY_HISTORY.WAREHOUSE_NAME
        data_type: TEXT
        sample_values:
          - COMPUTE_WH
          - ANALYTICS_WH
          - ETL_WH
          - TRANSFORM_WH
          - LOADING_WH

      - name: DATABASE_NAME
        description: Primary database accessed by the query.
        synonyms:
          - database
          - db
          - data source
        expr: QUERY_HISTORY.DATABASE_NAME
        data_type: TEXT

      - name: QUERY_TYPE
        description: Type of SQL statement executed.
        synonyms:
          - statement type
          - operation type
          - sql type
          - command type
        expr: QUERY_HISTORY.QUERY_TYPE
        data_type: TEXT
        sample_values:
          - SELECT
          - INSERT
          - UPDATE
          - DELETE
          - CREATE_TABLE
          - MERGE
          - COPY

      - name: EXECUTION_STATUS
        description: Query execution outcome.
        synonyms:
          - status
          - result
          - outcome
          - success status
        expr: QUERY_HISTORY.EXECUTION_STATUS
        data_type: TEXT
        sample_values:
          - SUCCESS
          - FAIL
          - INCIDENT

    time_dimensions:
      - name: START_TIME
        description: Timestamp when query execution began (UTC).
        synonyms:
          - query time
          - when
          - timestamp
          - date
          - execution start
          - begin time
        expr: QUERY_HISTORY.START_TIME
        data_type: TIMESTAMP_LTZ

      - name: END_TIME
        description: Timestamp when query execution completed (UTC).
        synonyms:
          - completion time
          - finished
          - end timestamp
        expr: QUERY_HISTORY.END_TIME
        data_type: TIMESTAMP_LTZ

    facts:
      - name: EXECUTION_TIME
        description: Query execution time in milliseconds.
        synonyms:
          - runtime
          - processing time
          - query time
          - run time
        expr: QUERY_HISTORY.EXECUTION_TIME
        data_type: NUMBER

      - name: TOTAL_ELAPSED_TIME
        description: >-
          Total query duration including compilation, queuing, and execution
          (milliseconds). This is the end-user experience.
        synonyms:
          - duration
          - total time
          - latency
          - response time
          - wall time
        expr: QUERY_HISTORY.TOTAL_ELAPSED_TIME
        data_type: NUMBER

      - name: BYTES_SCANNED
        description: Total bytes scanned by the query.
        synonyms:
          - data scanned
          - bytes read
          - data processed
          - scan volume
        expr: QUERY_HISTORY.BYTES_SCANNED
        data_type: NUMBER

      - name: BYTES_SPILLED_TO_REMOTE_STORAGE
        description: >-
          Bytes spilled to remote storage indicating severe memory pressure.
        synonyms:
          - remote spill
          - memory overflow
          - severe spill
        expr: QUERY_HISTORY.BYTES_SPILLED_TO_REMOTE_STORAGE
        data_type: NUMBER

    metrics:
      - name: QUERY_COUNT
        description: Total count of queries executed.
        synonyms:
          - total queries
          - number of queries
          - query volume
          - executions
        expr: COUNT(QUERY_HISTORY.QUERY_ID)

      - name: UNIQUE_USERS
        description: Number of unique users who executed queries.
        synonyms:
          - user count
          - distinct users
          - active users
        expr: COUNT(DISTINCT QUERY_HISTORY.USER_NAME)

      - name: ACTIVE_DAYS
        description: Number of distinct days with query activity.
        synonyms:
          - days active
          - distinct days
        expr: COUNT(DISTINCT DATE(QUERY_HISTORY.START_TIME))

      - name: AVG_EXECUTION_TIME_MS
        description: Average query execution time in milliseconds.
        synonyms:
          - average runtime
          - mean execution time
        expr: AVG(QUERY_HISTORY.EXECUTION_TIME)

      - name: AVG_DURATION_MS
        description: Average total query duration in milliseconds.
        synonyms:
          - average duration
          - mean latency
        expr: AVG(QUERY_HISTORY.TOTAL_ELAPSED_TIME)

      - name: P95_DURATION_MS
        description: 95th percentile query duration.
        synonyms:
          - 95th percentile
          - p95 latency
        expr: APPROX_PERCENTILE(QUERY_HISTORY.TOTAL_ELAPSED_TIME, 0.95)

      - name: TOTAL_BYTES_SCANNED
        description: Total bytes scanned across all queries.
        synonyms:
          - data volume
          - bytes processed
        expr: SUM(QUERY_HISTORY.BYTES_SCANNED)

      - name: TOTAL_TB_SCANNED
        description: Total terabytes scanned across all queries.
        synonyms:
          - terabytes scanned
          - TB processed
        expr: SUM(QUERY_HISTORY.BYTES_SCANNED) / (1024.0*1024*1024*1024)

      - name: FAILED_QUERY_COUNT
        description: Number of queries that failed.
        synonyms:
          - errors
          - failures
          - failed queries
        expr: SUM(CASE WHEN QUERY_HISTORY.EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END)

      - name: ERROR_RATE
        description: Percentage of queries that failed.
        synonyms:
          - failure rate
          - error percentage
        expr: 100.0 * SUM(CASE WHEN QUERY_HISTORY.EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0)

    filters:
      - name: EXCLUDE_SYSTEM_WAREHOUSES
        description: Exclude system-managed warehouses.
        synonyms:
          - user warehouses only
          - exclude system
        expr: QUERY_HISTORY.WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'

      - name: SUCCESSFUL_QUERIES
        description: Include only successful queries.
        synonyms:
          - successful only
          - completed
        expr: QUERY_HISTORY.EXECUTION_STATUS = 'SUCCESS'

      - name: FAILED_QUERIES
        description: Include only failed queries.
        synonyms:
          - errors only
          - failures
        expr: QUERY_HISTORY.EXECUTION_STATUS = 'FAIL'

      - name: SELECT_QUERIES
        description: Include only SELECT queries.
        synonyms:
          - reads only
        expr: QUERY_HISTORY.QUERY_TYPE = 'SELECT'

      - name: DML_QUERIES
        description: Include INSERT, UPDATE, DELETE, MERGE.
        synonyms:
          - writes only
          - modifications
        expr: QUERY_HISTORY.QUERY_TYPE IN ('INSERT', 'UPDATE', 'DELETE', 'MERGE')

      - name: TODAY
        description: Filter for queries from today only.
        synonyms:
          - today only
        expr: QUERY_HISTORY.START_TIME >= CURRENT_DATE()

      - name: LAST_7_DAYS
        description: Filter for queries from the last 7 days.
        synonyms:
          - past week
          - this week
        expr: QUERY_HISTORY.START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())

      - name: LAST_30_DAYS
        description: Filter for queries from the last 30 days.
        synonyms:
          - past month
          - this month
        expr: QUERY_HISTORY.START_TIME >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())

      - name: HIGH_ACTIVITY_USERS
        description: Users with more than 100 queries in 7 days.
        synonyms:
          - power users
          - heavy users
        expr: >-
          QUERY_HISTORY.USER_NAME IN (
            SELECT USER_NAME FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
            WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            GROUP BY USER_NAME HAVING COUNT(*) > 100
          )

  - name: QUERY_ATTRIBUTION_HISTORY
    description: >-
      Credit attribution data linking queries to their compute costs.
      Enables cost-per-user analysis and chargeback reporting.
    base_table:
      database: SNOWFLAKE
      schema: ACCOUNT_USAGE
      table: QUERY_ATTRIBUTION_HISTORY
    primary_key:
      columns:
        - QUERY_ID

    facts:
      - name: CREDITS_ATTRIBUTED_COMPUTE
        description: >-
          Compute credits consumed by this query. Primary metric for
          cost-per-user and chargeback analysis.
        synonyms:
          - query cost
          - credits used
          - compute cost
          - spend
          - credits
        expr: QUERY_ATTRIBUTION_HISTORY.CREDITS_ATTRIBUTED_COMPUTE
        data_type: NUMBER

    metrics:
      - name: TOTAL_CREDITS
        description: Total compute credits consumed.
        synonyms:
          - credit consumption
          - total cost
          - compute credits
          - spend
        expr: SUM(QUERY_ATTRIBUTION_HISTORY.CREDITS_ATTRIBUTED_COMPUTE)

      - name: AVG_CREDITS_PER_QUERY
        description: Average credits consumed per query.
        synonyms:
          - cost per query
          - average credits
        expr: AVG(QUERY_ATTRIBUTION_HISTORY.CREDITS_ATTRIBUTED_COMPUTE)

relationships:
  - name: query_to_attribution
    left_table: QUERY_HISTORY
    right_table: QUERY_ATTRIBUTION_HISTORY
    relationship_columns:
      - left_column: QUERY_ID
        right_column: QUERY_ID

verified_queries:
  - name: "Users by credit consumption"
    question: "Who is using the most credits?"
    verified_at: 1737400640
    verified_by: SE Community
    use_as_onboarding_question: true
    sql: |-
      SELECT
        __QUERY_HISTORY.USER_NAME,
        COUNT(*) AS QUERY_COUNT,
        SUM(__QUERY_ATTRIBUTION_HISTORY.CREDITS_ATTRIBUTED_COMPUTE) AS TOTAL_CREDITS,
        ROUND(SUM(__QUERY_ATTRIBUTION_HISTORY.CREDITS_ATTRIBUTED_COMPUTE) * 3, 2) AS ESTIMATED_COST_USD,
        AVG(__QUERY_ATTRIBUTION_HISTORY.CREDITS_ATTRIBUTED_COMPUTE) AS AVG_CREDITS_PER_QUERY,
        SUM(__QUERY_HISTORY.BYTES_SCANNED) / (1024*1024*1024*1024) AS TOTAL_TB_SCANNED
      FROM __QUERY_HISTORY
      LEFT JOIN __QUERY_ATTRIBUTION_HISTORY
        ON __QUERY_HISTORY.QUERY_ID = __QUERY_ATTRIBUTION_HISTORY.QUERY_ID
      WHERE __QUERY_HISTORY.START_TIME >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())
        AND __QUERY_HISTORY.WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      GROUP BY __QUERY_HISTORY.USER_NAME
      ORDER BY TOTAL_CREDITS DESC NULLS LAST
      LIMIT 20

  - name: "Most active users"
    question: "Who are the most active users?"
    verified_at: 1737400640
    verified_by: SE Community
    use_as_onboarding_question: true
    sql: |-
      SELECT
        USER_NAME,
        COUNT(*) AS QUERY_COUNT,
        COUNT(DISTINCT DATE(START_TIME)) AS ACTIVE_DAYS,
        AVG(TOTAL_ELAPSED_TIME) / 1000 AS AVG_DURATION_SECONDS,
        SUM(CASE WHEN EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END) AS FAILED_QUERIES,
        ROUND(SUM(CASE WHEN EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS ERROR_RATE_PCT
      FROM __QUERY_HISTORY
      WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
        AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      GROUP BY USER_NAME
      ORDER BY QUERY_COUNT DESC
      LIMIT 20

  - name: "Users with high error rates"
    question: "Which users have high error rates?"
    verified_at: 1737400640
    verified_by: SE Community
    sql: |-
      SELECT
        USER_NAME,
        COUNT(*) AS TOTAL_QUERIES,
        SUM(CASE WHEN EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END) AS FAILED_QUERIES,
        ROUND(SUM(CASE WHEN EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS ERROR_RATE_PCT
      FROM __QUERY_HISTORY
      WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
        AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      GROUP BY USER_NAME
      HAVING TOTAL_QUERIES >= 10 AND ERROR_RATE_PCT > 5
      ORDER BY ERROR_RATE_PCT DESC

  - name: "User activity trend"
    question: "Show user activity trend over time"
    verified_at: 1737400640
    verified_by: SE Community
    sql: |-
      SELECT
        DATE(START_TIME) AS ACTIVITY_DATE,
        COUNT(DISTINCT USER_NAME) AS ACTIVE_USERS,
        COUNT(*) AS TOTAL_QUERIES,
        SUM(CASE WHEN EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END) AS FAILED_QUERIES
      FROM __QUERY_HISTORY
      WHERE START_TIME >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())
        AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      GROUP BY ACTIVITY_DATE
      ORDER BY ACTIVITY_DATE DESC

  - name: "User query patterns"
    question: "What types of queries do users run?"
    verified_at: 1737400640
    verified_by: SE Community
    sql: |-
      SELECT
        USER_NAME,
        QUERY_TYPE,
        COUNT(*) AS QUERY_COUNT,
        AVG(TOTAL_ELAPSED_TIME) / 1000 AS AVG_DURATION_SECONDS
      FROM __QUERY_HISTORY
      WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
        AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      GROUP BY USER_NAME, QUERY_TYPE
      ORDER BY USER_NAME, QUERY_COUNT DESC

  - name: "User warehouse usage"
    question: "Which warehouses do users prefer?"
    verified_at: 1737400640
    verified_by: SE Community
    sql: |-
      SELECT
        USER_NAME,
        WAREHOUSE_NAME,
        COUNT(*) AS QUERY_COUNT,
        AVG(TOTAL_ELAPSED_TIME) / 1000 AS AVG_DURATION_SECONDS
      FROM __QUERY_HISTORY
      WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
        AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
      GROUP BY USER_NAME, WAREHOUSE_NAME
      ORDER BY USER_NAME, QUERY_COUNT DESC

  - name: "Users with expensive queries"
    question: "Which users run expensive queries?"
    verified_at: 1737400640
    verified_by: SE Community
    sql: |-
      SELECT
        __QUERY_HISTORY.USER_NAME,
        COUNT(*) AS EXPENSIVE_QUERY_COUNT,
        SUM(__QUERY_ATTRIBUTION_HISTORY.CREDITS_ATTRIBUTED_COMPUTE) AS TOTAL_CREDITS_FROM_EXPENSIVE,
        AVG(__QUERY_HISTORY.TOTAL_ELAPSED_TIME) / 1000 AS AVG_DURATION_SECONDS
      FROM __QUERY_HISTORY
      LEFT JOIN __QUERY_ATTRIBUTION_HISTORY
        ON __QUERY_HISTORY.QUERY_ID = __QUERY_ATTRIBUTION_HISTORY.QUERY_ID
      WHERE __QUERY_HISTORY.START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
        AND __QUERY_HISTORY.WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
        AND __QUERY_ATTRIBUTION_HISTORY.CREDITS_ATTRIBUTED_COMPUTE > 0.1
      GROUP BY __QUERY_HISTORY.USER_NAME
      ORDER BY TOTAL_CREDITS_FROM_EXPENSIVE DESC NULLS LAST
      LIMIT 20
    $$
);

-- ============================================================================
-- VALIDATION
-- ============================================================================

SELECT 'Semantic models deployed' AS status;
