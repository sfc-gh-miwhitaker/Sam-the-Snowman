/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * Module: 04_marketplace.sql
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * PURPOSE:
 *   Install the Snowflake Documentation listing used by Cortex Search.
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
 *   - 01_scaffolding.sql must be run first (deploy_all.sql handles this automatically)
 *   - ACCOUNTADMIN role privileges
 *   - Network access to Snowflake Marketplace
 *   - Ability to accept legal terms for marketplace listings
 *
 * Author: SE Community
 * Created: 2025-11-25
 * Expires: 2026-03-19
 * Version: 4.0
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
USE WAREHOUSE SFE_SAM_SNOWMAN_WH;

-- Accept legal terms for Snowflake Documentation marketplace listing
CALL SYSTEM$ACCEPT_LEGAL_TERMS('DATA_EXCHANGE_LISTING', 'GZSTZ67BY9OQ4');

-- Import Snowflake Documentation database from Marketplace
CREATE OR REPLACE DATABASE snowflake_documentation
    FROM LISTING 'GZSTZ67BY9OQ4'
    COMMENT = 'DEMO: Sam-the-Snowman - Snowflake Documentation from the Marketplace. (Expires: 2026-03-19)';

-- Grant configured role access to Snowflake Documentation
-- This restricts documentation access to only users with the configured role
GRANT IMPORTED PRIVILEGES ON DATABASE snowflake_documentation TO ROLE SYSADMIN;

-- Marketplace installation complete
