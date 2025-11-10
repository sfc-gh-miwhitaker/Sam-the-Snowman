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
 *   2. Set worksheet context: USE ROLE ACCOUNTADMIN; USE WAREHOUSE <warehouse>;
 *   3. Run all statements (Cmd/Ctrl + Shift + Enter).
 *
 * Result:
 *   - Ensures the shared demo database and DEPLOY schema exist.
 *   - Creates the SFE_GITHUB_API_INTEGRATION (idempotent).
 *   - Creates/fetches the Git repository stage at SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO.
 *   - Lists available SQL modules and prints the next action.
 ******************************************************************************/

-- Ensure ACCOUNTADMIN role for account-level objects
USE ROLE ACCOUNTADMIN;

-- Ensure shared demo database and deployment schema exist (reusable across demo assets)
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
    COMMENT = 'DEMO: Shared demo database';

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.DEPLOY
    COMMENT = 'DEMO: Deployment staging schema';

-- Provision account-wide Git API integration (safe to rerun; reused by all demo workspaces)
CREATE OR REPLACE API INTEGRATION SFE_GITHUB_API_INTEGRATION
    API_PROVIDER = git_https_api
    ENABLED = TRUE
    API_ALLOWED_PREFIXES = ('https://github.com/')
    COMMENT = 'DEMO: GitHub integration for Snowsight workspaces';

-- Create Git repository stage (central source for all deployment modules)
CREATE OR REPLACE GIT REPOSITORY SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO
    API_INTEGRATION = SFE_GITHUB_API_INTEGRATION
    ORIGIN = 'https://github.com/sfc-gh-miwhitaker/Sam-the-Snowman.git'
    BRANCH = 'main'
    COMMENT = 'DEMO: Sam-the-Snowman - Git repository clone for modular SQL execution';

-- Fetch the latest commit for the branch
ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO FETCH;

-- Verification summary (displays expected assets and their status)
WITH verification AS (
    SELECT 'DATABASE' AS object_type,
           'SNOWFLAKE_EXAMPLE' AS object_name,
           CASE WHEN EXISTS (
               SELECT 1
               FROM SNOWFLAKE.INFORMATION_SCHEMA.DATABASES
               WHERE DATABASE_NAME = 'SNOWFLAKE_EXAMPLE'
           ) THEN 'VERIFIED' ELSE 'MISSING' END AS status
    UNION ALL
    SELECT 'SCHEMA',
           'SNOWFLAKE_EXAMPLE.DEPLOY',
           CASE WHEN EXISTS (
               SELECT 1
               FROM SNOWFLAKE.INFORMATION_SCHEMA.SCHEMATA
               WHERE CATALOG_NAME = 'SNOWFLAKE_EXAMPLE'
                 AND SCHEMA_NAME = 'DEPLOY'
           ) THEN 'VERIFIED' ELSE 'MISSING' END
    UNION ALL
    SELECT 'API_INTEGRATION',
           'SFE_GITHUB_API_INTEGRATION',
           CASE WHEN EXISTS (
               SELECT 1
               FROM SNOWFLAKE.ACCOUNT_USAGE.API_INTEGRATIONS
               WHERE API_INTEGRATION_NAME = 'SFE_GITHUB_API_INTEGRATION'
                 AND DELETED IS NULL
           ) THEN 'VERIFIED' ELSE 'MISSING' END
    UNION ALL
    SELECT 'GIT_REPOSITORY',
           'SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO',
           CASE WHEN EXISTS (
               SELECT 1
               FROM SNOWFLAKE.ACCOUNT_USAGE.GIT_REPOSITORIES
               WHERE REPOSITORY_NAME = 'SFE_SAM_THE_SNOWMAN_REPO'
                 AND REPOSITORY_DATABASE_NAME = 'SNOWFLAKE_EXAMPLE'
                 AND REPOSITORY_SCHEMA_NAME = 'DEPLOY'
                 AND DELETED IS NULL
           ) THEN 'VERIFIED' ELSE 'MISSING' END
)
SELECT object_type, object_name, status
FROM verification
ORDER BY object_type;
