# Detailed Quickstart

**Time**: 5–7 minutes · **Role**: ACCOUNTADMIN · **Warehouse**: any size · **Difficulty**: Beginner

This guide expands the main quickstart with additional checkpoints, validation queries, and tips for rerunning specific modules.

---

## 0. Prerequisite Checklist

1. **Confirm ACCOUNTADMIN access**
   ```sql
   SHOW GRANTS TO USER CURRENT_USER();
   ```
2. **Pick a warehouse** – any size works (`SHOW WAREHOUSES;`).
3. **Verify your user email** – required for the test message (`SHOW USERS LIKE CURRENT_USER();`).
4. **Marketplace access** – you must be allowed to accept Marketplace terms.

Set worksheet context before proceeding:
```sql
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE <your_warehouse>;
```

---

## 1. Create a Snowsight Git Workspace

1. In Snowsight, open **Projects → Workspaces → From Git repository**.
2. Repository URL: `https://github.com/sfc-gh-miwhitaker/Sam-the-Snowman.git`.
3. Select or create a Git API integration:
   - Name: any descriptive value (for example `GITHUB_API_INTEGRATION`).
   - Allowed prefixes: `https://github.com/` *(important: include the trailing slash).* 
   - Authentication: **Public repository**.
4. Click **Create**. The repository’s files appear in the left navigator.

> The workspace gives you a safe copy inside Snowsight. Executing SQL from the workspace does not modify the upstream Git repository.

---

## 2. Mount the Git Repository Stage (`sql/00_config.sql`)

1. Open `sql/00_config.sql`.
2. Confirm the worksheet still uses `ACCOUNTADMIN` and your warehouse.
3. Click **Run All**.

Key outcomes:
- `SNOWFLAKE_EXAMPLE` and `SNOWFLAKE_EXAMPLE.DEPLOY` are created or confirmed.
- `SFE_GITHUB_API_INTEGRATION` is created or reused (idempotent).
- Git repository stage `SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO` is created and fetched.
- A `LIST @stage/branches/main/sql` output enumerates the deployment modules.

If any step fails, fix the issue and rerun the script—it is safe to repeat.

---

## 3. Run the Deployment Orchestrator (`deploy_all.sql`)

1. Open `deploy_all.sql` from the workspace.
2. The script assumes the SQL modules use `SYSADMIN` (the shipping default). If you edited the modules to use a different role, adjust them before continuing.
3. Ensure your worksheet context still has `ACCOUNTADMIN` + warehouse.
4. Click **Run All**.

What happens behind the scenes:
- Account prerequisites are set (Cortex cross-region toggle, CORTEX_USER grant).
- Modules 01–06 execute FROM the Git stage in order.
- Module 06 (`sql/06_validation.sql`) emits `SHOW` statements so you can confirm each asset.

Total runtime is typically two to three minutes.

---

## 4. Validate the Deployment

Work through the result sets returned by module 06:

1. **Notification integration**
   - Expect `SFE_EMAIL_INTEGRATION` in the `SHOW NOTIFICATION INTEGRATIONS` output.
2. **Git repository stage**
   - `SHOW GIT REPOSITORIES IN SCHEMA SNOWFLAKE_EXAMPLE.DEPLOY;` should list `SFE_SAM_THE_SNOWMAN_REPO`.
3. **Stored procedure**
   - `SHOW PROCEDURES IN SCHEMA SNOWFLAKE_EXAMPLE.INTEGRATIONS;` includes `SFE_SEND_EMAIL`.
4. **Semantic views**
   - `SHOW SEMANTIC VIEWS IN SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC;` lists three `sfe_` views.
5. **Agent**
   - `SHOW AGENTS IN SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS;` lists `SAM_THE_SNOWMAN`.
6. **Documentation database**
   - `SHOW DATABASES LIKE 'SNOWFLAKE_DOCUMENTATION';` returns a single row.
7. **Schema inventory**
   - `SHOW SCHEMAS IN DATABASE SNOWFLAKE_EXAMPLE;` highlights `DEPLOY`, `INTEGRATIONS`, and `SEMANTIC`.

If a section shows “No data”, rerun the related module (see Section 6) and investigate. The final query prints `Validation complete. Review the SHOW results above for object status.`

---

## 5. Functional Checks

1. **Email test** – after `sql/02_email_integration.sql` runs, check your inbox for *“Sam-the-Snowman - Test Email”*. If missing, confirm your profile email and rerun module 02.
2. **Agent visibility** – in Snowsight open **AI & ML → Agents** and ensure `Sam-the-Snowman` appears. Switch to the owning role (`USE ROLE SYSADMIN;`) if needed.
3. **Sample questions** – try a few prompts:
   - `What were my slowest queries today?`
   - `Which warehouses consumed the most credits last week?`
   - `Send me an email summary of query performance.`

---

## 6. Rerunning Specific Modules

Need to redeploy a component without running the full orchestrator? Execute modules directly from the Git stage:

```sql
-- Example: rerun semantic views
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE <your_warehouse>;
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.deploy.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/03_semantic_views.sql';
```

Modules are idempotent—rerunning them is safe. After rerunning a module, execute `sql/06_validation.sql` to confirm the change.

---

## 7. Cleanup (Optional)

Remove all demo objects while preserving shared databases:

```sql
USE ROLE ACCOUNTADMIN;
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.deploy.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/99_cleanup/teardown_all.sql';
```

This drops the agent, semantic views, email procedure, and Git stage. `SNOWFLAKE_EXAMPLE` and `SNOWFLAKE_INTELLIGENCE` remain for audit purposes.

---

## 8. Next Steps

- **Deployment checklist** – `docs/02-DEPLOYMENT.md`
- **Architecture deep dive** – `docs/03-ARCHITECTURE.md`
- **Running modules via Snow CLI** – `docs/04-ADVANCED-DEPLOYMENT.md`
- **Access management** – `docs/05-ROLE-BASED-ACCESS.md`
- **Regression tests** – `docs/06-TESTING.md`
- **Troubleshooting** – `docs/07-TROUBLESHOOTING.md`

With validation complete, you are ready to adapt Sam-the-Snowman to your environment or use it as a blueprint for your own Snowflake Intelligence agents.

