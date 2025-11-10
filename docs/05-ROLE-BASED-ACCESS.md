# Role-Based Access Control

**Sam-the-Snowman – Complete Guide to Role Management**

**Version:** 4.1  
**Last Updated:** 2025-11-10

---

## Overview

This guide covers all aspects of role-based access control for Sam-the-Snowman:
- **Default deployment** with SYSADMIN
- **Custom role deployment** for enterprise needs
- **Access management** for adding/removing users
- **Advanced scenarios** for complex environments
- **Troubleshooting** common role issues

**Quick Navigation**:
- [Part 1: Default Deployment](#part-1-default-deployment-sysadmin) - Start here for basic setup
- [Part 2: Custom Role Deployment](#part-2-custom-role-deployment) - Enterprise requirements
- [Part 3: Access Management](#part-3-access-management-after-deployment) - Add/remove users
- [Part 4: Advanced Scenarios](#part-4-advanced-scenarios) - Complex environments
- [Part 5: Troubleshooting](#part-5-troubleshooting--reference) - Common issues

---

## Part 1: Default Deployment (SYSADMIN)

### Quick Start

By default, Sam-the-Snowman uses the **SYSADMIN** role:

```sql
-- sql/00_config.sql (line 44)
SET role_name = 'SYSADMIN';
```

**What gets access**:
- The SYSADMIN role receives all privileges
- Users with SYSADMIN can see and use the agent
- No PUBLIC grants are issued (secure by default)

**To deploy**:
1. Keep default `role_name = 'SYSADMIN'` in `sql/00_config.sql`
2. Run deployment: `@sql/00_config.sql` → `@deploy_all.sql`
3. Grant SYSADMIN to users who need access

### Default Privileges Granted

During deployment, SYSADMIN receives:

| Privilege | Object | Purpose |
|-----------|--------|---------|
| `SNOWFLAKE.CORTEX_USER` | Database role | AI/ML features (required) |
| `USAGE` | `SNOWFLAKE_EXAMPLE` database | Access demo database |
| `USAGE` | `SNOWFLAKE_EXAMPLE.DEPLOY` schema | Access Git repository |
| `USAGE` | `SNOWFLAKE_EXAMPLE.INTEGRATIONS` schema | Access email procedure |
| `USAGE` | `SNOWFLAKE_EXAMPLE.SEMANTIC` schema | Access semantic views |
| `USAGE` | `SNOWFLAKE_INTELLIGENCE` database | Access agent infrastructure |
| `USAGE` | `SNOWFLAKE_INTELLIGENCE.AGENTS` schema | Access agents schema |
| `IMPORTED PRIVILEGES` | `snowflake_documentation` | Documentation search |
| `USAGE` | Agent `sam_the_snowman` | Run the agent |

**Access Model**: No PUBLIC grants → Users must have (and activate) SYSADMIN role to see the agent.

---

## Part 2: Custom Role Deployment

### When to Use Custom Roles

Use a custom role instead of SYSADMIN when:
- ✅ Your organization doesn't use SYSADMIN for application ownership
- ✅ You have dedicated roles for data engineering, analytics, or AI
- ✅ You need to restrict access to specific teams
- ✅ Compliance requires role-based segregation
- ✅ You're deploying to dev/test/prod environments separately

### How to Deploy with Custom Role

**3-Step Process**:

#### Step 1: Create or Identify Role

```sql
USE ROLE ACCOUNTADMIN;

-- Option A: Use existing role
SHOW ROLES LIKE 'DATA_ENGINEER_ROLE';

-- Option B: Create new role
CREATE ROLE IF NOT EXISTS SAM_AGENT_ADMIN
COMMENT = 'Role for managing Sam-the-Snowman agent';

-- Grant to appropriate users
GRANT ROLE SAM_AGENT_ADMIN TO USER jane_doe;
GRANT ROLE SAM_AGENT_ADMIN TO USER john_smith;
```

#### Step 2: Update Configuration

Edit `sql/00_config.sql` line 44:

```sql
-- Change from default
SET role_name = 'SYSADMIN';

-- To your custom role
SET role_name = 'SAM_AGENT_ADMIN';
```

#### Step 3: Deploy

```sql
-- From Snowsight Git Workspace
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;

-- Run configuration (uses custom role)
@sql/00_config.sql

-- Run deployment (grants to custom role)
@deploy_all.sql
```

**Result**: Agent is owned by `SAM_AGENT_ADMIN` instead of SYSADMIN.

### Custom Role Requirements

Your custom role needs these minimum privileges:

```sql
USE ROLE ACCOUNTADMIN;

-- 1. Cortex access (REQUIRED)
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE your_custom_role;

-- 2. Database ownership
GRANT OWNERSHIP ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE your_custom_role COPY CURRENT GRANTS;
GRANT OWNERSHIP ON SCHEMA SNOWFLAKE_EXAMPLE.DEPLOY TO ROLE your_custom_role;
GRANT OWNERSHIP ON SCHEMA SNOWFLAKE_EXAMPLE.INTEGRATIONS TO ROLE your_custom_role;
GRANT OWNERSHIP ON SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC TO ROLE your_custom_role;

-- 3. Agent infrastructure
GRANT OWNERSHIP ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS TO ROLE your_custom_role COPY CURRENT GRANTS;

-- 4. ACCOUNT_USAGE access (for semantic views)
GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE TO ROLE your_custom_role;

-- 5. Warehouse usage
GRANT USAGE ON WAREHOUSE COMPUTE_WH TO ROLE your_custom_role;
```

**Note**: The deployment script automatically grants these, but you may need to pre-grant in restricted environments.

---

## Part 3: Access Management (After Deployment)

### Grant Access to Additional Roles

After deploying with one role (e.g., SYSADMIN), you can grant access to other roles:

```sql
USE ROLE ACCOUNTADMIN;

-- Example: grant access to ANALYTICS_TEAM role
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE ANALYTICS_TEAM;
GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE ANALYTICS_TEAM;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.DEPLOY TO ROLE ANALYTICS_TEAM;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.INTEGRATIONS TO ROLE ANALYTICS_TEAM;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC TO ROLE ANALYTICS_TEAM;
GRANT USAGE ON DATABASE SNOWFLAKE_INTELLIGENCE TO ROLE ANALYTICS_TEAM;
GRANT USAGE ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS TO ROLE ANALYTICS_TEAM;
GRANT IMPORTED PRIVILEGES ON DATABASE snowflake_documentation TO ROLE ANALYTICS_TEAM;
GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman TO ROLE ANALYTICS_TEAM;
```

**Usage**: Users activate the role (`USE ROLE ANALYTICS_TEAM;`) to see the agent in Snowsight.

### Grant Read-Only Access (Analysts)

For users who should use the agent but not manage infrastructure:

```sql
USE ROLE ACCOUNTADMIN;

-- Create read-only user role
CREATE ROLE IF NOT EXISTS SAM_AGENT_USER
COMMENT = 'Read-only access to Sam-the-Snowman agent';

-- Grant minimum privileges (agent + semantic views only)
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE SAM_AGENT_USER;
GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE SAM_AGENT_USER;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC TO ROLE SAM_AGENT_USER;
GRANT SELECT ON ALL VIEWS IN SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC TO ROLE SAM_AGENT_USER;
GRANT USAGE ON DATABASE SNOWFLAKE_INTELLIGENCE TO ROLE SAM_AGENT_USER;
GRANT USAGE ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS TO ROLE SAM_AGENT_USER;
GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman TO ROLE SAM_AGENT_USER;
GRANT IMPORTED PRIVILEGES ON DATABASE snowflake_documentation TO ROLE SAM_AGENT_USER;
```

**Access Model**:
| Role | Can Use Agent? | Can Modify Views? | Can Manage Agent? |
|------|----------------|-------------------|-------------------|
| **Owner** (e.g., SAM_AGENT_ADMIN) | ✅ Yes | ✅ Yes | ✅ Yes |
| **User** (e.g., SAM_AGENT_USER) | ✅ Yes | ❌ No | ❌ No |

### Remove Access from a Role

To revoke access completely:

```sql
USE ROLE ACCOUNTADMIN;

-- Revoke in reverse order
REVOKE USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman FROM ROLE ANALYTICS_TEAM;
REVOKE IMPORTED PRIVILEGES ON DATABASE snowflake_documentation FROM ROLE ANALYTICS_TEAM;
REVOKE USAGE ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS FROM ROLE ANALYTICS_TEAM;
REVOKE USAGE ON DATABASE SNOWFLAKE_INTELLIGENCE FROM ROLE ANALYTICS_TEAM;
REVOKE USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC FROM ROLE ANALYTICS_TEAM;
REVOKE USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.INTEGRATIONS FROM ROLE ANALYTICS_TEAM;
REVOKE USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.DEPLOY FROM ROLE ANALYTICS_TEAM;
REVOKE USAGE ON DATABASE SNOWFLAKE_EXAMPLE FROM ROLE ANALYTICS_TEAM;
REVOKE DATABASE ROLE SNOWFLAKE.CORTEX_USER FROM ROLE ANALYTICS_TEAM;
```

**Note**: Users may need to refresh Snowsight (AI & ML > Agents) or sign out/in to see the agent disappear.

### Recommended Role Hierarchy

For organizations with multiple user types:

```
ACCOUNTADMIN (deploys, administers)
    ↓
SAM_AGENT_ADMIN (owns agent, manages infrastructure)
    ↓
SAM_AGENT_USER (uses agent, read-only)
```

**Setup**:
```sql
USE ROLE ACCOUNTADMIN;

-- Create roles
CREATE ROLE IF NOT EXISTS SAM_AGENT_ADMIN COMMENT = 'Manages Sam-the-Snowman';
CREATE ROLE IF NOT EXISTS SAM_AGENT_USER COMMENT = 'Uses Sam-the-Snowman';

-- Hierarchy (ADMIN inherits USER privileges)
GRANT ROLE SAM_AGENT_USER TO ROLE SAM_AGENT_ADMIN;

-- Grant to users
GRANT ROLE SAM_AGENT_ADMIN TO USER platform_engineer;
GRANT ROLE SAM_AGENT_USER TO USER analyst_1;
GRANT ROLE SAM_AGENT_USER TO USER analyst_2;

-- Deploy with admin role
-- sql/00_config.sql: SET role_name = 'SAM_AGENT_ADMIN';
```

---

## Part 4: Advanced Scenarios

### Scenario 1: Data Engineering Team Ownership

**Use case**: Data engineers manage the agent as part of their platform.

```sql
-- Use existing data engineering role
CREATE ROLE IF NOT EXISTS DATA_ENGINEER_ROLE;
GRANT ROLE DATA_ENGINEER_ROLE TO USER data_engineer_1;
GRANT ROLE DATA_ENGINEER_ROLE TO USER data_engineer_2;

-- Deploy with data engineering role
-- sql/00_config.sql: SET role_name = 'DATA_ENGINEER_ROLE';

-- Grant read-only access to analysts
CREATE ROLE IF NOT EXISTS ANALYST_ROLE;
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE ANALYST_ROLE;
GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman TO ROLE ANALYST_ROLE;
-- (plus schema grants as shown in Part 3)
```

**Benefits**:
- Aligns with existing team structure
- Engineers can update semantic views
- Analysts use agent without infrastructure access

---

### Scenario 2: Multi-Environment Strategy

**Use case**: Separate roles for dev, test, and production.

```sql
-- Dev environment
CREATE ROLE IF NOT EXISTS SAM_AGENT_DEV;
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE_DEV;

-- Test environment
CREATE ROLE IF NOT EXISTS SAM_AGENT_TEST;
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE_TEST;

-- Production environment
CREATE ROLE IF NOT EXISTS SAM_AGENT_PROD;
CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE_PROD;

-- For each environment, update:
-- sql/00_config.sql line 44: SET role_name = 'SAM_AGENT_DEV' (or TEST, PROD)
-- sql/00_config.sql line 73: SET git_repo_database = 'SNOWFLAKE_EXAMPLE_DEV'
```

**Result**: Isolated agents per environment with clear ownership and separation.

---

### Scenario 3: Service Account Deployment

**Use case**: Automated deployment via CI/CD pipeline.

```sql
USE ROLE ACCOUNTADMIN;

-- Create service account
CREATE USER IF NOT EXISTS svc_sam_agent
    PASSWORD = '<strong_password>'
    MUST_CHANGE_PASSWORD = FALSE
    EMAIL = 'sam-agent-svc@company.com'
    COMMENT = 'Service account for Sam-the-Snowman automation';

-- Create service role
CREATE ROLE IF NOT EXISTS SVC_SAM_AGENT_ROLE;
GRANT ROLE SVC_SAM_AGENT_ROLE TO USER svc_sam_agent;
GRANT ROLE SVC_SAM_AGENT_ROLE TO ROLE ACCOUNTADMIN; -- for setup

-- Deploy with service role
-- sql/00_config.sql: SET role_name = 'SVC_SAM_AGENT_ROLE';
```

**Benefits**:
- Clear audit trail (all actions by service account)
- No dependency on individual user accounts
- Suitable for automated pipelines

---

### Scenario 4: Migration from SYSADMIN to Custom Role

**Use case**: Already deployed with SYSADMIN, want to transfer to custom role.

**Steps**:

1. **Create target role**:
   ```sql
   USE ROLE ACCOUNTADMIN;
   CREATE ROLE IF NOT EXISTS SAM_AGENT_ADMIN;
   ```

2. **Transfer ownership**:
   ```sql
   -- Agent
   GRANT OWNERSHIP ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman 
   TO ROLE SAM_AGENT_ADMIN COPY CURRENT GRANTS;
   
   -- Schemas
   GRANT OWNERSHIP ON SCHEMA SNOWFLAKE_EXAMPLE.DEPLOY TO ROLE SAM_AGENT_ADMIN;
   GRANT OWNERSHIP ON SCHEMA SNOWFLAKE_EXAMPLE.INTEGRATIONS TO ROLE SAM_AGENT_ADMIN;
   GRANT OWNERSHIP ON SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC TO ROLE SAM_AGENT_ADMIN;
   
   -- Required privileges
   GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE SAM_AGENT_ADMIN;
   GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE TO ROLE SAM_AGENT_ADMIN;
   ```

3. **Update configuration**:
   ```sql
   -- sql/00_config.sql line 44: SET role_name = 'SAM_AGENT_ADMIN';
   ```

4. **Verify**:
   ```sql
   USE ROLE SAM_AGENT_ADMIN;
   SELECT SYSTEM$GET_AGENT_INFO('sam_the_snowman');
   SELECT COUNT(*) FROM SNOWFLAKE_EXAMPLE.SEMANTIC.sfe_query_performance LIMIT 1;
   ```

---

## Part 5: Troubleshooting & Reference

### Common Issues

#### Issue 1: Users Can't See the Agent

**Symptoms**: Agent doesn't appear in AI & ML > Agents

**Solutions**:
1. **Check role grant**:
   ```sql
   SHOW GRANTS TO USER <username>;
   -- Verify role with USAGE on agent is granted
   ```

2. **Activate correct role**:
   ```sql
   USE ROLE <role_with_access>;
   -- Then navigate to AI & ML > Agents
   ```

3. **Verify agent grant**:
   ```sql
   USE ROLE ACCOUNTADMIN;
   SHOW GRANTS ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman;
   ```

4. **Grant if missing**:
   ```sql
   GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman TO ROLE <role>;
   ```

---

#### Issue 2: Semantic Views Return No Data

**Symptoms**: Agent says "no data available" for queries

**Solutions**:
1. **Check ACCOUNT_USAGE access**:
   ```sql
   USE ROLE <your_role>;
   SELECT COUNT(*) FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY LIMIT 1;
   -- If error: insufficient privileges
   ```

2. **Grant access**:
   ```sql
   USE ROLE ACCOUNTADMIN;
   GRANT IMPORTED PRIVILEGES ON DATABASE SNOWFLAKE TO ROLE <your_role>;
   ```

3. **Verify semantic view access**:
   ```sql
   USE ROLE <your_role>;
   SELECT COUNT(*) FROM SNOWFLAKE_EXAMPLE.SEMANTIC.sfe_query_performance LIMIT 1;
   ```

---

#### Issue 3: Email Integration Fails

**Symptoms**: Test email not received during deployment

**Solutions**:
1. **Check notification integration**:
   ```sql
   USE ROLE ACCOUNTADMIN;
   DESC NOTIFICATION INTEGRATION SFE_EMAIL_INTEGRATION;
   ```

2. **Verify email domain allow-listed**:
   - Contact Snowflake support to allow-list your email domain
   - Required for notification integrations

3. **Test manually**:
   ```sql
   USE ROLE <your_role>;
   CALL SNOWFLAKE_EXAMPLE.INTEGRATIONS.sfe_send_email(
       'test@company.com',
       'Test Email',
       '<h1>Test</h1>'
   );
   ```

---

#### Issue 4: Insufficient Privileges During Deployment

**Symptoms**: Deployment fails with privilege errors

**Solutions**:
1. **Verify ACCOUNTADMIN**:
   ```sql
   SELECT CURRENT_ROLE();
   -- Must be ACCOUNTADMIN for deployment
   ```

2. **Use ACCOUNTADMIN**:
   ```sql
   USE ROLE ACCOUNTADMIN;
   @sql/00_config.sql
   @deploy_all.sql
   ```

The deployment script automatically grants privileges to your custom role.

---

#### Issue 5: Users Still See Agent After Revoke

**Symptoms**: Agent visible despite revoked access

**Solutions**:
1. **Run complete revoke**:
   ```sql
   -- Use full revoke script from Part 3
   ```

2. **Check role hierarchy**:
   ```sql
   SHOW GRANTS TO ROLE <user_role>;
   -- User may have inherited access from parent role
   ```

3. **Refresh Snowsight**:
   - Sign out and sign back in
   - Clear browser cache
   - Navigate away from AI & ML, then back

4. **Verify no higher role**:
   - User may be using ACCOUNTADMIN or another role with access
   - Check active role in Snowsight (top right)

---

### Verification Checklist

```sql
USE ROLE ACCOUNTADMIN;

-- 1. Check database grants
SHOW GRANTS ON DATABASE SNOWFLAKE_EXAMPLE;

-- 2. Check schema grants
SHOW GRANTS ON SCHEMA SNOWFLAKE_EXAMPLE.DEPLOY;
SHOW GRANTS ON SCHEMA SNOWFLAKE_EXAMPLE.INTEGRATIONS;
SHOW GRANTS ON SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC;

-- 3. Check agent grants
SHOW GRANTS ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman;

-- 4. Check documentation grants
SHOW GRANTS ON DATABASE snowflake_documentation;

-- 5. Check user's role grants
SHOW GRANTS TO ROLE <role_name>;
SHOW GRANTS TO USER <username>;
```

---

### Quick Reference: Grant Commands

**Full Access (Owner)**:
```sql
USE ROLE ACCOUNTADMIN;

GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE <target_role>;
GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE <target_role>;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.DEPLOY TO ROLE <target_role>;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.INTEGRATIONS TO ROLE <target_role>;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC TO ROLE <target_role>;
GRANT USAGE ON DATABASE SNOWFLAKE_INTELLIGENCE TO ROLE <target_role>;
GRANT USAGE ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS TO ROLE <target_role>;
GRANT IMPORTED PRIVILEGES ON DATABASE snowflake_documentation TO ROLE <target_role>;
GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman TO ROLE <target_role>;
```

**Read-Only Access (User)**:
```sql
USE ROLE ACCOUNTADMIN;

GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE <target_role>;
GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE <target_role>;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC TO ROLE <target_role>;
GRANT SELECT ON ALL VIEWS IN SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC TO ROLE <target_role>;
GRANT USAGE ON DATABASE SNOWFLAKE_INTELLIGENCE TO ROLE <target_role>;
GRANT USAGE ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS TO ROLE <target_role>;
GRANT USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman TO ROLE <target_role>;
GRANT IMPORTED PRIVILEGES ON DATABASE snowflake_documentation TO ROLE <target_role>;
```

**Complete Revoke**:
```sql
USE ROLE ACCOUNTADMIN;

REVOKE USAGE ON AGENT SNOWFLAKE_INTELLIGENCE.AGENTS.sam_the_snowman FROM ROLE <target_role>;
REVOKE IMPORTED PRIVILEGES ON DATABASE snowflake_documentation FROM ROLE <target_role>;
REVOKE USAGE ON SCHEMA SNOWFLAKE_INTELLIGENCE.AGENTS FROM ROLE <target_role>;
REVOKE USAGE ON DATABASE SNOWFLAKE_INTELLIGENCE FROM ROLE <target_role>;
REVOKE USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.SEMANTIC FROM ROLE <target_role>;
REVOKE USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.INTEGRATIONS FROM ROLE <target_role>;
REVOKE USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.DEPLOY FROM ROLE <target_role>;
REVOKE USAGE ON DATABASE SNOWFLAKE_EXAMPLE FROM ROLE <target_role>;
REVOKE DATABASE ROLE SNOWFLAKE.CORTEX_USER FROM ROLE <target_role>;
```

---

### Security Best Practices

When deploying with custom roles:

- [ ] **Least Privilege**: Grant minimum required access
- [ ] **Role Hierarchy**: Use parent/child roles (ADMIN → USER)
- [ ] **ACCOUNT_USAGE Access**: Required for semantic views
- [ ] **Cortex Access**: Required for AI features
- [ ] **Email Allow-listing**: Required for notifications
- [ ] **Documentation**: Update with role names and ownership
- [ ] **Audit Trail**: Review grants regularly with `SHOW GRANTS`

---

## Summary

**Default Path** (SYSADMIN):
1. Keep `role_name = 'SYSADMIN'` in config
2. Deploy
3. Grant SYSADMIN to users

**Custom Path** (Enterprise):
1. Create/identify custom role
2. Update `role_name` in config
3. Deploy (agent owned by custom role)
4. Grant custom role to users

**Access Management**:
- Grant full access: Use commands in Quick Reference
- Grant read-only: Use user-specific grants
- Revoke access: Use complete revoke script

**Need Help?** See [Troubleshooting](#part-5-troubleshooting--reference) or contact your Snowflake account team.
