/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * Module: 06_validation.sql
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * PURPOSE:
 *   Verify that all demo objects were created and are visible in Snowflake.
 *
 * Synopsis:
 *   Validates that all Sam-the-Snowman components were deployed successfully.
 *
 * Description:
 *   This module issues targeted SHOW statements so you can inspect the
 *   actual Snowflake objects created by the previous deployment modules.
 *   Review the result sets in Snowsight (or RESULT_SCAN) to confirm each
 *   asset exists as expected.
 *
 * Prerequisites:
 *   - All previous modules (00-05) must be run first
 *
 * Author: SE Community
 * Created: 2025-11-25
 * Expires: 2026-03-19
 * Version: 4.0
 * License: Apache 2.0
 *
 * Usage:
 *   This module is called by deploy_all.sql or can be run standalone
 *   to check deployment status.
 ******************************************************************************/

-- ============================================================================
-- VERIFY DEPLOYMENT
-- ============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE SFE_SAM_SNOWMAN_WH;

SHOW NOTIFICATION INTEGRATIONS LIKE 'SFE_EMAIL_INTEGRATION';

SHOW GIT REPOSITORIES IN SCHEMA SNOWFLAKE_EXAMPLE.GIT_REPOS;

SHOW PROCEDURES IN SCHEMA SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN;

SHOW SEMANTIC VIEWS IN SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS;

SHOW AGENTS IN SCHEMA SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN;

-- Verify Snowflake Intelligence object exists and has our agent
SHOW SNOWFLAKE INTELLIGENCES;

SHOW DATABASES LIKE 'SNOWFLAKE_DOCUMENTATION';

SHOW SCHEMAS IN DATABASE SNOWFLAKE_EXAMPLE;

SELECT 'Validation complete. Review the SHOW results above for object status.' AS validation_summary;
