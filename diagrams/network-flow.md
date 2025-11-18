# Network Flow - Sam-the-Snowman
Author: Michael Whitaker  
Last Updated: 2025-11-18  
Status: Reference Impl  
![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)  
Reference Impl: This code demonstrates prod-grade architectural patterns and best practice. review and customize security, networking, logic for your organization's specific requirements before deployment.

## Overview
End users connect through Snowsight over TLS, Snowflake fetches artifacts from GitHub, and outbound emails are relayed through Snowflake's notification service. No inbound firewall changes are required; all traffic originates from Snowflake-managed control planes using HTTPS on port 443.

## Diagram
```mermaid
graph TB
    subgraph "User Environment"
        DevWS[Developer Workstation]
        Snowsight[Snowsight UI\nprojects.snowflake.com]
    end

    subgraph "Snowflake Cloud"
        Gateway[Snowflake Cloud Services\nHTTPS :443]
        Warehouse[Virtual Warehouse\n(e.g., COMPUTE_WH)]
        Db[SNOWFLAKE_EXAMPLE Database]
        Agents[SNOWFLAKE_INTELLIGENCE.AGENTS]
        EmailProc[sfe_send_email() Procedure]
    end

    subgraph "External Services"
        GitHub[GitHub Repo\nHTTPS :443]
        Docs[Snowflake Documentation Marketplace]
        EmailSvc[Snowflake Notification Service\nSYSTEM$SEND_EMAIL]
        SMTP[Stakeholder Mail System]
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

## Component Descriptions
- **Developer Workstation & Snowsight**
  - Purpose: Entry point for administrators to deploy modules and invoke the agent.
  - Technology: Browser-based Snowsight UI with SSO + MFA enforced by the Snowflake account.
  - Location: Customer devices and Snowflake web tier.
  - Deps: Requires outbound HTTPS access to Snowsight (port 443).
- **Snowflake Cloud Services Gateway**
  - Purpose: Terminates HTTPS sessions, orchestrates SQL, and brokers outbound integrations.
  - Technology: Snowflake control plane in the customer's region.
  - Location: Snowflake-managed infrastructure.
  - Deps: Initiates outbound HTTPS requests to GitHub and Marketplace endpoints.
- **Virtual Warehouse**
  - Purpose: Provides compute for semantic queries, agent execution, and the email procedure.
  - Technology: Snowflake virtual warehouse (e.g., COMPUTE_WH or a dedicated demo warehouse).
  - Location: Customer Snowflake account.
  - Deps: Must be resumed prior to running `deploy_all.sql` or agent sessions.
- **SNOWFLAKE_EXAMPLE Database**
  - Purpose: Stores deployment (`DEPLOY`), integration, and semantic schemas used by the agent.
  - Technology: Snowflake database created by `sql/01_scaffolding.sql`.
  - Location: Customer Snowflake account.
  - Deps: Requires SYSADMIN (or delegated) ownership for ongoing maintenance.
- **SNOWFLAKE_INTELLIGENCE.AGENTS**
  - Purpose: Hosts the Sam-the-Snowman agent specification and tool bindings.
  - Technology: Snowflake Intelligence Agents service.
  - Location: `SNOWFLAKE_INTELLIGENCE.AGENTS` schema.
  - Deps: Needs `SNOWFLAKE.CORTEX_USER` database role plus access to semantic views.
- **GitHub Integration**
  - Purpose: Supplies deployment artifacts through `SFE_GITHUB_API_INTEGRATION`.
  - Technology: HTTPS integration created automatically by `deploy_all.sql`.
  - Location: Snowflake control plane initiates outbound fetches to `https://github.com`.
  - Deps: Allowed prefix `https://github.com/` and enabled API integration.
- **Notification Service & Email**
  - Purpose: Deliver HTML summaries without exposing SMTP credentials.
  - Technology: Python procedure `sfe_send_email` calling `SYSTEM$SEND_EMAIL`.
  - Location: Procedure in `SNOWFLAKE_EXAMPLE.INTEGRATIONS`; relay managed by Snowflake.
  - Deps: Requires `SFE_EMAIL_INTEGRATION` and outbound TLS to recipient mailboxes.

## Change History
See `.cursor/docs/DIAGRAM_CHANGELOG.md` for vhistory.
