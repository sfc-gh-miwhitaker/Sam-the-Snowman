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
Edit Config (sql/00_config.sql)
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

## Step 1: Configure Email Address (1 minute)

**Edit ONE file**: `sql/00_config.sql`

### 1.1: Open the Configuration File

In your preferred editor or Snowsight:
1. Navigate to the `sql/` directory
2. Open `00_config.sql`

### 1.2: Find the Email Configuration

Look for this section (around line 46):

```sql
-- ⚠️  REQUIRED: Your email address for test notifications
-- The deployment will send a test email to confirm the integration works
-- REPLACE 'your.email@company.com' WITH YOUR ACTUAL EMAIL ADDRESS
SET notification_recipient_email = 'your.email@company.com';
```

### 1.3: Update Your Email

Change the placeholder to your actual email address:

```sql
SET notification_recipient_email = 'jane.doe@mycompany.com';  -- your real email
```

### 1.4: (Optional) Review Advanced Settings

The file also contains Git integration settings. **You don't need to change these** unless you:
- Forked the repository to your own GitHub
- Want to use a different role (default is SYSADMIN)

**For first-time deployment**: Leave all other settings at their defaults.

### 1.5: Save the File

**Important**: If editing outside Snowsight, make sure you save the file!

---

## Step 2: Deploy Sam-the-Snowman (2-3 minutes)

### The Complete Flow Explained

Here's the step-by-step journey from GitHub URL to working agent:

```
GitHub Repository
    ↓
Snowsight Git Workspace (UI for browsing/editing files)
    ↓
Edit sql/00_config.sql (update email)
    ↓
Run sql/00_config.sql (creates Git Repository Stage)
    ↓
Run deploy_all.sql (executes modules FROM stage)
    ↓
Working Agent!
```

**Key Point**: We run TWO scripts:
1. **sql/00_config.sql** - Creates the Git Repository Stage
2. **deploy_all.sql** - Uses that stage to execute modules

---

### Step-by-Step Deployment

#### 2.1: Open Snowsight

Navigate to your Snowflake web interface:
- URL format: `https://<your_account>.snowflakecomputing.com`
- Example: `https://abc12345.us-east-1.snowflakecomputing.com`

#### 2.2: Create a Git Workspace

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

#### 2.3: Run Configuration Setup (REQUIRED FIRST!)

**This step creates the Git Repository Stage that deploy_all.sql needs.**

1. **In the file browser** (left panel), navigate to: `sql/`
2. **Click to open**: `00_config.sql`
3. **Find this line** (around line 46):
   ```sql
   SET notification_recipient_email = 'your.email@company.com';
   ```
4. **Update it** to your actual email address:
   ```sql
   SET notification_recipient_email = 'jane.doe@mycompany.com';
   ```
5. **Set your context** at the top of the SQL editor:
   ```sql
   USE ROLE ACCOUNTADMIN;
   USE WAREHOUSE COMPUTE_WH;  -- or your warehouse name
   ```
6. **Click** → **Run All** to execute sql/00_config.sql

**Expected output**:
```
Configuration validation passed. Email: jane.doe@mycompany.com
Database SNOWFLAKE_EXAMPLE created successfully
Schema TOOLS created successfully
API Integration SFE_GITHUB_API_INTEGRATION created successfully
Git Repository Stage created successfully
Git repository fetched successfully
Configuration and Git setup complete
```

**What just happened?**
- ✅ Validated your email address was updated
- ✅ Created databases and schemas
- ✅ Created Git API Integration
- ✅ Created Git Repository Stage at `@SNOWFLAKE_EXAMPLE.tools.SAM_THE_SNOWMAN_REPO`
- ✅ Cloned the repository into Snowflake for deployment

**Important**: You're editing the file IN the workspace. This is your personal copy - it won't commit changes to GitHub (that's fine, this is config specific to your deployment).

**Why this matters**: The Git Repository Stage is a full clone of the GitHub repo inside Snowflake. deploy_all.sql uses this stage to execute modules with `EXECUTE IMMEDIATE FROM '@stage/path'`.

#### 2.4: Run the Main Deployment

**Now that the Git Repository Stage exists, we can deploy the agent.**

1. **In the file browser**, navigate back to root and open: `deploy_all.sql`
2. **Verify your context** is still set (if not, set it again):
   ```sql
   USE ROLE ACCOUNTADMIN;
   USE WAREHOUSE COMPUTE_WH;
   ```
3. **Review the prerequisite check** (optional) - the script verifies the Git Repository Stage exists
4. **Click** → **Run All** (or press `Cmd+Shift+Enter` / `Ctrl+Shift+Enter`)
5. **Watch the deployment progress** in the output panel

**What you'll see**:
- Prerequisite check: "Git Repository Stage verified. Proceeding with deployment..."
- Each module executes sequentially FROM the stage
- Status messages appear in the results panel
- Green checkmarks ✓ when modules complete
- Total runtime: 2-3 minutes

---

### What Happens During Deployment

**Step 2.3** (sql/00_config.sql) - watch the output panel:

```
✓ Configuration validation
  - Email address verified
  - Settings validated

✓ Database scaffolding
  - SNOWFLAKE_EXAMPLE database created
  - TOOLS schema created

✓ Git integration
  - SFE_GITHUB_API_INTEGRATION created (or confirmed existing)
  - Git Repository Stage created: @SNOWFLAKE_EXAMPLE.tools.SAM_THE_SNOWMAN_REPO
  - Repository cloned into stage
  - Latest code fetched

Result: "Configuration and Git setup complete"
```

**Step 2.4** (deploy_all.sql) - modules execute FROM the stage:

```
✓ Prerequisite Check
  - Git Repository Stage verified: ✓

✓ Module 1: Scaffolding
  - SNOWFLAKE_INTELLIGENCE database created
  - Additional schemas and privileges

✓ Module 2: Email Integration
  - SFE_EMAIL_INTEGRATION created
  - send_email procedure deployed
  - Test email sent to your address

✓ Module 3: Semantic Views
  - query_performance view created
  - cost_analysis view created
  - warehouse_operations view created

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

## Step 3: Verify Deployment (1 minute)

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

## Step 4: Ask Your First Question (1 minute)

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

Located in `SNOWFLAKE_EXAMPLE.tools`:

- `query_performance` - Query execution metrics, errors, optimization opportunities
- `cost_analysis` - Warehouse credit consumption and cost tracking
- `warehouse_operations` - Warehouse utilization and capacity planning

### Agent

Located at `SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman`:

**Tools available**:
- Cortex Analyst (query_performance, cost_analysis, warehouse_operations)
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

### "ERROR: You must update notification_recipient_email"

**Cause**: You forgot to edit `sql/00_config.sql`  
**Fix**: Go back to Step 1, update your email address, then rerun `deploy_all.sql`

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
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.tools.SAM_THE_SNOWMAN_REPO/branches/main/sql/99_cleanup/teardown_all.sql';
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

