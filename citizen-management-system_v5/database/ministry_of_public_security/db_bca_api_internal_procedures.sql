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

