-- ==============================================================================
-- Script to Setup Automated Backup Jobs for DB_BCA
-- ==============================================================================
-- This script configures a comprehensive backup strategy using SQL Server Agent.
-- It creates three separate jobs for Full, Differential, and Log backups.
--
-- Pre-requisites:
-- 1. SQL Server Agent must be running.
-- 2. The backup directory '/var/opt/mssql/backups/' and subdirectories
--    'full', 'diff', 'log' should exist and be writable by the SQL Server service.
-- ==============================================================================

USE [master];
GO

PRINT N'Step 1: Setting DB_BCA to FULL Recovery Model...';
-- This is essential for enabling transaction log backups.
ALTER DATABASE [DB_BCA] SET RECOVERY FULL;
GO
PRINT N'  DB_BCA recovery model set to FULL.';
GO

-- ==============================================================================
-- Job 1: Full Backup (Weekly)
-- ==============================================================================
PRINT N'Step 2: Creating Weekly Full Backup Job...';
BEGIN
    DECLARE @jobId BINARY(16);

    -- Create the Job
    EXEC msdb.dbo.sp_add_job @job_name=N'DB_BCA - Weekly Full Backup',
        @enabled=1,
        @description=N'Performs a full backup of the DB_BCA database every Sunday at 2 AM.',
        @job_id = @jobId OUTPUT;

    -- Create the Job Step
    EXEC msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Execute Full Backup',
        @subsystem=N'TSQL',
        @command=N'
            DECLARE @BackupPath NVARCHAR(500);
            SET @BackupPath = N''/var/opt/mssql/backups/full/DB_BCA_FULL_'' + FORMAT(GETDATE(), ''yyyyMMdd_HHmmss'') + N''.bak'';
            BACKUP DATABASE [DB_BCA]
            TO DISK = @BackupPath
            WITH COMPRESSION, CHECKSUM, STATS = 10;
        ',
        @database_name=N'DB_BCA';

    -- Create the Schedule
    EXEC msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Weekly_Sunday_2AM',
        @enabled=1,
        @freq_type=8, -- Weekly
        @freq_interval=1, -- Sunday
        @freq_subday_type=1, -- At the specified time
        @active_start_time=20000; -- 02:00:00

    PRINT N'  Job ''DB_BCA - Weekly Full Backup'' created successfully.';
END
GO

-- ==============================================================================
-- Job 2: Differential Backup (Daily)
-- ==============================================================================
PRINT N'Step 3: Creating Daily Differential Backup Job...';
BEGIN
    DECLARE @jobId BINARY(16);

    EXEC msdb.dbo.sp_add_job @job_name=N'DB_BCA - Daily Differential Backup',
        @enabled=1,
        @description=N'Performs a differential backup daily (Mon-Sat) at 2 AM.',
        @job_id = @jobId OUTPUT;

    EXEC msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Execute Differential Backup',
        @subsystem=N'TSQL',
        @command=N'
            DECLARE @BackupPath NVARCHAR(500);
            SET @BackupPath = N''/var/opt/mssql/backups/diff/DB_BCA_DIFF_'' + FORMAT(GETDATE(), ''yyyyMMdd_HHmmss'') + N''.bak'';
            BACKUP DATABASE [DB_BCA]
            TO DISK = @BackupPath
            WITH DIFFERENTIAL, COMPRESSION, CHECKSUM, STATS = 10;
        ',
        @database_name=N'DB_BCA';

    EXEC msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily_Mon_Sat_2AM',
        @enabled=1,
        @freq_type=8, -- Weekly
        @freq_interval=126, -- Monday, Tuesday, Wednesday, Thursday, Friday, Saturday
        @freq_subday_type=1,
        @active_start_time=20000; -- 02:00:00

    PRINT N'  Job ''DB_BCA - Daily Differential Backup'' created successfully.';
END
GO

-- ==============================================================================
-- Job 3: Transaction Log Backup (Every 15 Minutes)
-- ==============================================================================
PRINT N'Step 4: Creating Transaction Log Backup Job...';
BEGIN
    DECLARE @jobId BINARY(16);

    EXEC msdb.dbo.sp_add_job @job_name=N'DB_BCA - Transaction Log Backup',
        @enabled=1,
        @description=N'Performs a transaction log backup every 15 minutes.',
        @job_id = @jobId OUTPUT;

    EXEC msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Execute Log Backup',
        @subsystem=N'TSQL',
        @command=N'
            DECLARE @BackupPath NVARCHAR(500);
            SET @BackupPath = N''/var/opt/mssql/backups/log/DB_BCA_LOG_'' + FORMAT(GETDATE(), ''yyyyMMdd_HHmmss'') + N''.trn'';
            BACKUP LOG [DB_BCA]
            TO DISK = @BackupPath
            WITH CHECKSUM, STATS = 10;
        ',
        @database_name=N'DB_BCA';

    EXEC msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Every_15_Minutes',
        @enabled=1,
        @freq_type=4, -- Daily
        @freq_interval=1,
        @freq_subday_type=4, -- Minutes
        @freq_subday_interval=15;

    PRINT N'  Job ''DB_BCA - Transaction Log Backup'' created successfully.';
END
GO

PRINT N'All backup jobs have been configured in SQL Server Agent.';
GO 