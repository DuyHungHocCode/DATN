USE [DB_BTP];
GO

PRINT N'Bắt đầu tạo các ràng buộc cho DB_BTP...';

--------------------------------------------------------------------------------
-- PHẦN I: RÀNG BUỘC KHÓA NGOẠI (FOREIGN KEY)
--------------------------------------------------------------------------------
PRINT N'--> I. Đang tạo ràng buộc khóa ngoại (FOREIGN KEY)...';

-- Bảng: BTP.DivorceRecord
-- Mô tả: Mỗi bản ghi ly hôn phải được liên kết đến một giấy chứng nhận kết hôn cụ thể.
PRINT N'  [BTP].[DivorceRecord]';
IF OBJECT_ID('BTP.FK_DivorceRecord_MarriageCertificate', 'F') IS NOT NULL
    ALTER TABLE [BTP].[DivorceRecord] DROP CONSTRAINT FK_DivorceRecord_MarriageCertificate;
GO

ALTER TABLE [BTP].[DivorceRecord]
    ADD CONSTRAINT FK_DivorceRecord_MarriageCertificate FOREIGN KEY ([marriage_certificate_id])
    REFERENCES [BTP].[MarriageCertificate]([marriage_certificate_id]);
GO

--------------------------------------------------------------------------------
-- PHẦN II: CÁC RÀNG BUỘC UNIQUE (ĐẢM BẢO TÍNH DUY NHẤT)
--------------------------------------------------------------------------------
PRINT N'--> II. Đang tạo các ràng buộc UNIQUE...';

-- Bảng: BTP.BirthCertificate
PRINT N'  [BTP].[BirthCertificate]';
-- Mô tả: Số giấy khai sinh là duy nhất cho các giấy tờ còn hiệu lực.
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'UQ_BirthCertificate_No' AND object_id = OBJECT_ID('BTP.BirthCertificate'))
    DROP INDEX UQ_BirthCertificate_No ON [BTP].[BirthCertificate];
GO
CREATE UNIQUE NONCLUSTERED INDEX UQ_BirthCertificate_No
ON [BTP].[BirthCertificate] ([birth_certificate_no])
WHERE ([status] = 1);
GO

-- Mô tả: Mỗi công dân chỉ có một giấy khai sinh duy nhất.
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'UQ_BirthCertificate_Citizen' AND object_id = OBJECT_ID('BTP.BirthCertificate'))
    DROP INDEX UQ_BirthCertificate_Citizen ON [BTP].[BirthCertificate];
GO
CREATE UNIQUE NONCLUSTERED INDEX UQ_BirthCertificate_Citizen
ON [BTP].[BirthCertificate] ([citizen_id]);
GO


-- Bảng: BTP.DeathCertificate
PRINT N'  [BTP].[DeathCertificate]';
-- Mô tả: Số giấy chứng tử là duy nhất cho các giấy tờ còn hiệu lực.
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'UQ_DeathCertificate_No' AND object_id = OBJECT_ID('BTP.DeathCertificate'))
    DROP INDEX UQ_DeathCertificate_No ON [BTP].[DeathCertificate];
GO
CREATE UNIQUE NONCLUSTERED INDEX UQ_DeathCertificate_No
ON [BTP].[DeathCertificate] ([death_certificate_no])
WHERE ([status] = 1);
GO

-- Mô tả: Mỗi công dân chỉ có một giấy chứng tử duy nhất.
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'UQ_DeathCertificate_Citizen' AND object_id = OBJECT_ID('BTP.DeathCertificate'))
    DROP INDEX UQ_DeathCertificate_Citizen ON [BTP].[DeathCertificate];
GO
CREATE UNIQUE NONCLUSTERED INDEX UQ_DeathCertificate_Citizen
ON [BTP].[DeathCertificate] ([citizen_id]);
GO


-- Bảng: BTP.MarriageCertificate
PRINT N'  [BTP].[MarriageCertificate]';
-- Mô tả: Số giấy chứng nhận kết hôn là duy nhất cho các giấy tờ còn hiệu lực.
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'UQ_MarriageCertificate_No' AND object_id = OBJECT_ID('BTP.MarriageCertificate'))
    DROP INDEX UQ_MarriageCertificate_No ON [BTP].[MarriageCertificate];
GO
CREATE UNIQUE NONCLUSTERED INDEX UQ_MarriageCertificate_No
ON [BTP].[MarriageCertificate] ([marriage_certificate_no])
WHERE ([status] = 1);
GO


-- Bảng: BTP.DivorceRecord
PRINT N'  [BTP].[DivorceRecord]';
-- Mô tả: Số bản án/quyết định ly hôn của tòa án là duy nhất.
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'UQ_DivorceRecord_JudgmentNo' AND object_id = OBJECT_ID('BTP.DivorceRecord'))
    DROP INDEX UQ_DivorceRecord_JudgmentNo ON [BTP].[DivorceRecord];
GO
CREATE UNIQUE NONCLUSTERED INDEX UQ_DivorceRecord_JudgmentNo
ON [BTP].[DivorceRecord] ([judgment_no]);
GO

-- Mô tả: Mỗi cuộc hôn nhân chỉ có thể được ly hôn một lần.
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'UQ_DivorceRecord_MarriageCert' AND object_id = OBJECT_ID('BTP.DivorceRecord'))
    DROP INDEX UQ_DivorceRecord_MarriageCert ON [BTP].[DivorceRecord];
GO
CREATE UNIQUE NONCLUSTERED INDEX UQ_DivorceRecord_MarriageCert
ON [BTP].[DivorceRecord] ([marriage_certificate_id]);
GO


PRINT N'Hoàn thành việc tạo tất cả các ràng buộc.';
GO
