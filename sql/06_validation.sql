/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * Module: 06_validation.sql
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * 
 * Synopsis:
 *   Validates that all Sam-the-Snowman components were deployed successfully.
 * 
 * Description:
 *   This module checks the deployment status of all components and displays
 *   a summary report. Each component should show PASS if deployment succeeded.
 *   
 *   Components validated:
 *   - agent.sam_the_snowman
 *   - integration.sfe_email_integration
 *   - procedure.send_email
 *   - semantic_view.cost_analysis
 *   - semantic_view.query_performance
 *   - semantic_view.warehouse_operations
 *   - database.snowflake_documentation
 * 
 * Prerequisites:
 *   - All previous modules (00-05) must be run first
 *   - deployment_log table must exist
 * 
 * Author: M. Whitaker (inspired by Kaitlyn Wells @snowflake)
 * Modified: 2025-11-07
 * Version: 3.1
 * License: Apache 2.0
 * 
 * Usage:
 *   This module is called by deploy_all.sql or can be run standalone
 *   to check deployment status.
 ******************************************************************************/

-- ============================================================================
-- VERIFY DEPLOYMENT
-- ============================================================================

-- Display deployment status for all components
-- All components should show PASS if deployment was successful
SELECT 
    component,
    status,
    CASE 
        WHEN status = 'PASS' THEN '✓'
        WHEN status = 'MISSING' THEN '✗'
        ELSE '?'
    END AS indicator
FROM SNOWFLAKE_EXAMPLE.PUBLIC.deployment_log
ORDER BY component;

-- Expected Output (if deployment succeeded):
-- | component                                  | status | indicator |
-- |--------------------------------------------|--------|-----------|
-- | agent.sam_the_snowman                      | PASS   | ✓         |
-- | database.snowflake_documentation           | PASS   | ✓         |
-- | git_repository.sam_the_snowman_repo        | PASS   | ✓         |
-- | integration.sfe_email_integration          | PASS   | ✓         |
-- | integration.sfe_github_api_integration     | PASS   | ✓         |
-- | procedure.send_email                       | PASS   | ✓         |
-- | semantic_view.cost_analysis                | PASS   | ✓         |
-- | semantic_view.query_performance            | PASS   | ✓         |
-- | semantic_view.warehouse_operations         | PASS   | ✓         |

-- Count summary
SELECT 
    COUNT(*) AS total_components,
    SUM(CASE WHEN status = 'PASS' THEN 1 ELSE 0 END) AS passed,
    SUM(CASE WHEN status = 'MISSING' THEN 1 ELSE 0 END) AS failed
FROM SNOWFLAKE_EXAMPLE.PUBLIC.deployment_log;

-- Expected Output:
-- | total_components | passed | failed |
-- |------------------|--------|--------|
-- | 9                | 9      | 0      |

-- Final status message
SELECT 
    CASE 
        WHEN SUM(CASE WHEN status = 'MISSING' THEN 1 ELSE 0 END) = 0 
        THEN '✓ All components deployed successfully! Sam-the-Snowman is ready to use.'
        ELSE '✗ Some components failed to deploy. Check the deployment log above for details.'
    END AS deployment_status
FROM SNOWFLAKE_EXAMPLE.PUBLIC.deployment_log;

-- Expected Output (success):
-- | deployment_status                                                           |
-- |-----------------------------------------------------------------------------|
-- | ✓ All components deployed successfully! Sam-the-Snowman is ready to use.  |
--
-- Next Steps:
-- 1. Check your email for the test notification (Subject: "Sam-the-Snowman - Test Email")
-- 2. Navigate to Snowsight: AI & ML > Agents
-- 3. Open "Sam-the-Snowman"
-- 4. Ask: "What were my top 10 slowest queries today?"

