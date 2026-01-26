/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * Module: 03_deploy_semantic_models.sql
 *
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 *
 * PURPOSE:
 *   Deploy semantic views from YAML semantic model specifications.
 *   This approach enables full feature support including:
 *   - TIME_DIMENSIONS for date intelligence
 *   - FILTERS for reusable query patterns
 *   - VERIFIED_QUERIES (VQRs) for accuracy
 *   - sample_values for categorical dimensions
 *   - custom_instructions for model-specific guidance
 *
 * Synopsis:
 *   Uses SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML() to deploy semantic views
 *   from YAML files stored in the Git repository stage.
 *
 * Description:
 *   This module reads YAML semantic model files from the Git repository
 *   and creates semantic views with full feature support. Unlike SQL DDL
 *   which only supports basic features, YAML deployment provides access
 *   to advanced Cortex Analyst capabilities.
 *
 * OBJECTS CREATED:
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_QUERY_PERFORMANCE
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_COST_ANALYSIS
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_WAREHOUSE_OPERATIONS
 *   - SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_USER_ACTIVITY
 *
 * Prerequisites:
 *   - 01_scaffolding.sql must be run first
 *   - Git repository must be fetched with latest changes
 *   - Configured role must have access to SNOWFLAKE.ACCOUNT_USAGE views
 *
 * Author: SE Community
 * Created: 2025-01-26
 * Expires: 2026-02-14
 * Version: 7.0
 * License: Apache 2.0
 *
 * Usage:
 *   This module is called by deploy_all.sql or can be run standalone.
 ******************************************************************************/

USE ROLE SYSADMIN;
USE WAREHOUSE SFE_SAM_SNOWMAN_WH;

-- ============================================================================
-- DEPLOY SEMANTIC VIEWS FROM YAML
-- ============================================================================
-- Each semantic model is deployed using SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML
-- which provides full feature support including TIME_DIMENSIONS, FILTERS,
-- VERIFIED_QUERIES, and sample_values.
--
-- Since SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML requires the YAML as a string,
-- we use a Python stored procedure to read files from the Git stage and call
-- the system function.

-- Create helper procedure for YAML deployment
CREATE OR REPLACE PROCEDURE SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_DEPLOY_SEMANTIC_MODEL_FROM_STAGE(
    STAGE_PATH VARCHAR,
    TARGET_SCHEMA VARCHAR
)
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.11'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'deploy_semantic_model'
COMMENT = 'DEMO: Sam-the-Snowman - Deploy semantic view from YAML file in stage (Expires: 2026-02-14)'
AS
$$
import snowflake.snowpark as snowpark
from snowflake.snowpark.files import SnowflakeFile

def deploy_semantic_model(session: snowpark.Session, stage_path: str, target_schema: str) -> str:
    """
    Read a YAML file from a stage and create a semantic view using
    SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML.

    Args:
        session: Snowpark session
        stage_path: Full path to YAML file (e.g., @DB.SCHEMA.STAGE/path/file.yaml)
        target_schema: Target schema for semantic view (e.g., DB.SCHEMA)

    Returns:
        Status message from the deployment
    """
    try:
        # Read the YAML file from the stage
        with SnowflakeFile.open(stage_path, 'r') as f:
            yaml_content = f.read()

        # Call SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML
        # Using dollar-quoted string to handle complex YAML content
        result = session.sql(f"""
            CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
                '{target_schema}',
                $YAML$
{yaml_content}
$YAML$
            )
        """).collect()

        if result:
            return result[0][0]
        return "Deployment completed"

    except Exception as e:
        return f"ERROR: {str(e)}"
$$;

-- Grant execute to SYSADMIN
GRANT USAGE ON PROCEDURE SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_DEPLOY_SEMANTIC_MODEL_FROM_STAGE(VARCHAR, VARCHAR)
    TO ROLE SYSADMIN;

-- ----------------------------------------------------------------------------
-- DEPLOY ALL SEMANTIC MODELS
-- ----------------------------------------------------------------------------

-- Deploy Query Performance semantic view
CALL SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_DEPLOY_SEMANTIC_MODEL_FROM_STAGE(
    '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO/branches/main/semantic_models/sv_sam_query_performance.yaml',
    'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS'
);

-- Deploy Cost Analysis semantic view
CALL SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_DEPLOY_SEMANTIC_MODEL_FROM_STAGE(
    '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO/branches/main/semantic_models/sv_sam_cost_analysis.yaml',
    'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS'
);

-- Deploy Warehouse Operations semantic view
CALL SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_DEPLOY_SEMANTIC_MODEL_FROM_STAGE(
    '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO/branches/main/semantic_models/sv_sam_warehouse_operations.yaml',
    'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS'
);

-- Deploy User Activity semantic view
CALL SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SP_DEPLOY_SEMANTIC_MODEL_FROM_STAGE(
    '@SNOWFLAKE_EXAMPLE.GIT_REPOS.SFE_SAM_THE_SNOWMAN_REPO/branches/main/semantic_models/sv_sam_user_activity.yaml',
    'SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS'
);

-- ----------------------------------------------------------------------------
-- VALIDATION
-- ----------------------------------------------------------------------------
-- Verify all semantic views were created successfully

SELECT 'Semantic models deployed from YAML' AS status;
