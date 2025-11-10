# Sam-the-Snowman: 5-Minute Quickstart

**Total Time**: 5 minutes  
**Goal**: Deploy a working AI agent for Snowflake optimization

---

## Prerequisites (2 minutes)

Before you begin, ensure you have:

- [ ] Snowflake account access
- [ ] `ACCOUNTADMIN` role granted to your user
- [ ] An active warehouse (any size works, e.g., `COMPUTE_WH`)
- [ ] Your work email address handy

```sql
-- Quick check: Do you have ACCOUNTADMIN?
SHOW GRANTS TO USER CURRENT_USER();

-- Quick check: Do you have a warehouse?
SHOW WAREHOUSES;
```

---

## Step 1: Prerequisites (1 minute)

Before you begin, make sure you have:

- [ ] **ACCOUNTADMIN role** access in Snowflake
- [ ] **Active warehouse** (any size, e.g., `COMPUTE_WH`)
- [ ] **Your work email address** ready to configure

Quick check:
```sql
-- Verify you have ACCOUNTADMIN
SHOW GRANTS TO USER CURRENT_USER();

-- Verify you have a warehouse
SHOW WAREHOUSES;
```

---

## Step 2: Deploy (2 minutes)

### The Simple Flow: GitHub URL → Snowsight Workspace → Deploy

Here's exactly how it works:

```
You have: GitHub URL
    ↓
Snowsight creates: Git Workspace (files appear in UI)
    ↓
You run: sql/00_config.sql (mount Git stage)
    ↓
You run: deploy_all.sql
    ↓
Script creates: Git Repository Stage (for automated deployment)
    ↓
Script executes: Modules 01-06 from the stage
    ↓
Result: Working AI agent!
```

---

### Step-by-Step Instructions

#### 2.1: Create a Git Workspace in Snowsight

1. **Open Snowsight** → Navigate to **Projects** > **Workspaces**
2. **Click** → **From Git repository**
3. **Fill in the workspace form**:
   - **Repository URL**: `https://github.com/sfc-gh-miwhitaker/Sam-the-Snowman.git`
   - **Workspace name**: `Sam-the-Snowman` (or leave default)
   - **API Integration**: 
     - If you already have a GitHub API integration, select it from the dropdown
     - If this is your first time, select **+ API Integration** (opens the dialog shown above)
   - **Authentication**: Select **Public repository**

4. **If creating a new API integration**, use these values in the popup:

   | Field | Value | Why |
   |-------|-------|-----|
   | **Name** | `GITHUB_API_INTEGRATION` | Reusable name (choose any descriptive name) |
   | **Allowed prefixes** | `https://github.com/` | ⚠️ Include trailing slash; enables ALL GitHub repos |
   | **Allowed authentication secrets** | `All` (default) | Leave as-is unless you need stricter control |
   | **OAuth authentication** | Leave unchecked | Only needed if using the Snowflake GitHub App |

   > **Important**: The Allowed prefixes field defaults to `https://`. Replace it with `https://github.com/` (generic prefix) so this integration works for every GitHub repository you create in the future.

   Click **Create** to close the dialog. The new integration will appear in the dropdown.

5. Back on the workspace form, ensure your new integration is selected, then click **Create**.

**What just happened?** 
- ✅ Snowflake can now connect to any repository on github.com
- ✅ You can reuse this API integration for future projects
- ✅ Repository files now appear in the left panel! 🎉

#### 2.2: Mount the Git Repository Stage (REQUIRED FIRST!)

**This step creates the Git repository stage that deploy_all.sql needs.**

1. In the workspace file browser, open `sql/00_config.sql` (no edits required)
2. Set worksheet context:
   ```sql
   USE WAREHOUSE COMPUTE_WH;  -- or any warehouse you have
   USE ROLE ACCOUNTADMIN;
   ```
3. Click **Run All** to execute the script

**Expected output**:
```
Database SNOWFLAKE_EXAMPLE created successfully
Schema SNOWFLAKE_EXAMPLE.DEPLOY created successfully
API Integration SFE_GITHUB_API_INTEGRATION created or reused
Git repository SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO created
Git repository fetched successfully
```

Followed by:
- `SHOW GIT REPOSITORIES ...` confirming the repository exists
- `LIST @SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql` showing every SQL module in the stage
- A summary row with the stage path and next action (“Open deploy_all.sql and run all statements.”)

**What just happened?** The stage script:
- ✅ Ensured the demo database and deployment schema exist
- ✅ Created or reused the Git API integration
- ✅ Created the Git repository stage at `@SNOWFLAKE_EXAMPLE.DEPLOY.SFE_SAM_THE_SNOWMAN_REPO`
- ✅ Fetched the latest code and verified the stage is readable from Snowsight

#### 2.3: Run the Main Deployment

**Now that the Git Repository Stage exists, we can deploy the agent.**

1. **In the workspace file browser**, open: `deploy_all.sql`
2. **(Optional)** Adjust the session variables at the top (change `SET role_name = 'SYSADMIN';` if you use a different deployment role)
3. **Verify your context** is still set:
   ```sql
   USE WAREHOUSE COMPUTE_WH;
   USE ROLE ACCOUNTADMIN;
   ```
4. **Click** → **Run All** (or press Cmd/Shift+Enter)
5. **Watch the deployment** ✨

---

### What Happens During Deployment?

**Stage Mount (sql/00_config.sql):**
```
✓ Ensures SNOWFLAKE_EXAMPLE and SNOWFLAKE_EXAMPLE.DEPLOY exist
✓ Creates Git API Integration (SFE_GITHUB_API_INTEGRATION)
✓ Creates Git Repository STAGE (@SNOWFLAKE_EXAMPLE.deploy.SFE_SAM_THE_SNOWMAN_REPO)
✓ Fetches the latest code into the stage
✓ Lists available SQL modules (LIST @stage/branches/main/sql)

Result: Git repository stage ready for deployment!
```

**deploy_all.sql:**
```
✓ Verifies Git Repository Stage exists
✓ Module 1: Scaffolding (databases, schemas, privileges)
✓ Module 2: Email integration (sends test email)
✓ Module 3: Semantic views (query performance analytics)
✓ Module 4: Marketplace documentation
✓ Module 5: AI agent creation
✓ Module 6: Validation (verifies all components)

Result: ✓ All components deployed successfully!
```

**Total Runtime**: ~3-4 minutes (1 min config + 2-3 min deployment)

---

### Key Concept: Why Two Steps?

**The Deployment Flow Explained**:

```
Step 2.2: sql/00_config.sql (run from workspace)
    ↓
Creates Git Repository Stage inside Snowflake
    ↓
Step 2.3: deploy_all.sql (runs FROM the stage)
    ↓
Modules execute from @stage/branches/main/sql/*.sql
```

**Why can't we do it in one step?**

The Git Repository Stage must exist BEFORE deploy_all.sql can reference it with `EXECUTE IMMEDIATE FROM '@stage/path'`. By running sql/00_config.sql first, we create the stage, then deploy_all.sql can use it.

**Three Objects Explained**:

1. **Git API Integration** (account-level, reusable)
   - Grants Snowflake access to github.com
   - Created once: `GITHUB_API_INTEGRATION`
   - Allows all repos: `https://github.com/`

2. **Git Workspace** (UI for browsing/editing)
   - Created in Snowsight
   - Shows repository files in left panel
   - Used to run sql/00_config.sql

3. **Git Repository Stage** (database object for automation)
   - Created by sql/00_config.sql
  - Full clone of repo: `@SNOWFLAKE_EXAMPLE.deploy.SFE_SAM_THE_SNOWMAN_REPO`
   - Used by deploy_all.sql to execute modules

---

## Step 3: Verify (1 minute)

### Check 1: Deployment Success

At the end of your worksheet results, you should see:

```
✓ All components deployed successfully! Sam-the-Snowman is ready to use.
```

### Check 2: Test Email

Check your inbox for an email from Snowflake:
- **Subject**: "Sam-the-Snowman - Test Email"
- **Body**: "Email Integration Test"

If you received it, email notifications work! 🎉

### Check 3: Access Your Agent

1. In Snowsight, navigate to: **AI & ML** > **Agents**
2. You should see **Sam-the-Snowman** listed
3. Click to open it

---

## Step 4: Ask Your First Question (1 minute)

Try these starter questions in the agent interface:

```
What were my top 10 slowest queries today?
```

```
Which warehouses are costing me the most money this month?
```

```
Show me queries with errors in the last 24 hours
```

```
Are my warehouses properly sized based on queue times?
```

---

## What's Next?

### Learn More
- **Architecture**: See `docs/03-ARCHITECTURE.md` for how semantic views power the agent
- **Advanced Deployment**: See `docs/04-ADVANCED-DEPLOYMENT.md` for modular deployment
- **Testing**: See `docs/06-TESTING.md` for comprehensive validation procedures
- **Troubleshooting**: See `docs/07-TROUBLESHOOTING.md` if anything goes wrong

### Customize the Agent
- Add your own semantic views (see `docs/03-ARCHITECTURE.md`)
- Restrict access to specific roles (see `docs/05-ROLE-BASED-ACCESS.md`)
- Deploy additional agents (use this as a template!)

### Share with Your Team
- Grant access: `GRANT ROLE SYSADMIN TO USER colleague_name;`
- They'll see the agent in their Snowsight interface automatically

---

## Troubleshooting Quick Reference

### "ERROR: Unable to determine notification email"
**Fix**: Your Snowflake user profile is missing an email address. Run:
```sql
ALTER USER <username> SET EMAIL = 'your.email@company.com';
```
Then rerun `sql/02_email_integration.sql`.

### "Insufficient privileges"
**Fix**: Ensure you're using `ACCOUNTADMIN` role:
```sql
USE ROLE ACCOUNTADMIN;
```

### "No active warehouse"
**Fix**: Set a warehouse before running deploy_all.sql:
```sql
USE WAREHOUSE COMPUTE_WH;  -- or any warehouse you have
```

### "Marketplace listing requires legal acceptance"
**Fix**: This is normal. Snowflake will prompt you to accept Marketplace terms.
Click "Accept" when prompted, then rerun `deploy_all.sql`.

### Still stuck?
See detailed troubleshooting: `docs/07-TROUBLESHOOTING.md`

---

## Clean Up (Optional)

To remove all Sam-the-Snowman components:

```sql
-- Run the teardown script
USE ROLE ACCOUNTADMIN;
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.deploy.SFE_SAM_THE_SNOWMAN_REPO/branches/main/sql/99_cleanup/teardown_all.sql';
```

**Time**: < 1 minute  
**Effect**: Removes agent, semantic views, email integration. Preserves shared databases per demo standards.

---

## Success! 🎉

You now have a production-ready AI agent analyzing your Snowflake environment.

**What you've deployed:**
- ✅ AI agent powered by Snowflake Cortex
- ✅ Semantic views for query performance, costs, and warehouse ops
- ✅ Email notification system
- ✅ Integrated Snowflake documentation search
- ✅ Role-based access control

**Cost**: Minimal. The agent uses your current warehouse context, so you control compute costs by choosing your warehouse size.

---

**Next**: Explore `docs/` for advanced features, or start asking questions! 🚀

