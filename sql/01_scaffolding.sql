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
 * 
 * Prerequisites:
 *   - Run 00_config.sql first to ensure the Git repository stage exists
 *   - ACCOUNTADMIN role privileges
 * 
 * Author: M. Whitaker (inspired by Kaitlyn Wells @snowflake)
 * Modified: 2025-11-14
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
GRANT OWNERSHIP ON DATABASE SNOWFLAKE_INTELLIGENCE TO ROLE SYSADMIN COPY CURRENT GRANTS;

-- Switch to the configured role to create the schema
USE ROLE SYSADMIN;

-- Create AGENTS schema within SNOWFLAKE_INTELLIGENCE
CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_INTELLIGENCE.AGENTS
COMMENT = 'DEMO: Sam-the-Snowman - Schema for Snowflake Intelligence agents';

-- ============================================================================
-- GRANT PRIVILEGES
-- ============================================================================

-- Grant the configured role access to SNOWFLAKE_EXAMPLE functional schemas
-- These are intentionally not granted to PUBLIC - users must be granted the configured role
GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.DEPLOY TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.INTEGRATIONS TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC TO ROLE SYSADMIN;

-- Grant the configured role access to SNOWFLAKE_INTELLIGENCE
-- Agent access will be controlled through role membership
GRANT USAGE ON DATABASE SNOWFLAKE_INTELLIGENCE TO ROLE SYSADMIN;
GRANT USAGE ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS TO ROLE SYSADMIN;

-- Grant agent creation privileges to the configured role
GRANT CREATE AGENT ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS TO ROLE SYSADMIN;

