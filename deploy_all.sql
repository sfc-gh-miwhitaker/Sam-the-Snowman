/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * File: deploy_all.sql
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * Synopsis:
 *   Single-command deployment orchestrator for Sam-the-Snowman.
 *   Designed to be run from a Snowsight Git Workspace.
 *
 * Prerequisites:
 *   1. ACCOUNTADMIN role access
 *   2. Active warehouse context (e.g., USE WAREHOUSE COMPUTE_WH;)
 *   3. Snowsight Git Workspace connected to this repository
 *
 * How to Deploy:
 *   
 *   Step 1: Create a Git Workspace in Snowsight
 *      • Navigate to: Projects > Workspaces
 *      • Click: "From Git repository"
 *      • Repository URL: https://github.com/sfc-gh-miwhitaker/Sam-the-Snowman.git
 *      • API Integration: 
 *        - If first time: Create new with these values:
 *          Name: GITHUB_API_INTEGRATION
 *          API Provider: git_https_api
 *          Allowed Prefixes: https://github.com/ (ALL repos, not just this one!)
 *          Enabled: ✓
 *        - If exists: Select from dropdown
 *      • Authentication: Public repository (no credentials needed)
 *      • Click: Create
 *
 *   Step 2: Configure Your Email
 *      • In the workspace file browser, open: sql/00_config.sql
 *      • Find: SET notification_recipient_email = 'your.email@company.com';
 *      • Update with your actual email address
 *      • Save the file (Ctrl+S / Cmd+S)
 *
 *   Step 3: Run This Deployment Script
 *      • In the workspace file browser, open: deploy_all.sql (this file)
 *      • Set context: USE WAREHOUSE COMPUTE_WH; USE ROLE ACCOUNTADMIN;
 *      • Click "Run All" or press Cmd/Shift+Enter
 *      • Wait ~2-3 minutes for completion
 *
 *   Step 4: Access Your Agent
 *      • Navigate to: AI & ML > Agents
 *      • Select: Sam-the-Snowman
 *      • Ask: "What were my top 10 slowest queries today?"
 *
 * What This Script Does:
 *   ✓ Validates configuration (email updated?)
 *   ✓ Creates Git repository stage for modular deployment
 *   ✓ Creates databases: SNOWFLAKE_EXAMPLE, SNOWFLAKE_INTELLIGENCE
 *   ✓ Configures email notifications (sends test email)
 *   ✓ Deploys semantic views for query analysis
 *   ✓ Installs Snowflake Documentation (Marketplace)
 *   ✓ Creates the AI agent with all tools
 *   ✓ Validates deployment success
 *
 * Technical Note:
 *   This script executes sql/00_config.sql first to create a Git repository
 *   stage at @SNOWFLAKE_EXAMPLE.tools.SAM_THE_SNOWMAN_REPO. Subsequent 
 *   modules (01-06) are executed directly from that stage using 
 *   EXECUTE IMMEDIATE FROM, demonstrating Snowflake's Git integration.
 *
 * Author: M. Whitaker (inspired by Kaitlyn Wells @snowflake)
 * Modified: 2025-11-10
 * Version: 3.2
 * License: Apache 2.0
 ******************************************************************************/

-- ============================================================================
-- DEPLOYMENT ORCHESTRATION
-- ============================================================================

-- Ensure ACCOUNTADMIN role is active for deployment
USE ROLE ACCOUNTADMIN;

-- Module 0: Configuration and Git Repository Stage Setup
-- IMPORTANT: This module must be run from the workspace files, not from a stage,
-- because it CREATES the Git repository stage that subsequent modules use.
-- We use $$ to embed the entire 00_config.sql content inline.
EXECUTE IMMEDIATE $$
@@sql/00_config.sql
$$;

-- Now that the Git repository stage exists at @SNOWFLAKE_EXAMPLE.tools.SAM_THE_SNOWMAN_REPO,
-- we can execute remaining modules directly from the cloned repository.

-- Module 1: Scaffolding
-- Creates databases, schemas, and grants necessary privileges
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.tools.SAM_THE_SNOWMAN_REPO/branches/main/sql/01_scaffolding.sql';

-- Module 2: Email Integration
-- Sets up notification integration and email delivery stored procedure
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.tools.SAM_THE_SNOWMAN_REPO/branches/main/sql/02_email_integration.sql';

-- Module 3: Semantic Views
-- Deploys analytical views for query performance, cost, and warehouse operations
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.tools.SAM_THE_SNOWMAN_REPO/branches/main/sql/03_semantic_views.sql';

-- Module 4: Marketplace Documentation
-- Installs Snowflake Documentation for Cortex Search
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.tools.SAM_THE_SNOWMAN_REPO/branches/main/sql/04_marketplace.sql';

-- Module 5: Agent Creation
-- Creates the Sam-the-Snowman AI agent with all tools configured
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.tools.SAM_THE_SNOWMAN_REPO/branches/main/sql/05_agent.sql';

-- Module 6: Validation
-- Verifies all components deployed successfully
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.tools.SAM_THE_SNOWMAN_REPO/branches/main/sql/06_validation.sql';
 
 
 



