/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * File: sql/99_cleanup/teardown_all.sql
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
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
 *   - SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman (Agent)
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS semantic views (SV_SAM_QUERY_PERFORMANCE, SV_SAM_COST_ANALYSIS, SV_SAM_WAREHOUSE_OPERATIONS)
 *   - SNOWFLAKE_EXAMPLE.INTEGRATIONS.sfe_send_email procedure
 *   - SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO (Git repository)
 *   - SNOWFLAKE_EXAMPLE.DEPLOY schema
 *   - SNOWFLAKE_EXAMPLE.INTEGRATIONS schema
 *   - Schemas: SNOWFLAKE_EXAMPLE.DEPLOY, SNOWFLAKE_EXAMPLE.INTEGRATIONS
 *
 * OBJECTS PRESERVED:
 *   - SNOWFLAKE_INTELLIGENCE.AGENTS schema (required by Snowflake)
 *   - snowflake_documentation database (shared marketplace resource used by multiple projects)
 *   - SNOWFLAKE_EXAMPLE (Database) - Shared demo database
 *   - SFE_GITHUB_API_INTEGRATION - Reusable across projects
 * 
 * Prerequisites:
 *   - ACCOUNTADMIN role privileges
 *   - Sam-the-Snowman previously deployed via `deploy_all.sql`
 * 
 * Author: SE Community (inspired by Kaitlyn Wells @snowflake)
 * Created: 2025-11-25
 * Expires: 2025-12-25
 * Version: 4.0
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
--   ❌ DO NOT DROP: SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
--      (Account-level agent visibility control - used by ALL agents)
--
--   ❌ DO NOT DROP: SFE_GITHUB_API_INTEGRATION  
--      (Reusable GitHub integration - used by multiple repos)
--
--   ❌ DO NOT DROP: SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS schema
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
--     DROP AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman;

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
-- Note: Agents are schema-level objects in SNOWFLAKE_INTELLIGENCE.AGENTS
-- It is safe to drop an agent - it does not affect any underlying data
-- Re-running the setup script will recreate the agent

DROP AGENT IF EXISTS SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman;

-- Remove semantic views from SEMANTIC_MODELS (explicit drops for clarity)
DROP SEMANTIC VIEW IF EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_QUERY_PERFORMANCE;
DROP SEMANTIC VIEW IF EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_COST_ANALYSIS;
DROP SEMANTIC VIEW IF EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_WAREHOUSE_OPERATIONS;

-- ============================================================================
-- REMOVE SCHEMAS (After all objects dropped)
-- ============================================================================

-- Drop the functional schemas created by Sam-the-Snowman
-- Note: SEMANTIC_MODELS is a shared schema, only drop Sam-specific views (done above)
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.DEPLOY CASCADE;
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.INTEGRATIONS CASCADE;
-- Note: DO NOT drop SEMANTIC_MODELS schema (shared across projects, only drop views)

-- ============================================================================
-- LEGACY CLEANUP (For older deployments)
-- ============================================================================

DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.tools CASCADE;

-- ============================================================================
-- PRESERVATION NOTES
-- ============================================================================

-- Objects intentionally preserved:
-- - SNOWFLAKE_INTELLIGENCE.AGENTS: Required by Snowflake for agents, may be used by other agents
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
-- DROP AGENT IF EXISTS SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman;

-- Manually drop schemas (only if verified no other demos use them)
-- DROP SCHEMA IF EXISTS SNOWFLAKE_INTELLIGENCE.AGENTS;
-- DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.tools;

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

DROP AGENT IF EXISTS SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman;

-- Drop database schemas (ONLY after confirming no other demos use them)
-- DROP SCHEMA IF EXISTS SNOWFLAKE_INTELLIGENCE.AGENTS CASCADE;
DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.tools CASCADE;

-- Intentionally preserved: snowflake_documentation is shared across demos; do not drop

-- Final confirmation message
SELECT 
    'All Sam-the-Snowman components have been removed. SNOWFLAKE_EXAMPLE and SNOWFLAKE_INTELLIGENCE databases preserved.' as message;

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
SHOW SCHEMAS IN DATABASE SNOWFLAKE_INTELLIGENCE;

-- Check for agents in SNOWFLAKE_INTELLIGENCE
-- Note: This will fail if the database/schemas no longer exist
SHOW AGENTS IN SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS;

-- Check for Cortex Search service
-- SHOW SERVICES IN SCHEMA SNOWFLAKE_EXAMPLE.tools;

/*************************************************************************************************************************
 * --- Notes on Shared Resources ---
 *
 * Database (SNOWFLAKE_EXAMPLE):
 *   - Per demo project standards, the SNOWFLAKE_EXAMPLE database is NEVER dropped.
 *   - This database is shared across multiple demo/example projects.
 *   - Only schema-level objects (DEPLOY, INTEGRATIONS, SEMANTIC) are removed.
 *   - The database remains for audit trails and reuse by other demos.
 *
 * Database (SNOWFLAKE_INTELLIGENCE):
 *   - Required by Snowflake for hosting agents in SNOWFLAKE_INTELLIGENCE.AGENTS.
 *   - This database is NEVER dropped as it may contain other agents.
 *   - Only the sam_the_snowman agent is removed.
 *
 * Schemas (SNOWFLAKE_INTELLIGENCE.AGENTS, SNOWFLAKE_EXAMPLE.DEPLOY/INTEGRATIONS/SEMANTIC):
 *   - These schemas are SHARED across demo projects and other agents.
 *   - The default teardown preserves the schemas and removes only Sam-the-Snowman objects.
 *   - Drop the schemas ONLY after confirming no other demos or agents rely on them.
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
 *   - SNOWFLAKE_INTELLIGENCE database (ownership transferred from ACCOUNTADMIN)
 *   - SNOWFLAKE_INTELLIGENCE.AGENTS schema
 *   - SNOWFLAKE_EXAMPLE.DEPLOY, SNOWFLAKE_EXAMPLE.INTEGRATIONS schemas
 *   - All semantic views (sfe_query_performance, sfe_cost_analysis, sfe_warehouse_operations)
 *   - Agent sam_the_snowman in SNOWFLAKE_INTELLIGENCE.AGENTS
 *
 * ACCOUNTADMIN owns:
 *   - SFE_EMAIL_INTEGRATION (Notification Integration)
 *
 * SYSADMIN (or configured role) has USAGE on:
 *   - SNOWFLAKE_EXAMPLE database and functional schemas
 *   - SNOWFLAKE_INTELLIGENCE database and AGENTS schema
 *   - Agent sam_the_snowman
 *
 *************************************************************************************************************************/

-- For additional verification, query SNOWFLAKE.INFORMATION_SCHEMA.OBJECTS or rerun
-- deploy_all.sql to rebuild the environment as needed.

