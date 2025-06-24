-- File: 07_repo_procedures_and_functions.sql
-- Description: Contains stored procedures and functions refactored from raw SQL in citizen_repo.py.

USE [DB_BCA];
GO

--------------------------------------------------------------------------------
-- 1. Stored Procedure for searching citizens
--------------------------------------------------------------------------------
IF OBJECT_ID('[API_Internal].[SearchCitizens]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[SearchCitizens];
GO

CREATE PROCEDURE [API_Internal].[SearchCitizens]
    @full_name NVARCHAR(100) = NULL,
    @date_of_birth DATE = NULL,
    @limit INT = 20,
    @offset INT = 0
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        c.*, -- Select all columns from Citizen table
        nat.nationality_name,
        eth.ethnicity_name,
        rel.religion_name,
        occ.occupation_name,
        bp.province_name AS birth_province_name,
        cp.province_name AS current_province_name,
        cd.district_name AS current_district_name,
        cw.ward_name AS current_ward_name
    FROM [BCA].[Citizen] c
    LEFT JOIN [Reference].[Nationalities] nat ON c.nationality_id = nat.nationality_id
    LEFT JOIN [Reference].[Ethnicities] eth ON c.ethnicity_id = eth.ethnicity_id
    LEFT JOIN [Reference].[Religions] rel ON c.religion_id = rel.religion_id
    LEFT JOIN [Reference].[Occupations] occ ON c.occupation_id = occ.occupation_id
    LEFT JOIN [Reference].[Provinces] bp ON c.birth_province_id = bp.province_id
    LEFT JOIN [BCA].[Address] pa ON c.primary_address_id = pa.address_id -- Join to get current address IDs
    LEFT JOIN [Reference].[Provinces] cp ON pa.province_id = cp.province_id
    LEFT JOIN [Reference].[Districts] cd ON pa.district_id = cd.district_id
    LEFT JOIN [Reference].[Wards] cw ON pa.ward_id = cw.ward_id
    WHERE 
        (@full_name IS NULL OR c.full_name LIKE '%' + @full_name + '%') AND
        (@date_of_birth IS NULL OR c.date_of_birth = @date_of_birth)
    ORDER BY c.full_name
    OFFSET @offset ROWS
    FETCH NEXT @limit ROWS ONLY;
END;
GO
PRINT N'Stored Procedure [API_Internal].[SearchCitizens] created.';
GO

--------------------------------------------------------------------------------
-- 2. Function to map reason code to ID
--------------------------------------------------------------------------------
IF OBJECT_ID('[API_Internal].[MapReasonCodeToId]', 'FN') IS NOT NULL
    DROP FUNCTION [API_Internal].[MapReasonCodeToId];
GO

CREATE FUNCTION [API_Internal].[MapReasonCodeToId] (
    @reason_code VARCHAR(50)
)
RETURNS INT
AS
BEGIN
    DECLARE @reason_id INT;
    
    SELECT @reason_id = hct.change_type_id
    FROM [Reference].[HouseholdChangeTypes] hct
    WHERE hct.change_code = @reason_code;

    -- Return the found ID, or a default value (e.g., 2 for 'Chuyển đến') if not found
    RETURN ISNULL(@reason_id, 2);
END;
GO
PRINT N'Function [API_Internal].[MapReasonCodeToId] created.';
GO

--------------------------------------------------------------------------------
-- 3. Function to validate authority ID
--------------------------------------------------------------------------------
IF OBJECT_ID('[API_Internal].[ValidateAuthorityId]', 'FN') IS NOT NULL
    DROP FUNCTION [API_Internal].[ValidateAuthorityId];
GO

CREATE FUNCTION [API_Internal].[ValidateAuthorityId] (
    @authority_id INT
)
RETURNS BIT
AS
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM [Reference].[Authorities] 
        WHERE authority_id = @authority_id AND is_active = 1
    )
        RETURN 1; -- True, valid
    
    RETURN 0; -- False, invalid or inactive
END;
GO
PRINT N'Function [API_Internal].[ValidateAuthorityId] created.';
GO


--------------------------------------------------------------------------------
-- 5. Stored Procedure to find a household by ID
--------------------------------------------------------------------------------
IF OBJECT_ID('[API_Internal].[FindHouseholdById]', 'P') IS NOT NULL
    DROP PROCEDURE [API_Internal].[FindHouseholdById];
GO

CREATE PROCEDURE [API_Internal].[FindHouseholdById]
    @household_id INT
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        h.*,
        hs.status_name_vi AS household_status
    FROM 
        [BCA].[Household] h
    LEFT JOIN 
        [Reference].[HouseholdStatuses] hs ON h.household_status_id = hs.household_status_id
    WHERE 
        h.household_id = @household_id;
END;
GO
PRINT N'Stored Procedure [API_Internal].[FindHouseholdById] created.';
GO

--------------------------------------------------------------------------------
-- 6. Function to check if a citizen is in an active household
--------------------------------------------------------------------------------
IF OBJECT_ID('[API_Internal].[IsCitizenInActiveHousehold]', 'FN') IS NOT NULL
    DROP FUNCTION [API_Internal].[IsCitizenInActiveHousehold];
GO

CREATE FUNCTION [API_Internal].[IsCitizenInActiveHousehold] (
    @citizen_id VARCHAR(12)
)
RETURNS BIT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM [BCA].[HouseholdMember] hm
        JOIN [Reference].[HouseholdMemberStatuses] hms ON hm.member_status_id = hms.member_status_id
        WHERE hm.citizen_id = @citizen_id AND hms.status_code = 'ACTIVE'
    )
        RETURN 1;
    RETURN 0;
END;
GO
PRINT N'Function [API_Internal].[IsCitizenInActiveHousehold] created.';
GO

--------------------------------------------------------------------------------
-- 7. Function to check if a citizen is a member of a specific household
--------------------------------------------------------------------------------
IF OBJECT_ID('[API_Internal].[IsCitizenMemberOfHousehold]', 'FN') IS NOT NULL
    DROP FUNCTION [API_Internal].[IsCitizenMemberOfHousehold];
GO

CREATE FUNCTION [API_Internal].[IsCitizenMemberOfHousehold] (
    @citizen_id VARCHAR(12),
    @household_id INT
)
RETURNS BIT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM [BCA].[HouseholdMember]
        WHERE citizen_id = @citizen_id AND household_id = @household_id
    )
        RETURN 1;
    RETURN 0;
END;
GO
PRINT N'Function [API_Internal].[IsCitizenMemberOfHousehold] created.';
GO

--------------------------------------------------------------------------------
-- 8. Function to check if a citizen is the head of a household
--------------------------------------------------------------------------------
IF OBJECT_ID('[API_Internal].[IsCitizenHeadOfHousehold]', 'FN') IS NOT NULL
    DROP FUNCTION [API_Internal].[IsCitizenHeadOfHousehold];
GO

CREATE FUNCTION [API_Internal].[IsCitizenHeadOfHousehold] (
    @citizen_id VARCHAR(12),
    @household_id INT
)
RETURNS BIT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM [BCA].[Household]
        WHERE head_of_household_id = @citizen_id AND household_id = @household_id
    )
        RETURN 1;
    RETURN 0;
END;
GO
PRINT N'Function [API_Internal].[IsCitizenHeadOfHousehold] created.';
GO

--------------------------------------------------------------------------------
-- 9. Function to count active household members excluding a specific citizen
--------------------------------------------------------------------------------
IF OBJECT_ID('[API_Internal].[CountActiveHouseholdMembersExcludingCitizen]', 'FN') IS NOT NULL
    DROP FUNCTION [API_Internal].[CountActiveHouseholdMembersExcludingCitizen];
GO

CREATE FUNCTION [API_Internal].[CountActiveHouseholdMembersExcludingCitizen] (
    @household_id INT,
    @exclude_citizen_id VARCHAR(12)
)
RETURNS INT
AS
BEGIN
    DECLARE @count INT;
    SELECT @count = COUNT(*)
    FROM [BCA].[HouseholdMember] hm
    JOIN [Reference].[HouseholdMemberStatuses] hms ON hm.member_status_id = hms.member_status_id
    WHERE hm.household_id = @household_id
      AND hm.citizen_id != @exclude_citizen_id
      AND hms.status_code = 'ACTIVE';
    RETURN @count;
END;
GO
PRINT N'Function [API_Internal].[CountActiveHouseholdMembersExcludingCitizen] created.';
GO 