/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * Module: 01_scaffolding.sql
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * Synopsis:
 *   Creates databases, schemas, and grants privileges for Sam-the-Snowman.
 *
 * Description:
 *   This module creates the required database and schema infrastructure:
 *   - SNOWFLAKE_EXAMPLE database and schemas:
 *     - SEMANTIC_MODELS (shared location for semantic views)
 *     - GIT_REPOS (shared location for Snowflake Git repository clones)
 *     - SAM_THE_SNOWMAN (project schema for procedures and optional helper objects)
 *   - SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT (for agent visibility control)
 *   - Privilege grants to the configured role
 *
 * OBJECTS CREATED:
 *   - SNOWFLAKE_EXAMPLE database
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS schema (shared for semantic views)
 *   - SNOWFLAKE_EXAMPLE.GIT_REPOS schema (shared for Git repository clones)
 *   - SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN schema (project schema)
 *   - SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT (visibility control for agents)
 *
 * Prerequisites:
 *   - Run deploy_all.sql (preferred) or ensure the Git repository stage already exists
 *   - ACCOUNTADMIN role privileges
 *
 * Author: SE Community
 * Created: 2025-11-25
 * Expires: 2026-01-15
 * Version: 4.0
 * License: Apache 2.0
 *
 * Usage:
 *   This module is called by deploy_all.sql or can be run standalone
 *   after setting configuration variables.
 ******************************************************************************/

-- ============================================================================
-- CREATE SNOWFLAKE_EXAMPLE DATABASE AND SCHEMA
-- ============================================================================

USE ROLE SYSADMIN;
USE WAREHOUSE SFE_SAM_SNOWMAN_WH;

-- Create the demo database (mandatory for all demo projects)
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
COMMENT = 'DEMO: Demo/Example projects - NOT FOR PRODUCTION (Expires: 2026-01-15)';

-- Shared schema for Snowflake Git repository clones (shared across demos).
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.GIT_REPOS
COMMENT = 'DEMO: Shared Git repository clones for demo deployments (Expires: 2026-01-15)';

-- Project schema (collision-proof) for Sam-the-Snowman objects that are not semantic views.
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN
COMMENT = 'DEMO: Sam-the-Snowman - Project schema (Expires: 2026-01-15)';

-- SEMANTIC_MODELS is the mandatory location for all Cortex Analyst semantic views
-- All semantic views must use SV_ prefix (e.g., SV_QUERY_PERFORMANCE)
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS
COMMENT = 'MANDATORY: All semantic views for Cortex Analyst agents (Expires: 2026-01-15)';

-- ============================================================================
-- CREATE SNOWFLAKE INTELLIGENCE OBJECT (Agent Visibility Control)
-- ============================================================================
-- The Snowflake Intelligence object controls which agents appear in the UI
-- Agents added to this object are visible via Tier 1 (curated list)
-- If the Snowflake Intelligence object exists but contains zero agents, Snowflake can fall back to other
-- discovery logic. For the curated experience, add agents to this object.

USE ROLE ACCOUNTADMIN;

-- CREATE SNOWFLAKE INTELLIGENCE does not currently support IF NOT EXISTS.
-- Make creation idempotent by swallowing the "already exists" error.
BEGIN
  CREATE SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT;
EXCEPTION
  WHEN OTHER THEN
    IF (CONTAINS(SQLERRM, 'already exists')) THEN
      -- No-op: object already exists.
      NULL;
    ELSE
      RAISE;
    END IF;
END;

-- Grant visibility to all users (they can see agents in the UI)
GRANT USAGE ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE PUBLIC;

-- Grant management to SYSADMIN (can add/remove agents)
-- Note: MODIFY privilege allows adding/removing agents from the object
GRANT MODIFY ON SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT TO ROLE SYSADMIN;

USE ROLE SYSADMIN;

-- ============================================================================
-- GRANT PRIVILEGES
-- ============================================================================

-- Grant the configured role access to SNOWFLAKE_EXAMPLE functional schemas
-- These are intentionally not granted to PUBLIC - users must be granted the configured role
GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.GIT_REPOS TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS TO ROLE SYSADMIN;

-- Cortex Analyst requires REFERENCES and SELECT on the semantic view for the role used by the caller.
-- For the demo default, grant to SYSADMIN only (no PUBLIC data access).
GRANT REFERENCES, SELECT ON ALL SEMANTIC VIEWS IN SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS TO ROLE SYSADMIN;
GRANT REFERENCES, SELECT ON FUTURE SEMANTIC VIEWS IN SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS TO ROLE SYSADMIN;

-- Grant agent creation privileges to the configured role in the project schema.
GRANT CREATE AGENT ON SCHEMA SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN TO ROLE SYSADMIN;
