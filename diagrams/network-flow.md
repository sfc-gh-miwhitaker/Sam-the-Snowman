# Network Flow - Sam-the-Snowman

**Author:** Michael Whitaker  
**Last Updated:** 2025-11-12  
**Status:** ⚠️ **DEMO/NON-PRODUCTION**

---

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)

⚠️ **WARNING: This is a demonstration project. NOT FOR PRODUCTION USE.**

---

## Overview

This diagram maps the connectivity between Snowsight, Snowflake services, external integrations, and downstream email delivery. All traffic uses TLS over port 443 except where noted. No inbound firewalls are opened; Snowflake initiates outbound connections to GitHub and email infrastructure.

---

## Diagram

```mermaid
graph TB
    subgraph "User Environment"
        DevWS[Developer Workstation]
        Snowsight[Snowsight UI<br/>projects.snowflake.com]
    end

    subgraph "Snowflake Cloud"
        Gateway[Snowflake Cloud Services<br/>HTTPS :443]
        Warehouse[User-Selected Warehouse<br/>(e.g., COMPUTE_WH)]
        Db[SNOWFLAKE_EXAMPLE Database]
        Agents[SNOWFLAKE_INTELLIGENCE.AGENTS]
        EmailProc[sfe_send_email()<br/>Stored Procedure]
    end

    subgraph "External Services"
        GitHub[GitHub Repo<br/>HTTPS :443]
        Docs[Snowflake Documentation Marketplace]
        EmailSvc[Snowflake Notification Service<br/>(SYSTEM$SEND_EMAIL)]
        SMTP[Recipient Mail System]
    end

    DevWS -->|SSO / MFA| Snowsight
    Snowsight -->|HTTPS :443| Gateway
    Gateway -->|Execute SQL| Warehouse
    Warehouse --> Db
    Warehouse --> Agents
    Agents --> EmailProc
    EmailProc --> EmailSvc
    EmailSvc -->|TLS Email Delivery| SMTP
    Gateway -->|FETCH via SFE_GITHUB_API_INTEGRATION| GitHub
    Gateway -->|Marketplace Subscription| Docs
```

---

## Component Descriptions

### Developer Workstation & Snowsight
- **Purpose:** Entry point for administrators to deploy modules and interact with the agent.
- **Technology:** Browser-based access with SSO/MFA enforced by the Snowflake account.
- **Location:** Customer-controlled devices.
- **Dependencies:** Requires network access to Snowsight over HTTPS (443).

### Snowflake Cloud Services Gateway
- **Purpose:** Terminates HTTPS connections from Snowsight and orchestrates SQL execution.
- **Technology:** Snowflake control plane.
- **Location:** Snowflake-managed region hosting the account.
- **Dependencies:** Initiates outbound connections to GitHub during stage fetches; routes queries to virtual warehouses.

### User-Selected Warehouse
- **Purpose:** Provides compute for semantic view queries, agent planning, and email procedure execution.
- **Technology:** Snowflake virtual warehouse (e.g., `COMPUTE_WH` or dedicated demo warehouse).
- **Location:** Customer Snowflake account.
- **Dependencies:** Must be resumed before running deployment scripts or agent conversations.

### SNOWFLAKE_EXAMPLE Database
- **Purpose:** Houses deployment (`DEPLOY`), integration, and semantic schemas.
- **Technology:** Snowflake database with demo schemas.
- **Location:** Customer Snowflake account.
- **Dependencies:** Populated by `sql/01_scaffolding.sql` and subsequent modules.

### SNOWFLAKE_INTELLIGENCE.AGENTS
- **Purpose:** Stores the Sam-the-Snowman AI agent specification.
- **Technology:** Snowflake Intelligence Agents service.
- **Location:** `SNOWFLAKE_INTELLIGENCE.AGENTS` schema.
- **Dependencies:** Requires `USE ROLE SYSADMIN` (or equivalent) and `SNOWFLAKE.CORTEX_USER` grant.

### sfe_send_email() & Notification Service
- **Purpose:** Deliver HTML reports to stakeholders.
- **Technology:** Python stored procedure invoking `SYSTEM$SEND_EMAIL`.
- **Location:** Stored procedure in `SNOWFLAKE_EXAMPLE.INTEGRATIONS`; serverless notification backend managed by Snowflake.
- **Dependencies:** Uses `SFE_EMAIL_INTEGRATION`; outbound email delivered over TLS.

### GitHub Repository Access
- **Purpose:** Provide source artifacts through the Git Repository stage.
- **Technology:** `SFE_GITHUB_API_INTEGRATION` (HTTPS to github.com).
- **Location:** Snowflake control plane initiates connections.
- **Dependencies:** Allowed prefix `https://github.com/` and enabled integration created by `sql/00_config.sql`.

### Snowflake Documentation Marketplace
- **Purpose:** Supplies Cortex Search with reference material.
- **Technology:** Marketplace share `SNOWFLAKE_DOCUMENTATION.SHARED.CKE_SNOWFLAKE_DOCS_SERVICE`.
- **Location:** Snowflake-managed dataset subscribed during deployment.
- **Dependencies:** Requires marketplace subscription executed in `sql/04_marketplace.sql`.

---

## Change History

See `.cursor/docs/DIAGRAM_CHANGELOG.md` for version history.

