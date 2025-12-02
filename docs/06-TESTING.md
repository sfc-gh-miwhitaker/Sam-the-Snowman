# Testing & Validation

**Purpose**: Confirm that the Sam-the-Snowman deployment is healthy and ready for end users.

---

## 1. Pre-Deployment Sanity Checks

Run these commands before executing `deploy_all.sql`.

```sql
-- Ensure you have the right context
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE SFE_SAM_SNOWMAN_WH;

-- Confirm Cortex support
SHOW DATABASE ROLES IN DATABASE SNOWFLAKE LIKE 'CORTEX_USER';

-- Confirm your profile has an email address
SHOW USERS LIKE CURRENT_USER();
```

If any check fails, resolve it before continuing (for example, add an email with `ALTER USER ... SET EMAIL`).

---

## 2. Post-Deployment Verification

`deploy_all.sql` ends by running `sql/06_validation.sql`. Review the result sets or re-run the script manually:

```sql
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE SFE_SAM_SNOWMAN_WH;
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.deploy.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/06_validation.sql';
```

Expected highlights:

| Check | Command | Expected |
|-------|---------|----------|
| Notification integration | `SHOW NOTIFICATION INTEGRATIONS LIKE 'SFE_EMAIL_INTEGRATION';` | One row, `ENABLED = TRUE` |
| Git repository stage | `SHOW GIT REPOSITORIES IN SCHEMA SNOWFLAKE_EXAMPLE.DEPLOY;` | `SFE_SAM_THE_SNOWMAN_REPO` listed |
| Email procedure | `SHOW PROCEDURES IN SCHEMA SNOWFLAKE_EXAMPLE.INTEGRATIONS;` | `SFE_SEND_EMAIL` present |
| Demo warehouse | `SHOW WAREHOUSES LIKE 'SFE_SAM_SNOWMAN_WH';` | One row, state = SUSPENDED or RESUMED |
| Semantic views | `SHOW SEMANTIC VIEWS IN SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS;` | All three `SV_SAM_*` views listed |
| Agent | `SHOW AGENTS IN SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS;` | `SAM_THE_SNOWMAN` listed |
| Documentation | `SHOW DATABASES LIKE 'SNOWFLAKE_DOCUMENTATION';` | One row |

Optional data spot-check:
```sql
SELECT COUNT(*) AS query_rows FROM SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_QUERY_PERFORMANCE;
```
A non-zero count confirms the view can read `ACCOUNT_USAGE` data.

---

## 3. Functional Smoke Tests

### Email integration
1. Confirm you received *“Sam-the-Snowman - Test Email”* from Snowflake Notifications.
2. If not, rerun `sql/02_email_integration.sql` after verifying your user email.

### Agent prompts
Ask each question in the Snowsight chat interface:
```
What were my top 10 slowest queries today?
```
```
Which warehouses consumed the most credits this month?
```
```
Send me an email summary of query performance.
```
Each answer should include a table sourced from the semantic views plus a narrative recommendation. The email prompt should return “Email sent successfully”.

### Schema access
Switch to the owning role (default `SYSADMIN`) and run:
```sql
USE ROLE SYSADMIN;
SELECT CURRENT_ROLE();
SELECT COUNT(*) FROM SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS.SV_SAM_COST_ANALYSIS;
```
This confirms analysts with the owning role can query the views directly if needed.

---

## 4. Access Regression Tests (Optional)

If you granted access to another role (for example `ANALYTICS_TEAM`):

```sql
USE ROLE ANALYTICS_TEAM;
SHOW AGENTS IN SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS;
```

You should see `SAM_THE_SNOWMAN`. If not, reapply the grants in `docs/05-ROLE-BASED-ACCESS.md`.

---

## 5. Rollback / Cleanup Test

Ensure the teardown script runs without errors:

```sql
USE ROLE ACCOUNTADMIN;
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.deploy.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/99_cleanup/teardown_all.sql';
```

Then redeploy (steps in `QUICKSTART.md`) to confirm modular scripts remain idempotent.

---

## 6. Success Criteria

A deployment is considered healthy when all of the following are true:

- Validation script outputs contain the expected objects.
- Test email arrives successfully.
- Agent responds to the sample prompts with tables backed by your data.
- Optional roles can access the agent if granted.
- Teardown script completes and a fresh deployment succeeds.

Document the results of each test for your change log or release checklist.

