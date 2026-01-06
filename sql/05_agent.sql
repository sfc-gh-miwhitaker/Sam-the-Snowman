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
 *   - SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_THE_SNOWMAN (Agent)
 *
 * Prerequisites:
 *   - All previous modules (00-04) must be run first
 *   - Semantic views must exist
 *   - Email integration must be configured
 *   - Snowflake Documentation must be installed
 *
 * Author: SE Community
 * Created: 2025-11-25
 * Expires: 2026-01-15
 * Version: 4.0
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
USE WAREHOUSE SFE_SAM_SNOWMAN_WH;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA SAM_THE_SNOWMAN;

-- Create the Sam-the-Snowman agent with domain-specific semantic views.
-- Note: Agent visibility is managed via the Snowflake Intelligence object.
CREATE OR REPLACE AGENT SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_THE_SNOWMAN
  COMMENT = 'DEMO: Sam-the-Snowman - AI assistant for query performance, cost control, and warehouse operations (Expires: 2026-01-15)'
  PROFILE = '{"display_name": "Sam-the-Snowman"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  instructions:
    response: "You are Sam-the-Snowman, a Snowflake Assistant. Provide specific recommendations with clear next steps, actual metrics, prioritized solutions, and Snowflake best practices."
    orchestration: |-
      TOOL SELECTION:
      - query_performance: slow queries, errors, optimization, performance issues, execution metrics
      - cost_analysis: costs, spend, credits, budget, expensive queries, FinOps
      - warehouse_operations: sizing, queues, utilization, capacity, concurrency
      - snowflake_knowledge_ext_documentation: features, best practices, how-to guides
      - cortex_email_tool: send reports via email

      FILTERING RULES:
      - ALWAYS filter out system-managed warehouses: WAREHOUSE_NAME != 'SYSTEM$STREAMLIT_NOTEBOOK_WH'
      - NEVER include SYSTEM$STREAMLIT_NOTEBOOK_WH in analysis or recommendations
      - Users cannot control system-managed warehouses

      Always cite specific metrics. Prioritize by business impact.
    sample_questions:
      - question: "What are my top 10 slowest queries and how can I optimize them?"
      - question: "Which warehouses are costing me the most money?"
      - question: "Are my warehouses properly sized based on queue times?"
      - question: "Show me queries with errors and how to fix them"

  tools:
    - tool_spec:
        name: query_performance
        type: cortex_analyst_text_to_sql
        description: "Analyze query performance, errors, and optimization. Use for: slow queries, errors, execution times, cache efficiency, spilling, partitions."
    - tool_spec:
        name: cost_analysis
        type: cortex_analyst_text_to_sql
        description: "Track warehouse costs and credit consumption. Use for: costs, spend, credits, budget, expensive queries, trends."
    - tool_spec:
        name: warehouse_operations
        type: cortex_analyst_text_to_sql
        description: "Monitor warehouse utilization and capacity. Use for: sizing, queues, utilization, over/under-provisioning, capacity planning."
    - tool_spec:
        name: snowflake_knowledge_ext_documentation
        type: cortex_search
        description: "Search Snowflake documentation for best practices and features."
    - tool_spec:
        name: cortex_email_tool
        type: generic
        description: "Send analysis reports via email."
        input_schema:
          type: object
          properties:
            body:
              type: string
              description: "HTML content for the email body."
            recipient_email:
              type: string
              description: "Email address of the recipient."
            subject:
              type: string
              description: "Subject line for the message."
          required:
            - body
            - recipient_email
            - subject

  tool_resources:
    query_performance:
      semantic_view: "SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_QUERY_PERFORMANCE"
      execution_environment:
        type: warehouse
        warehouse: "SFE_SAM_SNOWMAN_WH"
        query_timeout: 60
    cost_analysis:
      semantic_view: "SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_COST_ANALYSIS"
      execution_environment:
        type: warehouse
        warehouse: "SFE_SAM_SNOWMAN_WH"
        query_timeout: 60
    warehouse_operations:
      semantic_view: "SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_WAREHOUSE_OPERATIONS"
      execution_environment:
        type: warehouse
        warehouse: "SFE_SAM_SNOWMAN_WH"
        query_timeout: 60
    snowflake_knowledge_ext_documentation:
      id_column: "SOURCE_URL"
      title_column: "DOCUMENT_TITLE"
      max_results: 10
      name: "SNOWFLAKE_DOCUMENTATION.SHARED.CKE_SNOWFLAKE_DOCS_SERVICE"
    cortex_email_tool:
      type: procedure
      identifier: "SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SFE_SEND_EMAIL"
      execution_environment:
        type: warehouse
        warehouse: "SFE_SAM_SNOWMAN_WH"
        query_timeout: 60
  $$;

-- Grant usage to the configured role only (restricts agent access to authorized users)
-- To grant access to additional roles, run:
--   GRANT USAGE ON AGENT SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_THE_SNOWMAN TO ROLE <role_name>;
GRANT USAGE ON AGENT SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_THE_SNOWMAN TO ROLE SYSADMIN;

-- ============================================================================
-- ADD AGENT TO SNOWFLAKE INTELLIGENCE OBJECT
-- ============================================================================
-- Adding the agent to the Snowflake Intelligence object makes it visible in the UI
-- via Tier 1 (curated list). Users can still access the agent directly if they
-- have USAGE on the agent.

ALTER SNOWFLAKE INTELLIGENCE SNOWFLAKE_INTELLIGENCE_OBJECT_DEFAULT
    ADD AGENT SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_THE_SNOWMAN;

-- Agent creation complete
