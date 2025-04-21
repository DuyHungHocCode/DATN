-- File: national_citizen_central_server/functions/sync_logic.sql
-- Description: Chứa các function PL/pgSQL thực hiện logic đồng bộ hóa dữ liệu
--              từ các schema mirror (BCA, BTP) vào schema central trên DB Trung tâm (TT).
-- Version: 3.0 (Structural Outline and Examples)
--
-- Dependencies:
-- - Schemas 'central', 'sync', 'public_security_mirror', 'justice_mirror', 'reference', 'partitioning'.
-- - Các bảng trong các schema trên.
-- - Các ENUMs cần thiết.
-- - Function partitioning.log_history.
-- - Function partitioning.determine_partition_for_citizen (hoặc logic tương tự dựa trên địa chỉ).
-- =============================================================================

\echo '--> Định nghĩa functions đồng bộ dữ liệu cho national_citizen_central_server...'

-- Kết nối tới database Trung tâm (nếu chạy file riêng lẻ)
\connect national_citizen_central_server

BEGIN;

-- Đảm bảo schema sync tồn tại
CREATE SCHEMA IF NOT EXISTS sync;
COMMENT ON SCHEMA sync IS '[QLDCQG-TT] Schema chứa cấu hình, bảng trạng thái và logic cho quá trình đồng bộ hóa dữ liệu';

-- ============================================================================
-- I. HÀM CHÍNH ĐIỀU PHỐI ĐỒNG BỘ
-- ============================================================================

-- Function: sync.run_synchronization
-- Description: Hàm chính được gọi bởi pg_cron hoặc Airflow để thực hiện
--              toàn bộ quy trình đồng bộ dữ liệu từ BCA và BTP vào Central.
-- Arguments: None
-- Returns: VOID
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sync.run_synchronization() RETURNS VOID AS $$
DECLARE
    v_start_time TIMESTAMPTZ := clock_timestamp();
    v_last_sync_bca TIMESTAMPTZ;
    v_last_sync_btp TIMESTAMPTZ;
    v_current_sync_time TIMESTAMPTZ := v_start_time; -- Thời điểm bắt đầu của lần sync này
    v_processed_citizens BIGINT := 0;
    v_processed_households BIGINT := 0;
    v_error_details TEXT;
BEGIN
    RAISE NOTICE '[%] Bắt đầu sync.run_synchronization...', v_start_time;
    PERFORM partitioning.log_history('sync', 'synchronization', 'all', 'SYNC_START', 'Running', 'Bắt đầu quy trình đồng bộ hóa.');

    -- 1. Lấy thời điểm đồng bộ thành công lần cuối (cần có bảng để lưu trạng thái này)
    -- Ví dụ: SELECT last_success_bca, last_success_btp INTO v_last_sync_bca, v_last_sync_btp FROM sync.sync_status LIMIT 1;
    -- Giả định lấy được giá trị, nếu không thì lấy thời điểm rất xa trong quá khứ để sync toàn bộ lần đầu
    v_last_sync_bca := '2000-01-01 00:00:00+07'::TIMESTAMPTZ; -- Placeholder
    v_last_sync_btp := '2000-01-01 00:00:00+07'::TIMESTAMPTZ; -- Placeholder
    RAISE NOTICE '[%] Đồng bộ thay đổi từ BCA sau: %, từ BTP sau: %', clock_timestamp(), v_last_sync_bca, v_last_sync_btp;

    -- 2. Đồng bộ dữ liệu Công dân (Citizen)
    RAISE NOTICE '[%] Bắt đầu đồng bộ Công dân...', clock_timestamp();
    BEGIN
        v_processed_citizens := sync.sync_citizens(v_last_sync_bca, v_last_sync_btp, v_current_sync_time);
        RAISE NOTICE '[%] Hoàn thành đồng bộ Công dân. Đã xử lý (ước tính): % bản ghi.', clock_timestamp(), v_processed_citizens;
        PERFORM partitioning.log_history('sync', 'synchronization', 'integrated_citizen', 'SYNC_STEP', 'Success', format('Đồng bộ công dân hoàn thành. Xử lý: %s', v_processed_citizens));
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_details = PG_EXCEPTION_DETAIL;
        RAISE WARNING '[%] Lỗi khi đồng bộ Công dân: % - Detail: %', clock_timestamp(), SQLERRM, v_error_details;
        PERFORM partitioning.log_history('sync', 'synchronization', 'integrated_citizen', 'SYNC_STEP', 'Failed', format('Lỗi đồng bộ công dân: %s. Detail: %s', SQLERRM, v_error_details));
        -- Cân nhắc có nên dừng toàn bộ quy trình hay tiếp tục các bước khác
        -- Ghi nhận lỗi và kết thúc hàm ở đây để an toàn
         PERFORM partitioning.log_history('sync', 'synchronization', 'all', 'SYNC_END', 'Failed', format('Quy trình dừng do lỗi đồng bộ công dân: %s', SQLERRM));
        RETURN;
    END;

    -- 3. Đồng bộ dữ liệu Hộ khẩu (Household)
    RAISE NOTICE '[%] Bắt đầu đồng bộ Hộ khẩu...', clock_timestamp();
     BEGIN
        v_processed_households := sync.sync_households(v_last_sync_btp, v_current_sync_time);
        RAISE NOTICE '[%] Hoàn thành đồng bộ Hộ khẩu. Đã xử lý (ước tính): % bản ghi.', clock_timestamp(), v_processed_households;
        PERFORM partitioning.log_history('sync', 'synchronization', 'integrated_household', 'SYNC_STEP', 'Success', format('Đồng bộ hộ khẩu hoàn thành. Xử lý: %s', v_processed_households));
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS v_error_details = PG_EXCEPTION_DETAIL;
        RAISE WARNING '[%] Lỗi khi đồng bộ Hộ khẩu: % - Detail: %', clock_timestamp(), SQLERRM, v_error_details;
        PERFORM partitioning.log_history('sync', 'synchronization', 'integrated_household', 'SYNC_STEP', 'Failed', format('Lỗi đồng bộ hộ khẩu: %s. Detail: %s', SQLERRM, v_error_details));
         PERFORM partitioning.log_history('sync', 'synchronization', 'all', 'SYNC_END', 'Failed', format('Quy trình dừng do lỗi đồng bộ hộ khẩu: %s', SQLERRM));
        RETURN;
    END;

    -- 4. Cập nhật thời điểm đồng bộ thành công lần cuối
    -- Ví dụ: UPDATE sync.sync_status SET last_success_bca = v_current_sync_time, last_success_btp = v_current_sync_time, last_run_status = 'Success';
    RAISE NOTICE '[%] Cập nhật thời điểm đồng bộ thành công: %', clock_timestamp(), v_current_sync_time;

    PERFORM partitioning.log_history('sync', 'synchronization', 'all', 'SYNC_END', 'Success', format('Hoàn thành đồng bộ. Công dân: %s, Hộ khẩu: %s.', v_processed_citizens, v_processed_households), (v_processed_citizens + v_processed_households), EXTRACT(EPOCH FROM (clock_timestamp() - v_start_time)) * 1000);
    RAISE NOTICE '[%] Kết thúc sync.run_synchronization.', clock_timestamp();

END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION sync.run_synchronization() IS '[QLDCQG-TT] Hàm chính điều phối toàn bộ quy trình đồng bộ dữ liệu từ BCA và BTP vào DB Trung tâm.';


-- ============================================================================
-- II. HÀM ĐỒNG BỘ CHI TIẾT (VÍ DỤ CẤU TRÚC)
-- ============================================================================

-- Function: sync.sync_citizens
-- Description: Đồng bộ dữ liệu công dân từ mirror vào bảng central.integrated_citizen.
--              Đây là ví dụ cấu trúc, cần triển khai logic chi tiết.
-- Arguments: _last_sync_bca, _last_sync_btp, _current_sync_time
-- Returns: BIGINT (Số lượng công dân được xử lý/upsert)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sync.sync_citizens(
    _last_sync_bca TIMESTAMPTZ,
    _last_sync_btp TIMESTAMPTZ,
    _current_sync_time TIMESTAMPTZ
) RETURNS BIGINT AS $$
DECLARE
    v_upserted_count BIGINT := 0;
    v_row RECORD;
    v_citizen_data JSONB; -- Biến để xây dựng dữ liệu JSON cho upsert
    v_partition_info RECORD; -- Biến để lưu thông tin phân vùng mới
BEGIN
    RAISE NOTICE '[sync.sync_citizens] Bắt đầu xử lý công dân...';

    -- Bước 1: Xác định các citizen_id cần cập nhật
    -- Bao gồm những citizen mới hoặc có thay đổi trong BCA hoặc BTP kể từ lần sync cuối
    -- Giả định các bảng mirror có cột 'updated_at' (cần kiểm tra thực tế FDW có hỗ trợ không)
    WITH changed_citizens AS (
        SELECT citizen_id FROM public_security_mirror.citizen WHERE updated_at > _last_sync_bca
        UNION
        SELECT citizen_id FROM justice_mirror.birth_certificate WHERE updated_at > _last_sync_btp
        UNION
        SELECT citizen_id FROM justice_mirror.death_certificate WHERE updated_at > _last_sync_btp
        UNION
        SELECT husband_id FROM justice_mirror.marriage WHERE updated_at > _last_sync_btp
        UNION
        SELECT wife_id FROM justice_mirror.marriage WHERE updated_at > _last_sync_btp
        -- Thêm các nguồn thay đổi khác (vd: cư trú, CCCD, ly hôn...)
    )
    -- Bước 2: Lặp qua từng citizen_id cần xử lý
    FOR v_row IN SELECT DISTINCT citizen_id FROM changed_citizens LOOP
        -- Bước 3: Thu thập dữ liệu mới nhất từ các bảng mirror cho citizen_id này
        -- Ví dụ lấy thông tin cơ bản từ BCA
        SELECT to_jsonb(c.*) INTO v_citizen_data
        FROM public_security_mirror.citizen c
        WHERE c.citizen_id = v_row.citizen_id;

        IF v_citizen_data IS NULL THEN
            RAISE WARNING '[sync.sync_citizens] Không tìm thấy thông tin citizen % trong mirror BCA.', v_row.citizen_id;
            CONTINUE; -- Bỏ qua nếu không có thông tin cơ bản
        END IF;

        -- Bước 4: [TODO: Implement Logic] Lấy thêm dữ liệu từ các bảng khác
        --         (CCCD, cư trú từ BCA mirror; khai sinh, khai tử, hôn nhân từ BTP mirror)
        --         và hợp nhất vào biến v_citizen_data (dạng JSONB).
        --         Ví dụ: Lấy thông tin CCCD mới nhất
        --         DECLARE v_id_card JSONB;
        --         SELECT to_jsonb(ic.*) INTO v_id_card FROM public_security_mirror.identification_card ic
        --         WHERE ic.citizen_id = v_row.citizen_id AND ic.card_status = 'Đang sử dụng' LIMIT 1;
        --         IF v_id_card IS NOT NULL THEN
        --             v_citizen_data := v_citizen_data || jsonb_build_object(
        --                 'current_id_card_number', v_id_card->'card_number',
        --                 'current_id_card_type', v_id_card->'card_type',
        --                 ...
        --             );
        --         END IF;
        --         Tương tự cho các thông tin khác...

        -- Bước 5: [TODO: Implement Logic] Xác định thông tin phân vùng mới
        --         Dựa trên địa chỉ thường trú/tạm trú mới nhất. Có thể gọi hàm tương tự
        --         partitioning.determine_partition_for_citizen nhưng truy vấn bảng mirror.
        --         Giả sử kết quả lưu vào v_partition_info (geographical_region, province_id, district_id)
        --         Ví dụ đơn giản:
        SELECT 'Bắc'::TEXT, 1::INT, 1::INT INTO v_partition_info; -- Placeholder

        IF v_partition_info.geographical_region IS NULL OR v_partition_info.province_id IS NULL OR v_partition_info.district_id IS NULL THEN
             RAISE WARNING '[sync.sync_citizens] Không thể xác định phân vùng mới cho citizen %. Bỏ qua.', v_row.citizen_id;
             CONTINUE;
        END IF;

        -- Bước 6: [TODO: Implement Logic] Xử lý xung đột (nếu có) và hoàn thiện v_citizen_data

        -- Bước 7: Upsert vào bảng central.integrated_citizen
        -- Sử dụng INSERT ... ON CONFLICT DO UPDATE
        INSERT INTO central.integrated_citizen (
            citizen_id, full_name, date_of_birth, gender, -- Các cột cơ bản
            geographical_region, province_id, district_id, -- Cột phân vùng
            last_synced_from_bca, last_integrated_at -- Metadata
            -- ... Thêm các cột khác từ v_citizen_data ...
        ) VALUES (
            v_row.citizen_id,
            v_citizen_data->>'full_name',
            (v_citizen_data->>'date_of_birth')::DATE,
            (v_citizen_data->>'gender')::gender_type,
            v_partition_info.geographical_region,
            v_partition_info.province_id,
            v_partition_info.district_id,
            CASE WHEN (v_citizen_data->>'updated_at')::TIMESTAMPTZ > _last_sync_bca THEN _current_sync_time ELSE NULL END, -- Chỉ cập nhật nếu nguồn BCA thay đổi
            _current_sync_time
            -- ... Thêm các giá trị khác ...
        )
        ON CONFLICT (citizen_id) DO UPDATE SET -- Giả định citizen_id là unique constraint logic
            full_name = EXCLUDED.full_name,
            date_of_birth = EXCLUDED.date_of_birth,
            gender = EXCLUDED.gender,
            geographical_region = EXCLUDED.geographical_region, -- Cập nhật cả cột phân vùng
            province_id = EXCLUDED.province_id,
            district_id = EXCLUDED.district_id,
            last_synced_from_bca = GREATEST(central.integrated_citizen.last_synced_from_bca, EXCLUDED.last_synced_from_bca), -- Cập nhật nếu mới hơn
            -- last_synced_from_btp = ... (Cập nhật tương tự nếu có thay đổi từ BTP)
            last_integrated_at = EXCLUDED.last_integrated_at
            -- ... Cập nhật các cột khác ...
        WHERE
            -- Chỉ UPDATE nếu dữ liệu mới thực sự khác dữ liệu cũ (tối ưu hóa)
            ROW(central.integrated_citizen.full_name, central.integrated_citizen.date_of_birth, ...)
            IS DISTINCT FROM
            ROW(EXCLUDED.full_name, EXCLUDED.date_of_birth, ...);

        GET DIAGNOSTICS v_upserted_count = ROW_COUNT; -- Đếm số dòng được INSERT hoặc UPDATE

    END LOOP;

    RETURN v_upserted_count; -- Trả về số lượng đã xử lý
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION sync.sync_citizens(TIMESTAMPTZ, TIMESTAMPTZ, TIMESTAMPTZ) IS '[QLDCQG-TT] Đồng bộ dữ liệu công dân từ mirror vào bảng central.integrated_citizen (Cần triển khai logic chi tiết).';


-- Function: sync.sync_households
-- Description: Đồng bộ dữ liệu hộ khẩu từ mirror vào bảng central.integrated_household.
--              Đây là ví dụ cấu trúc, cần triển khai logic chi tiết.
-- Arguments: _last_sync_btp, _current_sync_time
-- Returns: BIGINT (Số lượng hộ khẩu được xử lý/upsert)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION sync.sync_households(
    _last_sync_btp TIMESTAMPTZ,
    _current_sync_time TIMESTAMPTZ
) RETURNS BIGINT AS $$
DECLARE
    v_upserted_count BIGINT := 0;
    v_row RECORD;
    v_household_data JSONB;
    v_partition_info RECORD;
BEGIN
    RAISE NOTICE '[sync.sync_households] Bắt đầu xử lý hộ khẩu...';

    -- Bước 1: Xác định các household_id cần cập nhật từ justice_mirror.household
    -- Giả định có cột updated_at
    FOR v_row IN SELECT household_id FROM justice_mirror.household WHERE updated_at > _last_sync_btp LOOP

        -- Bước 2: Thu thập dữ liệu hộ khẩu từ mirror
        SELECT to_jsonb(h.*) INTO v_household_data
        FROM justice_mirror.household h
        WHERE h.household_id = v_row.household_id;

        IF v_household_data IS NULL THEN CONTINUE; END IF;

        -- Bước 3: [TODO: Implement Logic] Lấy thông tin địa chỉ chi tiết và xác định phân vùng
        --         Dựa vào v_household_data->>'address_id' (logic link đến public_security.address)
        --         Cần truy vấn public_security_mirror.address để lấy province_id, district_id, region_id...
        --         Lưu kết quả vào v_partition_info (geographical_region, province_id, district_id, region_id)
        --         Và lấy address_detail nếu cần.
        --         Ví dụ đơn giản:
        SELECT 'Trung'::TEXT, 48::INT, 490::INT, 2::SMALLINT INTO v_partition_info; -- Placeholder

        IF v_partition_info.geographical_region IS NULL OR v_partition_info.province_id IS NULL OR v_partition_info.district_id IS NULL THEN
             RAISE WARNING '[sync.sync_households] Không thể xác định phân vùng mới cho household %. Bỏ qua.', v_row.household_id;
             CONTINUE;
        END IF;

        -- Bước 4: Upsert vào bảng central.integrated_household
        INSERT INTO central.integrated_household (
            source_system, source_household_id, household_book_no, head_of_household_citizen_id,
            address_detail, ward_id, -- Cần lấy ward_id từ address mirror
            registration_date, issuing_authority_id, household_type, status,
            region_id, province_id, district_id, geographical_region,
            source_created_at, source_updated_at, integrated_at
        ) VALUES (
            'BTP', -- Nguồn
            (v_household_data->>'household_id')::VARCHAR, -- ID nguồn
            v_household_data->>'household_book_no',
            v_household_data->>'head_of_household_id',
            -- [TODO] Lấy address_detail từ address mirror
            NULL, -- Placeholder cho address_detail
            -- [TODO] Lấy ward_id từ address mirror
            NULL, -- Placeholder cho ward_id
            (v_household_data->>'registration_date')::DATE,
            (v_household_data->>'issuing_authority_id')::SMALLINT,
            (v_household_data->>'household_type')::household_type,
            (v_household_data->>'status')::household_status,
            v_partition_info.region_id,
            v_partition_info.province_id,
            v_partition_info.district_id,
            v_partition_info.geographical_region,
            (v_household_data->>'created_at')::TIMESTAMPTZ,
            (v_household_data->>'updated_at')::TIMESTAMPTZ,
            _current_sync_time
        )
        ON CONFLICT (source_system, source_household_id) DO UPDATE SET
            household_book_no = EXCLUDED.household_book_no,
            head_of_household_citizen_id = EXCLUDED.head_of_household_citizen_id,
            address_detail = EXCLUDED.address_detail, -- Cập nhật địa chỉ
            ward_id = EXCLUDED.ward_id,             -- Cập nhật ward_id
            registration_date = EXCLUDED.registration_date,
            issuing_authority_id = EXCLUDED.issuing_authority_id,
            household_type = EXCLUDED.household_type,
            status = EXCLUDED.status,
            region_id = EXCLUDED.region_id,             -- Cập nhật phân vùng
            province_id = EXCLUDED.province_id,
            district_id = EXCLUDED.district_id,
            geographical_region = EXCLUDED.geographical_region,
            source_updated_at = EXCLUDED.source_updated_at,
            integrated_at = EXCLUDED.integrated_at
        WHERE
            -- Chỉ UPDATE nếu có thay đổi thực sự
            ROW(central.integrated_household.household_book_no, ...)
            IS DISTINCT FROM
            ROW(EXCLUDED.household_book_no, ...);

         GET DIAGNOSTICS v_upserted_count = ROW_COUNT;

    END LOOP;

     RETURN v_upserted_count;
END;
$$ LANGUAGE plpgsql;
COMMENT ON FUNCTION sync.sync_households(TIMESTAMPTZ, TIMESTAMPTZ) IS '[QLDCQG-TT] Đồng bộ dữ liệu hộ khẩu từ mirror vào bảng central.integrated_household (Cần triển khai logic chi tiết).';


COMMIT;

\echo '-> Hoàn thành định nghĩa functions đồng bộ dữ liệu (cấu trúc ví dụ) cho national_citizen_central_server.'

-- TODO (Các bước tiếp theo):
-- 1. Implement Detailed Logic: Triển khai chi tiết logic trong các hàm sync.*:
--    - Logic lấy dữ liệu đầy đủ từ các bảng mirror.
--    - Logic xác định bản ghi "hiện tại" (current).
--    - Logic xác định phân vùng dựa trên địa chỉ mới nhất.
--    - Logic xử lý xung đột dữ liệu giữa BCA và BTP.
--    - Logic kiểm tra sự khác biệt trước khi UPDATE để tối ưu hóa.
--    - Logic xử lý lỗi và ghi log chi tiết.
-- 2. Incremental Sync State: Tạo bảng (ví dụ: sync.sync_status) để lưu trữ thời điểm đồng bộ thành công cuối cùng cho từng nguồn (BCA, BTP) và sử dụng nó trong hàm run_synchronization.
-- 3. Testing: Kiểm thử kỹ lưỡng logic đồng bộ với nhiều kịch bản dữ liệu khác nhau.
-- 4. Performance Tuning: Tối ưu hóa các câu lệnh SQL, sử dụng index hiệu quả, cân nhắc xử lý song song nếu cần.
-- 5. Permissions: Cấp quyền EXECUTE trên các hàm sync.* này cho role sync_user và role quản trị.