# Deployment Checklist
**Sam-the-Snowman - Pre-Deployment Verification**
This checklist ensures all prerequisites are met before deploying the Sam-the-Snowman.

**Version**: 3.1  
**Last Updated**: 2025-11-07

## Required Configuration Changes

Before running `deploy_all.sql` (or individual modules), verify these configurations:

### 1. Configuration Variables (edit first section of deploy_all.sql)
- [ ] Confirm `SET role_name = 'SYSADMIN';` (adjust if you use another deployment role)
- [ ] Update `SET notification_recipient_email = 'YOUR_EMAIL_ADDRESS@EMAILDOMAIN.COM';` with a valid address
- [ ] Update `API_ALLOWED_PREFIXES` / `ORIGIN` in the GitHub integration section if you intend to point at a private repository

**Note**: The agent uses the user's current warehouse context—no dedicated warehouse needed.

### 2. Email Configuration
- [ ] Ensure `notification_recipient_email` points to an allow-listed address
- [ ] Confirm email domain is allow-listed in Snowflake notification settings
- [ ] Test email delivery after deployment

### 3. Prerequisites Verification
- [ ] ACCOUNTADMIN role access confirmed
- [ ] Cortex features enabled in account
- [ ] Network access for Marketplace listings enabled
- [ ] Users have access to at least one warehouse

## Deployment Steps

1. [ ] Review and update configuration variables (`sql/00_config.sql`)
2. [ ] Execute `deploy_all.sql` in Snowsight (Git + Worksheets integration) as ACCOUNTADMIN
    - Equivalent manual flow: run modules `sql/00_config.sql` → `sql/06_validation.sql`
3. [ ] Verify test email received
4. [ ] Test agent with sample query
5. [ ] Review security grants align with organizational policies

## Post-Deployment Validation

Run these commands to verify successful deployment:

```sql
-- Verify database and schemas exist
SHOW DATABASES LIKE 'SNOWFLAKE_EXAMPLE';
SHOW SCHEMAS IN DATABASE SNOWFLAKE_EXAMPLE;

-- Verify semantic views
SHOW SEMANTIC VIEWS IN SCHEMA SNOWFLAKE_EXAMPLE.tools;

-- Verify agent (Snowflake requires SNOWFLAKE_INTELLIGENCE.AGENTS)
SHOW SCHEMAS IN DATABASE SNOWFLAKE_INTELLIGENCE;
SHOW AGENTS IN SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS;
DESC AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman;

-- Verify documentation database import
SHOW DATABASES LIKE 'snowflake_documentation';

-- Quick smoke test
-- Navigate to AI & ML > Agents in Snowsight
-- Select sam_the_snowman
-- Ask: "What were my top 5 slowest queries today?"
```

## Security Review Checklist

- [x] Uses SYSADMIN role (or configured role) for object creation; ACCOUNTADMIN used only when required
- [x] Access scoped to configured role (no PUBLIC grants)
- [x] SQL injection protection in Python procedure
- [x] All user inputs properly escaped
- [x] ACCOUNTADMIN used only where required:
  - Account-level settings (CORTEX_ENABLED_CROSS_REGION)
  - Database role grants (SNOWFLAKE.CORTEX_USER)
  - Marketplace operations (legal terms, database import)
- [x] Agent uses user's warehouse context (no dedicated warehouse = simpler permissions)
- [x] All sensitive values documented as configuration variables

## Code Quality Standards Met

- [x] Apache 2.0 LICENSE file created
- [x] Comprehensive file header with author, version, usage
- [x] All SQL keywords UPPERCASE
- [x] All identifiers lowercase_snake_case
- [x] Clear inline comments throughout
- [x] Security considerations documented in README
- [x] Idempotent script (safe to re-run)
- [x] All placeholders clearly marked and documented

## Additional Resources

- [TESTING.md](TESTING.md) - Comprehensive testing procedures
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common issues and solutions
- [AGENT_ARCHITECTURE.md](AGENT_ARCHITECTURE.md) - Semantic views, tool configuration, and examples
- [ROLE_BASED_ACCESS.md](ROLE_BASED_ACCESS.md) - Restrict access to specific teams
