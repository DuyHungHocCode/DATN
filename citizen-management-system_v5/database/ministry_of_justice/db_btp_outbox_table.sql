-- Add to citizen-management-system_v5/database/ministry_of_justice/db_btp_outbox_table.sql
USE [DB_BTP];
GO

-- Table for outbox pattern implementation
IF OBJECT_ID('BTP.EventOutbox', 'U') IS NOT NULL DROP TABLE [BTP].[EventOutbox];
GO

CREATE TABLE [BTP].[EventOutbox] (
    [outbox_id] BIGINT IDENTITY(1,1) PRIMARY KEY,
    [aggregate_type] VARCHAR(50) NOT NULL, -- DeathCertificate, MarriageCertificate, etc.
    [aggregate_id] BIGINT NOT NULL, -- The certificate ID
    [event_type] VARCHAR(100) NOT NULL, -- citizen_died, citizen_married, etc.
    [payload] NVARCHAR(MAX) NOT NULL, -- JSON payload
    [created_at] DATETIME2(7) DEFAULT SYSDATETIME(),
    [processed] BIT DEFAULT 0, -- Whether processed
    [processed_at] DATETIME2(7) NULL, -- When processed
    [retry_count] INT DEFAULT 0, -- Number of attempts
    [error_message] NVARCHAR(MAX) NULL, -- Last error
    [next_retry_at] DATETIME2(7) NULL -- When to try next
);
GO

