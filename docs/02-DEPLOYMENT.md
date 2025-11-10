# Deployment Checklist

**Version**: 4.0 · **Last updated**: 2025-11-10

Use this checklist before and after running `deploy_all.sql` (or the individual modules) to ensure a clean deployment.

---

## Pre-Deployment

### Required Access
- [ ] ACCOUNTADMIN role available to your user
- [ ] Warehouse access confirmed (`SHOW WAREHOUSES;`)
- [ ] Ability to accept Snowflake Marketplace legal terms

### Configuration Review
- [ ] SQL modules are unmodified or intentionally updated (they default to `USE ROLE SYSADMIN;`)
- [ ] User profile email set (required for the test message)
- [ ] Optional: edit the SQL modules if you plan to deploy with a role other than SYSADMIN

### Stage Preparation
- [ ] Snowsight Git workspace created from `https://github.com/sfc-gh-miwhitaker/Sam-the-Snowman.git`
- [ ] `sql/00_config.sql` executed successfully (Git repository stage created and fetched)

---

## Deployment Steps

1. [ ] Run `sql/00_config.sql` (ACCOUNTADMIN) to mount the Git repository stage.
2. [ ] Execute `deploy_all.sql` (ACCOUNTADMIN). The script runs modules 01–06 from the stage.
3. [ ] Watch the results – the final section runs `sql/06_validation.sql` and prints `SHOW` outputs for every object.
4. [ ] Confirm the test email arrives.
5. [ ] Open Snowsight → **AI & ML → Agents** and confirm `Sam-the-Snowman` appears.

Need to re-run a single component? Execute the corresponding module directly:
```sql
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.deploy.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/<module>.sql';
```

---

## Post-Deployment Verification

Run these commands (or consult the output from `sql/06_validation.sql`) to confirm each asset:

```sql
-- Integration & email procedure
SHOW NOTIFICATION INTEGRATIONS LIKE 'SFE_EMAIL_INTEGRATION';
SHOW PROCEDURES IN SCHEMA SNOWFLAKE_EXAMPLE.INTEGRATIONS;

-- Semantic views
SHOW SEMANTIC VIEWS IN SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC;

-- Agent & schemas
SHOW AGENTS IN SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS;
SHOW SCHEMAS IN DATABASE SNOWFLAKE_EXAMPLE;
SHOW DATABASES LIKE 'SNOWFLAKE_DOCUMENTATION';
```

### Functional Smoke Test
1. Ask the agent: “What were my top 5 slowest queries today?”
2. Ask: “Which warehouses consumed the most credits last week?”
3. Call the email tool: “Send me an email summary of query performance.”

---

## Security Review

- Ownership defaults to `SYSADMIN`. If you need a different owner, edit the SQL modules before deployment.
- No PUBLIC grants are created; grant access to additional roles explicitly.
- `SNOWFLAKE.CORTEX_USER` database role is granted to the owning role during deployment.
- The Snowpark procedure uses parameter binding and only calls `SYSTEM$SEND_EMAIL`.
- Semantic views read from `SNOWFLAKE.ACCOUNT_USAGE` (read-only data).

---

## Cleanup

To remove the demo artifacts while preserving shared databases:

```sql
USE ROLE ACCOUNTADMIN;
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.deploy.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/99_cleanup/teardown_all.sql';
```

---

## Related Guides

- `docs/01-QUICKSTART.md` – detailed walkthrough with checkpoints
- `docs/03-ARCHITECTURE.md` – semantic view and agent design
- `docs/04-ADVANCED-DEPLOYMENT.md` – partial redeployments, Snow CLI usage
- `docs/05-ROLE-BASED-ACCESS.md` – how to grant or restrict agent access
- `docs/06-TESTING.md` – regression and smoke tests
- `docs/07-TROUBLESHOOTING.md` – quick fixes for common issues
