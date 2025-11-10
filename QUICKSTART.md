# Sam-the-Snowman Quickstart

**Time**: ~5 minutes · **Role required**: ACCOUNTADMIN · **Warehouse**: any size

Follow these steps in Snowsight to deploy the demo agent and confirm it is ready for use.

---

## 1. Prerequisites

- ACCOUNTADMIN role granted to your user (`SHOW GRANTS TO USER CURRENT_USER();`)
- At least one warehouse you can use (`SHOW WAREHOUSES;`)
- Your Snowflake user profile has an email address (for the test message)
- Network access to Snowflake Marketplace (required for the documentation listing)

Set your worksheet context before running any scripts:

```sql
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE <your_warehouse>;
```

---

## 2. Create a Snowsight Git Workspace

1. Navigate to **Projects → Workspaces**.
2. Click **From Git repository**.
3. Enter the repository URL `https://github.com/sfc-gh-miwhitaker/Sam-the-Snowman.git`.
4. Select an existing Git API integration, or create one with:
   - Name: `GITHUB_API_INTEGRATION`
   - Allowed prefixes: `https://github.com/`
   - Authentication: **Public repository**
5. Click **Create** – the repo files appear in the left pane.

You now have a personal workspace copy of the project. Running SQL from the workspace does not push changes back to GitHub.

---

## 3. Mount the Git Repository Stage (`sql/00_config.sql`)

1. Open `sql/00_config.sql` in the workspace.
2. Confirm the worksheet still uses `ACCOUNTADMIN` and your warehouse.
3. Click **Run All**.

What to expect:
- `SNOWFLAKE_EXAMPLE` and `SNOWFLAKE_EXAMPLE.DEPLOY` verified or created
- `SFE_GITHUB_API_INTEGRATION` created (idempotent)
- Git repository stage `SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO` created and fetched
- `LIST @.../branches/main/sql` output showing the deployment modules

This step must succeed before `deploy_all.sql` can reference the stage.

---

## 4. Run the Deployment Orchestrator (`deploy_all.sql`)

1. Open `deploy_all.sql`.
2. Keep the default configuration unless you have edited the SQL modules to use a different role (they target `SYSADMIN` by default).
3. Ensure your worksheet context is still set (ACCOUNTADMIN + warehouse).
4. Click **Run All**.

The script runs modules 01–06 directly from the Git stage and takes roughly two minutes. Module 06 executes the validation script, which prints `SHOW` results for every object that should exist.

---

## 5. Verify

1. **Review the validation output** – you should see result sets for:
   - Notification integrations (expect `SFE_EMAIL_INTEGRATION`)
   - Git repository stage (one row for `SFE_SAM_THE_SNOWMAN_REPO`)
   - Stored procedures (`sfe_send_email`)
   - Semantic views (`sfe_query_performance`, `sfe_cost_analysis`, `sfe_warehouse_operations`)
   - Agents (`sam_the_snowman`)
   - Schema listings in `SNOWFLAKE_EXAMPLE`
   - Documentation database (`snowflake_documentation`)

2. **Check your inbox** – look for *“Sam-the-Snowman - Test Email”* from Snowflake Notifications. If it is missing, confirm your user email and rerun `sql/02_email_integration.sql`.

3. **Open the agent** – in Snowsight, go to **AI & ML → Agents** and select `Sam-the-Snowman`.

---

## 6. Ask a Question

Try one of these prompts to exercise each tool:

```
What were my top 10 slowest queries today?
```
```
Which warehouses used the most credits this month?
```
```
Send me an email summary of query performance.
```

If the answers look reasonable, the semantic views and email procedure are working.

---

## 7. Cleanup (Optional)

To drop all Sam-the-Snowman objects while leaving shared demo databases intact:

```sql
USE ROLE ACCOUNTADMIN;
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.deploy.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/99_cleanup/teardown_all.sql';
```

---

## Next Steps

- Need deeper detail? Read `docs/01-QUICKSTART.md` for validation checkpoints.
- Running modules individually or via Snow CLI? See `docs/04-ADVANCED-DEPLOYMENT.md`.
- Managing access? Review `docs/05-ROLE-BASED-ACCESS.md`.
- Looking for regression tests? Start with `docs/06-TESTING.md`.
- Encountered an error? Consult `docs/07-TROUBLESHOOTING.md`.

