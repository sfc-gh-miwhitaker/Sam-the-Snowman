/*******************************************************************************
 * DEMO PROJECT: Sam-the-Snowman
 * Module: 02_email_integration.sql
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * 
 * Synopsis:
 *   Creates email notification integration and stored procedure for Sam-the-Snowman.
 * 
 * Description:
 *   This module sets up email delivery capabilities:
 *   - Creates SFE_EMAIL_INTEGRATION notification integration
 *   - Creates send_email stored procedure with SQL injection protection
 *   - Tests the email integration
 * 
 * OBJECTS CREATED:
 *   - SFE_EMAIL_INTEGRATION (Notification Integration)
 *   - SNOWFLAKE_EXAMPLE.INTEGRATIONS.sfe_send_email (Stored Procedure)
 * 
 * Prerequisites:
 *   - 00_config.sql and 01_scaffolding.sql must be run first
 *   - Email domain allow-listed for notification integrations
 *   - ACCOUNTADMIN role privileges
 * 
 * Author: M. Whitaker (inspired by Kaitlyn Wells @snowflake)
 * Modified: 2025-11-07
 * Version: 3.1
 * License: Apache 2.0
 * 
 * Usage:
 *   This module is called by deploy_all.sql or can be run standalone
 *   after setting configuration variables.
 ******************************************************************************/

-- ============================================================================
-- CREATE EMAIL NOTIFICATION INTEGRATION
-- ============================================================================

-- Create email notification integration for agent output delivery
-- Requires ACCOUNTADMIN privileges
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE NOTIFICATION INTEGRATION SFE_EMAIL_INTEGRATION
    TYPE = EMAIL
    ENABLED = TRUE
    DEFAULT_SUBJECT = 'Sam-the-Snowman'
    COMMENT = 'DEMO: Sam-the-Snowman - Email notification integration for delivering agent output.';

-- Grant usage on notification integration to the specified role
GRANT USAGE ON INTEGRATION SFE_EMAIL_INTEGRATION TO ROLE identifier($role_name);

UPDATE SNOWFLAKE_EXAMPLE.PUBLIC.deployment_log SET status = 'PASS' WHERE component = 'integration.sfe_email_integration';

-- Switch back to the specified role for remaining objects
USE ROLE identifier($role_name);

-- ============================================================================
-- CREATE EMAIL STORED PROCEDURE
-- ============================================================================

-- Create stored procedure to send HTML emails (sfe_ prefix for demo safety)
CREATE OR REPLACE PROCEDURE SNOWFLAKE_EXAMPLE.INTEGRATIONS.sfe_send_email(
    recipient_email VARCHAR,
    subject VARCHAR,
    body VARCHAR
)
RETURNS VARCHAR
LANGUAGE PYTHON
RUNTIME_VERSION = '3.12'
PACKAGES = ('snowflake-snowpark-python')
HANDLER = 'send_email'
COMMENT = 'DEMO: Sam-the-Snowman - Sends HTML email using SYSTEM$SEND_EMAIL with proper SQL injection protection'
AS
$$
import snowflake.snowpark as snowpark

def send_email(session: snowpark.Session, recipient_email: str, subject: str, body: str):
    """
    Send HTML email via Snowflake notification integration.
    
    Security: Uses session.call() to prevent SQL injection.
    
    Args:
        session: Snowpark session object
        recipient_email: Email address of the recipient
        subject: Email subject line
        body: HTML body content
        
    Returns:
        Success message or error description
    """
    try:
        session.call("SYSTEM$SEND_EMAIL", 
                     'SFE_EMAIL_INTEGRATION', 
                     recipient_email, 
                     subject, 
                     body, 
                     'text/html')
        return "Email sent successfully"
    except Exception as e:
        return f"Error sending email: {str(e)}"
$$;

UPDATE SNOWFLAKE_EXAMPLE.PUBLIC.deployment_log SET status = 'PASS' WHERE component = 'procedure.send_email';

-- ============================================================================
-- TEST EMAIL INTEGRATION
-- ============================================================================

-- Test the email integration using configured recipient
-- This will send a test email to verify the notification integration works
CALL SNOWFLAKE_EXAMPLE.INTEGRATIONS.sfe_send_email(
    $notification_recipient_email,
    'Sam-the-Snowman - Test Email',
    '<h1>Email Integration Test</h1><p>This is a test of the Sam-the-Snowman email notification system.</p>'
);

-- Expected Output:
-- +------------------------+
-- | SEND_EMAIL             |
-- +------------------------+
-- | Email sent successfully|
-- +------------------------+
--
-- Next Step: Check your email inbox for the test message
-- Subject: "Sam-the-Snowman - Test Email"
-- From: Snowflake Notifications
-- If not received within 2 minutes, check your spam folder or verify
-- your email domain is allow-listed in Snowflake notification settings

-- Email integration complete

