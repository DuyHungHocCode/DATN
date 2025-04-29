-- =============================================================================
-- File: 01_common/04_reference_tables_constraints.sql
-- Description: Thêm các ràng buộc FOREIGN KEY và CHECK phức tạp cho các bảng
--              tham chiếu dùng chung trong schema 'reference'. Script này cần
--              chạy trên CẢ 3 database (BCA, BTP, TT).
-- Version: 3.1 (Adds constraints deferred from structure creation)
--
-- Yêu cầu:
-- - Chạy sau script 01_common/03_reference_tables_structure.sql.
-- - Các bảng tham chiếu phải tồn tại trong schema 'reference'.
-- - Cần quyền thay đổi bảng (ALTER TABLE) trong schema 'reference'.
-- =============================================================================

\echo '*** BẮT ĐẦU THÊM RÀNG BUỘC CHO BẢNG THAM CHIẾU (REFERENCE TABLES) ***'

-- === 1. THỰC THI TRÊN DATABASE BỘ CÔNG AN (ministry_of_public_security) ===

\echo '[Bước 1] Thêm ràng buộc cho bảng tham chiếu trên database: ministry_of_public_security...'
\connect ministry_of_public_security

-- Ràng buộc cho bảng: provinces
ALTER TABLE reference.provinces
    ADD CONSTRAINT fk_province_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id);
-- (Thêm CHECK constraint nếu cần, ví dụ kiểm tra tính hợp lệ của administrative_unit_id/administrative_region_id)
-- ALTER TABLE reference.provinces ADD CONSTRAINT ck_province_admin_unit CHECK (administrative_unit_id IN (1, 2));

-- Ràng buộc cho bảng: districts
ALTER TABLE reference.districts
    ADD CONSTRAINT fk_district_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);
-- ALTER TABLE reference.districts ADD CONSTRAINT ck_district_admin_unit CHECK (administrative_unit_id IN (1, 2, 3, 4));

-- Ràng buộc cho bảng: wards
ALTER TABLE reference.wards
    ADD CONSTRAINT fk_ward_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id);
-- ALTER TABLE reference.wards ADD CONSTRAINT ck_ward_admin_unit CHECK (administrative_unit_id IN (5, 6, 7));

-- Ràng buộc cho bảng: authorities
ALTER TABLE reference.authorities
    ADD CONSTRAINT fk_authority_ward FOREIGN KEY (ward_id) REFERENCES reference.wards(ward_id),
    ADD CONSTRAINT fk_authority_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),
    ADD CONSTRAINT fk_authority_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    ADD CONSTRAINT fk_authority_parent FOREIGN KEY (parent_authority_id) REFERENCES reference.authorities(authority_id);

-- Ràng buộc cho bảng: relationship_types (Tự tham chiếu)
ALTER TABLE reference.relationship_types
    ADD CONSTRAINT fk_inverse_relationship FOREIGN KEY (inverse_relationship_type_id)
    REFERENCES reference.relationship_types(relationship_type_id) DEFERRABLE INITIALLY DEFERRED;
    -- DEFERRABLE INITIALLY DEFERRED cho phép chèn dữ liệu có tham chiếu vòng tròn

-- Ràng buộc cho bảng: prison_facilities
ALTER TABLE reference.prison_facilities
    ADD CONSTRAINT fk_prison_ward FOREIGN KEY (ward_id) REFERENCES reference.wards(ward_id),
    ADD CONSTRAINT fk_prison_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id),
    ADD CONSTRAINT fk_prison_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id),
    ADD CONSTRAINT fk_prison_managing_authority FOREIGN KEY (managing_authority_id) REFERENCES reference.authorities(authority_id);

\echo '   -> Hoàn thành thêm ràng buộc cho ministry_of_public_security.'


-- === 2. THỰC THI TRÊN DATABASE BỘ TƯ PHÁP (ministry_of_justice) ===

\echo '[Bước 2] Thêm ràng buộc cho bảng tham chiếu trên database: ministry_of_justice...'
\connect ministry_of_justice

-- (Lặp lại các lệnh ALTER TABLE ... ADD CONSTRAINT ... như trên)
ALTER TABLE reference.provinces ADD CONSTRAINT fk_province_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id);
ALTER TABLE reference.districts ADD CONSTRAINT fk_district_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);
ALTER TABLE reference.wards ADD CONSTRAINT fk_ward_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id);
ALTER TABLE reference.authorities ADD CONSTRAINT fk_authority_ward FOREIGN KEY (ward_id) REFERENCES reference.wards(ward_id);
ALTER TABLE reference.authorities ADD CONSTRAINT fk_authority_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id);
ALTER TABLE reference.authorities ADD CONSTRAINT fk_authority_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);
ALTER TABLE reference.authorities ADD CONSTRAINT fk_authority_parent FOREIGN KEY (parent_authority_id) REFERENCES reference.authorities(authority_id);
ALTER TABLE reference.relationship_types ADD CONSTRAINT fk_inverse_relationship FOREIGN KEY (inverse_relationship_type_id) REFERENCES reference.relationship_types(relationship_type_id) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE reference.prison_facilities ADD CONSTRAINT fk_prison_ward FOREIGN KEY (ward_id) REFERENCES reference.wards(ward_id);
ALTER TABLE reference.prison_facilities ADD CONSTRAINT fk_prison_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id);
ALTER TABLE reference.prison_facilities ADD CONSTRAINT fk_prison_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);
ALTER TABLE reference.prison_facilities ADD CONSTRAINT fk_prison_managing_authority FOREIGN KEY (managing_authority_id) REFERENCES reference.authorities(authority_id);

\echo '   -> Hoàn thành thêm ràng buộc cho ministry_of_justice.'


-- === 3. THỰC THI TRÊN DATABASE MÁY CHỦ TRUNG TÂM (national_citizen_central_server) ===

\echo '[Bước 3] Thêm ràng buộc cho bảng tham chiếu trên database: national_citizen_central_server...'
\connect national_citizen_central_server

-- (Lặp lại các lệnh ALTER TABLE ... ADD CONSTRAINT ... như trên)
ALTER TABLE reference.provinces ADD CONSTRAINT fk_province_region FOREIGN KEY (region_id) REFERENCES reference.regions(region_id);
ALTER TABLE reference.districts ADD CONSTRAINT fk_district_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);
ALTER TABLE reference.wards ADD CONSTRAINT fk_ward_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id);
ALTER TABLE reference.authorities ADD CONSTRAINT fk_authority_ward FOREIGN KEY (ward_id) REFERENCES reference.wards(ward_id);
ALTER TABLE reference.authorities ADD CONSTRAINT fk_authority_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id);
ALTER TABLE reference.authorities ADD CONSTRAINT fk_authority_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);
ALTER TABLE reference.authorities ADD CONSTRAINT fk_authority_parent FOREIGN KEY (parent_authority_id) REFERENCES reference.authorities(authority_id);
ALTER TABLE reference.relationship_types ADD CONSTRAINT fk_inverse_relationship FOREIGN KEY (inverse_relationship_type_id) REFERENCES reference.relationship_types(relationship_type_id) DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE reference.prison_facilities ADD CONSTRAINT fk_prison_ward FOREIGN KEY (ward_id) REFERENCES reference.wards(ward_id);
ALTER TABLE reference.prison_facilities ADD CONSTRAINT fk_prison_district FOREIGN KEY (district_id) REFERENCES reference.districts(district_id);
ALTER TABLE reference.prison_facilities ADD CONSTRAINT fk_prison_province FOREIGN KEY (province_id) REFERENCES reference.provinces(province_id);
ALTER TABLE reference.prison_facilities ADD CONSTRAINT fk_prison_managing_authority FOREIGN KEY (managing_authority_id) REFERENCES reference.authorities(authority_id);

\echo '   -> Hoàn thành thêm ràng buộc cho national_citizen_central_server.'

-- === KẾT THÚC ===

\echo '*** HOÀN THÀNH THÊM RÀNG BUỘC CHO BẢNG THAM CHIẾU ***'
\echo '-> Đã thêm các ràng buộc FOREIGN KEY và CHECK cần thiết cho schema "reference" trên cả 3 database.'
\echo '-> Bước tiếp theo: Chạy các script tạo cấu trúc bảng nghiệp vụ cho từng database ([db_name]/01_tables_structure.sql).'

