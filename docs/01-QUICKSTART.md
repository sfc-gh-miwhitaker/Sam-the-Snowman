# Sam-the-Snowman: Detailed Quickstart Guide

**Total Time**: 5-7 minutes  
**Difficulty**: Beginner  
**Prerequisites**: ACCOUNTADMIN role, active warehouse

This guide provides a detailed walkthrough with validation checks at each step.

---

## Visual Deployment Flow

```
Prerequisites Check
       ↓
Run Stage Mount (sql/00_config.sql)
       ↓
Run deploy_all.sql (2-3 minutes)
       ↓
Verify Email Received
       ↓
Access Agent in Snowsight
       ↓
Ask First Question
       ↓
Done! 🎉
```

---

## Step 0: Prerequisites Check (2 minutes)

### Check 1: ACCOUNTADMIN Role

```sql
-- Check your current role
SELECT CURRENT_ROLE();

-- Check roles available to you
SHOW GRANTS TO USER CURRENT_USER();
```

**Expected**: You should see `ACCOUNTADMIN` in the list of granted roles.

**If missing**: Ask your Snowflake administrator to grant you ACCOUNTADMIN:
```sql
GRANT ROLE ACCOUNTADMIN TO USER your_username;
```

### Check 2: Active Warehouse

```sql
-- List available warehouses
SHOW WAREHOUSES;

-- Set an active warehouse
USE WAREHOUSE COMPUTE_WH;  -- replace with any warehouse from the list above
```

**Expected**: You should see at least one warehouse listed.

**If missing**: Create a warehouse (or ask your admin):
```sql
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH 
    WAREHOUSE_SIZE = XSMALL 
    AUTO_SUSPEND = 60 
    AUTO_RESUME = TRUE;
```

### Check 3: Network Access

Sam-the-Snowman will install the Snowflake Documentation listing from the Marketplace. This requires:
- Network access to Snowflake Marketplace
- Ability to accept legal terms for Marketplace listings

**No special action needed** - deployment will prompt you if access is blocked.

---

## Step 1: Create a Snowsight Workspace (1 minute)

### 1.1: Open Snowsight

Navigate to your Snowflake web interface:
- URL format: `https://<your_account>.snowflakecomputing.com`
- Example: `https://abc12345.us-east-1.snowflakecomputing.com`

### 1.2: Create a Git Workspace

1. **Navigate to** → **Projects** > **Workspaces**
2. **Click** → **From Git repository**
3. **Fill in the workspace form**:

| Field | Value |
|-------|-------|
| Repository URL | `https://github.com/sfc-gh-miwhitaker/Sam-the-Snowman.git` |
| Workspace name | `Sam-the-Snowman` (or leave default) |
| API Integration | Select existing OR click **+ API Integration** (opens popup) |
| Authentication | Select **Public repository** |

4. **If creating a new API Integration** (first-time setup), configure the popup with these values:

| Field | Value | Notes |
|-------|-------|-------|
| **Name** | `GITHUB_API_INTEGRATION` | Any descriptive name works |
| **Allowed prefixes** | `https://github.com/` | ⚠️ Replace default `https://` with this generic prefix (include trailing slash) |
| **Allowed authentication secrets** | `All` (default) | Leave as-is unless you require stricter control |
| **OAuth authentication** | Leave unchecked | Only enable if using Snowflake GitHub App |

Click **Create** in the popup. The new integration now appears in the dropdown.

> **Critical**: Do **not** use a repo-specific URL in Allowed prefixes. Using `https://github.com/` lets you reuse this API integration for every GitHub repository you connect in the future.

5. Back on the workspace form, ensure your integration is selected, then click **Create**.

**What just happened?**  
- ✅ Created an API Integration (or selected existing one) that grants Snowflake access to **all** repositories on github.com
- ✅ Created a Workspace connected to this specific repository
- ✅ Repository files now appear in the left panel! 🎉

**Why generic prefix?** The API Integration is an **account-level object** that you'll reuse across many projects. Setting `Allowed Prefixes` to `https://github.com/` means you can create workspaces for any GitHub repo without creating new integrations each time.

## Step 2: Mount the Git Repository Stage (1 minute)

**This step creates the Git repository stage that deploy_all.sql needs.**

1. In the workspace file browser, navigate to `sql/`
2. Open `00_config.sql` (no edits required)
3. Set context at the top of the worksheet:
   ```sql
   USE ROLE ACCOUNTADMIN;
   USE WAREHOUSE COMPUTE_WH;  -- or your preferred warehouse
   ```
4. Click **Run All** to execute the script

**Expected output:**
```
Database SNOWFLAKE_EXAMPLE created successfully
Schema SNOWFLAKE_EXAMPLE.DEPLOY created successfully
API Integration SFE_GITHUB_API_INTEGRATION created or reused
Git repository SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO created
Git repository fetched successfully
```

Followed by:
- `SHOW GIT REPOSITORIES ...` confirming the repository exists
- `LIST @SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql` showing every SQL module available in the stage
- A one-row summary with the exact stage path and the next action (“Open deploy_all.sql and run all statements.”)

**What just happened?**
- ✅ Ensured the demo database and deployment schema exist
- ✅ Created or reused the `SFE_GITHUB_API_INTEGRATION`
- ✅ Created the Git repository stage at `@SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO`
- ✅ Fetched the latest code and confirmed the stage is readable from Snowsight
- ✅ Displayed the exact stage path you’ll use in the next step

**Important**: You're editing the file IN the workspace. This is your personal copy - it won't commit changes to GitHub (that's fine, this is config specific to your deployment).

**Why this matters**: The Git Repository Stage is a full clone of the GitHub repo inside Snowflake. deploy_all.sql uses this stage to execute modules with `EXECUTE IMMEDIATE FROM '@stage/path'`.

## Step 3: Run the Main Deployment

**Now that the Git Repository Stage exists, we can deploy the agent.**

1. **In the file browser**, navigate back to root and open: `deploy_all.sql`
2. **(Optional)** Customize the session variables at the top (e.g., change `SET role_name = 'SYSADMIN';` if you use a different deployment role)
3. **Verify your context** is still set (if not, set it again):
   ```sql
   USE ROLE ACCOUNTADMIN;
   USE WAREHOUSE COMPUTE_WH;
   ```
4. **Review the prerequisite check** (optional) - the script verifies the Git Repository Stage exists
5. **Click** → **Run All** (or press `Cmd+Shift+Enter` / `Ctrl+Shift+Enter`)
6. **Watch the deployment progress** in the output panel

**What you'll see**:
- Prerequisite check: "Git Repository Stage verified. Proceeding with deployment..."
- Each module executes sequentially FROM the stage
- Status messages appear in the results panel
- Green checkmarks ✓ when modules complete
- Total runtime: 2-3 minutes

---

### What Happens During Deployment

**Stage Mount (sql/00_config.sql)** - watch the output panel:

```
✓ Stage mount prerequisites
  - SNOWFLAKE_EXAMPLE database created (idempotent)
  - SNOWFLAKE_EXAMPLE.DEPLOY schema created (idempotent)

✓ Git integration
  - SFE_GITHUB_API_INTEGRATION created (or confirmed existing)
  - Git Repository Stage created: @SNOWFLAKE_EXAMPLE.deploy.SFE_SAM_THE_SNOWMAN_REPO
  - Repository cloned into stage
  - Latest code fetched
  - Stage contents listed (LIST command) to confirm availability of all SQL modules
  - Summary row returned with stage path and next action

Result: Stage mounted and ready for deploy_all.sql
```

**deploy_all.sql** - modules execute FROM the stage:

```
✓ Prerequisite Check
  - Git Repository Stage verified: ✓

✓ Module 1: Scaffolding
  - SNOWFLAKE_INTELLIGENCE database created
  - Additional schemas and privileges

✓ Module 2: Email Integration
  - SFE_EMAIL_INTEGRATION created
  - sfe_send_email procedure deployed (Python Snowpark)
  - Notification output confirms which email address will be used
  - Test email sent to your address

✓ Module 3: Semantic Views
  - sfe_query_performance view created
  - sfe_cost_analysis view created
  - sfe_warehouse_operations view created

✓ Module 4: Marketplace Documentation
  - Snowflake Documentation installed (may prompt for legal acceptance)

✓ Module 5: Agent Creation
  - sam_the_snowman agent deployed
  - All tools and capabilities enabled

✓ Module 6: Validation
  - All components verified: PASS ✓
```

**Total Runtime**: ~3-4 minutes (1 min config + 2-3 min deployment)

**If prompted about Marketplace terms**: Click "Accept" and the deployment will continue automatically.

---

## Step 4: Verify Deployment (1 minute)

### 3.1: Check Final Output

At the very end of your worksheet results, you should see:

```
| deployment_status                                                           |
|-----------------------------------------------------------------------------|
| ✓ All components deployed successfully! Sam-the-Snowman is ready to use.  |
```

**If you see this**: Deployment succeeded! Proceed to Step 3.2.

**If you see "Some components failed"**: See [`docs/07-TROUBLESHOOTING.md`](07-TROUBLESHOOTING.md)

### 3.2: Check Your Email

Within 1-2 minutes, check your inbox for:

- **From**: Snowflake Notifications
- **Subject**: "Sam-the-Snowman - Test Email"
- **Body**: "Email Integration Test" with HTML formatting

**If received**: Email integration works! 🎉  
**If not received**: Check spam folder, or verify email domain is allow-listed (see Troubleshooting)

### 3.3: Verify Agent in Snowsight

1. In Snowsight, click the **hamburger menu** (top-left)
2. Navigate to **AI & ML** > **Agents**
3. You should see **Sam-the-Snowman** listed

**If visible**: Agent deployed successfully! 🎉  
**If not visible**: Refresh the page, or check you're using the configured role (default: SYSADMIN)

---

## Step 5: Ask Your First Question (1 minute)

### 4.1: Open the Agent

In Snowsight:
1. Navigate to **AI & ML** > **Agents**
2. Click on **Sam-the-Snowman**

### 4.2: Test with a Simple Query

Type this question in the chat interface:

```
What were my top 5 slowest queries today?
```

**Expected Response**:
- The agent will query `SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY`
- You'll see a table with query_id, query_text, execution_time, warehouse_name
- The agent will provide analysis and recommendations

**If it works**: Congratulations! Your agent is fully operational! 🚀

**If it fails**: See [`docs/07-TROUBLESHOOTING.md`](07-TROUBLESHOOTING.md)

### 4.3: Try More Complex Questions

Now try these:

```
Which warehouses are costing me the most money this month?
```

```
Show me queries with errors in the last 24 hours
```

```
Send me an email summary of query performance
```

**Expected**: The agent will use different semantic views and tools based on your question.

---

## What You've Deployed

### Databases

| Database | Purpose | Owner |
|----------|---------|-------|
| `SNOWFLAKE_EXAMPLE` | Demo database for semantic views and tools | Configured role (default: SYSADMIN) |
| `SNOWFLAKE_INTELLIGENCE` | Required by Snowflake for agents | Configured role (default: SYSADMIN) |
| `snowflake_documentation` | Marketplace listing for documentation search | ACCOUNTADMIN |

### Semantic Views

Located in `SNOWFLAKE_EXAMPLE.semantic`:

- `sfe_query_performance` - Query execution metrics, errors, optimization opportunities
- `sfe_cost_analysis` - Warehouse credit consumption and cost tracking
- `sfe_warehouse_operations` - Warehouse utilization and capacity planning

### Agent

Located at `SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman`:

**Tools available**:
- Cortex Analyst (sfe_query_performance, sfe_cost_analysis, sfe_warehouse_operations)
- Cortex Search (snowflake_knowledge_ext_documentation)
- Email delivery (cortex_email_tool)

**Access**: Restricted to configured role only (default: SYSADMIN)

---

## Next Steps

### Share with Your Team

Grant the configured role to colleagues:

```sql
GRANT ROLE SYSADMIN TO USER colleague_name;
```

They'll automatically see the agent in their Snowsight interface.

### Customize the Agent

- **Add your own semantic views**: See [`docs/03-ARCHITECTURE.md`](03-ARCHITECTURE.md)
- **Restrict to specific roles**: See [`docs/05-ROLE-BASED-ACCESS.md`](05-ROLE-BASED-ACCESS.md)
- **Modify agent instructions**: Edit `sql/05_agent.sql` and redeploy

### Learn More

- **Architecture deep-dive**: [`docs/03-ARCHITECTURE.md`](03-ARCHITECTURE.md)
- **Modular deployment**: [`docs/04-ADVANCED-DEPLOYMENT.md`](04-ADVANCED-DEPLOYMENT.md)
- **Testing procedures**: [`docs/06-TESTING.md`](06-TESTING.md)
- **Troubleshooting**: [`docs/07-TROUBLESHOOTING.md`](07-TROUBLESHOOTING.md)

---

## Troubleshooting Quick Reference

### "ERROR: Unable to determine notification email"

**Cause**: Your Snowflake user profile does not have an email address.  
**Fix**: Ask an administrator (or yourself) to run `ALTER USER <username> SET EMAIL = 'your.email@company.com';`, then rerun `sql/02_email_integration.sql`.

### "Insufficient privileges to perform operation"

**Cause**: You're not using ACCOUNTADMIN role  
**Fix**: Run `USE ROLE ACCOUNTADMIN;` before executing `deploy_all.sql`

### "No active warehouse selected"

**Cause**: No warehouse context is set  
**Fix**: Run `USE WAREHOUSE <your_warehouse>;` before executing `deploy_all.sql`

### "Marketplace listing requires legal acceptance"

**Cause**: Normal behavior for first-time Marketplace installation  
**Fix**: Click "Accept" when prompted, deployment will continue automatically

### Agent not visible in Snowsight

**Cause**: You don't have the configured role (default: SYSADMIN)  
**Fix**: Have your admin grant you the role: `GRANT ROLE SYSADMIN TO USER your_username;`

### Still stuck?

See comprehensive troubleshooting guide: [`docs/07-TROUBLESHOOTING.md`](07-TROUBLESHOOTING.md)

---

## Cleanup (Optional)

To remove all Sam-the-Snowman components:

```sql
USE ROLE ACCOUNTADMIN;
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.deploy.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/99_cleanup/teardown_all.sql';
```

**Time**: < 1 minute  
**Effect**: Removes agent, semantic views, email integration  
**Preserved**: Shared databases per demo project standards

---

## Success! 🎉

You now have a production-ready AI agent for Snowflake optimization.

**What's working:**
- ✅ AI agent analyzing your query history
- ✅ Semantic views for performance, cost, and operations
- ✅ Email notifications
- ✅ Integrated documentation search
- ✅ Role-based access control

**Cost**: Minimal. The agent uses your current warehouse context - you control compute costs.

---

**Questions?** See [`docs/07-TROUBLESHOOTING.md`](07-TROUBLESHOOTING.md) or open a GitHub issue.

