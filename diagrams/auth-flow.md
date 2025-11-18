# Auth Flow - Sam-the-Snowman
Author: Michael Whitaker  
Last Updated: 2025-11-18  
Status: Reference Impl  
![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)  
Reference Impl: This code demonstrates prod-grade architectural patterns and best practice. review and customize security, networking, logic for your organization's specific requirements before deployment.

## Overview
This sequence diagram shows how ACCOUNTADMIN provisions the demo, how SYSADMIN owns runtime assets, and how analysts authenticate to use the agent. RBAC gates every stage, no secrets are stored in code, and email delivery relies on Snowflake-managed credentials.

## Diagram
```mermaid
sequenceDiagram
    actor Admin as Deployment Admin (ACCOUNTADMIN)
    participant Snowsight as Snowsight Workspace
    participant Snowflake as Snowflake Cloud Services
    participant SYSADMIN as SYSADMIN Role
    participant Agent as Sam-the-Snowman Agent
    participant Email as SFE_EMAIL_INTEGRATION
    actor Analyst as Analyst (SYSADMIN)

    Admin->>Snowsight: Authenticate via SSO + MFA
    Snowsight->>Snowflake: Open deploy_all.sql (ACCOUNTADMIN)
    Snowflake->>Snowflake: Create SFE_GITHUB_API_INTEGRATION + stage (Phase 1)
    Snowsight->>Snowflake: Run deploy_all.sql (ACCOUNTADMIN)
    Snowflake->>SYSADMIN: Grant ownership/usage on schemas and agent
    Admin->>Snowsight: Switch session to SYSADMIN for validation

    Analyst->>Snowsight: Authenticate via SSO (SYSADMIN or delegated role)
    Snowsight->>Agent: Invoke Sam-the-Snowman conversation
    Agent->>Snowflake: Query semantic views using active warehouse
    Agent->>Email: Call sfe_send_email() (optional report delivery)
    Email-->>Analyst: Deliver HTML email via SYSTEM$SEND_EMAIL
```

## Component Descriptions
- **Deployment Admin (ACCOUNTADMIN)**
  - Purpose: Provision integrations, databases, and agent resources.
  - Technology: Snowsight worksheet running `deploy_all.sql`.
  - Location: Customer identity provider federated with Snowflake SSO.
  - Deps: Requires MFA, ACCOUNTADMIN role, and an active warehouse.
- **SYSADMIN Role**
  - Purpose: Owns demo schemas, semantic views, and the agent during steady state.
  - Technology: Snowflake RBAC role targeted inside each module.
  - Location: Snowflake account.
  - Deps: Receives `SNOWFLAKE.CORTEX_USER` database role plus `USAGE` on agent and schemas.
- **Sam-the-Snowman Agent**
  - Purpose: Orchestrate semantic analytics, documentation lookup, and email delivery.
  - Technology: Snowflake Intelligence Agent stored in `SNOWFLAKE_INTELLIGENCE.AGENTS`.
  - Location: Snowflake account.
  - Deps: Requires active warehouse from caller and permissions on semantic views/procedure.
- **SFE_EMAIL_INTEGRATION**
  - Purpose: Send optional emails without exposing SMTP credentials.
  - Technology: Snowflake notification integration invoked via `SYSTEM$SEND_EMAIL`.
  - Location: Snowflake control plane; usage granted to SYSADMIN.
  - Deps: Created with ACCOUNTADMIN privileges in `sql/02_email_integration.sql`.
- **Analysts (SYSADMIN or Delegated Role)**
  - Purpose: Day-to-day users who ask questions and receive recommendations.
  - Technology: Snowsight agent interface.
  - Location: Customer workforce authenticated through SSO.
  - Deps: Must activate a warehouse and assume a role with agent `USAGE`.

## Change History
See `.cursor/docs/DIAGRAM_CHANGELOG.md` for vhistory.
