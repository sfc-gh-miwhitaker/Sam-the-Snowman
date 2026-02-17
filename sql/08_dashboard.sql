/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * Module: 08_dashboard.sql
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * PURPOSE:
 *   Deploy Sam's Analytics Dashboard as a Streamlit in Snowflake (SiS) app.
 *   Provides visual companion to Sam's conversational intelligence.
 *
 * Synopsis:
 *   Creates a native Streamlit application showcasing:
 *   - Week-over-week trend analysis with KPI cards
 *   - Warehouse efficiency scores with letter grades
 *   - Cost anomaly detection with severity highlighting
 *   - Interactive time-series visualizations
 *
 * OBJECTS CREATED:
 *   - SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAMS_DASHBOARD (Streamlit App)
 *
 * Prerequisites:
 *   - 01_scaffolding.sql must be run first
 *   - 03c_python_analytics_tool.sql must be run first (provides analytics SPs)
 *   - Container runtime must be available in account
 *
 * Author: SE Community
 * Created: 2025-01-26
 * Expires: 2026-03-19
 * Version: 6.0
 * License: Apache 2.0
 *
 * Usage:
 *   This module is called by deploy_all.sql or can be run standalone.
 ******************************************************************************/

USE ROLE SYSADMIN;
USE WAREHOUSE SFE_SAM_SNOWMAN_WH;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA SAM_THE_SNOWMAN;

-- ============================================================================
-- STREAMLIT IN SNOWFLAKE: Sam's Analytics Dashboard
-- ============================================================================

CREATE OR REPLACE STREAMLIT SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAMS_DASHBOARD
    FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO/branches/main/streamlit/'
    MAIN_FILE = 'streamlit_app.py'
    QUERY_WAREHOUSE = SFE_SAM_SNOWMAN_WH
    TITLE = 'Sam''s Analytics Dashboard'
    COMMENT = 'DEMO: Sam-the-Snowman - Visual analytics companion dashboard (Expires: 2026-03-19)';

-- Grant access to SYSADMIN (dashboard users will need this role or equivalent)
GRANT USAGE ON STREAMLIT SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAMS_DASHBOARD TO ROLE SYSADMIN;

-- Dashboard deployment complete
SELECT
    'DASHBOARD DEPLOYED' AS status,
    'Projects > Streamlit > SAMS_DASHBOARD' AS location,
    'Sam''s Analytics Dashboard' AS app_name;
