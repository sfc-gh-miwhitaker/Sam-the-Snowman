/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * File: deploy_all.sql
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * Synopsis:
 *   Orchestrates the Sam-the-Snowman deployment by sourcing the modular SQL files.
 *
 * Usage:
 *   - Open this file in Snowsight (Git + Worksheets integration) or any Snowflake SQL client.
 *   - Update configuration values inside `sql/00_config.sql` before running if needed.
 *   - Execute this file top-to-bottom as ACCOUNTADMIN. Before running, fill in the
 *     GIT CONFIGURATION section below with the GitHub organization/repository you
 *     actually use. The script creates the Git repo clone using those values and
 *     runs each module with `EXECUTE IMMEDIATE FROM @<repo>/branches/<branch>/...`.
 ******************************************************************************/
 
-- ============================================================================
-- GIT CONFIGURATION (REQUIRED – UPDATE THESE PLACEHOLDERS BEFORE RUNNING)
-- ============================================================================

SET git_api_integration_name = 'SFE_GITHUB_API_INTEGRATION';
SET git_allowed_prefix = 'https://github.com/YOUR-ORG/';  -- include trailing slash
SET git_repo_database = 'SNOWFLAKE_EXAMPLE';
SET git_repo_schema = 'tools';
SET git_repo_name = 'SAM_THE_SNOWMAN_REPO';
SET git_repo_origin = 'https://github.com/YOUR-ORG/YOUR-REPO.git';
SET git_repo_branch = 'main';

SET git_repo_fqn = '"' || $git_repo_database || '"."' || $git_repo_schema || '"."' || $git_repo_name || '"';
SET git_repo_stage_prefix = '@' || $git_repo_database || '.' || $git_repo_schema || '.' || $git_repo_name || '/branches/' || $git_repo_branch;

USE ROLE ACCOUNTADMIN;

EXECUTE IMMEDIATE
    'CREATE DATABASE IF NOT EXISTS "' || $git_repo_database || '" COMMENT = ''DEMO: Sam-the-Snowman - Shared demo database''';

EXECUTE IMMEDIATE
    'CREATE SCHEMA IF NOT EXISTS "' || $git_repo_database || '"."' || $git_repo_schema || '" COMMENT = ''DEMO: Sam-the-Snowman - Shared demo tooling schema''';

EXECUTE IMMEDIATE
    'CREATE OR REPLACE API INTEGRATION "' || $git_api_integration_name || '" ' ||
    'API_PROVIDER = GITHUB ENABLED = TRUE API_ALLOWED_PREFIXES = (''' || $git_allowed_prefix || ''') ' ||
    'COMMENT = ''DEMO: Sam-the-Snowman - GitHub integration for Git repository access''';

EXECUTE IMMEDIATE
    'CREATE OR REPLACE GIT REPOSITORY ' || $git_repo_fqn || ' ' ||
    'API_INTEGRATION = "' || $git_api_integration_name || '" ' ||
    'ORIGIN = ''' || $git_repo_origin || ''' ' ||
    'BRANCH = ''' || $git_repo_branch || ''' ' ||
    'COMMENT = ''DEMO: Sam-the-Snowman - Git repository clone for modular SQL execution''';

EXECUTE IMMEDIATE
    'ALTER GIT REPOSITORY ' || $git_repo_fqn || ' FETCH';

-- ============================================================================
-- Execute modules from configured Git repository clone
-- ============================================================================

EXECUTE IMMEDIATE
    'EXECUTE IMMEDIATE FROM ' || $git_repo_stage_prefix || '/sql/00_config.sql';

EXECUTE IMMEDIATE
    'EXECUTE IMMEDIATE FROM ' || $git_repo_stage_prefix || '/sql/01_scaffolding.sql';

EXECUTE IMMEDIATE
    'EXECUTE IMMEDIATE FROM ' || $git_repo_stage_prefix || '/sql/02_email_integration.sql';

EXECUTE IMMEDIATE
    'EXECUTE IMMEDIATE FROM ' || $git_repo_stage_prefix || '/sql/03_semantic_views.sql';

EXECUTE IMMEDIATE
    'EXECUTE IMMEDIATE FROM ' || $git_repo_stage_prefix || '/sql/04_marketplace.sql';

EXECUTE IMMEDIATE
    'EXECUTE IMMEDIATE FROM ' || $git_repo_stage_prefix || '/sql/05_agent.sql';

EXECUTE IMMEDIATE
    'EXECUTE IMMEDIATE FROM ' || $git_repo_stage_prefix || '/sql/06_validation.sql';
 
 
 



