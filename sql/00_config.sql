/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * Module: 00_config.sql
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * Purpose:
 *   Mount the Sam-the-Snowman Git repository as a Snowflake stage.
 *   Run this script when deploy_all.sql reports that the repository stage is missing.
 *
 * Usage:
 *   1. Open this file in Snowsight.
 *   2. Set worksheet context: USE WAREHOUSE <warehouse>;
 *   3. Run all statements (Cmd/Ctrl + Shift + Enter).
 *
 * Result:
 *   - Ensures the shared demo database and DEPLOY schema exist.
 *   - Creates the SFE_GITHUB_API_INTEGRATION (idempotent).
 *   - Creates/fetches the Git repository stage at SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO.
 *   - Lists available SQL modules and prints the next action.
 ******************************************************************************/

-- Deployment role (override if your org uses a custom role)
SET deployment_role = 'SYSADMIN';

-- Operate under least-privilege deployment role by default
USE ROLE IDENTIFIER($deployment_role);

-- Ensure shared demo database and deployment schema exist (reusable across demo assets)
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
    COMMENT = 'DEMO: Sam-the-Snowman - Shared demo database';

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.DEPLOY
    COMMENT = 'DEMO: Sam-the-Snowman - Deployment staging schema';

-- Elevate privilege only for account-level integration work
USE ROLE ACCOUNTADMIN;

-- Provision account-wide Git API integration (safe to rerun; reused by all demo workspaces)
CREATE OR REPLACE API INTEGRATION SFE_GITHUB_API_INTEGRATION
    API_PROVIDER = git_https_api
    ENABLED = TRUE
    API_ALLOWED_PREFIXES = ('https://github.com/')
    COMMENT = 'DEMO: GitHub integration for Snowsight workspaces';

GRANT USAGE ON INTEGRATION SFE_GITHUB_API_INTEGRATION TO ROLE IDENTIFIER($deployment_role);

-- Return to deployment role for all remaining objects
USE ROLE IDENTIFIER($deployment_role);

-- Create Git repository stage (central source for all deployment modules)
CREATE OR REPLACE GIT REPOSITORY SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO
    API_INTEGRATION = SFE_GITHUB_API_INTEGRATION
    ORIGIN = 'https://github.com/sfc-gh-miwhitaker/Sam-the-Snowman.git'
    COMMENT = 'DEMO: Sam-the-Snowman - Git repository clone for modular SQL execution';

-- Fetch the latest commit for the branch
ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO FETCH;

-- Verification: each DESC will fail if the object is missing
DESC DATABASE SNOWFLAKE_EXAMPLE;
DESC SCHEMA SNOWFLAKE_EXAMPLE.DEPLOY;
DESC INTEGRATION SFE_GITHUB_API_INTEGRATION;
DESC GIT REPOSITORY SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO;

SELECT 'Shared objects verified. Git repository stage is ready for deploy_all.sql.' AS verification_status;
