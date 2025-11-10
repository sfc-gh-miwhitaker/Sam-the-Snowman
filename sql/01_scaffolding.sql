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
 *   - SNOWFLAKE_EXAMPLE database and functional schemas (DEPLOY, INTEGRATIONS, SEMANTIC)
 *   - SNOWFLAKE_INTELLIGENCE database and AGENTS schema (required by Snowflake)
 *   - Privilege grants to the configured role
 *   - Deployment logging infrastructure
 * 
 * OBJECTS CREATED:
 *   - SNOWFLAKE_EXAMPLE database
 *   - SNOWFLAKE_EXAMPLE.DEPLOY schema
 *   - SNOWFLAKE_EXAMPLE.INTEGRATIONS schema
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC schema
 *   - SNOWFLAKE_INTELLIGENCE database (ownership transferred to configured role)
 *   - SNOWFLAKE_INTELLIGENCE.AGENTS schema
 *   - Temporary deployment_log table
 * 
 * Prerequisites:
 *   - Run 00_config.sql first to ensure the Git repository stage exists
 *   - Execute from a session where deploy_all.sql has set session variables (role_name, git repo identifiers)
 *   - ACCOUNTADMIN role privileges
 * 
 * Author: M. Whitaker (inspired by Kaitlyn Wells @snowflake)
 * Modified: 2025-11-07
 * Version: 3.1
 * License: Apache 2.0
 * 
 * Usage:
 *   This module is called by deploy_all.sql or can be run standalone
 *   after setting configuration variables.
 ******************************************************************************/

-- ============================================================================
-- CREATE SNOWFLAKE_EXAMPLE DATABASE AND SCHEMA
-- ============================================================================

USE ROLE identifier($role_name);

-- Create the demo database (mandatory for all demo projects)
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
COMMENT = 'DEMO: Demo/Example projects - NOT FOR PRODUCTION';

-- Create functional schemas (organized by purpose)
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.DEPLOY
COMMENT = 'DEMO: Sam-the-Snowman - Deployment infrastructure (Git repositories, automation)';

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.INTEGRATIONS
COMMENT = 'DEMO: Sam-the-Snowman - External system integrations (email, webhooks, APIs)';

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC
COMMENT = 'DEMO: Sam-the-Snowman - Semantic views for agent tools and analytics';

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
GRANT OWNERSHIP ON DATABASE SNOWFLAKE_INTELLIGENCE TO ROLE identifier($role_name) COPY CURRENT GRANTS;

-- Switch to the configured role to create the schema
USE ROLE identifier($role_name);

-- Create AGENTS schema within SNOWFLAKE_INTELLIGENCE
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_INTELLIGENCE.AGENTS
COMMENT = 'DEMO: Sam-the-Snowman - Schema for Snowflake Intelligence agents';

-- ============================================================================
-- GRANT PRIVILEGES
-- ============================================================================

-- Grant the configured role access to SNOWFLAKE_EXAMPLE functional schemas
-- These are intentionally not granted to PUBLIC - users must be granted the configured role
GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE identifier($role_name);
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.DEPLOY TO ROLE identifier($role_name);
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.INTEGRATIONS TO ROLE identifier($role_name);
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC TO ROLE identifier($role_name);

-- Grant the configured role access to SNOWFLAKE_INTELLIGENCE
-- Agent access will be controlled through role membership
GRANT USAGE ON DATABASE SNOWFLAKE_INTELLIGENCE TO ROLE identifier($role_name);
GRANT USAGE ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS TO ROLE identifier($role_name);

-- Grant agent creation privileges to the configured role
GRANT CREATE AGENT ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS TO ROLE identifier($role_name);

-- ============================================================================
-- INITIALIZE DEPLOYMENT LOG
-- ============================================================================

USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA PUBLIC;

CREATE OR REPLACE TEMP TABLE deployment_log(component STRING, status STRING);
INSERT INTO deployment_log (component, status) VALUES
    ('agent.sam_the_snowman', 'MISSING'),
    ('integration.sfe_email_integration', 'MISSING'),
    (CONCAT('integration.', LOWER($git_api_integration_name)), 'MISSING'),
    (CONCAT('git_repository.', LOWER($git_repo_name)), 'MISSING'),
    ('procedure.send_email', 'MISSING'),
    ('semantic_view.cost_analysis', 'MISSING'),
    ('semantic_view.query_performance', 'MISSING'),
    ('semantic_view.warehouse_operations', 'MISSING'),
    ('database.snowflake_documentation', 'PRESERVED');

-- Mark Git integration and repository as deployed (created in deploy_all.sql)
EXECUTE IMMEDIATE
    'UPDATE SNOWFLAKE_EXAMPLE.PUBLIC.deployment_log SET status = ''PASS'' WHERE component = ''integration.' || LOWER($git_api_integration_name) || '''';

EXECUTE IMMEDIATE
    'UPDATE SNOWFLAKE_EXAMPLE.PUBLIC.deployment_log SET status = ''PASS'' WHERE component = ''git_repository.' || LOWER($git_repo_name) || '''';

-- Scaffolding complete

