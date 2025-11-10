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

## Step 1: Configure (1 minute)

**Edit ONE file**: `sql/00_config.sql`

Find this line:
```sql
SET notification_recipient_email = 'your.email@company.com';
```

Change it to your actual email address:
```sql
SET notification_recipient_email = 'jane.doe@mycompany.com';
```

**That's it!** Everything else uses smart defaults.

---

## Step 2: Deploy (2 minutes)

### The Simple Flow: GitHub URL → Snowsight Workspace → Deploy

Here's exactly how it works:

```
You have: GitHub URL
    ↓
Snowsight creates: Git Workspace (files appear in UI)
    ↓
You edit: sql/00_config.sql (update email)
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

#### 2.2: Edit Your Email Configuration

1. **In the workspace file browser** (left panel), navigate to: `sql/00_config.sql`
2. **Find this line** (around line 46):
   ```sql
   SET notification_recipient_email = 'your.email@company.com';
   ```
3. **Change it** to your actual email:
   ```sql
   SET notification_recipient_email = 'jane.doe@mycompany.com';
   ```
4. **Save the file**: Ctrl+S (Windows) or Cmd+S (Mac)

**Note**: You're editing the file IN the workspace - it won't commit to GitHub (that's fine, this is your personal config).

#### 2.3: Run the Deployment

1. **In the workspace file browser**, open: `deploy_all.sql`
2. **Set your context** (at the top of the SQL editor):
   ```sql
   USE WAREHOUSE COMPUTE_WH;  -- or any warehouse you have
   USE ROLE ACCOUNTADMIN;
   ```
3. **Click** → **Run All** (or press Cmd/Shift+Enter)
4. **Watch the magic** ✨

---

### What Happens During Deployment?

The script executes in this order:

```
Module 0: Configuration (sql/00_config.sql)
   ↓ Validates your email address was updated
   ↓ Creates Git API integration
   ↓ Creates Git Repository STAGE at @SNOWFLAKE_EXAMPLE.tools.SAM_THE_SNOWMAN_REPO
   ↓ This stage is a clone of the GitHub repo inside Snowflake

Module 1-6: (executed FROM the stage)
   ↓ Now modules run from @stage/branches/main/sql/*.sql
   ↓ Creates databases, schemas, privileges
   ↓ Sets up email notifications (sends test email)
   ↓ Deploys semantic views for query analysis
   ↓ Installs Snowflake Documentation (Marketplace)
   ↓ Creates the AI agent
   ↓ Validates everything worked

Result: ✓ All components deployed successfully!
```

**Expected Runtime**: 2-3 minutes

---

### Key Concept: Workspace vs Stage vs API Integration

**Git API Integration** (reusable across projects):
- Account-level object (not database-specific)
- Grants Snowflake permission to access GitHub
- **Allowed Prefixes**: `https://github.com/` (all repos, not just one)
- Created once, reused forever
- Example: `GITHUB_API_INTEGRATION`

**Git Workspace** (per-project UI):
- Lives in Snowsight UI
- Lets you browse/edit files for ONE repository
- Connected to a specific GitHub repository URL
- Used for development
- References the API Integration for authentication

**Git Repository Stage** (per-project database object):
- Lives in Snowflake database as a stage object
- Used for automated deployment
- A full clone of the GitHub repo inside Snowflake
- Created by deployment script
- Example: `@SNOWFLAKE_EXAMPLE.tools.SAM_THE_SNOWMAN_REPO`

**The Flow**:
```
API Integration (once) → allows access to github.com
    ↓
Workspace (per project) → browses specific repo
    ↓
Stage (per project) → clones repo for automation
```

The script uses `@@sql/00_config.sql` to reference the workspace file, then that file creates the stage, then modules 01-06 execute FROM the stage. Clever! 🧠

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

### "ERROR: You must update notification_recipient_email"
**Fix**: You forgot to edit `sql/00_config.sql` - go back to Step 1

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
EXECUTE IMMEDIATE FROM '@SNOWFLAKE_EXAMPLE.tools.SAM_THE_SNOWMAN_REPO/branches/main/sql/99_cleanup/teardown_all.sql';
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

