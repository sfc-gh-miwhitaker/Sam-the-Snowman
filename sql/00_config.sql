/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * Module: 00_config.sql
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * 
 * Synopsis:
 *   Configuration variables and account-level prerequisites for Sam-the-Snowman.
 * 
 * Description:
 *   This module sets up configuration variables and enables Cortex features.
 *   Customize the variables below before running the deployment.
 * 
 * Configuration Variables:
 *   - role_name: Role that will own and access the agent (default: SYSADMIN)
 *   - notification_recipient_email: Email address for test notifications
 * 
 * Prerequisites:
 *   - ACCOUNTADMIN role privileges
 *   - Cortex features enabled in the account
 * 
 * Author: M. Whitaker (inspired by Kaitlyn Wells @snowflake)
 * Modified: 2025-11-07
 * Version: 3.1
 * License: Apache 2.0
 * 
 * Usage:
 *   This module is called by deploy_all.sql or can be run standalone.
 ******************************************************************************/

-- ============================================================================
-- CONFIGURATION VARIABLES (REQUIRED: Update these before deployment)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- STEP 1: Configure Role and Email
-- ----------------------------------------------------------------------------

-- Role that will own and have access to the agent
-- Default: SYSADMIN (change if you want a different role)
SET role_name = 'SYSADMIN';

-- ⚠️  REQUIRED: Your email address for test notifications
-- The deployment will send a test email to confirm the integration works
-- REPLACE 'your.email@company.com' WITH YOUR ACTUAL EMAIL ADDRESS
SET notification_recipient_email = 'your.email@company.com';

-- ----------------------------------------------------------------------------
-- STEP 2: Configure Git Integration (Advanced - defaults work for most users)
-- ----------------------------------------------------------------------------

-- Git API Integration name (uses SFE_ prefix per demo project standards)
SET git_api_integration_name = 'SFE_GITHUB_API_INTEGRATION';

-- Allowed GitHub URL prefix (restrict after first deployment if desired)
SET git_allowed_prefix = 'https://github.com/';

-- Target database and schema for Git repository and tools
SET git_repo_database = 'SNOWFLAKE_EXAMPLE';
SET git_repo_schema = 'tools';

-- Git repository name (consider adding SFE_ prefix for strict demo compliance)
SET git_repo_name = 'SAM_THE_SNOWMAN_REPO';

-- Source repository URL and branch
-- Default: Official Sam-the-Snowman repository
-- Change this if you forked the repo or want to point to your own Git server
SET git_repo_origin = 'https://github.com/sfc-gh-miwhitaker/Sam-the-Snowman.git';
SET git_repo_branch = 'main';

-- Derived variables (do not edit these)
SET git_repo_fqn = '"' || $git_repo_database || '"."' || $git_repo_schema || '"."' || $git_repo_name || '"';
SET git_repo_stage_prefix = '@' || $git_repo_database || '.' || $git_repo_schema || '.' || $git_repo_name || '/branches/' || $git_repo_branch;

-- ============================================================================
-- CONFIGURATION VALIDATION
-- ============================================================================

-- Validate that email address was updated (prevents common deployment mistake)
DO $$
BEGIN
    IF ($notification_recipient_email LIKE '%YOUR_EMAIL%' 
        OR $notification_recipient_email = 'your.email@company.com'
        OR $notification_recipient_email = 'YOUR_EMAIL_ADDRESS@EMAILDOMAIN.COM') THEN
        RETURN 'ERROR: You must update notification_recipient_email in sql/00_config.sql before deploying!';
    END IF;
    RETURN 'Configuration validation passed. Email: ' || $notification_recipient_email;
END;
$$;

-- Expected Output (success):
-- +--------------------------------------------------------------------------+
-- | anonymous block                                                          |
-- +--------------------------------------------------------------------------+
-- | Configuration validation passed. Email: jane.doe@company.com            |
-- +--------------------------------------------------------------------------+
--
-- If you see "ERROR: You must update notification_recipient_email", 
-- edit the email address above and rerun this module

-- ============================================================================
-- ACCOUNT-LEVEL PREREQUISITES
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- Enable cross-region Cortex model access for the account
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

-- Grant Cortex access to the configured role (restricts Cortex features to authorized users)
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE identifier($role_name);

-- ============================================================================
-- GIT INTEGRATION SETUP
-- ============================================================================

-- Create the target database and schema for Git repository
EXECUTE IMMEDIATE
    'CREATE DATABASE IF NOT EXISTS "' || $git_repo_database || '" COMMENT = ''DEMO: Sam-the-Snowman - Shared demo database''';

EXECUTE IMMEDIATE
    'CREATE SCHEMA IF NOT EXISTS "' || $git_repo_database || '"."' || $git_repo_schema || '" COMMENT = ''DEMO: Sam-the-Snowman - Shared demo tooling schema''';

-- Create Git API integration for repository access
EXECUTE IMMEDIATE
    'CREATE OR REPLACE API INTEGRATION "' || $git_api_integration_name || '" ' ||
    'API_PROVIDER = git_https_api ENABLED = TRUE API_ALLOWED_PREFIXES = (''' || $git_allowed_prefix || ''') ' ||
    'COMMENT = ''DEMO: Sam-the-Snowman - GitHub integration for Git repository access''';

-- Create and fetch the Git repository
EXECUTE IMMEDIATE
    'CREATE OR REPLACE GIT REPOSITORY ' || $git_repo_fqn || ' ' ||
    'API_INTEGRATION = "' || $git_api_integration_name || '" ' ||
    'ORIGIN = ''' || $git_repo_origin || ''' ' ||
    'BRANCH = ''' || $git_repo_branch || ''' ' ||
    'COMMENT = ''DEMO: Sam-the-Snowman - Git repository clone for modular SQL execution''';

EXECUTE IMMEDIATE
    'ALTER GIT REPOSITORY ' || $git_repo_fqn || ' FETCH';

-- Verify Git repository was created successfully
EXECUTE IMMEDIATE
    'SHOW GIT REPOSITORIES LIKE ''' || $git_repo_name || ''' IN SCHEMA ' || $git_repo_database || '.' || $git_repo_schema;

-- Configuration and Git setup complete
-- All variables are now available to subsequent deployment modules

