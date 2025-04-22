-- =============================================================================
-- File: database/schemas/central_server/summary_views.sql
-- Description: Tạo các view tổng hợp dữ liệu trên máy chủ trung tâm
-- Version: 1.0
-- 
-- Các view chính:
-- 1. Dân số theo đơn vị hành chính
-- 2. Thống kê biến động dân cư
-- 3. Tổng hợp thông tin hộ khẩu
-- 4. Thống kê CCCD và đăng ký tạm trú
-- 5. Thống kê theo độ tuổi và giới tính
-- 6. Thống kê tỷ lệ khai sinh, khai tử
-- 7. Báo cáo động dân cư theo khu vực
-- 8. Dashboard dân số quốc gia
-- =============================================================================

\echo 'Tạo các view tổng hợp dữ liệu cho máy chủ trung tâm...'
\connect national_citizen_central_server

BEGIN;

-- =============================================================================
-- 1. VIEW THỐNG KÊ DÂN SỐ THEO ĐƠN VỊ HÀNH CHÍNH
-- =============================================================================
DROP VIEW IF EXISTS central.vw_population_by_administrative_unit CASCADE;
CREATE VIEW central.vw_population_by_administrative_unit AS
SELECT 
    r.region_id,
    r.region_name,
    p.province_id,
    p.province_name,
    d.district_id,
    d.district_name,
    w.ward_id,
    w.ward_name,
    COUNT(DISTINCT c.citizen_id) AS total_population,
    SUM(CASE WHEN c.gender = 'Nam' THEN 1 ELSE 0 END) AS male_population,
    SUM(CASE WHEN c.gender = 'Nữ' THEN 1 ELSE 0 END) AS female_population,
    SUM(CASE WHEN c.gender = 'Khác' THEN 1 ELSE 0 END) AS other_gender_population,
    SUM(CASE WHEN c.death_status = 'Còn sống' THEN 1 ELSE 0 END) AS living_population,
    SUM(CASE WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) < 18 THEN 1 ELSE 0 END) AS minor_population,
    SUM(CASE WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 18 AND 60 THEN 1 ELSE 0 END) AS working_age_population,
    SUM(CASE WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) > 60 THEN 1 ELSE 0 END) AS elderly_population
FROM 
    public_security.citizen c
JOIN 
    reference.regions r ON c.region_id = r.region_id
JOIN 
    reference.provinces p ON c.province_id = p.province_id
JOIN 
    public_security.address a ON a.province_id = p.province_id
JOIN 
    public_security.citizen_address ca ON ca.citizen_id = c.citizen_id AND ca.address_id = a.address_id
JOIN 
    reference.districts d ON a.district_id = d.district_id
JOIN 
    reference.wards w ON a.ward_id = w.ward_id
WHERE 
    ca.address_type = 'Thường trú' 
    AND ca.status = TRUE
    AND c.status = TRUE
GROUP BY 
    r.region_id, r.region_name,
    p.province_id, p.province_name,
    d.district_id, d.district_name,
    w.ward_id, w.ward_name
WITH DATA;

COMMENT ON VIEW central.vw_population_by_administrative_unit IS 'Thống kê dân số theo đơn vị hành chính từ cấp miền đến phường/xã';

-- =============================================================================
-- 2. VIEW THỐNG KÊ BIẾN ĐỘNG DÂN CƯ HÀNG THÁNG
-- =============================================================================
DROP VIEW IF EXISTS central.vw_monthly_population_change CASCADE;
CREATE VIEW central.vw_monthly_population_change AS
SELECT
    DATE_TRUNC('month', pc.change_date)::DATE AS month_year,
    r.region_name,
    p.province_name,
    pc.change_type,
    COUNT(*) AS change_count
FROM
    justice.population_change pc
JOIN
    reference.regions r ON pc.region_id = r.region_id
JOIN
    reference.provinces p ON pc.province_id = p.province_id
WHERE
    pc.status = TRUE
    AND pc.change_date >= CURRENT_DATE - INTERVAL '3 years'
GROUP BY
    DATE_TRUNC('month', pc.change_date)::DATE,
    r.region_name,
    p.province_name,
    pc.change_type
ORDER BY
    month_year DESC,
    r.region_name,
    p.province_name,
    pc.change_type
WITH DATA;

COMMENT ON VIEW central.vw_monthly_population_change IS 'Thống kê biến động dân cư hàng tháng theo khu vực và loại biến động';

-- =============================================================================
-- 3. VIEW TỔNG HỢP HỘ KHẨU
-- =============================================================================
DROP VIEW IF EXISTS central.vw_household_summary CASCADE;
CREATE VIEW central.vw_household_summary AS
SELECT
    r.region_id,
    r.region_name,
    p.province_id,
    p.province_name,
    d.district_id,
    d.district_name,
    h.household_type,
    COUNT(DISTINCT h.household_id) AS household_count,
    COUNT(DISTINCT hm.citizen_id) AS total_members,
    AVG(subq.member_count) AS avg_household_size,
    MAX(subq.member_count) AS max_household_size,
    MIN(subq.member_count) AS min_household_size
FROM
    justice.household h
JOIN
    (SELECT 
        household_id, 
        COUNT(*) AS member_count 
     FROM 
        justice.household_member 
     WHERE 
        status = 'Active' 
     GROUP BY 
        household_id
    ) AS subq ON h.household_id = subq.household_id
JOIN
    justice.household_member hm ON h.household_id = hm.household_id AND hm.status = 'Active'
JOIN
    reference.regions r ON h.region_id = r.region_id
JOIN
    reference.provinces p ON h.province_id = p.province_id
JOIN
    public_security.address a ON h.address_id = a.address_id
JOIN
    reference.districts d ON a.district_id = d.district_id
WHERE
    h.status = TRUE
GROUP BY
    r.region_id,
    r.region_name,
    p.province_id,
    p.province_name,
    d.district_id,
    d.district_name,
    h.household_type
WITH DATA;

COMMENT ON VIEW central.vw_household_summary IS 'Tổng hợp thông tin hộ khẩu và thành viên theo đơn vị hành chính và loại hộ khẩu';

-- =============================================================================
-- 4. VIEW THỐNG KÊ CĂN CƯỚC CÔNG DÂN VÀ ĐĂNG KÝ TẠM TRÚ
-- =============================================================================
DROP VIEW IF EXISTS central.vw_id_card_and_residence_stats CASCADE;
CREATE VIEW central.vw_id_card_and_residence_stats AS
SELECT
    r.region_name,
    p.province_name,
    COUNT(DISTINCT c.citizen_id) AS total_citizens,
    COUNT(DISTINCT CASE WHEN ic.card_status = 'Đang sử dụng' THEN ic.card_id ELSE NULL END) AS active_id_cards,
    COUNT(DISTINCT CASE WHEN ic.card_type = 'CCCD gắn chip' THEN ic.card_id ELSE NULL END) AS smart_id_cards,
    COUNT(DISTINCT CASE WHEN ic.expiry_date < CURRENT_DATE THEN ic.card_id ELSE NULL END) AS expired_id_cards,
    COUNT(DISTINCT pr.permanent_residence_id) AS permanent_residence_count,
    COUNT(DISTINCT tr.temporary_residence_id) AS temporary_residence_count,
    ROUND(COUNT(DISTINCT CASE WHEN ic.card_status = 'Đang sử dụng' THEN ic.card_id ELSE NULL END)::NUMERIC / 
          NULLIF(COUNT(DISTINCT c.citizen_id), 0) * 100, 2) AS id_card_coverage_percent
FROM
    public_security.citizen c
LEFT JOIN
    public_security.identification_card ic ON c.citizen_id = ic.citizen_id
LEFT JOIN
    public_security.permanent_residence pr ON c.citizen_id = pr.citizen_id AND pr.status = TRUE
LEFT JOIN
    public_security.temporary_residence tr ON c.citizen_id = tr.citizen_id AND tr.status = 'Active'
JOIN
    reference.regions r ON c.region_id = r.region_id
JOIN
    reference.provinces p ON c.province_id = p.province_id
WHERE
    c.status = TRUE AND
    c.death_status = 'Còn sống' AND
    DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) >= 14
GROUP BY
    r.region_name,
    p.province_name
WITH DATA;

COMMENT ON VIEW central.vw_id_card_and_residence_stats IS 'Thống kê tình hình cấp CCCD và đăng ký cư trú theo tỉnh/thành phố';

-- =============================================================================
-- 5. VIEW THỐNG KÊ DÂN SỐ THEO ĐỘ TUỔI VÀ GIỚI TÍNH (POPULATION PYRAMID)
-- =============================================================================
DROP VIEW IF EXISTS central.vw_population_pyramid CASCADE;
CREATE VIEW central.vw_population_pyramid AS
WITH age_groups AS (
    SELECT
        c.citizen_id,
        c.gender,
        r.region_name,
        p.province_name,
        CASE
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) < 5 THEN '0-4'
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 5 AND 9 THEN '5-9'
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 10 AND 14 THEN '10-14'
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 15 AND 19 THEN '15-19'
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 20 AND 24 THEN '20-24'
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 25 AND 29 THEN '25-29'
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 30 AND 34 THEN '30-34'
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 35 AND 39 THEN '35-39'
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 40 AND 44 THEN '40-44'
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 45 AND 49 THEN '45-49'
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 50 AND 54 THEN '50-54'
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 55 AND 59 THEN '55-59'
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 60 AND 64 THEN '60-64'
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 65 AND 69 THEN '65-69'
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 70 AND 74 THEN '70-74'
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 75 AND 79 THEN '75-79'
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 80 AND 84 THEN '80-84'
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) >= 85 THEN '85+'
        END AS age_group,
        CASE
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) < 5 THEN 1
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 5 AND 9 THEN 2
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 10 AND 14 THEN 3
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 15 AND 19 THEN 4
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 20 AND 24 THEN 5
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 25 AND 29 THEN 6
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 30 AND 34 THEN 7
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 35 AND 39 THEN 8
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 40 AND 44 THEN 9
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 45 AND 49 THEN 10
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 50 AND 54 THEN 11
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 55 AND 59 THEN 12
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 60 AND 64 THEN 13
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 65 AND 69 THEN 14
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 70 AND 74 THEN 15
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 75 AND 79 THEN 16
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 80 AND 84 THEN 17
            WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) >= 85 THEN 18
        END AS age_group_order
    FROM
        public_security.citizen c
    JOIN
        reference.regions r ON c.region_id = r.region_id
    JOIN
        reference.provinces p ON c.province_id = p.province_id
    WHERE
        c.status = TRUE AND
        c.death_status = 'Còn sống'
)
SELECT
    region_name,
    province_name,
    age_group,
    age_group_order,
    SUM(CASE WHEN gender = 'Nam' THEN 1 ELSE 0 END) AS male_count,
    SUM(CASE WHEN gender = 'Nữ' THEN 1 ELSE 0 END) AS female_count,
    SUM(CASE WHEN gender = 'Khác' THEN 1 ELSE 0 END) AS other_gender_count,
    COUNT(*) AS total_count
FROM
    age_groups
GROUP BY
    region_name,
    province_name,
    age_group,
    age_group_order
ORDER BY
    region_name,
    province_name,
    age_group_order
WITH DATA;

COMMENT ON VIEW central.vw_population_pyramid IS 'Tháp dân số theo độ tuổi và giới tính, phân theo tỉnh/thành phố';

-- =============================================================================
-- 6. VIEW THỐNG KÊ TỶ LỆ KHAI SINH, KHAI TỬ, KẾT HÔN, LY HÔN
-- =============================================================================
DROP VIEW IF EXISTS central.vw_vital_statistics CASCADE;
CREATE VIEW central.vw_vital_statistics AS
WITH birth_data AS (
    SELECT
        p.province_id,
        p.province_name,
        r.region_name,
        DATE_TRUNC('month', bc.registration_date)::DATE AS month_year,
        COUNT(*) AS birth_count
    FROM
        justice.birth_certificate bc
    JOIN
        reference.regions r ON bc.region_id = r.region_id
    JOIN
        reference.provinces p ON bc.province_id = p.province_id
    WHERE
        bc.status = TRUE
        AND bc.registration_date >= CURRENT_DATE - INTERVAL '5 years'
    GROUP BY
        p.province_id, p.province_name, r.region_name, DATE_TRUNC('month', bc.registration_date)::DATE
),
death_data AS (
    SELECT
        p.province_id,
        p.province_name,
        r.region_name,
        DATE_TRUNC('month', dc.registration_date)::DATE AS month_year,
        COUNT(*) AS death_count
    FROM
        justice.death_certificate dc
    JOIN
        reference.regions r ON dc.region_id = r.region_id
    JOIN
        reference.provinces p ON dc.province_id = p.province_id
    WHERE
        dc.status = TRUE
        AND dc.registration_date >= CURRENT_DATE - INTERVAL '5 years'
    GROUP BY
        p.province_id, p.province_name, r.region_name, DATE_TRUNC('month', dc.registration_date)::DATE
),
marriage_data AS (
    SELECT
        p.province_id,
        p.province_name,
        r.region_name,
        DATE_TRUNC('month', m.registration_date)::DATE AS month_year,
        COUNT(*) AS marriage_count
    FROM
        justice.marriage m
    JOIN
        reference.regions r ON m.region_id = r.region_id
    JOIN
        reference.provinces p ON m.province_id = p.province_id
    WHERE
        m.status = TRUE
        AND m.registration_date >= CURRENT_DATE - INTERVAL '5 years'
    GROUP BY
        p.province_id, p.province_name, r.region_name, DATE_TRUNC('month', m.registration_date)::DATE
),
divorce_data AS (
    SELECT
        p.province_id,
        p.province_name,
        r.region_name,
        DATE_TRUNC('month', d.registration_date)::DATE AS month_year,
        COUNT(*) AS divorce_count
    FROM
        justice.divorce d
    JOIN
        reference.regions r ON d.region_id = r.region_id
    JOIN
        reference.provinces p ON d.province_id = p.province_id
    WHERE
        d.status = TRUE
        AND d.registration_date >= CURRENT_DATE - INTERVAL '5 years'
    GROUP BY
        p.province_id, p.province_name, r.region_name, DATE_TRUNC('month', d.registration_date)::DATE
),
all_dates AS (
    SELECT DISTINCT
        month_year,
        province_id,
        province_name,
        region_name
    FROM (
        SELECT month_year, province_id, province_name, region_name FROM birth_data
        UNION
        SELECT month_year, province_id, province_name, region_name FROM death_data
        UNION
        SELECT month_year, province_id, province_name, region_name FROM marriage_data
        UNION
        SELECT month_year, province_id, province_name, region_name FROM divorce_data
    ) combined
)
SELECT
    ad.month_year,
    ad.region_name,
    ad.province_name,
    COALESCE(bd.birth_count, 0) AS birth_count,
    COALESCE(dd.death_count, 0) AS death_count,
    COALESCE(md.marriage_count, 0) AS marriage_count,
    COALESCE(dvd.divorce_count, 0) AS divorce_count,
    COALESCE(bd.birth_count, 0) - COALESCE(dd.death_count, 0) AS natural_population_growth,
    CASE
        WHEN COALESCE(md.marriage_count, 0) = 0 THEN 0
        ELSE ROUND(COALESCE(dvd.divorce_count, 0)::NUMERIC / COALESCE(md.marriage_count, 1) * 100, 2)
    END AS divorce_rate_percent
FROM
    all_dates ad
LEFT JOIN
    birth_data bd ON ad.month_year = bd.month_year AND ad.province_id = bd.province_id
LEFT JOIN
    death_data dd ON ad.month_year = dd.month_year AND ad.province_id = dd.province_id
LEFT JOIN
    marriage_data md ON ad.month_year = md.month_year AND ad.province_id = md.province_id
LEFT JOIN
    divorce_data dvd ON ad.month_year = dvd.month_year AND ad.province_id = dvd.province_id
ORDER BY
    ad.month_year DESC,
    ad.region_name,
    ad.province_name
WITH DATA;

COMMENT ON VIEW central.vw_vital_statistics IS 'Thống kê tỷ lệ khai sinh, khai tử, kết hôn, ly hôn theo tháng và tỉnh/thành phố';

-- =============================================================================
-- 7. VIEW BÁO CÁO BIẾN ĐỘNG DÂN CƯ THEO KHU VỰC
-- =============================================================================
DROP VIEW IF EXISTS central.vw_migration_statistics CASCADE;
CREATE VIEW central.vw_migration_statistics AS
WITH migration_data AS (
    SELECT
        cm.citizen_id,
        cm.movement_type,
        sr.region_name AS source_region,
        sp.province_name AS source_province,
        tr.region_name AS target_region,
        tp.province_name AS target_province,
        DATE_TRUNC('month', cm.departure_date)::DATE AS month_year
    FROM
        public_security.citizen_movement cm
    LEFT JOIN
        reference.regions sr ON cm.source_region_id = sr.region_id
    LEFT JOIN
        reference.provinces sp ON cm.from_address_id = sp.province_id
    LEFT JOIN
        reference.regions tr ON cm.target_region_id = tr.region_id
    LEFT JOIN
        reference.provinces tp ON cm.to_address_id = tp.province_id
    WHERE
        cm.departure_date >= CURRENT_DATE - INTERVAL '3 years'
)
SELECT
    month_year,
    source_region,
    source_province,
    target_region,
    target_province,
    COUNT(CASE WHEN movement_type = 'Trong nước' THEN citizen_id END) AS domestic_migration_count,
    COUNT(CASE WHEN movement_type = 'Xuất cảnh' THEN citizen_id END) AS emigration_count,
    COUNT(CASE WHEN movement_type = 'Nhập cảnh' THEN citizen_id END) AS immigration_count,
    COUNT(CASE WHEN movement_type = 'Tái nhập cảnh' THEN citizen_id END) AS reentry_count,
    COUNT(citizen_id) AS total_movements
FROM
    migration_data
GROUP BY
    month_year,
    source_region,
    source_province,
    target_region,
    target_province
ORDER BY
    month_year DESC,
    source_region,
    source_province,
    target_region,
    target_province
WITH DATA;

COMMENT ON VIEW central.vw_migration_statistics IS 'Thống kê di cư và biến động dân cư giữa các khu vực';

-- =============================================================================
-- 8. VIEW DASHBOARD DÂN SỐ QUỐC GIA
-- =============================================================================
DROP VIEW IF EXISTS central.vw_national_population_dashboard CASCADE;
CREATE VIEW central.vw_national_population_dashboard AS
SELECT
    r.region_name,
    p.province_name,
    COUNT(DISTINCT c.citizen_id) AS total_population,
    -- Thống kê giới tính
    ROUND(SUM(CASE WHEN c.gender = 'Nam' THEN 1 ELSE 0 END)::NUMERIC / COUNT(DISTINCT c.citizen_id) * 100, 2) AS male_percentage,
    ROUND(SUM(CASE WHEN c.gender = 'Nữ' THEN 1 ELSE 0 END)::NUMERIC / COUNT(DISTINCT c.citizen_id) * 100, 2) AS female_percentage,
    
    -- Thống kê độ tuổi
    SUM(CASE WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) < 15 THEN 1 ELSE 0 END) AS age_under_15_count,
    SUM(CASE WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 15 AND 64 THEN 1 ELSE 0 END) AS age_15_to_64_count,
    SUM(CASE WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) >= 65 THEN 1 ELSE 0 END) AS age_65_plus_count,
    
    -- Tỷ lệ phụ thuộc
    ROUND((SUM(CASE WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) < 15 THEN 1 ELSE 0 END) + 
           SUM(CASE WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) >= 65 THEN 1 ELSE 0 END))::NUMERIC /
          NULLIF(SUM(CASE WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) BETWEEN 15 AND 64 THEN 1 ELSE 0 END), 0) * 100, 2) AS dependency_ratio,
    
    -- Thống kê hộ khẩu
    COUNT(DISTINCT h.household_id) AS total_households,
    ROUND(COUNT(DISTINCT c.citizen_id)::NUMERIC / NULLIF(COUNT(DISTINCT h.household_id), 0), 2) AS avg_household_size,
    
    -- Thống kê CCCD
    SUM(CASE WHEN ic.card_status = 'Đang sử dụng' THEN 1 ELSE 0 END) AS active_id_card_count,
    ROUND(SUM(CASE WHEN ic.card_status = 'Đang sử dụng' THEN 1 ELSE 0 END)::NUMERIC / 
          NULLIF(SUM(CASE WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) >= 14 THEN 1 ELSE 0 END), 0) * 100, 2) AS id_card_coverage,
    
    -- Thống kê dân số theo nhóm dân tộc
    SUM(CASE WHEN c.ethnicity_id = 1 THEN 1 ELSE 0 END) AS kinh_population,
    SUM(CASE WHEN c.ethnicity_id != 1 THEN 1 ELSE 0 END) AS ethnic_minority_population,
    
    -- Thống kê dân số theo tôn giáo
    SUM(CASE WHEN c.religion_id = 9 THEN 1 ELSE 0 END) AS no_religion_population,
    SUM(CASE WHEN c.religion_id != 9 AND c.religion_id IS NOT NULL THEN 1 ELSE 0 END) AS with_religion_population,
    
    -- Thống kê trình độ học vấn (với người trên 15 tuổi)
    ROUND(SUM(CASE WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) >= 15 AND c.education_level IN ('Đại học', 'Thạc sĩ', 'Tiến sĩ') THEN 1 ELSE 0 END)::NUMERIC /
          NULLIF(SUM(CASE WHEN DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) >= 15 THEN 1 ELSE 0 END), 0) * 100, 2) AS higher_education_percentage
FROM
    public_security.citizen c
JOIN
    reference.regions r ON c.region_id = r.region_id
JOIN
    reference.provinces p ON c.province_id = p.province_id
LEFT JOIN
    public_security.citizen_address ca ON c.citizen_id = ca.citizen_id AND ca.address_type = 'Thường trú' AND ca.status = TRUE
LEFT JOIN
    public_security.address a ON ca.address_id = a.address_id
LEFT JOIN
    justice.household_member hm ON c.citizen_id = hm.citizen_id AND hm.status = 'Active'
LEFT JOIN
    justice.household h ON hm.household_id = h.household_id AND h.status = TRUE
LEFT JOIN
    public_security.identification_card ic ON c.citizen_id = ic.citizen_id AND ic.card_status = 'Đang sử dụng'
WHERE
    c.status = TRUE AND
    c.death_status = 'Còn sống'
GROUP BY
    r.region_name,
    p.province_name
WITH DATA;

COMMENT ON VIEW central.vw_national_population_dashboard IS 'Bảng tổng hợp thông tin dân số quốc gia cho dashboard';

-- =============================================================================
-- 9. VIEW BÁO CÁO ĐỘNG THÁI DÂN SỐ (POPULATION DYNAMICS)
-- =============================================================================
DROP VIEW IF EXISTS central.vw_population_dynamics CASCADE;
CREATE VIEW central.vw_population_dynamics AS
WITH years AS (
    SELECT generate_series(
        DATE_PART('year', CURRENT_DATE) - 10,
        DATE_PART('year', CURRENT_DATE),
        1
    )::INTEGER AS year
),
birth_data AS (
    SELECT
        DATE_PART('year', date_of_birth)::INTEGER AS year,
        COUNT(*) AS birth_count
    FROM
        justice.birth_certificate
    WHERE
        status = TRUE AND
        DATE_PART('year', date_of_birth) >= DATE_PART('year', CURRENT_DATE) - 10
    GROUP BY
        DATE_PART('year', date_of_birth)::INTEGER
),
death_data AS (
    SELECT
        DATE_PART('year', date_of_death)::INTEGER AS year,
        COUNT(*) AS death_count
    FROM
        justice.death_certificate
    WHERE
        status = TRUE AND
        DATE_PART('year', date_of_death) >= DATE_PART('year', CURRENT_DATE) - 10
    GROUP BY
        DATE_PART('year', date_of_death)::INTEGER
),
immigration_data AS (
    SELECT
        DATE_PART('year', arrival_date)::INTEGER AS year,
        COUNT(*) AS immigration_count
    FROM
        public_security.citizen_movement
    WHERE
        movement_type = 'Nhập cảnh' AND
        arrival_date IS NOT NULL AND
        DATE_PART('year', arrival_date) >= DATE_PART('year', CURRENT_DATE) - 10
    GROUP BY
        DATE_PART('year', arrival_date)::INTEGER
),
emigration_data AS (
    SELECT
        DATE_PART('year', departure_date)::INTEGER AS year,
        COUNT(*) AS emigration_count
    FROM
        public_security.citizen_movement
    WHERE
        movement_type = 'Xuất cảnh' AND
        DATE_PART('year', departure_date) >= DATE_PART('year', CURRENT_DATE) - 10
    GROUP BY
        DATE_PART('year', departure_date)::INTEGER
)
SELECT
    y.year,
    COALESCE(bd.birth_count, 0) AS birth_count,
    COALESCE(dd.death_count, 0) AS death_count,
    COALESCE(id.immigration_count, 0) AS immigration_count,
    COALESCE(ed.emigration_count, 0) AS emigration_count,
    COALESCE(bd.birth_count, 0) - COALESCE(dd.death_count, 0) AS natural_growth,
    COALESCE(id.immigration_count, 0) - COALESCE(ed.emigration_count, 0) AS migration_balance,
    (COALESCE(bd.birth_count, 0) - COALESCE(dd.death_count, 0)) + 
    (COALESCE(id.immigration_count, 0) - COALESCE(ed.emigration_count, 0)) AS total_population_growth
FROM
    years y
LEFT JOIN
    birth_data bd ON y.year = bd.year
LEFT JOIN
    death_data dd ON y.year = dd.year
LEFT JOIN
    immigration_data id ON y.year = id.year
LEFT JOIN
    emigration_data ed ON y.year = ed.year
ORDER BY
    y.year DESC
WITH DATA;

COMMENT ON VIEW central.vw_population_dynamics IS 'Báo cáo về động thái dân số (sinh, tử, nhập cư, xuất cư) theo năm';

-- =============================================================================
-- 10. VIEW THỐNG KÊ BẰNG CẤP VÀ NGHỀ NGHIỆP
-- =============================================================================
DROP VIEW IF EXISTS central.vw_education_occupation_statistics CASCADE;
CREATE VIEW central.vw_education_occupation_statistics AS
SELECT
    r.region_name,
    p.province_name,
    c.education_level,
    o.occupation_name,
    COUNT(DISTINCT c.citizen_id) AS citizen_count,
    ROUND(AVG(DATE_PART('year', age(CURRENT_DATE, c.date_of_birth))), 1) AS avg_age,
    COUNT(CASE WHEN c.gender = 'Nam' THEN 1 ELSE NULL END) AS male_count,
    COUNT(CASE WHEN c.gender = 'Nữ' THEN 1 ELSE NULL END) AS female_count,
    COUNT(CASE WHEN c.gender = 'Khác' THEN 1 ELSE NULL END) AS other_gender_count
FROM
    public_security.citizen c
JOIN
    reference.regions r ON c.region_id = r.region_id
JOIN
    reference.provinces p ON c.province_id = p.province_id
LEFT JOIN
    reference.occupations o ON c.occupation_id = o.occupation_id
WHERE
    c.status = TRUE AND
    c.death_status = 'Còn sống' AND
    DATE_PART('year', age(CURRENT_DATE, c.date_of_birth)) >= 15
GROUP BY
    r.region_name,
    p.province_name,
    c.education_level,
    o.occupation_name
WITH DATA;

COMMENT ON VIEW central.vw_education_occupation_statistics IS 'Thống kê trình độ học vấn và nghề nghiệp của dân cư theo khu vực';

COMMIT;

\echo 'Hoàn thành việc tạo các view tổng hợp dữ liệu cho máy chủ trung tâm!'