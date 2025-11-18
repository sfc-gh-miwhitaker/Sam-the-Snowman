# Data Model - Sam-the-Snowman
Author: Michael Whitaker  
Last Updated: 2025-11-18  
Status: Reference Impl  
![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)  
Reference Impl: This code demonstrates prod-grade architectural patterns and best practice. review and customize security, networking, logic for your organization's specific requirements before deployment.

## Overview
The data model connects Snowflake telemetry (`SNOWFLAKE.ACCOUNT_USAGE`) to the semantic views in `SNOWFLAKE_EXAMPLE.SEMANTIC`, which in turn power the Intelligence agent stored in `SNOWFLAKE_INTELLIGENCE.AGENTS`. All analytical objects follow the SFE_ prefix pattern to ensure clean discovery and cleanup.

## Diagram
```mermaid
erDiagram
    ACCOUNT_USAGE_QUERY_HISTORY ||--o{ SFE_QUERY_PERFORMANCE : feeds
    ACCOUNT_USAGE_WAREHOUSE_METERING_HISTORY ||--o{ SFE_COST_ANALYSIS : feeds
    ACCOUNT_USAGE_WAREHOUSE_LOAD_HISTORY ||--o{ SFE_WAREHOUSE_OPERATIONS : feeds
    SFE_QUERY_PERFORMANCE ||--o{ SAM_THE_SNOWMAN_AGENT : referenced_by
    SFE_COST_ANALYSIS ||--o{ SAM_THE_SNOWMAN_AGENT : referenced_by
    SFE_WAREHOUSE_OPERATIONS ||--o{ SAM_THE_SNOWMAN_AGENT : referenced_by

    ACCOUNT_USAGE_QUERY_HISTORY {
        VARCHAR QUERY_ID PK
        TIMESTAMP_NTZ START_TIME
        NUMBER TOTAL_ELAPSED_TIME_MS
        NUMBER BYTES_SCANNED
        VARCHAR WAREHOUSE_NAME
        VARCHAR EXECUTION_STATUS
    }

    ACCOUNT_USAGE_WAREHOUSE_METERING_HISTORY {
        NUMBER WAREHOUSE_ID PK
        VARCHAR WAREHOUSE_NAME
        TIMESTAMP_NTZ START_TIME
        NUMBER CREDITS_USED
        NUMBER CREDITS_USED_COMPUTE
        NUMBER CREDITS_USED_CLOUD_SERVICES
    }

    ACCOUNT_USAGE_WAREHOUSE_LOAD_HISTORY {
        NUMBER WAREHOUSE_ID PK
        VARCHAR WAREHOUSE_NAME
        TIMESTAMP_NTZ START_TIME
        NUMBER AVG_RUNNING
        NUMBER AVG_QUEUED_LOAD
        NUMBER AVG_BLOCKED
    }

    SFE_QUERY_PERFORMANCE {
        VARCHAR QUERY_ID PK
        VARCHAR QUERY_TEXT
        NUMBER TOTAL_ELAPSED_TIME
        NUMBER QUEUED_OVERLOAD_TIME
        NUMBER BYTES_SPILLED_TO_REMOTE_STORAGE
        VARCHAR WAREHOUSE_NAME
    }

    SFE_COST_ANALYSIS {
        VARCHAR WAREHOUSE_NAME
        TIMESTAMP_NTZ START_TIME
        NUMBER CREDITS_USED
        NUMBER CREDITS_USED_COMPUTE
        NUMBER CREDITS_USED_CLOUD_SERVICES
    }

    SFE_WAREHOUSE_OPERATIONS {
        VARCHAR WAREHOUSE_NAME
        TIMESTAMP_NTZ START_TIME
        NUMBER AVG_RUNNING
        NUMBER AVG_QUEUED_LOAD
        NUMBER AVG_BLOCKED
    }

    SAM_THE_SNOWMAN_AGENT {
        VARCHAR AGENT_NAME PK
        VARIANT TOOL_RESOURCES
        TIMESTAMP_NTZ CREATED_AT
    }
```

## Component Descriptions
- **ACCOUNT_USAGE Source Tables**
  - Purpose: Capture authoritative telemetry for queries, warehouse spend, and capacity.
  - Technology: Snowflake-provided shared views inside `SNOWFLAKE.ACCOUNT_USAGE`.
  - Location: Snowflake control plane (read-only for customers).
  - Deps: Requires ACCOUNTADMIN-granted access; data drives every semantic view.
- **Semantic Views (SFE_QUERY_PERFORMANCE / SFE_COST_ANALYSIS / SFE_WAREHOUSE_OPERATIONS)**
  - Purpose: Provide governed, LLM-friendly layers for Cortex tools.
  - Technology: Snowflake Semantic Views defined in `sql/03_semantic_views.sql`.
  - Location: `SNOWFLAKE_EXAMPLE.SEMANTIC` schema.
  - Deps: Join to ACCOUNT_USAGE views and expose curated metrics plus synonyms.
- **Sam-the-Snowman Agent Catalog Entry**
  - Purpose: Persist agent instructions, tool bindings, and semantic view references.
  - Technology: Snowflake Intelligence Agent stored in `SNOWFLAKE_INTELLIGENCE.AGENTS`.
  - Location: `SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman`.
  - Deps: Relies on semantic views and procedure identifiers defined in `sql/05_agent.sql`.

## Change History
See `.cursor/docs/DIAGRAM_CHANGELOG.md` for vhistory.
