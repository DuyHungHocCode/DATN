-- Enable Change Data Capture (CDC) on the new EventOutbox table.
-- Note: CDC must be enabled on the database first by running: EXEC sys.sp_cdc_enable_db;
PRINT N'Enabling CDC on [BCA].[EventOutbox]...';
IF NOT EXISTS (
    SELECT 1
    FROM sys.tables t
    JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'BCA' AND t.name = 'EventOutbox' AND t.is_tracked_by_cdc = 1
)
BEGIN
    EXEC sys.sp_cdc_enable_table
        @source_schema = N'BCA',
        @source_name   = N'EventOutbox',
        @role_name     = N'null', -- Allow all users to access CDC data
        @supports_net_changes = 0;
    PRINT N'  CDC enabled for [BCA].[EventOutbox].';
END
ELSE
BEGIN
    PRINT N'  CDC is already enabled for [BCA].[EventOutbox].';
END
GO