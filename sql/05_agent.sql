/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * Module: 05_agent.sql
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * 
 * Synopsis:
 *   Creates the Sam-the-Snowman AI agent with domain-specific tools.
 * 
 * Description:
 *   This module creates the Snowflake Intelligence agent that orchestrates
 *   multiple tools to provide comprehensive Snowflake optimization insights:
 *   
 *   Tools:
 *   - query_performance: Cortex Analyst for query analysis
 *   - cost_analysis: Cortex Analyst for cost tracking
 *   - warehouse_operations: Cortex Analyst for capacity planning
 *   - snowflake_knowledge_ext_documentation: Cortex Search for documentation
 *   - cortex_email_tool: Email delivery for reports
 * 
 * OBJECTS CREATED:
 *   - SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman (Agent)
 * 
 * Prerequisites:
 *   - All previous modules (00-04) must be run first
 *   - Semantic views must exist
 *   - Email integration must be configured
 *   - Snowflake Documentation must be installed
 * 
 * Author: M. Whitaker (inspired by Kaitlyn Wells @snowflake)
 * Modified: 2025-11-07
 * Version: 3.1
 * License: Apache 2.0
 * 
 * Usage:
 *   This module is called by deploy_all.sql or can be run standalone
 *   after all prerequisites are met.
 ******************************************************************************/

-- ============================================================================
-- CREATE SNOWFLAKE INTELLIGENCE AGENT
-- ============================================================================

-- Switch to the configured role for agent creation
USE ROLE SYSADMIN;
USE SNOWFLAKE_INTELLIGENCE.AGENTS;

-- Create the Sam-the-Snowman agent with domain-specific semantic views
-- Note: Agents MUST be created in SNOWFLAKE_INTELLIGENCE.AGENTS per Snowflake requirements
CREATE OR REPLACE AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman
WITH PROFILE = '{ "display_name": "Sam-the-Snowman" }'
COMMENT = 'DEMO: Sam-the-Snowman - AI-powered Snowflake Assistant with domain-specific semantic views for performance, cost, and warehouse optimization'
FROM SPECIFICATION $$
{
    "models": { "orchestration": "auto" },
    "instructions": {
        "response": "You are Sam-the-Snowman, a Snowflake Assistant. Provide specific recommendations with clear next steps, actual metrics, prioritized solutions, and Snowflake best practices.",
        "orchestration": "TOOL SELECTION:\n- query_performance: slow queries, errors, optimization, performance issues, execution metrics\n- cost_analysis: costs, spend, credits, budget, expensive queries, FinOps\n- warehouse_operations: sizing, queues, utilization, capacity, concurrency\n- snowflake_knowledge_ext_documentation: features, best practices, how-to guides\n- cortex_email_tool: send reports via email\n\nFILTERING RULES:\n- ALWAYS filter out system-managed warehouses: WAREHOUSE_NAME != 'SYSTEM$STREAMLIT_NOTEBOOK_WH'\n- NEVER include SYSTEM$STREAMLIT_NOTEBOOK_WH in analysis or recommendations\n- Users cannot control system-managed warehouses\n\nAlways cite specific metrics. Prioritize by business impact.",
        "sample_questions": [
            { "question": "What are my top 10 slowest queries and how can I optimize them?" },
            { "question": "Which warehouses are costing me the most money?" },
            { "question": "Are my warehouses properly sized based on queue times?" },
            { "question": "Show me queries with errors and how to fix them" }
        ]
    },
    "tools": [
        {
            "tool_spec": {
                "name": "query_performance",
                "type": "cortex_analyst_text_to_sql",
                "description": "Analyze query performance, errors, and optimization. Use for: slow queries, errors, execution times, cache efficiency, spilling, partitions."
            }
        },
        {
            "tool_spec": {
                "name": "cost_analysis",
                "type": "cortex_analyst_text_to_sql",
                "description": "Track warehouse costs and credit consumption. Use for: costs, spend, credits, budget, expensive queries, trends."
            }
        },
        {
            "tool_spec": {
                "name": "warehouse_operations",
                "type": "cortex_analyst_text_to_sql",
                "description": "Monitor warehouse utilization and capacity. Use for: sizing, queues, utilization, over/under-provisioning, capacity planning."
            }
        },
        {
            "tool_spec": {
                "name": "snowflake_knowledge_ext_documentation",
                "type": "cortex_search",
                "description": "Search Snowflake documentation for best practices and features."
            }
        },
        {
            "tool_spec": {
                "name": "cortex_email_tool",
                "type": "generic",
                "description": "Send analysis reports via email.",
                "input_schema": {
                    "type": "object",
                    "properties": {
                        "body": {
                            "description": "HTML content for the email body. If not provided, summarize the previous question in HTML.",
                            "type": "string"
                        },
                        "recipient_email": {
                            "description": "Email address of the recipient. Defaults to your_email_address@gmail.com if omitted.",
                            "type": "string"
                        },
                        "subject": {
                            "description": "Subject line for the message. Defaults to Sam-the-Snowman Analysis if omitted.",
                            "type": "string"
                        }
                    },
                    "required": ["body", "recipient_email", "subject"]
                }
            }
        }
    ],
    "tool_resources": {
        "query_performance": {
            "semantic_view": "SNOWFLAKE_EXAMPLE.SEMANTIC.sfe_query_performance"
        },
        "cost_analysis": {
            "semantic_view": "SNOWFLAKE_EXAMPLE.SEMANTIC.sfe_cost_analysis"
        },
        "warehouse_operations": {
            "semantic_view": "SNOWFLAKE_EXAMPLE.SEMANTIC.sfe_warehouse_operations"
        },
        "snowflake_knowledge_ext_documentation": {
            "id_column": "SOURCE_URL",
            "title_column": "DOCUMENT_TITLE",
            "max_results": 10,
            "name": "SNOWFLAKE_DOCUMENTATION.SHARED.CKE_SNOWFLAKE_DOCS_SERVICE"
        },
        "cortex_email_tool": {
            "identifier": "SNOWFLAKE_EXAMPLE.INTEGRATIONS.sfe_send_email",
            "name": "SFE_SEND_EMAIL(VARCHAR, VARCHAR, VARCHAR)",
            "type": "procedure",
            "execution_environment": {
                "type": "warehouse"
            }
        }
    }
}
$$;

-- Grant usage to the configured role only (restricts agent access to authorized users)
-- To grant access to additional roles, run: GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman TO ROLE <role_name>;
GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman TO ROLE SYSADMIN;

-- Agent creation complete

