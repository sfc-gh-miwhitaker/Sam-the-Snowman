/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * Module: 00_config.sql
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * 
 * Synopsis:
 *   Simplified configuration with smart defaults and auto-detection.
 * 
 * Description:
 *   This module configures Sam-the-Snowman with minimal user input:
 *   1. Auto-detects your email from Snowflake user profile
 *   2. Uses SYSADMIN role by default (customizable)
 *   3. Applies Sam-the-Snowman standards for all other settings
 * 
 * User Configuration (2 settings only):
 *   - role_name: Role for agent ownership (default: SYSADMIN)
 *   - notification_recipient_email: Auto-detected from user profile
 * 
 * For custom role deployments, see: docs/08-CUSTOM-ROLE-DEPLOYMENT.md
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
 *   Run this module from Snowsight (or the Snowflake Worksheet) BEFORE executing deploy_all.sql.
 *   It provisions the shared Git repository stage used by the deployment orchestrator.
 ******************************************************************************/

-- ============================================================================
-- USER CONFIGURATION (Only 2 settings to review!)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. ROLE CONFIGURATION
-- ----------------------------------------------------------------------------
-- The role that will own and access the Sam-the-Snowman agent.
--
-- Default: SYSADMIN (recommended for most deployments)
-- Custom: If your organization uses custom roles, change this.
--         See docs/05-ROLE-BASED-ACCESS.md (Part 2) for detailed guidance.
--
SET role_name = 'SYSADMIN';

-- ----------------------------------------------------------------------------
-- 2. EMAIL CONFIGURATION (Auto-Detected, Override if Needed)
-- ----------------------------------------------------------------------------
-- Email address for test notification during deployment.
-- We'll try to auto-detect from your Snowflake user profile.

-- Auto-detect email from current user profile
SET notification_recipient_email = (
    SELECT COALESCE(email, 'EMAIL_NOT_SET_IN_PROFILE') 
    FROM SNOWFLAKE.ACCOUNT_USAGE.USERS 
    WHERE name = CURRENT_USER() 
    LIMIT 1
);

-- ⚠️ OVERRIDE ONLY IF NEEDED:
-- If auto-detection fails (email not set in your user profile), uncomment and set manually:
-- SET notification_recipient_email = 'your.email@company.com';

-- ============================================================================
-- STATIC CONFIGURATION (Do not modify - uses Sam-the-Snowman standards)
-- ============================================================================

-- Git API Integration (reusable across all GitHub projects)
SET git_api_integration_name = 'SFE_GITHUB_API_INTEGRATION';
SET git_allowed_prefix = 'https://github.com/';

-- Database and schema structure (functional schema organization)
SET git_repo_database = 'SNOWFLAKE_EXAMPLE';
SET git_repo_schema = 'DEPLOY';

-- Git repository configuration (official Sam-the-Snowman repo)
SET git_repo_name = 'SFE_SAM_THE_SNOWMAN_REPO';
SET git_repo_origin = 'https://github.com/sfc-gh-miwhitaker/Sam-the-Snowman.git';
SET git_repo_branch = 'main';

-- Derived variables (computed from above, do not edit)
SET git_repo_fqn = '"' || $git_repo_database || '"."' || $git_repo_schema || '"."' || $git_repo_name || '"';
SET git_repo_stage_prefix = '@' || $git_repo_database || '.' || $git_repo_schema || '.' || $git_repo_name || '/branches/' || $git_repo_branch;

-- ============================================================================
-- CONFIGURATION VALIDATION
-- ============================================================================

-- Validate email configuration
DO $$
BEGIN
    -- Check if email auto-detection failed
    IF ($notification_recipient_email = 'EMAIL_NOT_SET_IN_PROFILE') THEN
        RETURN 'WARNING: Email not found in user profile. Please set notification_recipient_email manually in sql/00_config.sql (line 62) or add email to your Snowflake user profile.';
    END IF;
    
    -- Check if email still has placeholder values
    IF ($notification_recipient_email LIKE '%YOUR_EMAIL%' 
        OR $notification_recipient_email = 'your.email@company.com'
        OR $notification_recipient_email = 'YOUR_EMAIL_ADDRESS@EMAILDOMAIN.COM') THEN
        RETURN 'ERROR: Please update notification_recipient_email in sql/00_config.sql (line 62) with your actual email address.';
    END IF;
    
    -- Success
    RETURN 'Configuration validated. Role: ' || $role_name || ' | Email: ' || $notification_recipient_email;
END;
$$;

-- Expected Output (success):
-- +--------------------------------------------------------------------------+
-- | anonymous block                                                          |
-- +--------------------------------------------------------------------------+
-- | Configuration validated. Role: SYSADMIN | Email: jane.doe@company.com  |
-- +--------------------------------------------------------------------------+
--
-- If you see "WARNING: Email not found", either:
-- 1. Uncomment line 62 and set your email manually, OR
-- 2. Add email to your user profile: ALTER USER <username> SET EMAIL = 'your.email@company.com';

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

