# Role-Based Access Control

**Sam-the-Snowman – Restricting Access to Specific Teams**

This guide explains how to control who can use the Sam-the-Snowman agent by managing Snowflake roles and grants.

> **Version:** 3.1  
> **Last Updated:** 2025-11-07

---

## Default Access Model

- `sql/00_config.sql` sets the session variable `role_name` (default: `SYSADMIN`). When using the wrapper scripts (`tools/01_deploy.sh` or `tools\01_deploy.bat`), pass `--role YOUR_ROLE` to override this value at deploy time.
- During deployment, **only that role** receives the following privileges:
  - `SNOWFLAKE.CORTEX_USER` database role
  - USAGE on `SNOWFLAKE_EXAMPLE` database and `SNOWFLAKE_EXAMPLE.tools` schema
  - USAGE on `SNOWFLAKE_INTELLIGENCE` database and `SNOWFLAKE_INTELLIGENCE.AGENTS` schema
  - Imported privileges on `snowflake_documentation`
  - USAGE on agent `SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman`
- No PUBLIC grants are issued. Users must have (and activate) the configured role to see and run the agent.

**Implication:** If you deploy with the default settings, only `SYSADMIN` users can see and use Sam-the-Snowman.

---

## Change Access Before Deployment (Recommended)

1. Open `sql/00_config.sql`.
2. Set `role_name` to the Snowflake role that should own and use the agent (for example, `SET role_name = 'DATA_ENGINEERING_TEAM';`).
3. Run `deploy_all.sql` (or execute modules `sql/00_config.sql` → `sql/06_validation.sql`).
4. Grant the chosen role to the appropriate users (`GRANT ROLE DATA_ENGINEERING_TEAM TO USER ...;`).

This ensures all objects are owned and granted correctly from the start.

---

## Grant Additional Roles After Deployment

If you want to allow additional roles (while keeping the original owner role):

```sql
USE ROLE ACCOUNTADMIN;

-- Example: grant access to ANALYTICS_TEAM role
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE ANALYTICS_TEAM;
GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE ANALYTICS_TEAM;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.tools TO ROLE ANALYTICS_TEAM;
GRANT USAGE ON DATABASE SNOWFLAKE_INTELLIGENCE TO ROLE ANALYTICS_TEAM;
GRANT USAGE ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS TO ROLE ANALYTICS_TEAM;
GRANT IMPORTED PRIVILEGES ON DATABASE snowflake_documentation TO ROLE ANALYTICS_TEAM;
GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman TO ROLE ANALYTICS_TEAM;
```

Users must activate the granted role (`USE ROLE ANALYTICS_TEAM;`) to see the agent in Snowsight.

---

## Remove Access from a Role

```sql
USE ROLE ACCOUNTADMIN;

REVOKE USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman FROM ROLE ANALYTICS_TEAM;
REVOKE IMPORTED PRIVILEGES ON DATABASE snowflake_documentation FROM ROLE ANALYTICS_TEAM;
REVOKE USAGE ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS FROM ROLE ANALYTICS_TEAM;
REVOKE USAGE ON DATABASE SNOWFLAKE_INTELLIGENCE FROM ROLE ANALYTICS_TEAM;
REVOKE USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.tools FROM ROLE ANALYTICS_TEAM;
REVOKE USAGE ON DATABASE SNOWFLAKE_EXAMPLE FROM ROLE ANALYTICS_TEAM;
REVOKE DATABASE ROLE SNOWFLAKE.CORTEX_USER FROM ROLE ANALYTICS_TEAM;
```

After revoking, users may need to refresh Snowsight (AI & ML > Agents) to see the agent disappear.

---

## Verification Checklist

```sql
USE ROLE ACCOUNTADMIN;

-- Check which roles can access supporting objects
SHOW GRANTS ON DATABASE SNOWFLAKE_EXAMPLE;
SHOW GRANTS ON SCHEMA SNOWFLAKE_EXAMPLE.tools;
SHOW GRANTS ON DATABASE SNOWFLAKE_INTELLIGENCE;
SHOW GRANTS ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS;
SHOW GRANTS ON DATABASE snowflake_documentation;

-- Check who can run the agent
SHOW GRANTS ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman;
```

Use `SHOW GRANTS TO ROLE <role_name>;` to confirm that users’ active roles provide the required privileges.

---

## Troubleshooting

**Problem:** Users cannot see the agent.
- Verify they have been granted the role specified in `sql/00_config.sql` (or any additional role you granted).
- Confirm the role is active (`USE ROLE ...;`) or inherited via role hierarchy.
- Check Snowsight permissions—users need access to AI & ML features.

**Problem:** Users still see the agent after revoking access.
- Run the revoke statements above to ensure all supporting grants (database, schema, agent, documentation) are removed.
- Ask the user to refresh Snowsight or sign out/in.
- Ensure they are not using a higher-privileged role (e.g., ACCOUNTADMIN) that still has access.

**Problem:** Need to change the owning role after deployment.
- Update `sql/00_config.sql` with the new `role_name`.
- Re-run `sql/01_scaffolding.sql` (transfers ownership) and `sql/05_agent.sql` to recreate the agent with the new owner role.

---

## Quick Reference Commands

```sql
-- Grant access to a new role (summary)
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE <target_role>;
GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE <target_role>;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.tools TO ROLE <target_role>;
GRANT USAGE ON DATABASE SNOWFLAKE_INTELLIGENCE TO ROLE <target_role>;
GRANT USAGE ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS TO ROLE <target_role>;
GRANT IMPORTED PRIVILEGES ON DATABASE snowflake_documentation TO ROLE <target_role>;
GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman TO ROLE <target_role>;

-- Revoke access from a role (summary)
REVOKE USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman FROM ROLE <target_role>;
REVOKE IMPORTED PRIVILEGES ON DATABASE snowflake_documentation FROM ROLE <target_role>;
REVOKE USAGE ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS FROM ROLE <target_role>;
REVOKE USAGE ON DATABASE SNOWFLAKE_INTELLIGENCE FROM ROLE <target_role>;
REVOKE USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.tools FROM ROLE <target_role>;
REVOKE USAGE ON DATABASE SNOWFLAKE_EXAMPLE FROM ROLE <target_role>;
REVOKE DATABASE ROLE SNOWFLAKE.CORTEX_USER FROM ROLE <target_role>;
```

Managing access is as simple as choosing the correct role in `sql/00_config.sql` and granting that role to the right people. Use the commands above to extend or reduce access any time.

