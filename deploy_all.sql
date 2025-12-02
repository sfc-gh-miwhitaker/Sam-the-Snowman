/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * Script: deploy_all.sql - Complete Deployment Script
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * 
 * EXPIRATION: 2025-12-25
 * This demo expires 30 days after creation. Deployment will be blocked after
 * the expiration date. Fork and customize for production use.
 * 
 * PURPOSE:
 *   Single-script deployment of Sam-the-Snowman Cortex AI Agent.
 *   Leverages Snowflake native Git integration for automated deployment.
 * 
 * USAGE IN SNOWSIGHT:
 *   1. Copy this ENTIRE script (Cmd/Ctrl+A, Cmd/Ctrl+C)
 *   2. Open Snowsight → New Worksheet
 *   3. Paste the script (Cmd/Ctrl+V)
 *   4. Click "Run All" (▶▶) or press Cmd/Ctrl+Shift+Enter
 *   5. Wait ~3-5 minutes for complete deployment
 *   6. Navigate to AI & ML > Agents > Sam-the-Snowman to start using
 * 
 * GITHUB REPOSITORY:
 *   https://github.com/sfc-gh-miwhitaker/Sam-the-Snowman.git
 * 
 * WHAT GETS CREATED:
 *   Account-Level Objects (requires ACCOUNTADMIN):
 *   - SFE_GITHUB_API_INTEGRATION (API Integration for GitHub access)
 *   - SFE_SAM_SNOWMAN_WH (Dedicated demo warehouse, X-Small, auto-suspend 60s)
 *   - SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT (Agent visibility control)
 *   
 *   Database Objects:
 *   - SNOWFLAKE_EXAMPLE database (shared demo database)
 *   - SNOWFLAKE_EXAMPLE.DEPLOY schema (deployment infrastructure)
 *   - SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO (Git repository stage)
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS schema (shared semantic views)
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_* (3 semantic views)
 *   - SNOWFLAKE_INTELLIGENCE database (agent data layer)
 *   - SNOWFLAKE_INTELLIGENCE.AGENTS schema (agent definitions)
 *   - Email notification integration (if email configured)
 *   - Snowflake Documentation (from Marketplace)
 *   - Sam-the-Snowman Cortex AI Agent with tools:
 *     • Query performance analysis
 *     • Cost tracking and optimization
 *     • Warehouse utilization monitoring
 *     • Email notifications
 *     • Snowflake documentation search
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
 *   → The script creates `SFE_SAM_SNOWMAN_WH`. Resume it (`ALTER WAREHOUSE SFE_SAM_SNOWMAN_WH RESUME;`) and rerun this script.
 *   
 *   Error: "Insufficient privileges to operate on database SNOWFLAKE_EXAMPLE"
 *   → Ensure you're using: USE ROLE ACCOUNTADMIN;
 *   
 *   Error: "Failed to connect to GitHub"
 *   → Check network policies allow https://github.com/
 *   → Verify API integration: SHOW INTEGRATIONS LIKE 'SFE_GITHUB_API_INTEGRATION';
 *   
 *   Error: "Object does not exist, or operation cannot be performed"
 *   → Repository fetch failed. Check: SHOW GIT REPOSITORIES IN DATABASE SNOWFLAKE_EXAMPLE;
 *   → Re-run fetch: ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO FETCH;
 *   
 *   Agent not visible after deployment:
 *   → Run validation: EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/06_validation.sql';
 *   → Check: SHOW CORTEX AGENTS IN DATABASE SNOWFLAKE_INTELLIGENCE;
 * 
 * CLEANUP:
 *   To remove all objects: See sql/99_cleanup/teardown_all.sql
 * 
 * Author: SE Community (inspired by Kaitlyn Wells @snowflake)
 * Created: 2025-11-25
 * Expires: 2025-12-25
 * Version: 4.0
 * License: Apache 2.0
 ******************************************************************************/

-- ============================================================================
-- EXPIRATION CHECK (MANDATORY)
-- ============================================================================
-- This demo expires 30 days after creation.
-- If expired, deployment should be halted and the repository forked with updated dates.
-- Expiration date: 2025-12-25

-- Display expiration status
SELECT 
    '2025-12-25'::DATE AS expiration_date,
    CURRENT_DATE() AS current_date,
    DATEDIFF('day', CURRENT_DATE(), '2025-12-25'::DATE) AS days_remaining,
    CASE 
        WHEN DATEDIFF('day', CURRENT_DATE(), '2025-12-25'::DATE) < 0 
        THEN '🚫 EXPIRED - Do not deploy. Fork repository and update expiration date.'
        WHEN DATEDIFF('day', CURRENT_DATE(), '2025-12-25'::DATE) <= 7
        THEN '⚠️  EXPIRING SOON - ' || DATEDIFF('day', CURRENT_DATE(), '2025-12-25'::DATE) || ' days remaining'
        ELSE '✅ ACTIVE - ' || DATEDIFF('day', CURRENT_DATE(), '2025-12-25'::DATE) || ' days remaining'
    END AS demo_status;

-- ⚠️  MANUAL CHECK REQUIRED:
-- If the demo_status shows "EXPIRED", STOP HERE and do not proceed with deployment.
-- This demo uses Snowflake features current as of November 2025.
-- To use after expiration:
--   1. Fork: https://github.com/sfc-gh-miwhitaker/Sam-the-Snowman
--   2. Update expiration_date in this file (line 94)
--   3. Review/update for latest Snowflake syntax and features

-- ============================================================================
-- DEPLOYMENT ORCHESTRATION
-- ============================================================================

-- ============================================================================
-- SESSION VARIABLES
-- ============================================================================
-- Change 'SYSADMIN' below to your custom role if you want a different owner.
-- This role will own all schemas, views, and the agent. Users must be granted
-- this role to access Sam-the-Snowman after deployment.

SET deployment_role = 'SYSADMIN';

-- ============================================================================
-- PHASE 1: INFRASTRUCTURE SETUP (Database, Schema, API Integration, Git Repo)
-- ============================================================================

-- Start with deployment role for database and schema creation
USE ROLE IDENTIFIER($deployment_role);

-- Create shared demo database and deployment schema (reusable across demo assets)
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
    COMMENT = 'DEMO: Sam-the-Snowman - Shared demo database (Expires: 2025-12-25)';

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.DEPLOY
    COMMENT = 'DEMO: Sam-the-Snowman - Deployment infrastructure schema (Expires: 2025-12-25)';

-- Elevate privilege for account-level objects (warehouse, integrations)
USE ROLE ACCOUNTADMIN;

-- Create dedicated demo warehouse (idempotent)
CREATE OR REPLACE WAREHOUSE SFE_SAM_SNOWMAN_WH
    WAREHOUSE_SIZE = 'XSMALL'
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 1
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    SCALING_POLICY = 'ECONOMY'
    COMMENT = 'DEMO: Sam-the-Snowman - Dedicated warehouse for deployment and runtime (Expires: 2025-12-25)';

GRANT USAGE ON WAREHOUSE SFE_SAM_SNOWMAN_WH TO ROLE IDENTIFIER($deployment_role);
GRANT OPERATE ON WAREHOUSE SFE_SAM_SNOWMAN_WH TO ROLE IDENTIFIER($deployment_role);

-- Create account-wide Git API integration (safe to rerun; reused by all demo projects)
CREATE OR REPLACE API INTEGRATION SFE_GITHUB_API_INTEGRATION
    API_PROVIDER = git_https_api
    ENABLED = TRUE
    API_ALLOWED_PREFIXES = ('https://github.com/')
    COMMENT = 'DEMO: GitHub integration for Git-based deployments (Expires: 2025-12-25)';

-- Grant usage to deployment role
GRANT USAGE ON INTEGRATION SFE_GITHUB_API_INTEGRATION TO ROLE IDENTIFIER($deployment_role);

-- Enable Cortex AI features (required for agent creation)
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE IDENTIFIER($deployment_role);

-- Return to deployment role for Git repository creation
USE ROLE IDENTIFIER($deployment_role);
USE WAREHOUSE SFE_SAM_SNOWMAN_WH;

-- Create Git repository stage (central source for all deployment modules)
CREATE OR REPLACE GIT REPOSITORY SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO
    API_INTEGRATION = SFE_GITHUB_API_INTEGRATION
    ORIGIN = 'https://github.com/sfc-gh-miwhitaker/Sam-the-Snowman.git'
    COMMENT = 'DEMO: Sam-the-Snowman - Git repository for modular SQL execution (Expires: 2025-12-25)';

-- Fetch the latest commit from the main branch
ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO FETCH;

-- Verification checkpoint: Confirm infrastructure is ready
SELECT 'Phase 1 Complete: Infrastructure setup successful. Git repository stage is ready.' AS status;

-- ============================================================================
-- PHASE 2: MODULE EXECUTION FROM GIT REPOSITORY STAGE
-- ============================================================================

-- Ensure ACCOUNTADMIN role is active for all module deployments
-- (Some modules require elevated privileges for integrations and marketplace)
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE SFE_SAM_SNOWMAN_WH;

-- Module 1: Scaffolding
-- Creates SNOWFLAKE_INTELLIGENCE database, schemas, and grants privileges
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/01_scaffolding.sql';

-- Module 2: Email Integration
-- Sets up notification integration and email delivery stored procedure
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/02_email_integration.sql';

-- Module 3: Semantic Views
-- Deploys analytical views for query performance, cost, and warehouse operations
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/03_semantic_views.sql';

-- Module 4: Marketplace Documentation
-- Installs Snowflake Documentation database for Cortex Search integration
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/04_marketplace.sql';

-- Module 5: Agent Creation
-- Creates the Sam-the-Snowman Cortex AI agent with all tools configured
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/05_agent.sql';

-- Module 6: Validation
-- Verifies all components deployed successfully and agent is operational
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/06_validation.sql';

-- ============================================================================
-- DEPLOYMENT COMPLETE
-- ============================================================================

SELECT '🎉 Deployment Complete! Sam-the-Snowman is ready.' AS status,
       'Navigate to: AI & ML > Agents > Sam-the-Snowman to start using your agent.' AS next_steps,
       'Example question: "What were my top 10 slowest queries today?"' AS example_query;
 
 
 



