/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * Script: deploy_all.sql - Complete Deployment Script
 *
 * WARNING: NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * EXPIRATION: 2026-03-19
 * This demo expires 30 days after creation. Deployment will be blocked after
 * the expiration date. Fork and customize for production use.
 * Last updated: 2026-02-17 (updatetheworld audit)
 *
 * PURPOSE:
 *   Single-script deployment of Sam-the-Snowman Cortex AI Agent.
 *   Leverages Snowflake native Git integration for automated deployment.
 *
 * USAGE IN SNOWSIGHT:
 *   1. Copy this ENTIRE script (Cmd/Ctrl+A, Cmd/Ctrl+C)
 *   2. Open Snowsight -> New Worksheet
 *   3. Paste the script (Cmd/Ctrl+V)
 *   4. Click "Run All" or press Cmd/Ctrl+Shift+Enter
 *   5. Wait ~3-5 minutes for complete deployment
 *   6. Navigate to AI & ML > Agents > Sam-the-Snowman to start using
 *
 * GIT REPOSITORY:
 *   (This script deploys modules by cloning this repository into `SNOWFLAKE_EXAMPLE.GIT_REPOS`.)
 *
 * WHAT GETS CREATED:
 *   Account-Level Objects (requires ACCOUNTADMIN):
 *   - SFE_GITHUB_API_INTEGRATION (API Integration for GitHub access)
 *   - SFE_SAM_SNOWMAN_WH (Dedicated demo warehouse, X-Small, auto-suspend 60s)
 *   - SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT (Agent visibility control)
 *
 *   Database Objects:
 *   - SNOWFLAKE_EXAMPLE database (shared demo database)
 *   - SNOWFLAKE_EXAMPLE.GIT_REPOS schema (shared Git repository clones)
 *   - SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO (Git repository clone)
 *   - SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN schema (project schema)
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS schema (shared semantic views)
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_* (3 semantic views)
 *   - Email notification integration + stored procedure (optional)
 *   - Snowflake Documentation (from Marketplace)
 *   - Sam-the-Snowman Cortex AI Agent with tools:
 *     - Query performance analysis
 *     - Cost tracking and optimization
 *     - Warehouse utilization monitoring
 *     - Email notifications
 *     - Snowflake documentation search
 *
 * DEPLOYMENT TIME:
 *   ~3-5 minutes depending on account region and Marketplace installation
 *
 * PREREQUISITES:
 *   - ACCOUNTADMIN role access
 *   - Network access to GitHub
 *   - Email integration configured (optional, for notifications)
 *
 * SAFE TO RE-RUN:
 *   Yes. All statements use OR REPLACE or IF NOT EXISTS patterns.
 *   Re-running updates the agent and semantic views to latest version.
 *
 * TROUBLESHOOTING:
 *   Error: "Warehouse must be specified"
 *   -> The script creates `SFE_SAM_SNOWMAN_WH`. Resume it (`ALTER WAREHOUSE SFE_SAM_SNOWMAN_WH RESUME;`) and rerun this script.
 *
 *   Error: "Insufficient privileges to operate on database SNOWFLAKE_EXAMPLE"
 *   -> Ensure you're using: USE ROLE ACCOUNTADMIN;
 *
 *   Error: "Failed to connect to GitHub"
 *   -> Check network policies allow https://github.com/
 *   -> Verify API integration: SHOW INTEGRATIONS LIKE 'SFE_GITHUB_API_INTEGRATION';
 *
 *   Error: "Object does not exist, or operation cannot be performed"
 *   -> Repository fetch failed. Check: SHOW GIT REPOSITORIES IN DATABASE SNOWFLAKE_EXAMPLE;
 *   -> Re-run fetch: ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO FETCH;
 *
 *   Agent not visible after deployment:
 *   -> Run validation: EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/06_validation.sql';
 *   -> Check: SHOW AGENTS IN SCHEMA SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN;
 *
 * CLEANUP:
 *   To remove all objects: See sql/99_cleanup/teardown_all.sql
 *
 * Author: SE Community
 * Created: 2025-11-25
 * Expires: 2026-03-19
 * Version: 8.0
 * License: Apache 2.0
 ******************************************************************************/

-- ============================================================================
-- EXPIRATION CHECK (MANDATORY)
-- ============================================================================
-- This demo expires 30 days after creation.
-- If expired, deployment is blocked. Fork and update the expiration date in deploy_all.sql.
DECLARE
  demo_expired EXCEPTION (-20001, 'DEMO EXPIRED: Do not deploy. Fork the repository and update the expiration date in deploy_all.sql.');
BEGIN
  IF (CURRENT_DATE() > '2026-03-19'::DATE) THEN
    RAISE demo_expired;
  END IF;
END;

-- ============================================================================
-- DEPLOYMENT ORCHESTRATION
-- ============================================================================

-- ============================================================================
-- ROLE / OWNERSHIP NOTES
-- ============================================================================
-- NOTE: This demo deploys objects owned by SYSADMIN (except account-level objects
-- created by ACCOUNTADMIN). To use a different owning role, fork and update:
-- - this file (`deploy_all.sql`)
-- - the SQL modules in `sql/`

-- ============================================================================
-- PHASE 1: INFRASTRUCTURE SETUP (Database, Schema, API Integration, Git Repo)
-- ============================================================================

-- Start with deployment role for database and schema creation
USE ROLE SYSADMIN;

-- Create shared demo database and deployment schema (reusable across demo assets)
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
    COMMENT = 'DEMO: Sam-the-Snowman - Shared demo database (Expires: 2026-03-19)';

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.GIT_REPOS
    COMMENT = 'DEMO: Shared Git repository clones for demo deployments (Expires: 2026-03-19)';

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN
    COMMENT = 'DEMO: Sam-the-Snowman - Project schema (Expires: 2026-03-19)';

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS
    COMMENT = 'MANDATORY: All semantic views for Cortex Analyst agents (Expires: 2026-03-19)';

-- Elevate privilege for account-level objects (warehouse, integrations)
USE ROLE ACCOUNTADMIN;

-- Create dedicated demo warehouse (idempotent)
CREATE OR REPLACE WAREHOUSE SFE_SAM_SNOWMAN_WH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'DEMO: Sam-the-Snowman - Dedicated warehouse for deployment and runtime (Expires: 2026-03-19)';

GRANT USAGE ON WAREHOUSE SFE_SAM_SNOWMAN_WH TO ROLE SYSADMIN;
GRANT OPERATE ON WAREHOUSE SFE_SAM_SNOWMAN_WH TO ROLE SYSADMIN;

-- Create account-wide Git API integration (safe to rerun; reused by all demo projects)
CREATE OR REPLACE API INTEGRATION SFE_GITHUB_API_INTEGRATION
    API_PROVIDER = git_https_api
    ENABLED = TRUE
    API_ALLOWED_PREFIXES = ('https://github.com/')
    COMMENT = 'DEMO: GitHub integration for Git-based deployments (Expires: 2026-03-19)';

-- Grant usage to deployment role
GRANT USAGE ON INTEGRATION SFE_GITHUB_API_INTEGRATION TO ROLE SYSADMIN;

-- Enable Cortex AI features (required for agent creation)
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE SYSADMIN;

-- Return to deployment role for Git repository creation
USE ROLE SYSADMIN;
USE WAREHOUSE SFE_SAM_SNOWMAN_WH;

-- Create Git repository stage (central source for all deployment modules)
CREATE OR REPLACE GIT REPOSITORY SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO
    API_INTEGRATION = SFE_GITHUB_API_INTEGRATION
    ORIGIN = 'https://github.com/sfc-gh-miwhitaker/Sam-the-Snowman.git'
    COMMENT = 'DEMO: Sam-the-Snowman - Git repository for modular SQL execution (Expires: 2026-03-19)';

-- Fetch the latest commit from the main branch
ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO FETCH;

-- ============================================================================
-- PHASE 2: MODULE EXECUTION FROM GIT REPOSITORY STAGE
-- ============================================================================

-- Ensure ACCOUNTADMIN role is active for all module deployments
-- (Some modules require elevated privileges for integrations and marketplace)
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE SFE_SAM_SNOWMAN_WH;

-- Module 1: Scaffolding
-- Creates shared schemas, Snowflake Intelligence object, and grants privileges
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/01_scaffolding.sql';

-- Module 2: Email Integration
-- Sets up notification integration and email delivery stored procedure
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/02_email_integration.sql';

-- Module 3: Semantic Models (YAML-based deployment)
-- Deploys semantic views from YAML files with full feature support:
-- TIME_DIMENSIONS, FILTERS, VERIFIED_QUERIES, sample_values, custom_instructions
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/03_deploy_semantic_models.sql';

-- Module 3c: Python Analytics Tools
-- Deploys advanced analytics procedures (anomaly detection, efficiency scoring, trends)
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/03c_python_analytics_tool.sql';

-- Module 4: Marketplace Documentation
-- Installs Snowflake Documentation database for Cortex Search integration
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/04_marketplace.sql';

-- Module 5: Agent Creation
-- Creates the Sam-the-Snowman Cortex AI agent with all tools configured
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/05_agent.sql';

-- Module 6: Validation (optional)
-- Tip: Run this module manually after deployment for detailed SHOW output:
-- EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/06_validation.sql';

-- Module 7: Testing Framework
-- Deploys automated testing for semantic views and Python procedures
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/07_testing.sql';

-- Module 8: Sam's Analytics Dashboard
-- Deploys Streamlit in Snowflake app for visual analytics companion
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/08_dashboard.sql';

-- ============================================================================
-- DEPLOYMENT COMPLETE
-- ============================================================================

SELECT
  'DEPLOYMENT COMPLETE' AS status,
  CURRENT_TIMESTAMP() AS completed_at,
  'AI & ML > Agents > Sam-the-Snowman' AS agent_location,
  'Projects > Streamlit > SAMS_DASHBOARD' AS dashboard_location,
  'Example question: What were my top 10 slowest queries today?' AS example_question,
  'Run tests: CALL SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_RUN_TESTS()' AS test_command;
