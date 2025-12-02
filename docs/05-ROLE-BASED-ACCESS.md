# Role-Based Access Control

**Version**: 4.0 · **Last updated**: 2025-11-10

Sam-the-Snowman ships with the SYSADMIN role as the default owner. This guide explains how to keep that default secure, how to switch to a different owning role, and how to grant read-only access to additional teams.

---

## 1. Default Ownership (SYSADMIN)

The shipping SQL modules contain explicit `USE ROLE SYSADMIN;` statements and grant privileges to SYSADMIN. This means:

- Only users who activate `SYSADMIN` can see and use the agent.
- No PUBLIC grants are created.
- The cleanup script can safely remove all demo objects owned by SYSADMIN.

### Granting Access to Users

```sql
USE ROLE ACCOUNTADMIN;
GRANT ROLE SYSADMIN TO USER <username>;
```

Users must activate the role before opening the agent:
```sql
USE ROLE SYSADMIN;
```

---

## 2. Deploying with a Different Owning Role

To use a custom role (for example `SAM_AGENT_ADMIN`) you must edit the SQL modules before deploying.

1. **Create or identify the role**
   ```sql
   USE ROLE ACCOUNTADMIN;
   CREATE ROLE IF NOT EXISTS SAM_AGENT_ADMIN;
   GRANT ROLE SAM_AGENT_ADMIN TO USER <owner_username>;
   ```
2. **Edit the following files** and replace `USE ROLE SYSADMIN;` / `GRANT ... TO ROLE SYSADMIN` with your custom role:
   - `sql/01_scaffolding.sql`
   - `sql/02_email_integration.sql`
   - `sql/03_semantic_views.sql`
   - `sql/04_marketplace.sql`
   - `sql/05_agent.sql`
3. **Deploy** using the standard workflow (`deploy_all.sql` orchestrator).

The custom role receives ownership of all objects, and cleanup continues to work as long as the role names remain consistent.

> Remember to keep the modified scripts under version control if you plan to redeploy in the future.

---

## 3. Granting Usage to Additional Roles

After deployment you can grant read-only access to other teams without changing the owner.

```sql
USE ROLE ACCOUNTADMIN;

-- Example: share with ANALYTICS_TEAM
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE ANALYTICS_TEAM;
GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE ANALYTICS_TEAM;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS TO ROLE ANALYTICS_TEAM;
GRANT SELECT ON ALL VIEWS IN SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC_MODELS TO ROLE ANALYTICS_TEAM;
GRANT USAGE ON WAREHOUSE SFE_SAM_SNOWMAN_WH TO ROLE ANALYTICS_TEAM;
GRANT USAGE ON DATABASE SNOWFLAKE_INTELLIGENCE TO ROLE ANALYTICS_TEAM;
GRANT USAGE ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS TO ROLE ANALYTICS_TEAM;
GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman TO ROLE ANALYTICS_TEAM;
GRANT IMPORTED PRIVILEGES ON DATABASE snowflake_documentation TO ROLE ANALYTICS_TEAM;
```

Users activate the granted role before launching the agent:
```sql
USE ROLE ANALYTICS_TEAM;
```

---

## 4. Revoking Access or Cleaning Up

To remove a role’s access without dropping objects:
```sql
USE ROLE ACCOUNTADMIN;
REVOKE USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman FROM ROLE ANALYTICS_TEAM;
REVOKE USAGE ON DATABASE SNOWFLAKE_EXAMPLE FROM ROLE ANALYTICS_TEAM;
REVOKE DATABASE ROLE SNOWFLAKE.CORTEX_USER FROM ROLE ANALYTICS_TEAM;
```

To remove the demo entirely use `sql/99_cleanup/teardown_all.sql` (runs as ACCOUNTADMIN and drops the objects regardless of owning role).

---

## 5. Troubleshooting

| Issue | Resolution |
|-------|------------|
| Agent not visible in Snowsight | Activate the owning role (`USE ROLE SYSADMIN;`) or grant it to the user |
| Permission error when editing modules | Ensure you replaced every `USE ROLE SYSADMIN;` statement with your custom role |
| Analysts can see agent but not run queries | Grant `SNOWFLAKE.CORTEX_USER` and schema usage to their role |
| Email test fails after role change | Confirm the custom role has `USAGE` on the integration and procedure (rerun `sql/02_email_integration.sql`) |

---

## Related References

- `docs/04-ADVANCED-DEPLOYMENT.md` – partial redeployments and Snow CLI usage
- `docs/06-TESTING.md` – verification checklist after changing grants
- `docs/07-TROUBLESHOOTING.md` – additional issues and fixes

With these steps you can safely control who owns the Sam-the-Snowman assets and who is allowed to use the agent.
