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
 *   - SNOWFLAKE_EXAMPLE database and functional schemas (DEPLOY, INTEGRATIONS, SEMANTIC_MODELS)
 *   - SNOWFLAKE_INTELLIGENCE database and AGENTS schema (required by Snowflake)
 *   - SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT (for agent visibility control)
 *   - Privilege grants to the configured role
 * 
 * OBJECTS CREATED:
 *   - SNOWFLAKE_EXAMPLE database
 *   - SNOWFLAKE_EXAMPLE.DEPLOY schema
 *   - SNOWFLAKE_EXAMPLE.INTEGRATIONS schema
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS schema (mandatory for Cortex Analyst semantic views)
 *   - SNOWFLAKE_INTELLIGENCE database (ownership transferred to configured role)
 *   - SNOWFLAKE_INTELLIGENCE.AGENTS schema
 *   - SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT (visibility control for agents)
 * 
 * Prerequisites:
 *   - Run deploy_all.sql (preferred) or ensure the Git repository stage already exists
 *   - ACCOUNTADMIN role privileges
 * 
 * Author: SE Community (inspired by Kaitlyn Wells @snowflake)
 * Created: 2025-11-25
 * Expires: 2025-12-25
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
COMMENT = 'DEMO: Demo/Example projects - NOT FOR PRODUCTION (Expires: 2025-12-25)';

-- Create functional schemas (organized by purpose)
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.DEPLOY
COMMENT = 'DEMO: Sam-the-Snowman - Deployment infrastructure (Git repositories, automation) (Expires: 2025-12-25)';

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.INTEGRATIONS
COMMENT = 'DEMO: Sam-the-Snowman - External system integrations (email, webhooks, APIs) (Expires: 2025-12-25)';

-- SEMANTIC_MODELS is the mandatory location for all Cortex Analyst semantic views
-- All semantic views must use SV_ prefix (e.g., SV_QUERY_PERFORMANCE)
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS
COMMENT = 'MANDATORY: All semantic views for Cortex Analyst agents (Expires: 2025-12-25)';

-- ============================================================================
-- CREATE/CONFIGURE SNOWFLAKE_INTELLIGENCE DATABASE
-- ============================================================================
-- Snowflake requires agents to live in SNOWFLAKE_INTELLIGENCE.AGENTS
-- This database may already exist (possibly owned by ACCOUNTADMIN)
-- We need to ensure it exists and is owned by the configured role

-- Check and create SNOWFLAKE_INTELLIGENCE database if it doesn't exist
-- This must be done as ACCOUNTADMIN initially
USE ROLE ACCOUNTADMIN;

CREATE DATABASE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE
COMMENT = 'Snowflake Intelligence - Required database for Snowflake agents';

-- Transfer ownership to the configured role for proper management
-- This ensures the configured role can create/manage agents without ACCOUNTADMIN
GRANT OWNERSHIP ON DATABASE SNOWFLAKE_INTELLIGENCE TO ROLE SYSADMIN COPY CURRENT GRANTS;

-- Switch to the configured role to create the schema
USE ROLE SYSADMIN;

-- Create AGENTS schema within SNOWFLAKE_INTELLIGENCE
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_INTELLIGENCE.AGENTS
COMMENT = 'DEMO: Sam-the-Snowman - Schema for Snowflake Intelligence agents (Expires: 2025-12-25)';

-- ============================================================================
-- CREATE SNOWFLAKE INTELLIGENCE OBJECT (Agent Visibility Control)
-- ============================================================================
-- The Snowflake Intelligence object controls which agents appear in the UI
-- Agents added to this object are visible via Tier 1 (curated list)
-- Agents in SNOWFLAKE_INTELLIGENCE.AGENTS are also visible via Tier 2 (fallback)

USE ROLE ACCOUNTADMIN;

CREATE SNOWFLAKE INTELLIGENCE IF NOT EXISTS SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
    COMMENT = 'Central object for managing agent visibility in Snowflake Intelligence UI (Expires: 2025-12-25)';

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
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.DEPLOY TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.INTEGRATIONS TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS TO ROLE SYSADMIN;

-- SEMANTIC_MODELS requires PUBLIC access for Cortex Analyst to function
-- Grant USAGE to PUBLIC so all users can query semantic views
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS TO ROLE PUBLIC;

-- Grant REFERENCES on all views in SEMANTIC_MODELS (required for Cortex Analyst)
GRANT REFERENCES ON ALL VIEWS IN SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS TO ROLE PUBLIC;
GRANT REFERENCES ON FUTURE VIEWS IN SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS TO ROLE PUBLIC;

-- Grant the configured role access to SNOWFLAKE_INTELLIGENCE
-- Agent access will be controlled through role membership
GRANT USAGE ON DATABASE SNOWFLAKE_INTELLIGENCE TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS TO ROLE SYSADMIN;

-- Grant agent creation privileges to the configured role
GRANT CREATE AGENT ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS TO ROLE SYSADMIN;

