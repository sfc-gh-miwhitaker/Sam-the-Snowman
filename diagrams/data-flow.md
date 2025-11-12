# Data Flow - Sam-the-Snowman

**Author:** Michael Whitaker  
**Last Updated:** 2025-11-12  
**Status:** ⚠️ **DEMO/NON-PRODUCTION**

---

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)

⚠️ **WARNING: This is a demonstration project. NOT FOR PRODUCTION USE.**

---

## Overview

This diagram shows how Sam-the-Snowman reads Snowflake telemetry, enriches it with semantic views, and routes insights through the AI agent and optional email delivery. All data remains inside Snowflake; only email notifications leave the platform.

---

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

---

## Component Descriptions

### ACCOUNT_USAGE Sources
- **Purpose:** Provide authoritative telemetry about query execution, warehouse costs, and workload concurrency.
- **Technology:** Snowflake ACCOUNT_USAGE shared views.
- **Location:** Managed by Snowflake, queried via `SNOWFLAKE.ACCOUNT_USAGE`.
- **Dependencies:** Requires ACCOUNTADMIN-granted access to shared views.

### Semantic Views
- **Purpose:** Curate domain-specific datasets for the agent (performance, cost, warehouse operations) with business-friendly metadata.
- **Technology:** Snowflake Semantic Views created in `sql/03_semantic_views.sql`.
- **Location:** `SNOWFLAKE_EXAMPLE.SEMANTIC`.
- **Dependencies:** Reads ACCOUNT_USAGE tables; referenced by Cortex Analyst tools.

### Snowflake Documentation Service
- **Purpose:** Supplies best-practice context through Cortex Search.
- **Technology:** Snowflake Marketplace dataset `CKE_SNOWFLAKE_DOCS_SERVICE`.
- **Location:** `SNOWFLAKE_DOCUMENTATION.SHARED`.
- **Dependencies:** Installed via `sql/04_marketplace.sql`; exposed to the agent as a Cortex Search tool.

### Sam-the-Snowman Agent
- **Purpose:** Orchestrate semantic views, documentation lookup, and email delivery in response to natural-language questions.
- **Technology:** Snowflake Intelligence Agent defined in `sql/05_agent.sql`.
- **Location:** `SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman`.
- **Dependencies:** Requires semantic views, documentation service, and email procedure.

### Email Delivery Path
- **Purpose:** Send optional HTML summaries to stakeholders.
- **Technology:** Python stored procedure `sfe_send_email` calling `SYSTEM$SEND_EMAIL`.
- **Location:** `SNOWFLAKE_EXAMPLE.INTEGRATIONS.sfe_send_email`.
- **Dependencies:** Uses notification integration `SFE_EMAIL_INTEGRATION`; invoked by agent's `cortex_email_tool`.

### Snowsight Users
- **Purpose:** Analysts and operators who deploy and interact with the agent.
- **Technology:** Snowsight UI and SQL worksheets.
- **Location:** Snowflake web interface.
- **Dependencies:** Must assume a warehouse-capable role (default `SYSADMIN`) to query semantic views through the agent.

---

## Change History

See `.cursor/docs/DIAGRAM_CHANGELOG.md` for version history.

