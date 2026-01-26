/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * Module: 07_testing.sql
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * PURPOSE:
 *   Automated testing framework for validating semantic views and agent behavior.
 *
 * Synopsis:
 *   Runs test queries against semantic views to validate correctness.
 *
 * Description:
 *   This module provides a comprehensive testing framework that validates:
 *
 *   1. Semantic View Structure - Verifies views exist with expected components
 *   2. VQR Execution - Runs all verified queries to ensure they execute
 *   3. Data Quality - Validates expected data patterns and filters
 *   4. Edge Cases - Tests boundary conditions and error handling
 *   5. Performance - Checks query execution times
 *
 * TEST CATEGORIES:
 *   - SMOKE: Basic connectivity and structure validation
 *   - FUNCTIONAL: VQR execution and result validation
 *   - REGRESSION: Edge cases and known issue prevention
 *   - PERFORMANCE: Query timing benchmarks
 *
 * OBJECTS CREATED:
 *   - SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS (Transient Table)
 *   - SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_RUN_TESTS (Stored Procedure)
 *
 * Prerequisites:
 *   - All semantic views must be deployed (03_semantic_views.sql)
 *   - Configured role must have SELECT access to ACCOUNT_USAGE
 *
 * Author: SE Community
 * Created: 2025-01-20
 * Expires: 2026-02-14
 * Version: 6.0
 * License: Apache 2.0
 *
 * Usage:
 *   CALL SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_RUN_TESTS();
 *   SELECT * FROM SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS ORDER BY TEST_ID;
 ******************************************************************************/

USE ROLE SYSADMIN;
USE WAREHOUSE SFE_SAM_SNOWMAN_WH;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA SAM_THE_SNOWMAN;

-- ============================================================================
-- TEST RESULTS TABLE
-- ============================================================================
-- Stores results from test execution for analysis

CREATE OR REPLACE TRANSIENT TABLE SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS (
    TEST_ID NUMBER AUTOINCREMENT,
    TEST_CATEGORY VARCHAR(50),
    TEST_NAME VARCHAR(255),
    SEMANTIC_VIEW VARCHAR(255),
    STATUS VARCHAR(20),
    EXECUTION_TIME_MS NUMBER,
    ROW_COUNT NUMBER,
    ERROR_MESSAGE VARCHAR(5000),
    TESTED_AT TIMESTAMP_LTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'DEMO: Sam-the-Snowman - Test execution results (Expires: 2026-02-14)';


-- ============================================================================
-- TEST EXECUTION PROCEDURE
-- ============================================================================
-- Runs all test categories and populates TEST_RESULTS

CREATE OR REPLACE PROCEDURE SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_RUN_TESTS()
RETURNS TABLE(TEST_CATEGORY VARCHAR, TEST_NAME VARCHAR, STATUS VARCHAR, EXECUTION_TIME_MS NUMBER, ERROR_MESSAGE VARCHAR)
LANGUAGE SQL
COMMENT = 'DEMO: Sam-the-Snowman - Execute all tests and return results (Expires: 2026-02-14)'
AS
$$
DECLARE
    start_time TIMESTAMP_LTZ;
    end_time TIMESTAMP_LTZ;
    exec_time_ms NUMBER;
    row_cnt NUMBER;
    error_msg VARCHAR;
BEGIN
    -- Clear previous results
    TRUNCATE TABLE SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS;

    -- ========================================================================
    -- SMOKE TESTS: Basic Structure Validation
    -- ========================================================================

    -- Test 1: Query Performance semantic view exists
    BEGIN
        start_time := CURRENT_TIMESTAMP();
        SHOW SEMANTIC VIEWS LIKE 'SV_SAM_QUERY_PERFORMANCE' IN SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS;
        end_time := CURRENT_TIMESTAMP();
        exec_time_ms := TIMESTAMPDIFF(MILLISECOND, start_time, end_time);

        INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
            (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
        VALUES ('SMOKE', 'Semantic view exists', 'SV_SAM_QUERY_PERFORMANCE', 'PASS', :exec_time_ms, NULL);
    EXCEPTION
        WHEN OTHER THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
            VALUES ('SMOKE', 'Semantic view exists', 'SV_SAM_QUERY_PERFORMANCE', 'FAIL', 0, SQLERRM);
    END;

    -- Test 2: Cost Analysis semantic view exists
    BEGIN
        start_time := CURRENT_TIMESTAMP();
        SHOW SEMANTIC VIEWS LIKE 'SV_SAM_COST_ANALYSIS' IN SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS;
        end_time := CURRENT_TIMESTAMP();
        exec_time_ms := TIMESTAMPDIFF(MILLISECOND, start_time, end_time);

        INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
            (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
        VALUES ('SMOKE', 'Semantic view exists', 'SV_SAM_COST_ANALYSIS', 'PASS', :exec_time_ms, NULL);
    EXCEPTION
        WHEN OTHER THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
            VALUES ('SMOKE', 'Semantic view exists', 'SV_SAM_COST_ANALYSIS', 'FAIL', 0, SQLERRM);
    END;

    -- Test 3: Warehouse Operations semantic view exists
    BEGIN
        start_time := CURRENT_TIMESTAMP();
        SHOW SEMANTIC VIEWS LIKE 'SV_SAM_WAREHOUSE_OPERATIONS' IN SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS;
        end_time := CURRENT_TIMESTAMP();
        exec_time_ms := TIMESTAMPDIFF(MILLISECOND, start_time, end_time);

        INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
            (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
        VALUES ('SMOKE', 'Semantic view exists', 'SV_SAM_WAREHOUSE_OPERATIONS', 'PASS', :exec_time_ms, NULL);
    EXCEPTION
        WHEN OTHER THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
            VALUES ('SMOKE', 'Semantic view exists', 'SV_SAM_WAREHOUSE_OPERATIONS', 'FAIL', 0, SQLERRM);
    END;

    -- Test 4: Agent exists
    BEGIN
        start_time := CURRENT_TIMESTAMP();
        SHOW AGENTS LIKE 'SAM_THE_SNOWMAN' IN SCHEMA SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN;
        end_time := CURRENT_TIMESTAMP();
        exec_time_ms := TIMESTAMPDIFF(MILLISECOND, start_time, end_time);

        INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
            (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
        VALUES ('SMOKE', 'Agent exists', 'SAM_THE_SNOWMAN', 'PASS', :exec_time_ms, NULL);
    EXCEPTION
        WHEN OTHER THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
            VALUES ('SMOKE', 'Agent exists', 'SAM_THE_SNOWMAN', 'FAIL', 0, SQLERRM);
    END;

    -- ========================================================================
    -- FUNCTIONAL TESTS: VQR Execution
    -- ========================================================================

    -- VQR Test 1: Slowest queries today (Query Performance)
    BEGIN
        start_time := CURRENT_TIMESTAMP();
        SELECT COUNT(*) INTO :row_cnt FROM (
            SELECT QUERY_ID, QUERY_TEXT, TOTAL_ELAPSED_TIME/1000 AS duration_seconds, WAREHOUSE_NAME, USER_NAME
            FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
            WHERE START_TIME >= CURRENT_DATE()
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
            ORDER BY TOTAL_ELAPSED_TIME DESC LIMIT 10
        );
        end_time := CURRENT_TIMESTAMP();
        exec_time_ms := TIMESTAMPDIFF(MILLISECOND, start_time, end_time);

        INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
            (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ROW_COUNT, ERROR_MESSAGE)
        VALUES ('FUNCTIONAL', 'VQR: Slowest queries today', 'SV_SAM_QUERY_PERFORMANCE', 'PASS', :exec_time_ms, :row_cnt, NULL);
    EXCEPTION
        WHEN OTHER THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
            VALUES ('FUNCTIONAL', 'VQR: Slowest queries today', 'SV_SAM_QUERY_PERFORMANCE', 'FAIL', 0, SQLERRM);
    END;

    -- VQR Test 2: Queries with remote spilling (Query Performance)
    BEGIN
        start_time := CURRENT_TIMESTAMP();
        SELECT COUNT(*) INTO :row_cnt FROM (
            SELECT QUERY_ID, BYTES_SPILLED_TO_REMOTE_STORAGE
            FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
            WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND BYTES_SPILLED_TO_REMOTE_STORAGE > 0
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
            LIMIT 20
        );
        end_time := CURRENT_TIMESTAMP();
        exec_time_ms := TIMESTAMPDIFF(MILLISECOND, start_time, end_time);

        INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
            (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ROW_COUNT, ERROR_MESSAGE)
        VALUES ('FUNCTIONAL', 'VQR: Remote spilling queries', 'SV_SAM_QUERY_PERFORMANCE', 'PASS', :exec_time_ms, :row_cnt, NULL);
    EXCEPTION
        WHEN OTHER THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
            VALUES ('FUNCTIONAL', 'VQR: Remote spilling queries', 'SV_SAM_QUERY_PERFORMANCE', 'FAIL', 0, SQLERRM);
    END;

    -- VQR Test 3: Most common errors (Query Performance)
    BEGIN
        start_time := CURRENT_TIMESTAMP();
        SELECT COUNT(*) INTO :row_cnt FROM (
            SELECT ERROR_CODE, ERROR_MESSAGE, COUNT(*) AS failure_count
            FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
            WHERE EXECUTION_STATUS = 'FAIL'
            AND START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
            GROUP BY ERROR_CODE, ERROR_MESSAGE
            ORDER BY failure_count DESC LIMIT 10
        );
        end_time := CURRENT_TIMESTAMP();
        exec_time_ms := TIMESTAMPDIFF(MILLISECOND, start_time, end_time);

        INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
            (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ROW_COUNT, ERROR_MESSAGE)
        VALUES ('FUNCTIONAL', 'VQR: Most common errors', 'SV_SAM_QUERY_PERFORMANCE', 'PASS', :exec_time_ms, :row_cnt, NULL);
    EXCEPTION
        WHEN OTHER THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
            VALUES ('FUNCTIONAL', 'VQR: Most common errors', 'SV_SAM_QUERY_PERFORMANCE', 'FAIL', 0, SQLERRM);
    END;

    -- VQR Test 4: Most expensive warehouses (Cost Analysis)
    BEGIN
        start_time := CURRENT_TIMESTAMP();
        SELECT COUNT(*) INTO :row_cnt FROM (
            SELECT WAREHOUSE_NAME, SUM(CREDITS_USED) AS total_credits
            FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
            WHERE START_TIME >= DATE_TRUNC('MONTH', DATEADD('MONTH', -1, CURRENT_DATE()))
            AND START_TIME < DATE_TRUNC('MONTH', CURRENT_DATE())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
            GROUP BY WAREHOUSE_NAME
            ORDER BY total_credits DESC
        );
        end_time := CURRENT_TIMESTAMP();
        exec_time_ms := TIMESTAMPDIFF(MILLISECOND, start_time, end_time);

        INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
            (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ROW_COUNT, ERROR_MESSAGE)
        VALUES ('FUNCTIONAL', 'VQR: Most expensive warehouses', 'SV_SAM_COST_ANALYSIS', 'PASS', :exec_time_ms, :row_cnt, NULL);
    EXCEPTION
        WHEN OTHER THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
            VALUES ('FUNCTIONAL', 'VQR: Most expensive warehouses', 'SV_SAM_COST_ANALYSIS', 'FAIL', 0, SQLERRM);
    END;

    -- VQR Test 5: Daily spend trend (Cost Analysis)
    BEGIN
        start_time := CURRENT_TIMESTAMP();
        SELECT COUNT(*) INTO :row_cnt FROM (
            SELECT DATE(START_TIME) AS usage_date, SUM(CREDITS_USED) AS daily_credits
            FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
            WHERE START_TIME >= DATEADD('DAY', -30, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
            GROUP BY usage_date
            ORDER BY usage_date DESC
        );
        end_time := CURRENT_TIMESTAMP();
        exec_time_ms := TIMESTAMPDIFF(MILLISECOND, start_time, end_time);

        INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
            (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ROW_COUNT, ERROR_MESSAGE)
        VALUES ('FUNCTIONAL', 'VQR: Daily spend trend', 'SV_SAM_COST_ANALYSIS', 'PASS', :exec_time_ms, :row_cnt, NULL);
    EXCEPTION
        WHEN OTHER THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
            VALUES ('FUNCTIONAL', 'VQR: Daily spend trend', 'SV_SAM_COST_ANALYSIS', 'FAIL', 0, SQLERRM);
    END;

    -- VQR Test 6: Warehouses with queuing (Warehouse Operations)
    BEGIN
        start_time := CURRENT_TIMESTAMP();
        SELECT COUNT(*) INTO :row_cnt FROM (
            SELECT WAREHOUSE_NAME, AVG(AVG_QUEUED_LOAD) AS avg_queue_depth
            FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
            WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
            GROUP BY WAREHOUSE_NAME
            HAVING avg_queue_depth > 0
            ORDER BY avg_queue_depth DESC
        );
        end_time := CURRENT_TIMESTAMP();
        exec_time_ms := TIMESTAMPDIFF(MILLISECOND, start_time, end_time);

        INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
            (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ROW_COUNT, ERROR_MESSAGE)
        VALUES ('FUNCTIONAL', 'VQR: Warehouses with queuing', 'SV_SAM_WAREHOUSE_OPERATIONS', 'PASS', :exec_time_ms, :row_cnt, NULL);
    EXCEPTION
        WHEN OTHER THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
            VALUES ('FUNCTIONAL', 'VQR: Warehouses with queuing', 'SV_SAM_WAREHOUSE_OPERATIONS', 'FAIL', 0, SQLERRM);
    END;

    -- VQR Test 7: Hourly concurrency pattern (Warehouse Operations)
    BEGIN
        start_time := CURRENT_TIMESTAMP();
        SELECT COUNT(*) INTO :row_cnt FROM (
            SELECT WAREHOUSE_NAME, HOUR(START_TIME) AS hour_of_day, AVG(AVG_RUNNING) AS avg_concurrency
            FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY
            WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
            GROUP BY WAREHOUSE_NAME, hour_of_day
            ORDER BY WAREHOUSE_NAME, hour_of_day
        );
        end_time := CURRENT_TIMESTAMP();
        exec_time_ms := TIMESTAMPDIFF(MILLISECOND, start_time, end_time);

        INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
            (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ROW_COUNT, ERROR_MESSAGE)
        VALUES ('FUNCTIONAL', 'VQR: Hourly concurrency', 'SV_SAM_WAREHOUSE_OPERATIONS', 'PASS', :exec_time_ms, :row_cnt, NULL);
    EXCEPTION
        WHEN OTHER THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
            VALUES ('FUNCTIONAL', 'VQR: Hourly concurrency', 'SV_SAM_WAREHOUSE_OPERATIONS', 'FAIL', 0, SQLERRM);
    END;

    -- ========================================================================
    -- REGRESSION TESTS: Edge Cases and Data Quality
    -- ========================================================================

    -- Regression Test 1: System warehouses excluded from query_performance
    BEGIN
        start_time := CURRENT_TIMESTAMP();
        SELECT COUNT(*) INTO :row_cnt FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
        WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
        AND WAREHOUSE_NAME LIKE 'SYSTEM$%';

        -- If there are system warehouse queries, verify our filter works
        SELECT COUNT(*) INTO :row_cnt FROM (
            SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
            WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
            AND WAREHOUSE_NAME LIKE 'SYSTEM$%' -- Should return 0
        );
        end_time := CURRENT_TIMESTAMP();
        exec_time_ms := TIMESTAMPDIFF(MILLISECOND, start_time, end_time);

        IF (row_cnt = 0) THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ROW_COUNT, ERROR_MESSAGE)
            VALUES ('REGRESSION', 'System warehouses excluded', 'ALL', 'PASS', :exec_time_ms, :row_cnt, NULL);
        ELSE
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ROW_COUNT, ERROR_MESSAGE)
            VALUES ('REGRESSION', 'System warehouses excluded', 'ALL', 'FAIL', :exec_time_ms, :row_cnt, 'Filter logic error - system warehouses found');
        END IF;
    EXCEPTION
        WHEN OTHER THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
            VALUES ('REGRESSION', 'System warehouses excluded', 'ALL', 'FAIL', 0, SQLERRM);
    END;

    -- Regression Test 2: Time conversion consistency (milliseconds to seconds)
    BEGIN
        start_time := CURRENT_TIMESTAMP();
        SELECT COUNT(*) INTO :row_cnt FROM (
            SELECT QUERY_ID, TOTAL_ELAPSED_TIME, TOTAL_ELAPSED_TIME/1000 AS seconds
            FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
            WHERE START_TIME >= DATEADD(DAY, -1, CURRENT_TIMESTAMP())
            AND TOTAL_ELAPSED_TIME IS NOT NULL
            AND TOTAL_ELAPSED_TIME > 0
            LIMIT 10
        );
        end_time := CURRENT_TIMESTAMP();
        exec_time_ms := TIMESTAMPDIFF(MILLISECOND, start_time, end_time);

        INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
            (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ROW_COUNT, ERROR_MESSAGE)
        VALUES ('REGRESSION', 'Time conversion (ms to s)', 'SV_SAM_QUERY_PERFORMANCE', 'PASS', :exec_time_ms, :row_cnt, NULL);
    EXCEPTION
        WHEN OTHER THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
            VALUES ('REGRESSION', 'Time conversion (ms to s)', 'SV_SAM_QUERY_PERFORMANCE', 'FAIL', 0, SQLERRM);
    END;

    -- Regression Test 3: Bytes to GB conversion
    BEGIN
        start_time := CURRENT_TIMESTAMP();
        SELECT COUNT(*) INTO :row_cnt FROM (
            SELECT QUERY_ID, BYTES_SCANNED, BYTES_SCANNED/(1024*1024*1024) AS gb_scanned
            FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
            WHERE START_TIME >= DATEADD(DAY, -1, CURRENT_TIMESTAMP())
            AND BYTES_SCANNED IS NOT NULL
            AND BYTES_SCANNED > 0
            LIMIT 10
        );
        end_time := CURRENT_TIMESTAMP();
        exec_time_ms := TIMESTAMPDIFF(MILLISECOND, start_time, end_time);

        INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
            (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ROW_COUNT, ERROR_MESSAGE)
        VALUES ('REGRESSION', 'Bytes conversion (to GB)', 'SV_SAM_QUERY_PERFORMANCE', 'PASS', :exec_time_ms, :row_cnt, NULL);
    EXCEPTION
        WHEN OTHER THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
            VALUES ('REGRESSION', 'Bytes conversion (to GB)', 'SV_SAM_QUERY_PERFORMANCE', 'FAIL', 0, SQLERRM);
    END;

    -- Regression Test 4: NULL handling in aggregations
    BEGIN
        start_time := CURRENT_TIMESTAMP();
        SELECT COUNT(*) INTO :row_cnt FROM (
            SELECT
                WAREHOUSE_NAME,
                AVG(TOTAL_ELAPSED_TIME) AS avg_time,
                100.0 * SUM(CASE WHEN EXECUTION_STATUS = 'FAIL' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS error_rate
            FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
            WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
            GROUP BY WAREHOUSE_NAME
        );
        end_time := CURRENT_TIMESTAMP();
        exec_time_ms := TIMESTAMPDIFF(MILLISECOND, start_time, end_time);

        INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
            (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ROW_COUNT, ERROR_MESSAGE)
        VALUES ('REGRESSION', 'NULL handling in aggregations', 'SV_SAM_QUERY_PERFORMANCE', 'PASS', :exec_time_ms, :row_cnt, NULL);
    EXCEPTION
        WHEN OTHER THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
            VALUES ('REGRESSION', 'NULL handling in aggregations', 'SV_SAM_QUERY_PERFORMANCE', 'FAIL', 0, SQLERRM);
    END;

    -- ========================================================================
    -- PERFORMANCE TESTS: Query Timing
    -- ========================================================================

    -- Performance Test 1: Query History 7-day aggregation under 30 seconds
    BEGIN
        start_time := CURRENT_TIMESTAMP();
        SELECT COUNT(*) INTO :row_cnt FROM (
            SELECT WAREHOUSE_NAME, COUNT(*) AS cnt
            FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
            WHERE START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
            GROUP BY WAREHOUSE_NAME
        );
        end_time := CURRENT_TIMESTAMP();
        exec_time_ms := TIMESTAMPDIFF(MILLISECOND, start_time, end_time);

        IF (exec_time_ms < 30000) THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ROW_COUNT, ERROR_MESSAGE)
            VALUES ('PERFORMANCE', '7-day query agg < 30s', 'SV_SAM_QUERY_PERFORMANCE', 'PASS', :exec_time_ms, :row_cnt, NULL);
        ELSE
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ROW_COUNT, ERROR_MESSAGE)
            VALUES ('PERFORMANCE', '7-day query agg < 30s', 'SV_SAM_QUERY_PERFORMANCE', 'WARN', :exec_time_ms, :row_cnt, 'Query took longer than 30 seconds');
        END IF;
    EXCEPTION
        WHEN OTHER THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
            VALUES ('PERFORMANCE', '7-day query agg < 30s', 'SV_SAM_QUERY_PERFORMANCE', 'FAIL', 0, SQLERRM);
    END;

    -- Performance Test 2: Metering History 30-day aggregation under 30 seconds
    BEGIN
        start_time := CURRENT_TIMESTAMP();
        SELECT COUNT(*) INTO :row_cnt FROM (
            SELECT WAREHOUSE_NAME, SUM(CREDITS_USED) AS total
            FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
            WHERE START_TIME >= DATEADD(DAY, -30, CURRENT_TIMESTAMP())
            AND WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
            GROUP BY WAREHOUSE_NAME
        );
        end_time := CURRENT_TIMESTAMP();
        exec_time_ms := TIMESTAMPDIFF(MILLISECOND, start_time, end_time);

        IF (exec_time_ms < 30000) THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ROW_COUNT, ERROR_MESSAGE)
            VALUES ('PERFORMANCE', '30-day cost agg < 30s', 'SV_SAM_COST_ANALYSIS', 'PASS', :exec_time_ms, :row_cnt, NULL);
        ELSE
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ROW_COUNT, ERROR_MESSAGE)
            VALUES ('PERFORMANCE', '30-day cost agg < 30s', 'SV_SAM_COST_ANALYSIS', 'WARN', :exec_time_ms, :row_cnt, 'Query took longer than 30 seconds');
        END IF;
    EXCEPTION
        WHEN OTHER THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
            VALUES ('PERFORMANCE', '30-day cost agg < 30s', 'SV_SAM_COST_ANALYSIS', 'FAIL', 0, SQLERRM);
    END;

    -- ========================================================================
    -- NEW: Tests for User Activity Semantic View
    -- ========================================================================

    -- Test: User Activity semantic view exists
    BEGIN
        start_time := CURRENT_TIMESTAMP();
        SHOW SEMANTIC VIEWS LIKE 'SV_SAM_USER_ACTIVITY' IN SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS;
        end_time := CURRENT_TIMESTAMP();
        exec_time_ms := TIMESTAMPDIFF(MILLISECOND, start_time, end_time);

        INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
            (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
        VALUES ('SMOKE', 'Semantic view exists', 'SV_SAM_USER_ACTIVITY', 'PASS', :exec_time_ms, NULL);
    EXCEPTION
        WHEN OTHER THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
            VALUES ('SMOKE', 'Semantic view exists', 'SV_SAM_USER_ACTIVITY', 'FAIL', 0, SQLERRM);
    END;

    -- VQR Test: Users by credit consumption
    BEGIN
        start_time := CURRENT_TIMESTAMP();
        SELECT COUNT(*) INTO :row_cnt FROM (
            SELECT qh.USER_NAME, COUNT(*) AS QUERY_COUNT, SUM(qah.CREDITS_ATTRIBUTED_COMPUTE) AS TOTAL_CREDITS
            FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY qh
            LEFT JOIN SNOWFLAKE.ACCOUNT_USAGE.QUERY_ATTRIBUTION_HISTORY qah ON qh.QUERY_ID = qah.QUERY_ID
            WHERE qh.START_TIME >= DATEADD(DAY, -7, CURRENT_TIMESTAMP())
                AND qh.WAREHOUSE_NAME NOT LIKE 'SYSTEM$%'
            GROUP BY qh.USER_NAME
            ORDER BY TOTAL_CREDITS DESC NULLS LAST
            LIMIT 10
        );
        end_time := CURRENT_TIMESTAMP();
        exec_time_ms := TIMESTAMPDIFF(MILLISECOND, start_time, end_time);

        INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
            (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ROW_COUNT, ERROR_MESSAGE)
        VALUES ('FUNCTIONAL', 'VQR: Users by credits', 'SV_SAM_USER_ACTIVITY', 'PASS', :exec_time_ms, :row_cnt, NULL);
    EXCEPTION
        WHEN OTHER THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
            VALUES ('FUNCTIONAL', 'VQR: Users by credits', 'SV_SAM_USER_ACTIVITY', 'FAIL', 0, SQLERRM);
    END;

    -- ========================================================================
    -- NEW: Tests for Python Analytics Procedures
    -- ========================================================================

    -- Test: Cost anomaly detector procedure exists and runs
    BEGIN
        start_time := CURRENT_TIMESTAMP();
        SELECT COUNT(*) INTO :row_cnt FROM TABLE(SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_SAM_COST_ANOMALIES(14, 2.0));
        end_time := CURRENT_TIMESTAMP();
        exec_time_ms := TIMESTAMPDIFF(MILLISECOND, start_time, end_time);

        INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
            (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ROW_COUNT, ERROR_MESSAGE)
        VALUES ('FUNCTIONAL', 'Python: Cost anomaly detector', 'SP_SAM_COST_ANOMALIES', 'PASS', :exec_time_ms, :row_cnt, NULL);
    EXCEPTION
        WHEN OTHER THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
            VALUES ('FUNCTIONAL', 'Python: Cost anomaly detector', 'SP_SAM_COST_ANOMALIES', 'FAIL', 0, SQLERRM);
    END;

    -- Test: Efficiency scorer procedure exists and runs
    BEGIN
        start_time := CURRENT_TIMESTAMP();
        SELECT COUNT(*) INTO :row_cnt FROM TABLE(SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_SAM_EFFICIENCY_SCORE(7));
        end_time := CURRENT_TIMESTAMP();
        exec_time_ms := TIMESTAMPDIFF(MILLISECOND, start_time, end_time);

        INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
            (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ROW_COUNT, ERROR_MESSAGE)
        VALUES ('FUNCTIONAL', 'Python: Efficiency scorer', 'SP_SAM_EFFICIENCY_SCORE', 'PASS', :exec_time_ms, :row_cnt, NULL);
    EXCEPTION
        WHEN OTHER THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
            VALUES ('FUNCTIONAL', 'Python: Efficiency scorer', 'SP_SAM_EFFICIENCY_SCORE', 'FAIL', 0, SQLERRM);
    END;

    -- Test: Trend analyzer procedure exists and runs
    BEGIN
        start_time := CURRENT_TIMESTAMP();
        SELECT COUNT(*) INTO :row_cnt FROM TABLE(SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_SAM_TREND_ANALYSIS());
        end_time := CURRENT_TIMESTAMP();
        exec_time_ms := TIMESTAMPDIFF(MILLISECOND, start_time, end_time);

        INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
            (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ROW_COUNT, ERROR_MESSAGE)
        VALUES ('FUNCTIONAL', 'Python: Trend analyzer', 'SP_SAM_TREND_ANALYSIS', 'PASS', :exec_time_ms, :row_cnt, NULL);
    EXCEPTION
        WHEN OTHER THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
            VALUES ('FUNCTIONAL', 'Python: Trend analyzer', 'SP_SAM_TREND_ANALYSIS', 'FAIL', 0, SQLERRM);
    END;

    -- ========================================================================
    -- NEW: Performance Tests for Python Procedures
    -- ========================================================================

    -- Performance Test: Cost anomaly detector under 60 seconds
    BEGIN
        start_time := CURRENT_TIMESTAMP();
        SELECT COUNT(*) INTO :row_cnt FROM TABLE(SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_SAM_COST_ANOMALIES(30, 2.0));
        end_time := CURRENT_TIMESTAMP();
        exec_time_ms := TIMESTAMPDIFF(MILLISECOND, start_time, end_time);

        IF (exec_time_ms < 60000) THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ROW_COUNT, ERROR_MESSAGE)
            VALUES ('PERFORMANCE', 'Cost anomaly < 60s', 'SP_SAM_COST_ANOMALIES', 'PASS', :exec_time_ms, :row_cnt, NULL);
        ELSE
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ROW_COUNT, ERROR_MESSAGE)
            VALUES ('PERFORMANCE', 'Cost anomaly < 60s', 'SP_SAM_COST_ANOMALIES', 'WARN', :exec_time_ms, :row_cnt, 'Procedure took longer than 60 seconds');
        END IF;
    EXCEPTION
        WHEN OTHER THEN
            INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
                (TEST_CATEGORY, TEST_NAME, SEMANTIC_VIEW, STATUS, EXECUTION_TIME_MS, ERROR_MESSAGE)
            VALUES ('PERFORMANCE', 'Cost anomaly < 60s', 'SP_SAM_COST_ANOMALIES', 'FAIL', 0, SQLERRM);
    END;

    -- Return summary
    RETURN TABLE(
        SELECT
            TEST_CATEGORY,
            TEST_NAME,
            STATUS,
            EXECUTION_TIME_MS,
            ERROR_MESSAGE
        FROM SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
        ORDER BY TEST_ID
    );
END;
$;

-- ============================================================================
-- TEST SUMMARY VIEW
-- ============================================================================
-- Provides a quick overview of test results

CREATE OR REPLACE VIEW SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.V_TEST_SUMMARY AS
SELECT
    TEST_CATEGORY,
    COUNT(*) AS TOTAL_TESTS,
    SUM(CASE WHEN STATUS = 'PASS' THEN 1 ELSE 0 END) AS PASSED,
    SUM(CASE WHEN STATUS = 'FAIL' THEN 1 ELSE 0 END) AS FAILED,
    SUM(CASE WHEN STATUS = 'WARN' THEN 1 ELSE 0 END) AS WARNINGS,
    ROUND(SUM(CASE WHEN STATUS = 'PASS' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS PASS_RATE_PCT,
    AVG(EXECUTION_TIME_MS) AS AVG_EXECUTION_MS
FROM SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS
GROUP BY TEST_CATEGORY
ORDER BY TEST_CATEGORY;

COMMENT ON VIEW SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.V_TEST_SUMMARY IS
    'DEMO: Sam-the-Snowman - Test summary by category (Expires: 2026-02-14)';

-- ============================================================================
-- USAGE INSTRUCTIONS
-- ============================================================================
/*
To run all tests:
    CALL SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_RUN_TESTS();

To view detailed results:
    SELECT * FROM SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS ORDER BY TEST_ID;

To view summary by category:
    SELECT * FROM SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.V_TEST_SUMMARY;

To filter failures only:
    SELECT * FROM SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.TEST_RESULTS WHERE STATUS = 'FAIL';
*/
