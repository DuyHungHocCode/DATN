\connect ministry_of_public_security
TRUNCATE TABLE reference.religions CASCADE;

INSERT INTO reference.religions (religion_id, religion_code, religion_name, description, followers) VALUES
(1, 'BUDD', 'Phật giáo', 'Tôn giáo lớn nhất tại Việt Nam, du nhập từ thế kỷ II. Chủ yếu theo Phật giáo Đại thừa, với hệ thống chùa chiền rộng khắp và ảnh hưởng sâu sắc đến văn hóa dân tộc.', 14800000),

(2, 'CATH', 'Công giáo', 'Du nhập từ thế kỷ XVI, phát triển mạnh dưới thời Pháp thuộc. Có hệ thống nhà thờ và giáo xứ trên toàn quốc, đặc biệt tập trung ở miền Nam và miền Bắc.', 7200000),

(3, 'CAOD', 'Cao Đài', 'Tôn giáo bản địa ra đời năm 1926 tại Tây Ninh. Kết hợp giữa các yếu tố của Phật giáo, Đạo giáo, Nho giáo và Công giáo. Thánh địa chính tại Tây Ninh.', 4400000),

(4, 'HOAH', 'Phật giáo Hòa Hảo', 'Được sáng lập năm 1939 bởi Huỳnh Phú Sổ tại An Giang. Chú trọng tu tại gia, thực hành bốn ân và tứ đại trọng ân, phát triển mạnh ở đồng bằng sông Cửu Long.', 2000000),

(5, 'PROT', 'Tin Lành', 'Du nhập vào Việt Nam từ đầu thế kỷ XX. Có nhiều hệ phái khác nhau, phát triển mạnh trong cộng đồng các dân tộc thiểu số ở Tây Nguyên.', 1000000),

(6, 'ISLM', 'Hồi giáo', 'Chủ yếu theo hệ phái Sunni, tập trung trong cộng đồng người Chăm ở Nam Trung Bộ. Du nhập từ thế kỷ X-XI qua con đường thương mại.', 75000),

(7, 'HIND', 'Ấn Độ giáo', 'Còn tồn tại trong cộng đồng người Chăm ở Ninh Thuận, Bình Thuận. Là di sản từ vương quốc Champa cổ.', 50000),

(8, 'DAOM', 'Đạo Mẫu', 'Tín ngưỡng dân gian thờ Mẫu truyền thống của người Việt, bao gồm hệ thống Tứ phủ và các nghi lễ hầu đồng. Được UNESCO công nhận là di sản văn hóa phi vật thể.', 200000),

(9, 'NONE', 'Không tôn giáo', 'Nhóm người không theo tôn giáo cụ thể nhưng vẫn duy trì các hoạt động tín ngưỡng dân gian như thờ cúng tổ tiên.', 70000000),

(10, 'OTHR', 'Tôn giáo khác', 'Bao gồm các tín ngưỡng bản địa của các dân tộc thiểu số và các tôn giáo nhỏ khác.', 275000);

-- -- Nạp dữ liệu cho Bộ Tư pháp
\connect ministry_of_justice
TRUNCATE TABLE reference.religions CASCADE;

INSERT INTO reference.religions (religion_id, religion_code, religion_name, description, followers) VALUES
(1, 'BUDD', 'Phật giáo', 'Tôn giáo lớn nhất tại Việt Nam, du nhập từ thế kỷ II. Chủ yếu theo Phật giáo Đại thừa, với hệ thống chùa chiền rộng khắp và ảnh hưởng sâu sắc đến văn hóa dân tộc.', 14800000),

(2, 'CATH', 'Công giáo', 'Du nhập từ thế kỷ XVI, phát triển mạnh dưới thời Pháp thuộc. Có hệ thống nhà thờ và giáo xứ trên toàn quốc, đặc biệt tập trung ở miền Nam và miền Bắc.', 7200000),

(3, 'CAOD', 'Cao Đài', 'Tôn giáo bản địa ra đời năm 1926 tại Tây Ninh. Kết hợp giữa các yếu tố của Phật giáo, Đạo giáo, Nho giáo và Công giáo. Thánh địa chính tại Tây Ninh.', 4400000),

(4, 'HOAH', 'Phật giáo Hòa Hảo', 'Được sáng lập năm 1939 bởi Huỳnh Phú Sổ tại An Giang. Chú trọng tu tại gia, thực hành bốn ân và tứ đại trọng ân, phát triển mạnh ở đồng bằng sông Cửu Long.', 2000000),

(5, 'PROT', 'Tin Lành', 'Du nhập vào Việt Nam từ đầu thế kỷ XX. Có nhiều hệ phái khác nhau, phát triển mạnh trong cộng đồng các dân tộc thiểu số ở Tây Nguyên.', 1000000),

(6, 'ISLM', 'Hồi giáo', 'Chủ yếu theo hệ phái Sunni, tập trung trong cộng đồng người Chăm ở Nam Trung Bộ. Du nhập từ thế kỷ X-XI qua con đường thương mại.', 75000),

(7, 'HIND', 'Ấn Độ giáo', 'Còn tồn tại trong cộng đồng người Chăm ở Ninh Thuận, Bình Thuận. Là di sản từ vương quốc Champa cổ.', 50000),

(8, 'DAOM', 'Đạo Mẫu', 'Tín ngưỡng dân gian thờ Mẫu truyền thống của người Việt, bao gồm hệ thống Tứ phủ và các nghi lễ hầu đồng. Được UNESCO công nhận là di sản văn hóa phi vật thể.', 200000),

(9, 'NONE', 'Không tôn giáo', 'Nhóm người không theo tôn giáo cụ thể nhưng vẫn duy trì các hoạt động tín ngưỡng dân gian như thờ cúng tổ tiên.', 70000000),

(10, 'OTHR', 'Tôn giáo khác', 'Bao gồm các tín ngưỡng bản địa của các dân tộc thiểu số và các tôn giáo nhỏ khác.', 275000);

-- -- Nạp dữ liệu cho máy chủ trung tâm
\connect national_citizen_central_server
TRUNCATE TABLE reference.religions CASCADE;

INSERT INTO reference.religions (religion_id, religion_code, religion_name, description, followers) VALUES
(1, 'BUDD', 'Phật giáo', 'Tôn giáo lớn nhất tại Việt Nam, du nhập từ thế kỷ II. Chủ yếu theo Phật giáo Đại thừa, với hệ thống chùa chiền rộng khắp và ảnh hưởng sâu sắc đến văn hóa dân tộc.', 14800000),

(2, 'CATH', 'Công giáo', 'Du nhập từ thế kỷ XVI, phát triển mạnh dưới thời Pháp thuộc. Có hệ thống nhà thờ và giáo xứ trên toàn quốc, đặc biệt tập trung ở miền Nam và miền Bắc.', 7200000),

(3, 'CAOD', 'Cao Đài', 'Tôn giáo bản địa ra đời năm 1926 tại Tây Ninh. Kết hợp giữa các yếu tố của Phật giáo, Đạo giáo, Nho giáo và Công giáo. Thánh địa chính tại Tây Ninh.', 4400000),

(4, 'HOAH', 'Phật giáo Hòa Hảo', 'Được sáng lập năm 1939 bởi Huỳnh Phú Sổ tại An Giang. Chú trọng tu tại gia, thực hành bốn ân và tứ đại trọng ân, phát triển mạnh ở đồng bằng sông Cửu Long.', 2000000),

(5, 'PROT', 'Tin Lành', 'Du nhập vào Việt Nam từ đầu thế kỷ XX. Có nhiều hệ phái khác nhau, phát triển mạnh trong cộng đồng các dân tộc thiểu số ở Tây Nguyên.', 1000000),

(6, 'ISLM', 'Hồi giáo', 'Chủ yếu theo hệ phái Sunni, tập trung trong cộng đồng người Chăm ở Nam Trung Bộ. Du nhập từ thế kỷ X-XI qua con đường thương mại.', 75000),

(7, 'HIND', 'Ấn Độ giáo', 'Còn tồn tại trong cộng đồng người Chăm ở Ninh Thuận, Bình Thuận. Là di sản từ vương quốc Champa cổ.', 50000),

(8, 'DAOM', 'Đạo Mẫu', 'Tín ngưỡng dân gian thờ Mẫu truyền thống của người Việt, bao gồm hệ thống Tứ phủ và các nghi lễ hầu đồng. Được UNESCO công nhận là di sản văn hóa phi vật thể.', 200000),

(9, 'NONE', 'Không tôn giáo', 'Nhóm người không theo tôn giáo cụ thể nhưng vẫn duy trì các hoạt động tín ngưỡng dân gian như thờ cúng tổ tiên.', 70000000),

(10, 'OTHR', 'Tôn giáo khác', 'Bao gồm các tín ngưỡng bản địa của các dân tộc thiểu số và các tôn giáo nhỏ khác.', 275000);
