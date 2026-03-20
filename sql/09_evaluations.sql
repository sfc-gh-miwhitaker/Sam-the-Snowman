/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * Module: 09_evaluations.sql
 *
 * WARNING: NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * PURPOSE:
 *   Set up Cortex Agent Evaluations (GA March 2026) for Sam-the-Snowman.
 *   Creates evaluation dataset seeded from VQR-derived questions and a
 *   YAML configuration for automated evaluation runs.
 *
 * Synopsis:
 *   Demonstrates the Cortex Agent Evaluations framework with built-in
 *   metrics (answer_correctness, logical_consistency) and a custom
 *   Snowflake-optimization relevance metric.
 *
 * OBJECTS CREATED:
 *   - SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_EVALUATION_DATA (Table)
 *   - SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.YAML_FILE_FORMAT (File Format)
 *   - SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_EVALUATION_CONFIG (Stage)
 *
 * Prerequisites:
 *   - 05_agent.sql must be run first (agent must exist)
 *   - EXECUTE TASK ON ACCOUNT privilege
 *   - MONITOR privilege on the agent
 *
 * Author: SE Community
 * Created: 2026-03-19
 * Expires: 2026-04-18
 * Version: 1.0
 * License: Apache 2.0
 *
 * Usage:
 *   This module is called by deploy_all.sql or can be run standalone.
 *   After deployment, run an evaluation via Snowsight (AI & ML > Agents >
 *   Sam-the-Snowman > Evaluations) or via SQL:
 *
 *   CALL EXECUTE_AI_EVALUATION(
 *     'START',
 *     OBJECT_CONSTRUCT('run_name', 'sam-eval-1'),
 *     '@SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_EVALUATION_CONFIG/sam_evaluation_config.yaml'
 *   );
 ******************************************************************************/

USE ROLE SYSADMIN;
USE WAREHOUSE SFE_SAM_SNOWMAN_WH;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA SAM_THE_SNOWMAN;

-- ============================================================================
-- EVALUATION DATASET
-- ============================================================================
-- Seeded from VQR-derived questions with ground truth descriptions.
-- Ground truth uses natural language descriptions (not exact answers) so the
-- LLM judge can evaluate response quality against dynamic ACCOUNT_USAGE data.

CREATE OR REPLACE TABLE SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_EVALUATION_DATA (
    INPUT_QUERY VARCHAR,
    EXPECTED_OUTCOME VARIANT
)
COMMENT = 'DEMO: Sam-the-Snowman - Evaluation dataset for Cortex Agent Evaluations (Expires: 2026-04-18)';

INSERT INTO SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_EVALUATION_DATA
    (INPUT_QUERY, EXPECTED_OUTCOME)
SELECT 'What were my top 10 slowest queries today?',
       PARSE_JSON('{"ground_truth_output": "Response should list up to 10 queries ordered by TOTAL_ELAPSED_TIME descending, including QUERY_ID, duration in seconds, warehouse name, and user. System warehouses (SYSTEM$%) should be excluded."}')
UNION ALL
SELECT 'Which warehouses are costing me the most this month?',
       PARSE_JSON('{"ground_truth_output": "Response should show warehouses ranked by CREDITS_USED from WAREHOUSE_METERING_HISTORY for the current month, with dollar estimates at approximately $3/credit. System warehouses should be excluded."}')
UNION ALL
SELECT 'Are there any cost anomalies I should know about?',
       PARSE_JSON('{"ground_truth_output": "Response should invoke the cost_anomaly_detector tool and report any days with z-scores above the threshold, including severity level, percent above baseline, and the top contributing warehouse."}')
UNION ALL
SELECT 'Give me an efficiency score for my warehouses',
       PARSE_JSON('{"ground_truth_output": "Response should invoke the efficiency_scorer tool and present scores from 0-100 with letter grades (A-F) for each warehouse, including cache, spill, error, and queue sub-scores with recommendations."}')
UNION ALL
SELECT 'What changed compared to last week?',
       PARSE_JSON('{"ground_truth_output": "Response should invoke the trend_analyzer tool and compare this week vs last week for credits, query count, average duration, error rate, active warehouses, and active users with percentage changes."}')
UNION ALL
SELECT 'Which queries are spilling to remote storage?',
       PARSE_JSON('{"ground_truth_output": "Response should list queries with BYTES_SPILLED_TO_REMOTE_STORAGE > 0 from the past 7 days, including spill amount in GB, warehouse size, and duration. Should recommend upsizing warehouses or query optimization."}')
UNION ALL
SELECT 'Who is using the most credits?',
       PARSE_JSON('{"ground_truth_output": "Response should rank users by attributed compute credits using QUERY_ATTRIBUTION_HISTORY, showing query count and total credits per user. System warehouses should be excluded."}')
UNION ALL
SELECT 'How do I enable multi-cluster warehouses?',
       PARSE_JSON('{"ground_truth_output": "Response should use the documentation search tool (Cortex Search or web search) and provide guidance on ALTER WAREHOUSE with MAX_CLUSTER_COUNT and scaling policy settings."}')
UNION ALL
SELECT 'Show me warehouse utilization by hour of day',
       PARSE_JSON('{"ground_truth_output": "Response should query WAREHOUSE_LOAD_HISTORY grouped by hour, showing AVG_RUNNING concurrency patterns. Should offer to visualize with a chart."}')
UNION ALL
SELECT 'What are the most common query error codes?',
       PARSE_JSON('{"ground_truth_output": "Response should aggregate failed queries by ERROR_CODE and ERROR_MESSAGE from the past 7 days, showing failure count and affected users, ordered by frequency."}');

-- ============================================================================
-- EVALUATION INFRASTRUCTURE
-- ============================================================================

CREATE OR REPLACE FILE FORMAT SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.YAML_FILE_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = NONE
    RECORD_DELIMITER = '\n'
    SKIP_HEADER = 0
    FIELD_OPTIONALLY_ENCLOSED_BY = NONE
    ESCAPE_UNENCLOSED_FIELD = NONE
    COMMENT = 'DEMO: Sam-the-Snowman - File format for evaluation YAML configs (Expires: 2026-04-18)';

CREATE OR REPLACE STAGE SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_EVALUATION_CONFIG
    FILE_FORMAT = SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.YAML_FILE_FORMAT
    COMMENT = 'DEMO: Sam-the-Snowman - Stage for evaluation configuration YAML (Expires: 2026-04-18)';

-- Deploy evaluation config from Git repository stage
COPY FILES
    INTO @SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_EVALUATION_CONFIG
    FROM @SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO/branches/main/evaluations/
    FILES = ('sam_evaluation_config.yaml');

-- ============================================================================
-- GRANT PRIVILEGES
-- ============================================================================
-- Per Cortex Agent Evaluations docs, the executing role needs:
--   SNOWFLAKE.CORTEX_USER database role, EXECUTE TASK ON ACCOUNT,
--   CREATE DATASET ON SCHEMA, MONITOR on the agent, and READ on the config stage.

USE ROLE ACCOUNTADMIN;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE SYSADMIN;
GRANT EXECUTE TASK ON ACCOUNT TO ROLE SYSADMIN;

USE ROLE SYSADMIN;
GRANT MONITOR ON AGENT SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_THE_SNOWMAN TO ROLE SYSADMIN;
GRANT READ ON STAGE SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_EVALUATION_CONFIG TO ROLE SYSADMIN;

-- ============================================================================
-- USAGE INSTRUCTIONS
-- ============================================================================
/*
Run an evaluation via SQL:
    CALL EXECUTE_AI_EVALUATION(
      'START',
      OBJECT_CONSTRUCT('run_name', 'sam-eval-1'),
      '@SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_EVALUATION_CONFIG/sam_evaluation_config.yaml'
    );

Check evaluation status:
    CALL EXECUTE_AI_EVALUATION(
      'STATUS',
      OBJECT_CONSTRUCT('run_name', 'sam-eval-1'),
      '@SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_EVALUATION_CONFIG/sam_evaluation_config.yaml'
    );

View results:
    SELECT * FROM TABLE(SNOWFLAKE.LOCAL.GET_AI_EVALUATION_DATA(
      'SNOWFLAKE_EXAMPLE', 'SAM_THE_SNOWMAN', 'SAM_THE_SNOWMAN', 'CORTEX AGENT', 'sam-eval-1'
    ));

Or use Snowsight: AI & ML > Agents > Sam-the-Snowman > Evaluations
*/

SELECT 'Evaluation framework deployed' AS status,
       (SELECT COUNT(*) FROM SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_EVALUATION_DATA) AS evaluation_questions;
