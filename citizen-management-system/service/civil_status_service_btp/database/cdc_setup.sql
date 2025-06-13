-- CDC Setup for BTP.EventOutbox table
-- This script enables Change Data Capture for the EventOutbox table
-- to support real-time event streaming and data synchronization

-- Step 1: Enable CDC on the database (if not already enabled)
-- Note: This requires sysadmin privileges
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = DB_NAME() AND is_cdc_enabled = 1)
BEGIN
    EXEC sys.sp_cdc_enable_db;
    PRINT 'CDC enabled on database: ' + DB_NAME();
END
ELSE
BEGIN
    PRINT 'CDC is already enabled on database: ' + DB_NAME();
END
GO

-- Step 2: Enable CDC on the EventOutbox table
-- This creates a capture instance for the table
IF NOT EXISTS (
    SELECT 1 
    FROM cdc.change_tables ct
    INNER JOIN sys.tables t ON ct.source_object_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'BTP' AND t.name = 'EventOutbox'
)
BEGIN
    EXEC sys.sp_cdc_enable_table
        @source_schema = N'BTP',
        @source_name = N'EventOutbox',
        @role_name = NULL,
        @capture_instance = N'BTP_EventOutbox',
        @supports_net_changes = 0;
    
    PRINT 'CDC enabled on table: [BTP].[EventOutbox]';
END
ELSE
BEGIN
    PRINT 'CDC is already enabled on table: [BTP].[EventOutbox]';
END
GO

-- Step 3: Verify CDC setup
SELECT 
    s.name AS schema_name,
    t.name AS table_name,
    ct.capture_instance,
    ct.start_lsn,
    ct.create_date,
    ct.index_name,
    ct.captured_column_list
FROM cdc.change_tables ct
INNER JOIN sys.tables t ON ct.source_object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE s.name = 'BTP' AND t.name = 'EventOutbox';

-- Step 4: Check CDC job status
SELECT 
    job_type,
    database_id,
    last_run_time,
    next_run_time
FROM msdb.dbo.cdc_jobs
WHERE database_id = DB_ID();

-- Step 5: Sample query to read CDC data
-- Uncomment and modify as needed for testing
/*
DECLARE @from_lsn binary(10), @to_lsn binary(10);

-- Get the current maximum LSN
SET @to_lsn = sys.fn_cdc_get_max_lsn();

-- Get LSN from 1 hour ago (adjust as needed)
SET @from_lsn = sys.fn_cdc_get_min_lsn('BTP_EventOutbox');

-- Query changes
SELECT 
    __$start_lsn,
    __$end_lsn,
    __$seqval,
    __$operation,
    __$update_mask,
    *
FROM cdc.fn_cdc_get_all_changes_BTP_EventOutbox(@from_lsn, @to_lsn, 'all')
ORDER BY __$start_lsn, __$seqval;
*/

PRINT 'CDC setup completed for [BTP].[EventOutbox] table';
PRINT 'Use the sample query above to test CDC functionality'; 