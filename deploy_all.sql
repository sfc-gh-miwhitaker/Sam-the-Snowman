/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * File: deploy_all.sql
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * Synopsis:
 *   Deployment orchestrator for Sam-the-Snowman.
 *   Executes modules 01-06 FROM the Git Repository Stage.
 *
 * Prerequisites:
 *   1. ACCOUNTADMIN role access
 *   2. Active warehouse context (e.g., USE WAREHOUSE COMPUTE_WH;)
 *   3. Git Workspace created in Snowsight
 *   4. sql/00_config.sql ALREADY EXECUTED (creates the Git Repository Stage)
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
 *          Allowed authentication secrets: All
 *          Enabled: ✓
 *        - If exists: Select from dropdown
 *      • Authentication: Public repository (no credentials needed)
 *      • Click: Create
 *
 *   Step 2: Run Configuration Setup (REQUIRED FIRST!)
 *      • In workspace file browser, open: sql/00_config.sql
 *      • Find: SET notification_recipient_email = 'your.email@company.com';
 *      • Update with your actual email address
 *      • Set context: USE WAREHOUSE COMPUTE_WH; USE ROLE ACCOUNTADMIN;
 *      • Click "Run All" to execute sql/00_config.sql
 *      • This creates the Git Repository Stage needed by deploy_all.sql
 *      • Expected output: "Configuration and Git setup complete"
 *
 *   Step 3: Run This Deployment Script
 *      • In workspace file browser, open: deploy_all.sql (this file)
 *      • Verify context: USE WAREHOUSE COMPUTE_WH; USE ROLE ACCOUNTADMIN;
 *      • Click "Run All" or press Cmd/Shift+Enter
 *      • Wait ~2 minutes for completion
 *
 *   Step 4: Access Your Agent
 *      • Navigate to: AI & ML > Agents
 *      • Select: Sam-the-Snowman
 *      • Ask: "What were my top 10 slowest queries today?"
 *
 * What This Script Does:
 *   ✓ Executes modules 01-06 FROM the Git Repository Stage
 *   ✓ Creates databases: SNOWFLAKE_EXAMPLE, SNOWFLAKE_INTELLIGENCE
 *   ✓ Configures email notifications (sends test email)
 *   ✓ Deploys semantic views for query analysis
 *   ✓ Installs Snowflake Documentation (Marketplace)
 *   ✓ Creates the AI agent with all tools
 *   ✓ Validates deployment success
 *
 * Technical Note:
 *   This script assumes sql/00_config.sql was ALREADY executed, which created
 *   the Git Repository Stage at @SNOWFLAKE_EXAMPLE.tools.SAM_THE_SNOWMAN_REPO.
 *   All modules are executed FROM that stage using EXECUTE IMMEDIATE FROM.
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

-- ============================================================================
-- PREREQUISITE CHECK
-- ============================================================================
-- Verify that the Git Repository Stage exists (created by sql/00_config.sql)
-- If this fails, you need to run sql/00_config.sql first!

DO $$
BEGIN
    DECLARE
        stage_exists BOOLEAN;
    BEGIN
        stage_exists := (
            SELECT COUNT(*) > 0 
            FROM INFORMATION_SCHEMA.STAGES 
            WHERE STAGE_SCHEMA = 'TOOLS' 
              AND STAGE_NAME = 'SAM_THE_SNOWMAN_REPO'
        );
        
        IF (NOT stage_exists) THEN
            RETURN 'ERROR: Git Repository Stage not found! You must run sql/00_config.sql FIRST to create the stage.';
        END IF;
        
        RETURN 'Git Repository Stage verified. Proceeding with deployment...';
    END;
END;
$$;

-- ============================================================================
-- MODULE EXECUTION FROM GIT REPOSITORY STAGE
-- ============================================================================

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
 
 
 



