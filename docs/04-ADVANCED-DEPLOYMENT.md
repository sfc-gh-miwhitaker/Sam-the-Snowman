# Advanced Deployment

**Version**: 4.0 · **Last updated**: 2025-11-10

Sam-the-Snowman ships in modular SQL files so you can deploy, troubleshoot, or iterate on individual components. This guide explains how to work with those modules beyond the single-shot `deploy_all.sql` experience.

---

## 1. Module Directory

| Module | Purpose | Notes |
|--------|---------|-------|
| `sql/01_scaffolding.sql` | Creates databases, schemas, and grants (assumes `SYSADMIN`) | Idempotent |
| `sql/02_email_integration.sql` | Creates `SFE_EMAIL_INTEGRATION` and the Snowpark email procedure | Sends a test email |
| `sql/03_semantic_views.sql` | Builds semantic views for performance, cost, and warehouse analytics | Re-run after editing view definitions |
| `sql/04_marketplace.sql` | Installs the Snowflake Documentation marketplace database | Prompts for legal acceptance if needed |
| `sql/05_agent.sql` | Creates `sam_the_snowman` and binds all tools | Re-run after changing views or instructions |
| `sql/06_validation.sql` | Issues `SHOW` statements for every deployed object | Use after any partial redeploy |
| `sql/99_cleanup/teardown_all.sql` | Drops demo objects while preserving shared databases | Safe to run multiple times |

All modules are idempotent. They can be executed from Snowsight, Snow SQL, or Snow CLI.

---

## 2. Running Modules Individually (Snowsight)

When you only need to redeploy a subset of components:

1. Ensure the Git repository stage is up to date (re-run `deploy_all.sql` or run the snippet below).
   ```sql
   ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO FETCH;
   ```
2. Execute the module you want to refresh:
   ```sql
   EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.deploy.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/03_semantic_views.sql';
   ```
3. Run `sql/05_agent.sql` if your changes affect the agent’s tool bindings.
4. Finish with `sql/06_validation.sql` to confirm the object now appears in the `SHOW` output.

> Modules contain `USE ROLE SYSADMIN;` statements. If you need a different owner, edit those statements before running the module.

---

## 3. Using Snow CLI

The modules can be executed from your terminal with the Snow CLI (v3 or later):

```bash
# Run deploy_all.sql end-to-end
snow sql -f deploy_all.sql

# Run an individual module (after the stage exists)
snow sql -f sql/03_semantic_views.sql

# Run validation after a partial change
snow sql -f sql/06_validation.sql
```

Tips:
- Set your profile with ACCOUNTADMIN privileges before invoking the commands.
- When using the CLI, refresh the Git stage with `ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO FETCH;` before invoking modules (or simply re-run `deploy_all.sql`, which is idempotent).
- Use `--variable` or environment variables if you need to parameterise custom scripts (the shipped modules do not require parameters).

---

## 4. Partial Redeployment Recipes

### Refresh Semantic Views Only
```sql
EXECUTE IMMEDIATE FROM '@.../sql/03_semantic_views.sql';
EXECUTE IMMEDIATE FROM '@.../sql/05_agent.sql';
EXECUTE IMMEDIATE FROM '@.../sql/06_validation.sql';
```

### Update Agent Instructions
```sql
EXECUTE IMMEDIATE FROM '@.../sql/05_agent.sql';
EXECUTE IMMEDIATE FROM '@.../sql/06_validation.sql';
```

### Re-run Email Integration Test
```sql
EXECUTE IMMEDIATE FROM '@.../sql/02_email_integration.sql';
```

### Full Teardown and Redeploy
```sql
EXECUTE IMMEDIATE FROM '@.../sql/99_cleanup/teardown_all.sql';
EXECUTE IMMEDIATE FROM '@.../sql/01_scaffolding.sql';
EXECUTE IMMEDIATE FROM '@.../sql/02_email_integration.sql';
EXECUTE IMMEDIATE FROM '@.../sql/03_semantic_views.sql';
EXECUTE IMMEDIATE FROM '@.../sql/04_marketplace.sql';
EXECUTE IMMEDIATE FROM '@.../sql/05_agent.sql';
EXECUTE IMMEDIATE FROM '@.../sql/06_validation.sql';
```

---

## 5. Refreshing the Git Stage

If you want to pull the latest commit from GitHub after initial deployment:

1. Run `ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO FETCH;`
2. Execute any modules that changed in the new commit or rerun `deploy_all.sql`.
3. Run `sql/06_validation.sql` to confirm the update.

---

## 6. Troubleshooting Tips

| Symptom | Resolution |
|---------|------------|
| Stage not found when running a module | Run `ALTER GIT REPOSITORY SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO FETCH;` (or rerun `deploy_all.sql`) |
| Permission error in a module | Ensure the module’s `USE ROLE SYSADMIN;` matches your target role or edit the statements |
| Agent missing after redeploy | Run `sql/05_agent.sql`, then `sql/06_validation.sql` |
| Marketplace listing blocked | Accept the legal terms manually, then execute `sql/04_marketplace.sql` again |
| Email not received | Confirm the user email, rerun `sql/02_email_integration.sql`, check spam filters |

---

## 7. Related References

- `README.md` – deployment overview and documentation map
- `docs/01-QUICKSTART.md` – step-by-step Snowsight walkthrough
- `docs/05-ROLE-BASED-ACCESS.md` – customise ownership and user grants
- `docs/06-TESTING.md` – formal test cases
- `docs/07-TROUBLESHOOTING.md` – extended troubleshooting catalogue

Use this guide whenever you need to rerun part of the deployment, promote changes between environments, or execute the scripts from automation tooling.

