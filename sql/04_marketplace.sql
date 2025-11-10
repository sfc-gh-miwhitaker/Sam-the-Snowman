/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * Module: 04_marketplace.sql
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * 
 * Synopsis:
 *   Installs Snowflake Documentation from the Marketplace for Cortex Search.
 * 
 * Description:
 *   This module imports the Snowflake Documentation marketplace listing
 *   to enable the agent to search official Snowflake documentation for
 *   best practices, feature explanations, and how-to guides.
 * 
 * OBJECTS CREATED:
 *   - snowflake_documentation (Database - Marketplace listing)
 * 
 * Prerequisites:
 *   - 00_config.sql and 01_scaffolding.sql must be run first
 *   - ACCOUNTADMIN role privileges
 *   - Network access to Snowflake Marketplace
 *   - Ability to accept legal terms for marketplace listings
 * 
 * Author: M. Whitaker (inspired by Kaitlyn Wells @snowflake)
 * Modified: 2025-11-07
 * Version: 3.1
 * License: Apache 2.0
 * 
 * Usage:
 *   This module is called by deploy_all.sql or can be run standalone
 *   after setting configuration variables and creating scaffolding.
 ******************************************************************************/

-- ============================================================================
-- INSTALL SNOWFLAKE DOCUMENTATION FROM MARKETPLACE
-- ============================================================================

-- Switch to ACCOUNTADMIN for marketplace operations
USE ROLE ACCOUNTADMIN;

-- Accept legal terms for Snowflake Documentation marketplace listing
CALL SYSTEM$ACCEPT_LEGAL_TERMS('DATA_EXCHANGE_LISTING', 'GZSTZ67BY9OQ4');

-- Import Snowflake Documentation database from Marketplace
CREATE OR REPLACE DATABASE snowflake_documentation
    FROM LISTING IDENTIFIER('"GZSTZ67BY9OQ4"')
    COMMENT = 'DEMO: Sam-the-Snowman - Snowflake Documentation from the Marketplace.';

-- Grant configured role access to Snowflake Documentation
-- This restricts documentation access to only users with the configured role
GRANT IMPORTED PRIVILEGES ON DATABASE snowflake_documentation TO ROLE identifier($role_name);

UPDATE SNOWFLAKE_EXAMPLE.PUBLIC.deployment_log SET status = 'PASS' WHERE component = 'database.snowflake_documentation';

-- Marketplace installation complete

