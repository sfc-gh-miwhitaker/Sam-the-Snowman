/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * File: sql/99_cleanup/teardown_all.sql
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * PURPOSE:
 *   Remove all Sam-the-Snowman objects while preserving shared demo infrastructure.
 *
 * Synopsis:
 *   Complete teardown script for removing all Sam-the-Snowman components.
 *
 * Description:
 *   This script removes all resources created by `deploy_all.sql` (modules `sql/01_scaffolding.sql` … `sql/06_validation.sql`) following
 *   demo project standards. The SNOWFLAKE_EXAMPLE database is preserved per
 *   demo standards (shared across demos for audit/reuse). Only schema-level
 *   objects specific to Sam-the-Snowman are removed.
 *
 * OBJECTS REMOVED:
 *   - SFE_EMAIL_INTEGRATION (Notification Integration)
 *   - SFE_SAM_SNOWMAN_WH (Dedicated demo warehouse)
 *   - SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_THE_SNOWMAN (Agent)
 *   - SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAMS_DASHBOARD (Streamlit App)
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS semantic views (SV_SAM_QUERY_PERFORMANCE, SV_SAM_COST_ANALYSIS, SV_SAM_WAREHOUSE_OPERATIONS, SV_SAM_USER_ACTIVITY)
 *   - SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SFE_SEND_EMAIL procedure
 *   - SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_SAM_* procedures (Python analytics tools)
 *   - SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO (Git repository clone)
 *   - SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN schema
 *
 * OBJECTS PRESERVED:
 *   - snowflake_documentation database (shared marketplace resource used by multiple projects)
 *   - SNOWFLAKE_EXAMPLE (Database) - Shared demo database
 *   - SNOWFLAKE_EXAMPLE.GIT_REPOS schema (shared Git repository clones)
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS schema (shared semantic views schema)
 *   - SFE_GITHUB_API_INTEGRATION - Reusable across projects
 *
 * Prerequisites:
 *   - ACCOUNTADMIN role privileges
 *   - Sam-the-Snowman previously deployed via `deploy_all.sql`
 *
 * Author: SE Community
 * Created: 2025-11-25
 * Expires: 2026-03-19
 * Version: 6.0
 * License: Apache 2.0
 *
 * Usage:
 *   Execute this entire script as ACCOUNTADMIN. Safe to run multiple times.
 *   This script is idempotent and can be run multiple times without errors.
 *
 ******************************************************************************/

-- Set context
USE ROLE accountadmin;

-- ============================================================================
-- ⚠️  PROTECTED OBJECTS - NEVER DROP THESE
-- ============================================================================
-- The following account-level objects are SHARED across all demo projects
-- and must NEVER be dropped by any individual teardown script:
--
--   DO NOT DROP: SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
--      (Account-level agent visibility control - used by ALL agents)
--
--   DO NOT DROP: SFE_GITHUB_API_INTEGRATION
--      (Reusable GitHub integration - used by multiple repos)
--
--   DO NOT DROP: SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS schema
--      (Shared semantic views schema - only drop individual SV_* views)
--
-- ============================================================================

-- ============================================================================
-- REMOVE AGENT FROM SNOWFLAKE INTELLIGENCE OBJECT (Optional)
-- ============================================================================
-- Note: When we DROP AGENT below, it's automatically removed from the
-- Snowflake Intelligence object. This explicit removal is only needed if
-- you want to hide the agent without deleting it.
--
-- If you need to manually remove from object without deleting:
-- ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
--     DROP AGENT SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_THE_SNOWMAN;

-- ============================================================================
-- REMOVE INTEGRATION OBJECTS (Account-Level)
-- ============================================================================

-- Drop notification integration (project-specific)
DROP NOTIFICATION INTEGRATION IF EXISTS SFE_EMAIL_INTEGRATION;

-- Drop dedicated demo warehouse (project-specific)
DROP WAREHOUSE IF EXISTS SFE_SAM_SNOWMAN_WH;

-- ============================================================================
-- REMOVE SCHEMA OBJECTS (Database-Level)
-- ============================================================================

-- Remove schema-level objects. Dropping the schemas with CASCADE later in the
-- script will remove any remaining objects, so explicit per-object drops are
-- no longer required.

-- Remove the Sam-the-Snowman agent
-- Note: This demo creates the agent in the project schema for collision-proof cleanup.
-- It is safe to drop an agent - it does not affect any underlying data
-- Re-running the setup script will recreate the agent

DROP AGENT IF EXISTS SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_THE_SNOWMAN;

-- Remove Streamlit dashboard
DROP STREAMLIT IF EXISTS SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAMS_DASHBOARD;

-- Remove semantic views from SEMANTIC_MODELS (explicit drops for clarity)
DROP SEMANTIC VIEW IF EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_QUERY_PERFORMANCE;
DROP SEMANTIC VIEW IF EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_COST_ANALYSIS;
DROP SEMANTIC VIEW IF EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_WAREHOUSE_OPERATIONS;
DROP SEMANTIC VIEW IF EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_USER_ACTIVITY;

-- Remove Python analytics procedures (explicit drops for clarity)
-- Note: These are also removed by CASCADE on schema drop below
DROP PROCEDURE IF EXISTS SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_SAM_COST_ANOMALIES(INT, FLOAT);
DROP PROCEDURE IF EXISTS SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_SAM_EFFICIENCY_SCORE(INT);
DROP PROCEDURE IF EXISTS SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_SAM_TREND_ANALYSIS();

-- Drop the Git repository clone (do not drop the shared GIT_REPOS schema)
DROP GIT REPOSITORY IF EXISTS SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO;

-- ============================================================================
-- REMOVE SCHEMAS (After all objects dropped)
-- ============================================================================

-- Drop the collision-proof project schema (removes procedures and any other project-scoped objects)
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN CASCADE;
-- Note: DO NOT drop SEMANTIC_MODELS or GIT_REPOS schemas (shared across projects)

-- ============================================================================
-- LEGACY CLEANUP (For older deployments)
-- ============================================================================

DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.TOOLS CASCADE;

-- ============================================================================
-- PRESERVATION NOTES
-- ============================================================================

-- Objects intentionally preserved:
-- - SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT: Account-level visibility control, shared across all agents
-- - SNOWFLAKE_EXAMPLE (Database): Shared demo database for multiple projects
-- - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS: Shared schema for all Cortex Analyst semantic views
-- - SFE_GITHUB_API_INTEGRATION: Reusable API integration for all GitHub repositories
-- - snowflake_documentation: Shared Marketplace database

-- Remove the database
-- Note: Following demo project standards, we keep SNOWFLAKE_EXAMPLE database and shared marketplace databases (for example, snowflake_documentation) in place
-- The database is shared across demo projects and should persist for audit/reuse
-- Only schema-level objects are removed; the database itself remains

-- Final confirmation message
SELECT
    'All Sam-the-Snowman components have been removed' as message;

/*************************************************************************************************************************
 * --- TROUBLESHOOTING CLEANUP ---
 *
 * Description:
 *   This section provides commands to manually remove resources if the script above fails.
 *   These are intended for troubleshooting and should be used with caution.
 *
 *************************************************************************************************************************/

-- Set context
USE ROLE accountadmin;

-- Manually drop notification integration
-- DROP NOTIFICATION INTEGRATION IF EXISTS SFE_EMAIL_INTEGRATION;

-- Manually drop agents
-- DROP AGENT IF EXISTS SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_THE_SNOWMAN;

-- Manually drop schemas (only if verified no other demos use them)
-- DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.TOOLS;

/*************************************************************************************************************************
 * --- COMPLETE ACCOUNT CLEANUP (Caution!) ---
 *
 * Description:
 *   This section provides a complete cleanup script that removes all objects.
 *   Note: Per demo project standards, SNOWFLAKE_EXAMPLE database and shared
 *   schemas are preserved unless you have verified no other demos rely on them.
 *
 *************************************************************************************************************************/

-- Set context
USE ROLE accountadmin;

-- Drop notification integration
DROP NOTIFICATION INTEGRATION IF EXISTS SFE_EMAIL_INTEGRATION;

-- Modern deployments create the agent in the collision-proof project schema:
DROP AGENT IF EXISTS SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_THE_SNOWMAN;

-- Drop database schemas (ONLY after confirming no other demos use them)
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.TOOLS CASCADE;

-- Intentionally preserved: snowflake_documentation is shared across demos; do not drop

-- Final confirmation message
SELECT
    'All Sam-the-Snowman components have been removed. Shared infrastructure is preserved.' as message;

/*************************************************************************************************************************
 * --- Verification Queries ---
 *
 * Description:
 *   Use these queries to verify that all components have been removed.
 *
 *************************************************************************************************************************/

-- Set context
USE ROLE accountadmin;

-- Check for notification integration
SHOW NOTIFICATION INTEGRATIONS LIKE 'SFE_EMAIL_INTEGRATION';

-- Check for database schemas
SHOW SCHEMAS IN DATABASE SNOWFLAKE_EXAMPLE;

-- Check for the agent (will return no rows if removed)
SHOW AGENTS IN SCHEMA SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN;

-- Check for Cortex Search service
-- SHOW SERVICES IN SCHEMA SNOWFLAKE_EXAMPLE.TOOLS;

/*************************************************************************************************************************
 * --- Notes on Shared Resources ---
 *
 * Database (SNOWFLAKE_EXAMPLE):
 *   - Per demo project standards, the SNOWFLAKE_EXAMPLE database is NEVER dropped.
 *   - This database is shared across multiple demo/example projects.
 *   - Only schema-level objects specific to this demo are removed.
 *   - The database remains for audit trails and reuse by other demos.
 *
 * Shared schemas:
 *   - SNOWFLAKE_EXAMPLE.GIT_REPOS and SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS are shared across demos.
 *   - This teardown preserves those schemas and removes only Sam-the-Snowman objects.
 *
 * Notification Integration (SFE_EMAIL_INTEGRATION):
 *   - Uses the SFE_ prefix following demo project naming standards.
 *   - This is the name used in the setup script.
 *
 *************************************************************************************************************************/

/*************************************************************************************************************************
 * --- OBJECT OWNERSHIP SUMMARY ---
 *
 * This summary clarifies which roles own the created objects and are
 * therefore required to drop them. ACCOUNTADMIN can drop all objects.
 *
 * SYSADMIN (or configured role) owns:
 *   - SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN schema
 *   - SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO (Git repository clone)
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_* (semantic views)
 *   - SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_THE_SNOWMAN (agent)
 *   - SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAMS_DASHBOARD (Streamlit app)
 *   - SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SFE_SEND_EMAIL (procedure)
 *   - SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_SAM_* (Python analytics procedures)
 *
 * ACCOUNTADMIN owns:
 *   - SFE_EMAIL_INTEGRATION (Notification Integration)
 *   - SFE_SAM_SNOWMAN_WH (Warehouse)
 *   - SFE_GITHUB_API_INTEGRATION (API Integration)
 *
 *************************************************************************************************************************/

-- For additional verification, query SNOWFLAKE.INFORMATION_SCHEMA.OBJECTS or rerun
-- deploy_all.sql to rebuild the environment as needed.
