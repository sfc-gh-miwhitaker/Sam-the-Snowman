# Sam-the-Snowman Quickstart

**Time**: ~5 minutes · **Role required**: ACCOUNTADMIN · **Warehouse**: Auto-provisioned

Deploy the Sam-the-Snowman Cortex AI Agent with a single copy/paste operation in Snowsight.

---

## Prerequisites

- ACCOUNTADMIN role granted to your user
- Your Snowflake user profile has an email address configured (for notifications)
- Network access to GitHub and Snowflake Marketplace

> No warehouse setup required—`deploy_all.sql` provisions `SFE_SAM_SNOWMAN_WH` automatically.

---

## Deployment (2 Steps)

### Step 1: Copy the Deployment Script

Open the deployment script on GitHub:

**→ [`deploy_all.sql`](https://github.com/sfc-gh-miwhitaker/Sam-the-Snowman/blob/main/deploy_all.sql)**

Select all content (Cmd/Ctrl+A) and copy (Cmd/Ctrl+C).

### Step 2: Run in Snowsight

1. Open Snowsight and create a new SQL worksheet
2. Paste the entire deployment script (Cmd/Ctrl+V)
3. Click **"Run All"** (▶▶) or press **Cmd/Ctrl+Shift+Enter**

**Expected runtime**: 3-5 minutes

The script will automatically:
- ✓ Create dedicated demo warehouse (`SFE_SAM_SNOWMAN_WH`, X-Small, auto-suspend 60s)
- ✓ Create infrastructure (databases, schemas, API integration, Git repo stage)
- ✓ Deploy all modules from the Git repository stage
- ✓ Create semantic views for query analysis
- ✓ Install Snowflake Documentation (Marketplace)
- ✓ Create the Sam-the-Snowman AI agent
- ✓ Validate the deployment

> No manual warehouse setup required—the script handles compute provisioning.

---

## Verify Deployment

The final query result should show:

```
🎉 Deployment Complete! Sam-the-Snowman is ready.
```

If you see this message, all components were deployed successfully.

**Additional verification steps**:

1. **Check your email** – Look for *"Sam-the-Snowman - Test Email"* from Snowflake Notifications
2. **Navigate to AI & ML → Agents** in Snowsight
3. **Select Sam-the-Snowman** from the agent list

---

## Try the Agent

Click on the Sam-the-Snowman agent and ask:

**Example questions**:
```
What were my top 10 slowest queries today?
```

```
Which warehouses used the most credits this month?
```

```
Send me an email summary of query performance.
```

The agent will use semantic views and Snowflake documentation to analyze your account's query performance and costs.

---

## Troubleshooting

**Error: "Warehouse must be specified"**  
→ Resume the dedicated warehouse: `ALTER WAREHOUSE SFE_SAM_SNOWMAN_WH RESUME;` and rerun the script.

**Error: "Insufficient privileges"**  
→ Ensure you're using `USE ROLE ACCOUNTADMIN;`

**Error: "Failed to connect to GitHub"**  
→ Check that your account allows network access to https://github.com/

**Agent not visible after deployment**  
→ Re-run the validation module:
```sql
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/06_validation.sql';
```

For complete troubleshooting, see: `docs/07-TROUBLESHOOTING.md`

---

## Cleanup (Optional)

To remove all Sam-the-Snowman objects while preserving shared infrastructure:

```sql
USE ROLE ACCOUNTADMIN;
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/99_cleanup/teardown_all.sql';
```

**What gets removed:**
- Sam-the-Snowman agent
- Semantic views (sfe_query_performance, sfe_cost_analysis, sfe_warehouse_operations)
- Email integration (SFE_EMAIL_INTEGRATION)
- Dedicated demo warehouse (SFE_SAM_SNOWMAN_WH)
- Schemas: SNOWFLAKE_EXAMPLE.DEPLOY, SNOWFLAKE_EXAMPLE.INTEGRATIONS, SNOWFLAKE_EXAMPLE.SEMANTIC

**What gets preserved:**
- SNOWFLAKE_EXAMPLE database (shared across demos)
- SNOWFLAKE_INTELLIGENCE database (required by Snowflake, may contain other agents)
- SFE_GITHUB_API_INTEGRATION (reusable for other demos)
- snowflake_documentation database (shared marketplace resource)

---

## Next Steps

- **Detailed deployment docs**: See `docs/01-DEPLOYMENT.md`
- **Advanced deployment options**: See `docs/04-ADVANCED-DEPLOYMENT.md`
- **Role-based access control**: See `docs/05-ROLE-BASED-ACCESS.md`
- **Testing and validation**: See `docs/06-TESTING.md`
- **Troubleshooting guide**: See `docs/07-TROUBLESHOOTING.md`

