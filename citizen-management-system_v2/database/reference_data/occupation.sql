\echo 'Bắt đầu nạp dữ liệu cho bảng occupations...'

-- Xóa dữ liệu cũ (nếu có)
TRUNCATE TABLE reference.occupations CASCADE;

-- Nạp dữ liệu cho Bộ Công an
\connect ministry_of_public_security

INSERT INTO reference.occupations (occupation_id, occupation_code, occupation_name, description) VALUES
(1, 'MGMT', 'Quản lý và lãnh đạo', 'Các vị trí quản lý cấp cao và lãnh đạo trong tổ chức'),
(2, 'PROF', 'Chuyên gia và chuyên môn', 'Các nghề đòi hỏi trình độ chuyên môn cao'),
(3, 'TECH', 'Kỹ thuật và công nghệ', 'Các nghề liên quan đến kỹ thuật và công nghệ'),
(4, 'ADMN', 'Hành chính và văn phòng', 'Các công việc hành chính, văn phòng'),
(5, 'SERV', 'Dịch vụ và bán hàng', 'Các nghề trong lĩnh vực dịch vụ và bán hàng'),
(6, 'AGRI', 'Nông lâm ngư nghiệp', 'Các nghề trong lĩnh vực nông, lâm, ngư nghiệp'),
(7, 'PROD', 'Sản xuất và chế biến', 'Các nghề trong lĩnh vực sản xuất và chế biến'),
(8, 'CONS', 'Xây dựng và lắp đặt', 'Các nghề trong lĩnh vực xây dựng'),
(9, 'TRAN', 'Vận tải và logistics', 'Các nghề trong lĩnh vực vận tải và logistics'),
(10, 'OTHR', 'Khác', 'Các nghề khác không thuộc các nhóm trên');

-- Nạp dữ liệu cho Bộ Tư pháp
\connect ministry_of_justice

INSERT INTO reference.occupations (occupation_id, occupation_code, occupation_name, description) VALUES
(1, 'MGMT', 'Quản lý và lãnh đạo', 'Các vị trí quản lý cấp cao và lãnh đạo trong tổ chức'),
(2, 'PROF', 'Chuyên gia và chuyên môn', 'Các nghề đòi hỏi trình độ chuyên môn cao'),
(3, 'TECH', 'Kỹ thuật và công nghệ', 'Các nghề liên quan đến kỹ thuật và công nghệ'),
(4, 'ADMN', 'Hành chính và văn phòng', 'Các công việc hành chính, văn phòng'),
(5, 'SERV', 'Dịch vụ và bán hàng', 'Các nghề trong lĩnh vực dịch vụ và bán hàng'),
(6, 'AGRI', 'Nông lâm ngư nghiệp', 'Các nghề trong lĩnh vực nông, lâm, ngư nghiệp'),
(7, 'PROD', 'Sản xuất và chế biến', 'Các nghề trong lĩnh vực sản xuất và chế biến'),
(8, 'CONS', 'Xây dựng và lắp đặt', 'Các nghề trong lĩnh vực xây dựng'),
(9, 'TRAN', 'Vận tải và logistics', 'Các nghề trong lĩnh vực vận tải và logistics'),
(10, 'OTHR', 'Khác', 'Các nghề khác không thuộc các nhóm trên');

-- Nạp dữ liệu cho máy chủ trung tâm
\connect national_citizen_central_server

INSERT INTO reference.occupations (occupation_id, occupation_code, occupation_name, description) VALUES
(1, 'MGMT', 'Quản lý và lãnh đạo', 'Các vị trí quản lý cấp cao và lãnh đạo trong tổ chức'),
(2, 'PROF', 'Chuyên gia và chuyên môn', 'Các nghề đòi hỏi trình độ chuyên môn cao'),
(3, 'TECH', 'Kỹ thuật và công nghệ', 'Các nghề liên quan đến kỹ thuật và công nghệ'),
(4, 'ADMN', 'Hành chính và văn phòng', 'Các công việc hành chính, văn phòng'),
(5, 'SERV', 'Dịch vụ và bán hàng', 'Các nghề trong lĩnh vực dịch vụ và bán hàng'),
(6, 'AGRI', 'Nông lâm ngư nghiệp', 'Các nghề trong lĩnh vực nông, lâm, ngư nghiệp'),
(7, 'PROD', 'Sản xuất và chế biến', 'Các nghề trong lĩnh vực sản xuất và chế biến'),
(8, 'CONS', 'Xây dựng và lắp đặt', 'Các nghề trong lĩnh vực xây dựng'),
(9, 'TRAN', 'Vận tải và logistics', 'Các nghề trong lĩnh vực vận tải và logistics'),
(10, 'OTHR', 'Khác', 'Các nghề khác không thuộc các nhóm trên');