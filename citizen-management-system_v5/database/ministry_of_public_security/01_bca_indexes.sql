
USE [DB_BCA];
GO

PRINT 'Bắt đầu tạo chỉ mục cho DB_BCA...';
GO

-- ===================================================================
-- BẢNG CÔNG DÂN (BCA.Citizen)
-- ===================================================================

-- Clustered Index trên citizen_id đã có (do là PK)
PRINT 'Tạo chỉ mục cho BCA.Citizen...';

-- Tối ưu tìm kiếm theo họ tên
CREATE NONCLUSTERED INDEX IX_Citizen_Name ON [BCA].[Citizen] ([full_name])
INCLUDE ([citizen_id], [date_of_birth], [gender], [current_province_id], [current_district_id], [current_ward_id], [death_status]);
GO

-- Xem xét sử dụng Full-Text Index cho tìm kiếm tên linh hoạt nếu cần
-- CREATE FULLTEXT CATALOG FT_Citizen AS DEFAULT;
-- GO
-- CREATE FULLTEXT INDEX ON [BCA].[Citizen] ([full_name] LANGUAGE 1066) KEY INDEX PK_Citizen;
-- GO

-- Tối ưu tìm kiếm theo thông tin liên hệ
CREATE NONCLUSTERED INDEX IX_Citizen_Contact ON [BCA].[Citizen] ([phone_number])
INCLUDE ([citizen_id], [full_name], [date_of_birth]);
GO

CREATE NONCLUSTERED INDEX IX_Citizen_Email ON [BCA].[Citizen] ([email])
INCLUDE ([citizen_id], [full_name], [date_of_birth]);
GO

-- Tối ưu tra cứu theo ngày sinh
CREATE NONCLUSTERED INDEX IX_Citizen_DOB ON [BCA].[Citizen] ([date_of_birth])
INCLUDE ([citizen_id], [full_name], [gender], [current_province_id]);
GO

-- Tối ưu tìm kiếm theo giới tính
CREATE NONCLUSTERED INDEX IX_Citizen_Gender ON [BCA].[Citizen] ([gender])
INCLUDE ([citizen_id], [full_name], [date_of_birth]);
GO

-- Tối ưu tìm kiếm kết hợp họ tên và ngày sinh (phổ biến)
CREATE NONCLUSTERED INDEX IX_Citizen_NameDOB ON [BCA].[Citizen] ([full_name], [date_of_birth])
INCLUDE ([citizen_id], [gender], [current_province_id], [current_district_id], [current_ward_id]);
GO

-- Tối ưu tìm kiếm theo địa lý hiện tại
CREATE NONCLUSTERED INDEX IX_Citizen_CurrentProvince ON [BCA].[Citizen] ([current_province_id])
INCLUDE ([citizen_id], [full_name], [date_of_birth], [gender]);
GO

CREATE NONCLUSTERED INDEX IX_Citizen_CurrentDistrict ON [BCA].[Citizen] ([current_district_id])
INCLUDE ([citizen_id], [full_name], [date_of_birth], [gender], [current_province_id]);
GO

CREATE NONCLUSTERED INDEX IX_Citizen_CurrentWard ON [BCA].[Citizen] ([current_ward_id])
INCLUDE ([citizen_id], [full_name], [date_of_birth], [gender], [current_province_id], [current_district_id]);
GO

CREATE NONCLUSTERED INDEX IX_Citizen_CurrentLocation ON [BCA].[Citizen] ([current_province_id], [current_district_id], [current_ward_id])
INCLUDE ([citizen_id], [full_name], [date_of_birth], [gender]);
GO

-- Tối ưu tìm kiếm theo nơi sinh 
CREATE NONCLUSTERED INDEX IX_Citizen_BirthLocation ON [BCA].[Citizen] ([birth_province_id], [birth_district_id], [birth_ward_id])
INCLUDE ([citizen_id], [full_name], [date_of_birth]);
GO

-- Tối ưu tìm kiếm theo quê quán
CREATE NONCLUSTERED INDEX IX_Citizen_NativeLocation ON [BCA].[Citizen] ([native_province_id], [native_district_id], [native_ward_id])
INCLUDE ([citizen_id], [full_name], [date_of_birth]);
GO

-- Tối ưu tìm kiếm nhân khẩu học
CREATE NONCLUSTERED INDEX IX_Citizen_Demographics ON [BCA].[Citizen] ([nationality_id], [ethnicity_id], [religion_id])
INCLUDE ([citizen_id], [full_name], [date_of_birth], [gender]);
GO

-- Tối ưu tìm kiếm theo nghề nghiệp
CREATE NONCLUSTERED INDEX IX_Citizen_Occupation ON [BCA].[Citizen] ([occupation_id])
INCLUDE ([citizen_id], [full_name], [date_of_birth]);
GO

-- Tối ưu tìm kiếm theo quan hệ gia đình
CREATE NONCLUSTERED INDEX IX_Citizen_FamilyRelation ON [BCA].[Citizen] ([father_citizen_id])
INCLUDE ([citizen_id], [full_name], [date_of_birth]);
GO

CREATE NONCLUSTERED INDEX IX_Citizen_MotherRelation ON [BCA].[Citizen] ([mother_citizen_id])
INCLUDE ([citizen_id], [full_name], [date_of_birth]);
GO

CREATE NONCLUSTERED INDEX IX_Citizen_SpouseRelation ON [BCA].[Citizen] ([spouse_citizen_id])
INCLUDE ([citizen_id], [full_name], [date_of_birth], [gender]);
GO

-- Tối ưu tìm kiếm trạng thái (đã mất, còn sống, mất tích)
CREATE NONCLUSTERED INDEX IX_Citizen_DeathStatus ON [BCA].[Citizen] ([death_status])
INCLUDE ([citizen_id], [full_name], [date_of_birth], [date_of_death]);
GO

-- Filtered Index cho công dân còn sống (phổ biến)
CREATE NONCLUSTERED INDEX IX_Citizen_Living ON [BCA].[Citizen] ([full_name], [date_of_birth], [current_province_id])
INCLUDE ([citizen_id], [gender], [current_district_id], [current_ward_id])
WHERE ([death_status] = N'Còn sống');
GO

-- Filtered Index cho công dân đã mất
CREATE NONCLUSTERED INDEX IX_Citizen_Deceased ON [BCA].[Citizen] ([full_name], [date_of_death])
INCLUDE ([citizen_id], [date_of_birth], [gender])
WHERE ([death_status] = N'Đã mất');
GO

-- ===================================================================
-- BẢNG ĐỊA CHỈ (BCA.Address)
-- ===================================================================
PRINT 'Tạo chỉ mục cho BCA.Address...';

-- Tối ưu tìm kiếm địa chỉ theo phân cấp hành chính
CREATE NONCLUSTERED INDEX IX_Address_Province ON [BCA].[Address] ([province_id])
INCLUDE ([address_id], [address_detail], [district_id], [ward_id], [is_active]);
GO

CREATE NONCLUSTERED INDEX IX_Address_District ON [BCA].[Address] ([district_id])
INCLUDE ([address_id], [address_detail], [province_id], [ward_id], [is_active]);
GO

CREATE NONCLUSTERED INDEX IX_Address_Ward ON [BCA].[Address] ([ward_id])
INCLUDE ([address_id], [address_detail], [province_id], [district_id], [is_active]);
GO

CREATE NONCLUSTERED INDEX IX_Address_Hierarchy ON [BCA].[Address] ([province_id], [district_id], [ward_id])
INCLUDE ([address_id], [address_detail], [is_active]);
GO

-- Filtered Index cho địa chỉ đang hoạt động
CREATE NONCLUSTERED INDEX IX_Address_Active ON [BCA].[Address] ([province_id], [district_id], [ward_id])
INCLUDE ([address_id], [address_detail])
WHERE ([is_active] = 1);
GO

-- Tối ưu tìm kiếm địa lý (nếu latitude, longitude được sử dụng)
CREATE SPATIAL INDEX SPIX_Address_Location ON [BCA].[Address] ([latitude], [longitude]);
GO

-- ===================================================================
-- BẢNG THẺ CĂCƯỚC/CMND (BCA.IdentificationCard)
-- ===================================================================
PRINT 'Tạo chỉ mục cho BCA.IdentificationCard...';

-- Tối ưu tìm kiếm theo citizen_id (phổ biến)
CREATE NONCLUSTERED INDEX IX_IdentificationCard_Citizen ON [BCA].[IdentificationCard] ([citizen_id])
INCLUDE ([id_card_id], [card_number], [card_type], [issue_date], [expiry_date], [card_status]);
GO

-- Tối ưu tìm kiếm theo số thẻ
CREATE NONCLUSTERED INDEX IX_IdentificationCard_CardNumber ON [BCA].[IdentificationCard] ([card_number])
INCLUDE ([id_card_id], [citizen_id], [card_type], [issue_date], [expiry_date], [card_status]);
GO

-- Tối ưu tìm kiếm theo loại thẻ
CREATE NONCLUSTERED INDEX IX_IdentificationCard_CardType ON [BCA].[IdentificationCard] ([card_type])
INCLUDE ([id_card_id], [citizen_id], [card_number], [issue_date], [expiry_date], [card_status]);
GO

-- Tối ưu tìm kiếm theo ngày cấp
CREATE NONCLUSTERED INDEX IX_IdentificationCard_IssueDate ON [BCA].[IdentificationCard] ([issue_date])
INCLUDE ([id_card_id], [citizen_id], [card_number], [card_type], [expiry_date], [card_status]);
GO

-- Tối ưu tìm kiếm theo ngày hết hạn
CREATE NONCLUSTERED INDEX IX_IdentificationCard_ExpiryDate ON [BCA].[IdentificationCard] ([expiry_date])
INCLUDE ([id_card_id], [citizen_id], [card_number], [card_type], [issue_date], [card_status]);
GO

-- Tối ưu tìm kiếm theo cơ quan cấp
CREATE NONCLUSTERED INDEX IX_IdentificationCard_Authority ON [BCA].[IdentificationCard] ([issuing_authority_id])
INCLUDE ([id_card_id], [citizen_id], [card_number], [card_status]);
GO

-- Tối ưu tìm kiếm theo trạng thái thẻ
CREATE NONCLUSTERED INDEX IX_IdentificationCard_Status ON [BCA].[IdentificationCard] ([card_status])
INCLUDE ([id_card_id], [citizen_id], [card_number], [card_type], [issue_date], [expiry_date]);
GO

-- Filtered Index cho CCCD/CMND đang sử dụng (phổ biến)
CREATE NONCLUSTERED INDEX IX_IdentificationCard_Active ON [BCA].[IdentificationCard] ([citizen_id], [card_number])
INCLUDE ([id_card_id], [card_type], [issue_date], [expiry_date])
WHERE ([card_status] = N'Đang sử dụng');
GO

-- Composite Index cho lịch sử cấp thẻ theo công dân (phổ biến)
CREATE NONCLUSTERED INDEX IX_IdentificationCard_CitizenHistory ON [BCA].[IdentificationCard] ([citizen_id], [issue_date] DESC)
INCLUDE ([id_card_id], [card_number], [card_type], [expiry_date], [card_status]);
GO

-- ===================================================================
-- BẢNG LỊCH SỬ CƯ TRÚ (BCA.ResidenceHistory)
-- ===================================================================
PRINT 'Tạo chỉ mục cho BCA.ResidenceHistory...';

-- Tối ưu tìm kiếm theo citizen_id (phổ biến)
CREATE NONCLUSTERED INDEX IX_ResidenceHistory_Citizen ON [BCA].[ResidenceHistory] ([citizen_id])
INCLUDE ([residence_history_id], [address_id], [residence_type], [registration_date], [expiry_date], [status]);
GO

-- Tối ưu tìm kiếm theo địa chỉ
CREATE NONCLUSTERED INDEX IX_ResidenceHistory_Address ON [BCA].[ResidenceHistory] ([address_id])
INCLUDE ([residence_history_id], [citizen_id], [residence_type], [registration_date], [expiry_date], [status]);
GO

-- Tối ưu tìm kiếm theo loại cư trú (thường trú, tạm trú)
CREATE NONCLUSTERED INDEX IX_ResidenceHistory_Type ON [BCA].[ResidenceHistory] ([residence_type])
INCLUDE ([residence_history_id], [citizen_id], [address_id], [registration_date], [expiry_date], [status]);
GO

-- Tối ưu tìm kiếm theo ngày đăng ký
CREATE NONCLUSTERED INDEX IX_ResidenceHistory_RegistrationDate ON [BCA].[ResidenceHistory] ([registration_date])
INCLUDE ([residence_history_id], [citizen_id], [address_id], [residence_type], [expiry_date], [status]);
GO

-- Tối ưu tìm kiếm theo ngày hết hạn (cho tạm trú)
CREATE NONCLUSTERED INDEX IX_ResidenceHistory_ExpiryDate ON [BCA].[ResidenceHistory] ([expiry_date])
INCLUDE ([residence_history_id], [citizen_id], [address_id], [residence_type], [registration_date], [status])
WHERE ([expiry_date] IS NOT NULL);
GO

-- Tối ưu tìm kiếm theo trạng thái
CREATE NONCLUSTERED INDEX IX_ResidenceHistory_Status ON [BCA].[ResidenceHistory] ([status])
INCLUDE ([residence_history_id], [citizen_id], [address_id], [residence_type], [registration_date], [expiry_date]);
GO

-- Tối ưu tìm kiếm theo cơ quan đăng ký
CREATE NONCLUSTERED INDEX IX_ResidenceHistory_Authority ON [BCA].[ResidenceHistory] ([issuing_authority_id])
INCLUDE ([residence_history_id], [citizen_id], [address_id], [residence_type], [status]);
GO

-- Filtered Index cho cư trú đang hoạt động (phổ biến)
CREATE NONCLUSTERED INDEX IX_ResidenceHistory_Active ON [BCA].[ResidenceHistory] ([citizen_id], [address_id])
INCLUDE ([residence_history_id], [residence_type], [registration_date], [expiry_date])
WHERE ([status] = N'Active');
GO

-- Composite Index cho tìm kiếm lịch sử cư trú theo công dân (phổ biến)
CREATE NONCLUSTERED INDEX IX_ResidenceHistory_CitizenHistory ON [BCA].[ResidenceHistory] ([citizen_id], [registration_date] DESC)
INCLUDE ([residence_history_id], [address_id], [residence_type], [expiry_date], [status]);
GO

-- Composite Index cho tìm kiếm theo loại cư trú và trạng thái
CREATE NONCLUSTERED INDEX IX_ResidenceHistory_TypeStatus ON [BCA].[ResidenceHistory] ([residence_type], [status])
INCLUDE ([residence_history_id], [citizen_id], [address_id], [registration_date], [expiry_date]);
GO

-- ===================================================================
-- BẢNG HỒ SƠ HÌNH SỰ (BCA.CriminalRecord)
-- ===================================================================
PRINT 'Tạo chỉ mục cho BCA.CriminalRecord...';

-- Tối ưu tìm kiếm theo citizen_id (phổ biến)
CREATE NONCLUSTERED INDEX IX_CriminalRecord_Citizen ON [BCA].[CriminalRecord] ([citizen_id])
INCLUDE ([record_id], [crime_type], [crime_description], [crime_date], [judgment_no], [judgment_date]);
GO

-- Tối ưu tìm kiếm theo loại tội phạm
CREATE NONCLUSTERED INDEX IX_CriminalRecord_CrimeType ON [BCA].[CriminalRecord] ([crime_type])
INCLUDE ([record_id], [citizen_id], [crime_description], [crime_date], [judgment_no], [judgment_date]);
GO

-- Tối ưu tìm kiếm theo ngày phạm tội
CREATE NONCLUSTERED INDEX IX_CriminalRecord_CrimeDate ON [BCA].[CriminalRecord] ([crime_date])
INCLUDE ([record_id], [citizen_id], [crime_type], [crime_description], [judgment_no], [judgment_date]);
GO

-- Tối ưu tìm kiếm theo số quyết định tòa án
CREATE NONCLUSTERED INDEX IX_CriminalRecord_JudgmentNo ON [BCA].[CriminalRecord] ([judgment_no])
INCLUDE ([record_id], [citizen_id], [crime_type], [crime_date], [judgment_date]);
GO

-- Tối ưu tìm kiếm theo ngày quyết định
CREATE NONCLUSTERED INDEX IX_CriminalRecord_JudgmentDate ON [BCA].[CriminalRecord] ([judgment_date])
INCLUDE ([record_id], [citizen_id], [crime_type], [crime_date], [judgment_no]);
GO

-- Composite Index cho tìm kiếm lịch sử hình sự theo công dân (phổ biến)
CREATE NONCLUSTERED INDEX IX_CriminalRecord_CitizenHistory ON [BCA].[CriminalRecord] ([citizen_id], [crime_date] DESC)
INCLUDE ([record_id], [crime_type], [judgment_no], [judgment_date]);
GO

-- ===================================================================
-- BẢNG TRẠNG THÁI CÔNG DÂN (BCA.CitizenStatus)
-- ===================================================================
PRINT 'Tạo chỉ mục cho BCA.CitizenStatus...';

-- Tối ưu tìm kiếm theo citizen_id (phổ biến)
CREATE NONCLUSTERED INDEX IX_CitizenStatus_Citizen ON [BCA].[CitizenStatus] ([citizen_id])
INCLUDE ([status_id], [status_type], [status_date], [description], [is_current]);
GO

-- Tối ưu tìm kiếm theo loại trạng thái
CREATE NONCLUSTERED INDEX IX_CitizenStatus_Type ON [BCA].[CitizenStatus] ([status_type])
INCLUDE ([status_id], [citizen_id], [status_date], [description], [is_current]);
GO

-- Tối ưu tìm kiếm theo ngày thay đổi trạng thái
CREATE NONCLUSTERED INDEX IX_CitizenStatus_Date ON [BCA].[CitizenStatus] ([status_date])
INCLUDE ([status_id], [citizen_id], [status_type], [description], [is_current]);
GO

-- Filtered Index cho trạng thái hiện tại (phổ biến)
CREATE NONCLUSTERED INDEX IX_CitizenStatus_Current ON [BCA].[CitizenStatus] ([citizen_id], [status_type])
INCLUDE ([status_id], [status_date], [description])
WHERE ([is_current] = 1);
GO

-- Composite Index cho lịch sử trạng thái theo công dân (phổ biến)
CREATE NONCLUSTERED INDEX IX_CitizenStatus_CitizenHistory ON [BCA].[CitizenStatus] ([citizen_id], [status_date] DESC)
INCLUDE ([status_id], [status_type], [description], [is_current]);
GO

-- ===================================================================
-- BẢNG THAM CHIẾU (REFERENCE) - THÊM CHỈ MỤC NẾU CẦN
-- ===================================================================
PRINT 'Tạo chỉ mục bổ sung cho các bảng Reference...';

-- Ví dụ: Tối ưu tìm kiếm Wards theo tên hoặc mã
CREATE NONCLUSTERED INDEX IX_Wards_Name ON [Reference].[Wards] ([ward_name])
INCLUDE ([ward_id], [ward_code], [district_id]);
GO

CREATE NONCLUSTERED INDEX IX_Wards_Code ON [Reference].[Wards] ([ward_code])
INCLUDE ([ward_id], [ward_name], [district_id]);
GO

-- Ví dụ: Tối ưu tìm kiếm Districts theo tên hoặc mã
CREATE NONCLUSTERED INDEX IX_Districts_Name ON [Reference].[Districts] ([district_name])
INCLUDE ([district_id], [district_code], [province_id]);
GO

CREATE NONCLUSTERED INDEX IX_Districts_Code ON [Reference].[Districts] ([district_code])
INCLUDE ([district_id], [district_name], [province_id]);
GO

-- Ví dụ: Tối ưu tìm kiếm Provinces theo tên hoặc mã
CREATE NONCLUSTERED INDEX IX_Provinces_Name ON [Reference].[Provinces] ([province_name])
INCLUDE ([province_id], [province_code], [region_id]);
GO

CREATE NONCLUSTERED INDEX IX_Provinces_Code ON [Reference].[Provinces] ([province_code])
INCLUDE ([province_id], [province_name], [region_id]);
GO

-- ===================================================================
-- CHỈ MỤC HỖ TRỢ API
-- ===================================================================
PRINT 'Tạo chỉ mục hỗ trợ cho API...';

-- Index hỗ trợ xác thực nhanh cho API
CREATE NONCLUSTERED INDEX IX_Citizen_APIVerification ON [BCA].[Citizen] ([citizen_id], [full_name], [date_of_birth])
INCLUDE ([gender], [current_province_id], [death_status]);
GO

PRINT 'Hoàn thành tạo chỉ mục cho DB_BCA.';
GO