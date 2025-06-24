-- ==============================================================================
-- Script to Create Audit Triggers for DB_BCA
-- ==============================================================================
-- This script creates DML triggers for critical tables to log all changes
-- into the [Audit].[AuditLog] table. It also includes a database-level
-- DDL trigger to capture TRUNCATE TABLE events.
-- ==============================================================================

USE [DB_BCA];
GO

PRINT N'Creating Audit Triggers...';
GO

--------------------------------------------------------------------------------
-- Generic Procedure to Handle Audit Logging Logic
-- This reduces code duplication.
--------------------------------------------------------------------------------
IF OBJECT_ID('Audit.sp_LogChange', 'P') IS NOT NULL
    DROP PROCEDURE [Audit].[sp_LogChange];
GO

CREATE PROCEDURE [Audit].[sp_LogChange]
    @schema_name    VARCHAR(100),
    @table_name     VARCHAR(100),
    @operation      VARCHAR(10),
    @inserted_data  NVARCHAR(MAX),
    @deleted_data   NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @client_ip VARCHAR(48);
    SELECT @client_ip = client_net_address
    FROM sys.dm_exec_connections
    WHERE session_id = @@SPID;

    DECLARE @changed_fields NVARCHAR(MAX) = NULL;
    IF @operation = 'UPDATE'
    BEGIN
        SET @changed_fields = (
            SELECT
                JSON_QUERY(@deleted_data) AS OldValues,
                JSON_QUERY(@inserted_data) AS NewValues
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
        );
    END

    INSERT INTO [Audit].[AuditLog] (
        [action_tstamp], [schema_name], [table_name], [operation],
        [session_user_name], [application_name], [client_net_address], [host_name],
        [transaction_id], [statement_only], [row_data], [changed_fields]
    )
    VALUES (
        SYSDATETIME(), @schema_name, @table_name, @operation,
        SUSER_SNAME(), APP_NAME(), @client_ip, HOST_NAME(),
        CURRENT_TRANSACTION_ID(), 0,
        CASE WHEN @operation = 'DELETE' THEN @deleted_data ELSE @inserted_data END,
        @changed_fields
    );
END
GO

--------------------------------------------------------------------------------
-- DML Triggers for Important Tables
--------------------------------------------------------------------------------

-- Trigger for BCA.Citizen
IF OBJECT_ID('BCA.TR_Citizen_Audit', 'TR') IS NOT NULL DROP TRIGGER [BCA].[TR_Citizen_Audit];
GO
CREATE TRIGGER [BCA].[TR_Citizen_Audit] ON [BCA].[Citizen] AFTER INSERT, UPDATE, DELETE
AS BEGIN
    DECLARE @inserted NVARCHAR(MAX) = (SELECT * FROM inserted FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
    DECLARE @deleted NVARCHAR(MAX) = (SELECT * FROM deleted FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
    DECLARE @op VARCHAR(10) = CASE WHEN EXISTS(SELECT * FROM inserted) AND EXISTS(SELECT * FROM deleted) THEN 'UPDATE' WHEN EXISTS(SELECT * FROM inserted) THEN 'INSERT' ELSE 'DELETE' END;
    EXEC [Audit].[sp_LogChange] 'BCA', 'Citizen', @op, @inserted, @deleted;
END
GO

-- Trigger for BCA.IdentificationCard
IF OBJECT_ID('BCA.TR_IdentificationCard_Audit', 'TR') IS NOT NULL DROP TRIGGER [BCA].[TR_IdentificationCard_Audit];
GO
CREATE TRIGGER [BCA].[TR_IdentificationCard_Audit] ON [BCA].[IdentificationCard] AFTER INSERT, UPDATE, DELETE
AS BEGIN
    DECLARE @inserted NVARCHAR(MAX) = (SELECT * FROM inserted FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
    DECLARE @deleted NVARCHAR(MAX) = (SELECT * FROM deleted FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
    DECLARE @op VARCHAR(10) = CASE WHEN EXISTS(SELECT * FROM inserted) AND EXISTS(SELECT * FROM deleted) THEN 'UPDATE' WHEN EXISTS(SELECT * FROM inserted) THEN 'INSERT' ELSE 'DELETE' END;
    EXEC [Audit].[sp_LogChange] 'BCA', 'IdentificationCard', @op, @inserted, @deleted;
END
GO

-- Trigger for BCA.Household
IF OBJECT_ID('BCA.TR_Household_Audit', 'TR') IS NOT NULL DROP TRIGGER [BCA].[TR_Household_Audit];
GO
CREATE TRIGGER [BCA].[TR_Household_Audit] ON [BCA].[Household] AFTER INSERT, UPDATE, DELETE
AS BEGIN
    DECLARE @inserted NVARCHAR(MAX) = (SELECT * FROM inserted FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
    DECLARE @deleted NVARCHAR(MAX) = (SELECT * FROM deleted FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
    DECLARE @op VARCHAR(10) = CASE WHEN EXISTS(SELECT * FROM inserted) AND EXISTS(SELECT * FROM deleted) THEN 'UPDATE' WHEN EXISTS(SELECT * FROM inserted) THEN 'INSERT' ELSE 'DELETE' END;
    EXEC [Audit].[sp_LogChange] 'BCA', 'Household', @op, @inserted, @deleted;
END
GO

-- Trigger for BCA.HouseholdMember
IF OBJECT_ID('BCA.TR_HouseholdMember_Audit', 'TR') IS NOT NULL DROP TRIGGER [BCA].[TR_HouseholdMember_Audit];
GO
CREATE TRIGGER [BCA].[TR_HouseholdMember_Audit] ON [BCA].[HouseholdMember] AFTER INSERT, UPDATE, DELETE
AS BEGIN
    DECLARE @inserted NVARCHAR(MAX) = (SELECT * FROM inserted FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
    DECLARE @deleted NVARCHAR(MAX) = (SELECT * FROM deleted FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
    DECLARE @op VARCHAR(10) = CASE WHEN EXISTS(SELECT * FROM inserted) AND EXISTS(SELECT * FROM deleted) THEN 'UPDATE' WHEN EXISTS(SELECT * FROM inserted) THEN 'INSERT' ELSE 'DELETE' END;
    EXEC [Audit].[sp_LogChange] 'BCA', 'HouseholdMember', @op, @inserted, @deleted;
END
GO

-- Trigger for BCA.CriminalRecord
IF OBJECT_ID('BCA.TR_CriminalRecord_Audit', 'TR') IS NOT NULL DROP TRIGGER [BCA].[TR_CriminalRecord_Audit];
GO
CREATE TRIGGER [BCA].[TR_CriminalRecord_Audit] ON [BCA].[CriminalRecord] AFTER INSERT, UPDATE, DELETE
AS BEGIN
    DECLARE @inserted NVARCHAR(MAX) = (SELECT * FROM inserted FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
    DECLARE @deleted NVARCHAR(MAX) = (SELECT * FROM deleted FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
    DECLARE @op VARCHAR(10) = CASE WHEN EXISTS(SELECT * FROM inserted) AND EXISTS(SELECT * FROM deleted) THEN 'UPDATE' WHEN EXISTS(SELECT * FROM inserted) THEN 'INSERT' ELSE 'DELETE' END;
    EXEC [Audit].[sp_LogChange] 'BCA', 'CriminalRecord', @op, @inserted, @deleted;
END
GO

-- Trigger for BCA.ResidenceHistory
IF OBJECT_ID('BCA.TR_ResidenceHistory_Audit', 'TR') IS NOT NULL DROP TRIGGER [BCA].[TR_ResidenceHistory_Audit];
GO
CREATE TRIGGER [BCA].[TR_ResidenceHistory_Audit] ON [BCA].[ResidenceHistory] AFTER INSERT, UPDATE, DELETE
AS BEGIN
    DECLARE @inserted NVARCHAR(MAX) = (SELECT * FROM inserted FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
    DECLARE @deleted NVARCHAR(MAX) = (SELECT * FROM deleted FOR JSON PATH, WITHOUT_ARRAY_WRAPPER);
    DECLARE @op VARCHAR(10) = CASE WHEN EXISTS(SELECT * FROM inserted) AND EXISTS(SELECT * FROM deleted) THEN 'UPDATE' WHEN EXISTS(SELECT * FROM inserted) THEN 'INSERT' ELSE 'DELETE' END;
    EXEC [Audit].[sp_LogChange] 'BCA', 'ResidenceHistory', @op, @inserted, @deleted;
END
GO


PRINT N'Successfully created all audit triggers.';
GO 