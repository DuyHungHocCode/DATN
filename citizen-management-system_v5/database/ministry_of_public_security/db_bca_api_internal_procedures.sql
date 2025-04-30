USE [DB_BCA];
GO

-- Drop the function if it already exists
IF OBJECT_ID('[API_Internal].[GetCitizenDetails]', 'IF') IS NOT NULL
    DROP FUNCTION [API_Internal].[GetCitizenDetails];
GO

-- Create the Inline Table-Valued Function (iTVF) to get citizen details
CREATE FUNCTION [API_Internal].[GetCitizenDetails] (
    @citizen_id VARCHAR(12) -- Input: Citizen ID (CCCD)
)
RETURNS TABLE
AS
RETURN
(
    -- Select detailed citizen information by joining with reference tables
    SELECT
        -- Core Citizen Info
        c.[citizen_id],
        c.[full_name],
        c.[date_of_birth],
        c.[gender],

        -- Birth Place Info
        c.[birth_ward_id],
        bw.[ward_name] AS birth_ward_name,
        c.[birth_district_id],
        bd.[district_name] AS birth_district_name,
        c.[birth_province_id],
        bp.[province_name] AS birth_province_name,
        c.[birth_country_id],
        bc.[nationality_name] AS birth_country_name,
        c.[place_of_birth_code], -- Added from revised structure
        c.[place_of_birth_detail], -- Added from revised structure

        -- Native Place Info
        c.[native_ward_id],
        nw.[ward_name] AS native_ward_name,
        c.[native_district_id],
        nd.[district_name] AS native_district_name,
        c.[native_province_id],
        np.[province_name] AS native_province_name,

        -- Demographic Info
        c.[nationality_id],
        nat.[nationality_name],
        c.[ethnicity_id],
        eth.[ethnicity_name],
        c.[religion_id],
        rel.[religion_name],
        c.[blood_type], -- Added from revised structure

        -- Social/Economic Info
        c.[marital_status],
        c.[education_level],
        c.[occupation_id],
        occ.[occupation_name],
        c.[tax_code], -- Added from revised structure
        c.[social_insurance_no], -- Added from revised structure
        c.[health_insurance_no], -- Added from revised structure

        -- Current Address Info
        c.[current_address_detail],
        c.[current_ward_id],
        cw.[ward_name] AS current_ward_name,
        c.[current_district_id],
        cd.[district_name] AS current_district_name,
        c.[current_province_id],
        cp.[province_name] AS current_province_name,

        -- Family Info
        c.[father_citizen_id],
        c.[mother_citizen_id],
        c.[spouse_citizen_id],
        c.[representative_citizen_id],

        -- Status Info
        c.[death_status],
        c.[date_of_death],

        -- Contact Info
        c.[phone_number],
        c.[email],

        -- Metadata
        c.[created_at],
        c.[updated_at],
        c.[created_by], -- Added from revised structure
        c.[updated_by]  -- Added from revised structure

    FROM [BCA].[Citizen] c
    -- Joins for Birth Place
    LEFT JOIN [Reference].[Wards] bw ON c.birth_ward_id = bw.ward_id
    LEFT JOIN [Reference].[Districts] bd ON c.birth_district_id = bd.district_id
    LEFT JOIN [Reference].[Provinces] bp ON c.birth_province_id = bp.province_id
    LEFT JOIN [Reference].[Nationalities] bc ON c.birth_country_id = bc.nationality_id
    -- Joins for Native Place
    LEFT JOIN [Reference].[Wards] nw ON c.native_ward_id = nw.ward_id
    LEFT JOIN [Reference].[Districts] nd ON c.native_district_id = nd.district_id
    LEFT JOIN [Reference].[Provinces] np ON c.native_province_id = np.province_id
    -- Joins for Demographic Info
    LEFT JOIN [Reference].[Nationalities] nat ON c.nationality_id = nat.nationality_id
    LEFT JOIN [Reference].[Ethnicities] eth ON c.ethnicity_id = eth.ethnicity_id
    LEFT JOIN [Reference].[Religions] rel ON c.religion_id = rel.religion_id
    -- Join for Occupation
    LEFT JOIN [Reference].[Occupations] occ ON c.occupation_id = occ.occupation_id
    -- Joins for Current Address
    LEFT JOIN [Reference].[Wards] cw ON c.current_ward_id = cw.ward_id
    LEFT JOIN [Reference].[Districts] cd ON c.current_district_id = cd.district_id
    LEFT JOIN [Reference].[Provinces] cp ON c.current_province_id = cp.province_id
    -- Filter by the input citizen_id
    WHERE c.[citizen_id] = @citizen_id
);
GO

--====================================================================================

-- Drop the function if it already exists
IF OBJECT_ID('[API_Internal].[GetResidenceHistory]', 'IF') IS NOT NULL
    DROP FUNCTION [API_Internal].[GetResidenceHistory];
GO

-- Create the Inline Table-Valued Function (iTVF) to get comprehensive residence history
CREATE FUNCTION [API_Internal].[GetResidenceHistory] (
    @citizen_id VARCHAR(12) -- Input: Citizen ID (CCCD)
)
RETURNS TABLE
AS
RETURN
(
    -- Combine results from multiple queries using UNION ALL
    
    -- 1. Permanent and Temporary Residence History
    SELECT
        'ResidenceHistory' AS record_type,
        rh.[residence_type], -- 'Thường trú' or 'Tạm trú'
        rh.[residence_history_id] AS record_id,
        a.[address_detail],
        w.[ward_name],
        d.[district_name],
        p.[province_name],
        NULL AS destination_detail, -- Only for temporary absence
        rh.[registration_date] AS start_date,
        rh.[expiry_date] AS end_date,
        CASE 
            WHEN rh.[status] = 'Active' AND rh.[residence_type] = N'Thường trú' THEN 1
            ELSE 0
        END AS is_current_permanent_residence,
        CASE 
            WHEN rh.[status] = 'Active' AND rh.[residence_type] = N'Tạm trú' THEN 1
            ELSE 0
        END AS is_current_temporary_residence,
        0 AS is_temporary_absence,
        0 AS is_current_address,
        0 AS is_accommodation,
        rh.[registration_reason] AS reason,
        CASE
            WHEN rh.[status] = 'Moved' OR rh.[status] = 'Cancelled' THEN rh.[updated_at]
            WHEN rh.[status] = 'Expired' THEN rh.[expiry_date]
            ELSE NULL
        END AS deregistration_date,
        rh.[status] AS record_status,
        rh.[host_name],
        rh.[host_citizen_id],
        rh.[host_relationship],
        auth.[authority_name] AS issuing_authority,
        rh.[verification_status],
        rh.[notes],
        rh.[created_at],
        rh.[updated_at]
    FROM [BCA].[ResidenceHistory] rh
    INNER JOIN [BCA].[Address] a ON rh.address_id = a.address_id
    LEFT JOIN [Reference].[Wards] w ON a.ward_id = w.ward_id
    LEFT JOIN [Reference].[Districts] d ON a.district_id = d.district_id
    LEFT JOIN [Reference].[Provinces] p ON a.province_id = p.province_id
    LEFT JOIN [Reference].[Authorities] auth ON rh.issuing_authority_id = auth.authority_id
    WHERE rh.[citizen_id] = @citizen_id
    
    UNION ALL
    
    -- 2. Temporary Absence Records
    SELECT
        'TemporaryAbsence' AS record_type,
        N'Tạm vắng' AS residence_type,
        ta.[temporary_absence_id] AS record_id,
        CASE 
            WHEN a.address_id IS NOT NULL THEN a.address_detail 
            ELSE NULL 
        END AS address_detail,
        CASE 
            WHEN a.address_id IS NOT NULL THEN w.ward_name 
            ELSE NULL 
        END AS ward_name,
        CASE 
            WHEN a.address_id IS NOT NULL THEN d.district_name 
            ELSE NULL 
        END AS district_name,
        CASE 
            WHEN a.address_id IS NOT NULL THEN p.province_name 
            ELSE NULL 
        END AS province_name,
        ta.[destination_detail],
        ta.[from_date] AS start_date,
        ta.[to_date] AS end_date,
        0 AS is_current_permanent_residence,
        0 AS is_current_temporary_residence,
        1 AS is_temporary_absence,
        0 AS is_current_address,
        0 AS is_accommodation,
        ta.[reason],
        ta.[return_date] AS deregistration_date,
        ta.[status] AS record_status,
        NULL AS host_name,
        NULL AS host_citizen_id,
        NULL AS host_relationship,
        auth.[authority_name] AS issuing_authority,
        ta.[verification_status],
        ta.[notes],
        ta.[created_at],
        ta.[updated_at]
    FROM [BCA].[TemporaryAbsence] ta
    LEFT JOIN [BCA].[Address] a ON ta.destination_address_id = a.address_id
    LEFT JOIN [Reference].[Wards] w ON a.ward_id = w.ward_id
    LEFT JOIN [Reference].[Districts] d ON a.district_id = d.district_id
    LEFT JOIN [Reference].[Provinces] p ON a.province_id = p.province_id
    LEFT JOIN [Reference].[Authorities] auth ON ta.registration_authority_id = auth.authority_id
    WHERE ta.[citizen_id] = @citizen_id
    
    UNION ALL
    
    -- 3. Current Residence and Other Address Types (from CitizenAddress)
    SELECT
        'CitizenAddress' AS record_type,
        ca.[address_type] AS residence_type,
        ca.[citizen_address_id] AS record_id,
        a.[address_detail],
        w.[ward_name],
        d.[district_name],
        p.[province_name],
        NULL AS destination_detail,
        ca.[from_date] AS start_date,
        ca.[to_date] AS end_date,
        0 AS is_current_permanent_residence,
        0 AS is_current_temporary_residence,
        0 AS is_temporary_absence,
        CASE 
            WHEN ca.[address_type] = N'Nơi ở hiện tại' AND ca.[status] = 1 THEN 1
            ELSE 0
        END AS is_current_address,
        CASE 
            WHEN ca.[address_type] = N'Khác' AND ca.[status] = 1 THEN 1
            ELSE 0
        END AS is_accommodation,
        NULL AS reason,
        CASE
            WHEN ca.[status] = 0 THEN ca.[updated_at]
            WHEN ca.[to_date] IS NOT NULL THEN ca.[to_date]
            ELSE NULL
        END AS deregistration_date,
        CASE 
            WHEN ca.[status] = 1 THEN 'Active' 
            ELSE 'Inactive' 
        END AS record_status,
        NULL AS host_name,
        NULL AS host_citizen_id,
        NULL AS host_relationship,
        auth.[authority_name] AS issuing_authority,
        ca.[verification_status],
        ca.[notes],
        ca.[created_at],
        ca.[updated_at]
    FROM [BCA].[CitizenAddress] ca
    INNER JOIN [BCA].[Address] a ON ca.address_id = a.address_id
    LEFT JOIN [Reference].[Wards] w ON a.ward_id = w.ward_id
    LEFT JOIN [Reference].[Districts] d ON a.district_id = d.district_id
    LEFT JOIN [Reference].[Provinces] p ON a.province_id = p.province_id
    LEFT JOIN [Reference].[Authorities] auth ON ca.issuing_authority_id = auth.authority_id
    WHERE ca.[citizen_id] = @citizen_id
)
GO

-- Create a complementary function to get citizen contact information
IF OBJECT_ID('[API_Internal].[GetCitizenContactInfo]', 'IF') IS NOT NULL
    DROP FUNCTION [API_Internal].[GetCitizenContactInfo];
GO

CREATE FUNCTION [API_Internal].[GetCitizenContactInfo] (
    @citizen_id VARCHAR(12)
)
RETURNS TABLE
AS
RETURN
(
    SELECT
        c.[citizen_id],
        c.[phone_number],
        c.[email],
        c.[full_name],
        c.[current_address_detail],
        w.[ward_name] AS current_ward_name,
        d.[district_name] AS current_district_name,
        p.[province_name] AS current_province_name
    FROM [BCA].[Citizen] c
    LEFT JOIN [Reference].[Wards] w ON c.current_ward_id = w.ward_id
    LEFT JOIN [Reference].[Districts] d ON c.current_district_id = d.district_id
    LEFT JOIN [Reference].[Provinces] p ON c.current_province_id = p.province_id
    WHERE c.[citizen_id] = @citizen_id
)
GO