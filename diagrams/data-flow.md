# Data Flow - Sam-the-Snowman
Author: Michael Whitaker  
Last Updated: 2025-11-18  
Status: Reference Impl  
![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)  
Reference Impl: This code demonstrates prod-grade architectural patterns and best practice. review and customize security, networking, logic for your organization's specific requirements before deployment.

## Overview
This diagram traces telemetry from `SNOWFLAKE.ACCOUNT_USAGE`, through curated semantic views, into the Snowflake Intelligence agent and optional email delivery. All processing occurs inside Snowflake; only HTML notifications exit the platform via the managed email service.

## Diagram
```mermaid
graph TB
    subgraph "Source Systems"
        QH[ACCOUNT_USAGE.QUERY_HISTORY]
        WMH[ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY]
        WLH[ACCOUNT_USAGE.WAREHOUSE_LOAD_HISTORY]
        Docs[Snowflake Documentation<br/>Marketplace Dataset]
    end

    subgraph "Semantic Layer<br/>SNOWFLAKE_EXAMPLE.SEMANTIC"
        View1[(sfe_query_performance)]
        View2[(sfe_cost_analysis)]
        View3[(sfe_warehouse_operations)]
    end

    subgraph "Knowledge Services"
        CKE[CKE_SNOWFLAKE_DOCS_SERVICE]
    end

    subgraph "Agent Execution"
        Agent[Sam-the-Snowman<br/>AI Agent]
    end

    subgraph "Communication"
        EmailProc[sfe_send_email()<br/>Stored Procedure]
        Notify[SYSTEM$SEND_EMAIL]
        Inbox[Stakeholder Mailbox]
    end

    subgraph "Consumers"
        Snowsight[Snowsight Users]
    end

    QH --> View1
    WMH --> View2
    WLH --> View3
    Docs --> CKE
    View1 --> Agent
    View2 --> Agent
    View3 --> Agent
    CKE --> Agent
    Agent --> Snowsight
    Agent --> EmailProc --> Notify --> Inbox
```

## Component Descriptions
- **ACCOUNT_USAGE Sources**
  - Purpose: Provide authoritative telemetry for queries, spend, and warehouse load.
  - Technology: Snowflake system views within `SNOWFLAKE.ACCOUNT_USAGE`.
  - Location: Snowflake-managed shared database.
  - Deps: Requires ACCOUNTADMIN access plus an active warehouse.
- **Semantic Views**
  - Purpose: Present curated, LLM-friendly datasets for the agent tools.
  - Technology: Semantic Views defined in `sql/03_semantic_views.sql`.
  - Location: `SNOWFLAKE_EXAMPLE.SEMANTIC`.
  - Deps: Reads ACCOUNT_USAGE views; referenced by Cortex Analyst tools in `sql/05_agent.sql`.
- **Snowflake Documentation Service**
  - Purpose: Supply Cortex Search with authoritative best practices.
  - Technology: Marketplace share `SNOWFLAKE_DOCUMENTATION.SHARED.CKE_SNOWFLAKE_DOCS_SERVICE`.
  - Location: Installed via `sql/04_marketplace.sql`.
  - Deps: Requires Marketplace subscription and imported privileges.
- **Demo Warehouse (SFE_SAM_SNOWMAN_WH)**
  - Purpose: Provide consistent compute for ingestion, semantic view creation, and agent workloads.
  - Technology: Snowflake X-Small warehouse created by `deploy_all.sql` (auto-suspend 60s).
  - Location: Customer Snowflake account.
  - Deps: Script resumes it on demand; you can resize/grant other roles as needed.
- **Sam-the-Snowman Agent**
  - Purpose: Orchestrate semantic analytics, documentation lookup, and email delivery.
  - Technology: Snowflake Intelligence Agent.
  - Location: `SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman`.
  - Deps: Needs semantic views, Cortex Search dataset, and email procedure to exist.
- **Email Delivery Path**
  - Purpose: Send optional HTML recaps to stakeholders.
  - Technology: Python procedure `sfe_send_email` calling `SYSTEM$SEND_EMAIL`.
  - Location: `SNOWFLAKE_EXAMPLE.INTEGRATIONS`.
  - Deps: Uses `SFE_EMAIL_INTEGRATION` and the agent `cortex_email_tool`.
- **Snowsight Consumers**
  - Purpose: Provide conversational and worksheet access for admins/analysts.
  - Technology: Snowsight UI.
  - Location: Snowflake web interface.
  - Deps: Users must activate a warehouse and hold SYSADMIN (or delegated) role.

## Change History
See `.cursor/docs/DIAGRAM_CHANGELOG.md` for vhistory.
