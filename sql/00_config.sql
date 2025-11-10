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
-- CONFIGURATION VARIABLES
-- ============================================================================

-- Role that will own and have access to the agent
-- Change this if you want to use a different role (e.g., custom_data_role)
SET role_name = 'SYSADMIN';

-- Email address for test notifications and default Cortex email tool recipient
-- REPLACE THIS WITH YOUR ACTUAL EMAIL ADDRESS
SET notification_recipient_email = 'YOUR_EMAIL_ADDRESS@EMAILDOMAIN.COM';

-- ============================================================================
-- ACCOUNT-LEVEL PREREQUISITES
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- Enable cross-region Cortex model access for the account
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';

-- Grant Cortex access to the configured role (restricts Cortex features to authorized users)
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE identifier($role_name);

-- Configuration complete

