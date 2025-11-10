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
 *   This script removes all resources created by `deploy_all.sql` (and the modules in `sql/00_config.sql` … `sql/06_validation.sql`) following
 *   demo project standards. The SNOWFLAKE_EXAMPLE database is preserved per
 *   demo standards (shared across demos for audit/reuse). Only schema-level
 *   objects specific to Sam-the-Snowman are removed.
 * 
 * OBJECTS REMOVED:
 *   - SFE_EMAIL_INTEGRATION (Notification Integration)
 *   - SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman (Agent)
 *   - SNOWFLAKE_EXAMPLE.tools semantic views (query_performance, cost_analysis, warehouse_operations)
 *   - SNOWFLAKE_EXAMPLE.tools.send_email procedure
 *   - SNOWFLAKE_EXAMPLE.tools.SAM_THE_SNOWMAN_REPO (Git repository)
 *
 * OBJECTS PRESERVED:
 *   - SNOWFLAKE_INTELLIGENCE.AGENTS schema (required by Snowflake)
 *   - SNOWFLAKE_EXAMPLE.tools schema (shared across demos)
 *   - snowflake_documentation database (shared marketplace resource used by multiple projects)
 *   - SNOWFLAKE_EXAMPLE (Database) - Shared demo database
 * 
 * Prerequisites:
 *   - ACCOUNTADMIN role privileges
 *   - Sam-the-Snowman previously deployed via `deploy_all.sql`
 *
 * Usage:
 *   Execute this entire script as ACCOUNTADMIN. Safe to run multiple times.
 *
* Author: M. Whitaker (inspired by Kaitlyn Wells @snowflake)
* Modified: 2025-11-07
* Version: 3.1
 * License: Apache 2.0
 *
 * Idempotency:
 *   This script is idempotent and can be run multiple times without errors.
 *
 ******************************************************************************/

-- Set context
USE ROLE accountadmin;

-- Drop notification integration
DROP NOTIFICATION INTEGRATION IF EXISTS SFE_EMAIL_INTEGRATION;

DROP GIT REPOSITORY IF EXISTS SNOWFLAKE_EXAMPLE.tools.sam_the_snowman_repo;

-- Remove the semantic views
DROP SEMANTIC VIEW IF EXISTS SNOWFLAKE_EXAMPLE.tools.query_performance;
DROP SEMANTIC VIEW IF EXISTS SNOWFLAKE_EXAMPLE.tools.cost_analysis;
DROP SEMANTIC VIEW IF EXISTS SNOWFLAKE_EXAMPLE.tools.warehouse_operations;

-- Remove the stored procedure
DROP PROCEDURE IF EXISTS SNOWFLAKE_EXAMPLE.tools.send_email(VARCHAR, VARCHAR, VARCHAR);

-- Remove the Sam-the-Snowman agent
-- Note: Agents are schema-level objects in SNOWFLAKE_INTELLIGENCE.AGENTS
-- It is safe to drop an agent - it does not affect any underlying data
-- Re-running the setup script will recreate the agent

DROP AGENT IF EXISTS SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman;

-- Schemas and databases intentionally preserved:
-- - SNOWFLAKE_INTELLIGENCE.AGENTS: Required by Snowflake for agents, may be used by other agents
-- - SNOWFLAKE_EXAMPLE.tools: Shared across demo projects
-- Use optional troubleshooting or full cleanup steps below ONLY after confirming
-- no other objects depend on these schemas.

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
 *   - Only schema-level objects (tools) are removed.
 *   - The database remains for audit trails and reuse by other demos.
 *
 * Database (SNOWFLAKE_INTELLIGENCE):
 *   - Required by Snowflake for hosting agents in SNOWFLAKE_INTELLIGENCE.AGENTS.
 *   - This database is NEVER dropped as it may contain other agents.
 *   - Only the sam_the_snowman agent is removed.
 *
 * Schemas (SNOWFLAKE_INTELLIGENCE.AGENTS, SNOWFLAKE_EXAMPLE.tools):
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
 *   - SNOWFLAKE_EXAMPLE.tools schema
 *   - All semantic views (query_performance, cost_analysis, warehouse_operations)
 *   - Agent sam_the_snowman in SNOWFLAKE_INTELLIGENCE.AGENTS
 *
 * ACCOUNTADMIN owns:
 *   - SFE_EMAIL_INTEGRATION (Notification Integration)
 *
 * SYSADMIN (or configured role) has USAGE on:
 *   - SNOWFLAKE_EXAMPLE database and tools schema
 *   - SNOWFLAKE_INTELLIGENCE database and AGENTS schema
 *   - Agent sam_the_snowman
 *
 *************************************************************************************************************************/

-- Final check for any remaining objects in the schemas
-- This should return only non-Sam-the-Snowman objects if cleanup was successful
SHOW OBJECTS IN SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS;
SHOW OBJECTS IN SCHEMA SNOWFLAKE_EXAMPLE.tools;

