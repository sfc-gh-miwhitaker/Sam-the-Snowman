# Network Flow - Sam-the-Snowman

Author: SE Community
Last Updated: 2025-12-16
Expires: 2026-01-15 (30 days from creation)
Status: Reference Implementation

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)

> **Reference Implementation:** This code demonstrates production-grade architectural patterns and best practices. Review and customize security, networking, and logic for your organization's specific requirements before deployment.

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
        Warehouse[Demo Warehouse\nSFE_SAM_SNOWMAN_WH]
        Db[SNOWFLAKE_EXAMPLE Database]
        Agent[Agent\nSNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_THE_SNOWMAN]
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
    Warehouse --> Agent
    Agent --> EmailProc
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
- **Demo Warehouse (SFE_SAM_SNOWMAN_WH)**
  - Purpose: Provides compute for semantic queries, agent execution, and the email procedure.
  - Technology: Snowflake X-Small warehouse created and managed by `deploy_all.sql`.
  - Location: Customer Snowflake account.
  - Deps: Script auto-creates/resumes it; you can resize or grant additional roles as needed.
- **SNOWFLAKE_EXAMPLE Database**
  - Purpose: Stores shared Git clones (`GIT_REPOS`), the project schema (`SAM_THE_SNOWMAN`), and shared semantic views (`SEMANTIC_MODELS`).
  - Technology: Snowflake database created by `sql/01_scaffolding.sql`.
  - Location: Customer Snowflake account.
  - Deps: Requires SYSADMIN (or delegated) ownership for ongoing maintenance.
- **Agent (Sam-the-Snowman)**
  - Purpose: Hosts the Sam-the-Snowman agent specification and tool bindings.
  - Technology: Snowflake Intelligence Agents service.
  - Location: `SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN.SAM_THE_SNOWMAN`.
  - Deps: Needs `SNOWFLAKE.CORTEX_USER` database role plus access to semantic views.
- **GitHub Integration**
  - Purpose: Supplies deployment artifacts through `SFE_GITHUB_API_INTEGRATION`.
  - Technology: HTTPS integration created automatically by `deploy_all.sql`.
  - Location: Snowflake control plane initiates outbound fetches to `https://github.com`.
  - Deps: Allowed prefix `https://github.com/` and enabled API integration.
- **Notification Service & Email**
  - Purpose: Deliver HTML summaries without exposing SMTP credentials.
  - Technology: Python procedure `sfe_send_email` calling `SYSTEM$SEND_EMAIL`.
  - Location: Procedure in `SNOWFLAKE_EXAMPLE.SAM_THE_SNOWMAN`; relay managed by Snowflake.
  - Deps: Requires `SFE_EMAIL_INTEGRATION` and outbound TLS to recipient mailboxes.
