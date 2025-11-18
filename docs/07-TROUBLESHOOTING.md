# Troubleshooting

Use this quick-reference when a deployment step fails or the agent does not behave as expected.

---

## 1. Common Issues

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| `SQL access control error: Insufficient privileges` | Worksheet not using `ACCOUNTADMIN` when required | Run `USE ROLE ACCOUNTADMIN;` and rerun the statement |
| `Git repository stage not found` when running a module | Stage fetch hasn't run this session | `ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO FETCH;` (or rerun `deploy_all.sql`) |
| `SHOW NOTIFICATION INTEGRATIONS` returns no rows | Email module failed or was skipped | Re-run `sql/02_email_integration.sql`; confirm your user has an email address |
| Test email not received | User profile missing email or blocked domain | `ALTER USER <name> SET EMAIL = 'you@company.com';` then rerun module 02; check spam filters |
| Marketplace install denied | Legal terms not yet accepted | Run `sql/04_marketplace.sql`, accept the prompt, rerun if needed |
| Semantic views exist but return zero rows | `ACCOUNT_USAGE` data delayed or role lacks privileges | Wait a few minutes, ensure role has `IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE` (handled by modules) |
| Agent missing from Snowsight | User not activating owning role | `USE ROLE SYSADMIN;` (or your custom role) before opening **AI & ML → Agents** |
| Validation output lacks expected objects | A module failed silently | Re-run the missing module(s) followed by `sql/06_validation.sql` |
| Cleanup script reports schema not found | Previous cleanup succeeded | This is expected; the script is idempotent |

---

## 2. Diagnostic Commands

Run these statements to inspect the current state:

```sql
-- Stage and integration
SHOW GIT REPOSITORIES IN SCHEMA SNOWFLAKE_EXAMPLE.DEPLOY;
SHOW NOTIFICATION INTEGRATIONS LIKE 'SFE_EMAIL_INTEGRATION';

-- Semantic views and data access
SHOW SEMANTIC VIEWS IN SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC;
SELECT COUNT(*) FROM SNOWFLAKE_EXAMPLE.SEMANTIC.sfe_query_performance;

-- Agent visibility
SHOW AGENTS IN SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS;

-- Documentation database
SHOW DATABASES LIKE 'SNOWFLAKE_DOCUMENTATION';
```

If a command returns “No data”, rerun the module responsible for that object.

---

## 3. Resetting Components

| Component | Redeploy Command |
|-----------|------------------|
| Email integration | `EXECUTE IMMEDIATE FROM '@.../sql/02_email_integration.sql';` |
| Semantic views | `EXECUTE IMMEDIATE FROM '@.../sql/03_semantic_views.sql';` |
| Agent | `EXECUTE IMMEDIATE FROM '@.../sql/05_agent.sql';` |
| Full validation | `EXECUTE IMMEDIATE FROM '@.../sql/06_validation.sql';` |
| Cleanup | `EXECUTE IMMEDIATE FROM '@.../sql/99_cleanup/teardown_all.sql';` |

Before running modules directly, refresh the Git stage with `ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO FETCH;` (or rerun `deploy_all.sql`).

---

## 4. Getting Help

- Review `docs/06-TESTING.md` for detailed verification steps.
- Confirm you are on the latest commit by running `ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO FETCH;` (or rerun `deploy_all.sql`).
- If issues persist, capture the exact error message and open an issue on GitHub or contact your Snowflake administrator.
