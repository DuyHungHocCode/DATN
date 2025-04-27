'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';

// --- Định nghĩa kiểu dữ liệu cho Citizen (kết hợp BCA & BTP) ---
interface CitizenData {
  // BCA: citizen
  citizen_id: string;
  full_name: string;
  date_of_birth: string; // Format: DD/MM/YYYY
  place_of_birth_code?: string;
  place_of_birth_detail?: string; // Dùng tạm text
  gender: string; // 'Nam' | 'Nữ' | 'Khác'
  blood_type?: string;
  ethnicity_id?: number;
  religion_id?: number;
  nationality_id?: number;
  father_citizen_id?: string;
  mother_citizen_id?: string;
  education_level?: string;
  occupation_id?: number;
  occupation_detail?: string;
  tax_code?: string;
  social_insurance_no?: string;
  health_insurance_no?: string;
  current_email?: string;
  current_phone_number?: string;

  // BCA: identification_card (Lấy bản ghi mới nhất)
  card_number?: string;
  card_type?: string;
  issue_date?: string; // Format: DD/MM/YYYY
  expiry_date?: string; // Format: DD/MM/YYYY
  issuing_authority_id?: number;
  card_status?: string;
  previous_card_number?: string; // Thêm mới

  // BCA: citizen_status (Lấy bản ghi mới nhất)
  citizen_status_type?: string; // 'Còn sống', 'Đã mất', 'Mất tích'
  status_date?: string; // Ngày cập nhật trạng thái Format: DD/MM/YYYY

  // BCA: permanent_residence + address (Lấy bản ghi mới nhất)
  permanent_residence?: {
    address_detail: string;
    ward_id?: number;
    district_id?: number;
    province_id?: number;
    registration_date?: string; // Format: DD/MM/YYYY
    issuing_authority_id?: number; // Nơi ĐK
    // Derived/Joined Fields
    ward_name?: string;
    district_name?: string;
    province_name?: string;
    issuing_authority_name?: string; // Tên nơi ĐK
  };

  // BCA: temporary_residence + address (Lấy bản ghi mới nhất, nếu có)
  temporary_residence?: {
    address_detail: string;
    ward_id?: number;
    district_id?: number;
    province_id?: number;
    registration_date?: string; // Format: DD/MM/YYYY
    expiry_date?: string; // Ngày hết hạn tạm trú Format: DD/MM/YYYY
    purpose?: string; // Mục đích tạm trú
    issuing_authority_id?: number; // Nơi ĐK
    // Derived/Joined Fields
    ward_name?: string;
    district_name?: string;
    province_name?: string;
    issuing_authority_name?: string; // Tên nơi ĐK
  };

  // BTP (Giả lập từ API): birth_certificate
  father_full_name?: string;
  mother_full_name?: string;
  place_of_birth_full?: string; // Có thể lấy từ BTP nếu chi tiết hơn BCA

  // BTP (Giả lập từ API): marriage / divorce
  marital_status?: string; // 'Độc thân', 'Đã kết hôn', 'Đã ly hôn', 'Góa'
  spouse_citizen_id?: string;
  spouse_full_name?: string;
  marriage_date?: string; // Format: DD/MM/YYYY
  divorce_date?: string; // Format: DD/MM/YYYY

  // Reference Data (Giả lập đã join)
  ethnicity_name?: string;
  religion_name?: string;
  nationality_name?: string;
  occupation_name?: string;
  card_issuing_authority_name?: string; // Tên cơ quan cấp CCCD
}
// --- Kết thúc định nghĩa kiểu ---


const CitizenSearch = () => {
  // State for search input
  const [searchInput, setSearchInput] = useState('');
  const [searchType, setSearchType] = useState('citizen_id'); // 'citizen_id' or 'full_name'
  const [triggerSearch, setTriggerSearch] = useState(0); // State để kích hoạt useEffect tìm kiếm

  // State for results and loading/error
  const [isSearching, setIsSearching] = useState(false);
  const [searchError, setSearchError] = useState('');
  const [citizenData, setCitizenData] = useState<CitizenData | null>(null); // Sử dụng kiểu dữ liệu đã định nghĩa

  // Get current date in Vietnamese format
  const today = new Date();
  const days = ['Chủ Nhật', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy'];
  const dayName = days[today.getDay()];
  const formattedDate = `${dayName}, ${today.getDate().toString().padStart(2, '0')}/${(today.getMonth() + 1).toString().padStart(2, '0')}/${today.getFullYear()}`;

  // --- useEffect để gọi API (giả lập) khi triggerSearch thay đổi ---
  useEffect(() => {
    // Chỉ thực hiện tìm kiếm nếu triggerSearch > 0 (đã bấm nút tìm kiếm)
    if (triggerSearch === 0 || !searchInput.trim()) {
      // Không tìm kiếm nếu chưa bấm nút hoặc input rỗng
      if (triggerSearch > 0 && !searchInput.trim()) {
         setSearchError('Vui lòng nhập thông tin tìm kiếm.');
      }
      return;
    }

    const performSearch = async () => {
      setIsSearching(true);
      setSearchError('');
      setCitizenData(null); // Xóa kết quả cũ

      // Giả lập gọi API bằng fetch
      const apiEndpoint = `/api/citizen-lookup?type=${searchType}&value=${encodeURIComponent(searchInput)}`;
      console.log('Simulating fetch to:', apiEndpoint);

      try {
        // --- Giả lập Fetch ---
        // Thay thế phần này bằng fetch thật khi có API
        const response = await new Promise<{ ok: boolean; json: () => Promise<any>; status: number }>((resolve, reject) => {
          setTimeout(() => {
            // Giả lập dữ liệu trả về dựa trên input
            if ((searchType === 'citizen_id' && searchInput === '012345678901') || (searchType === 'full_name' && searchInput.toLowerCase() === 'nguyễn văn a')) {
              // ---- Dữ liệu giả lập đầy đủ ----
              const mockData: CitizenData = {
                // BCA: citizen
                citizen_id: '012345678901',
                full_name: 'Nguyễn Văn A',
                date_of_birth: '15/05/1980',
                place_of_birth_detail: 'Phường Liễu Giai, Quận Ba Đình, Thành phố Hà Nội', // Giữ text nếu chưa có cấu trúc
                gender: 'Nam',
                blood_type: 'O+',
                ethnicity_id: 1, // Kinh
                religion_id: 1, // Không
                nationality_id: 1, // Việt Nam
                father_citizen_id: '012000000001',
                mother_citizen_id: '012000000002',
                education_level: 'Đại học',
                occupation_id: 123, // ID Kỹ sư CNTT
                occupation_detail: 'Lập trình viên cao cấp tại công ty XYZ',
                tax_code: '8901234567',
                social_insurance_no: 'SI12345678',
                health_insurance_no: 'HI87654321',
                current_email: 'nguyenvana@email.com',
                current_phone_number: '0912345678',

                // BCA: identification_card
                card_number: '012345678901',
                card_type: 'CCCD gắn chip',
                issue_date: '10/06/2021',
                expiry_date: '10/06/2041', // CCCD mới thường có hạn dài
                issuing_authority_id: 1, // ID Cục Cảnh sát QLHC về TTXH
                card_status: 'Đang sử dụng',
                previous_card_number: '123456789', // Số CMND cũ

                // BCA: citizen_status
                citizen_status_type: 'Còn sống',
                status_date: '01/01/2020', // Ngày cập nhật trạng thái gần nhất

                // BCA: permanent_residence + address + reference (giả lập join)
                permanent_residence: {
                  address_detail: 'Số 123 Đường Trần Duy Hưng',
                  ward_id: 101, district_id: 11, province_id: 1,
                  registration_date: '20/07/2015',
                  issuing_authority_id: 10, // ID Công an Quận Cầu Giấy
                  // Derived/Joined Fields
                  ward_name: 'Phường Trung Hòa',
                  district_name: 'Quận Cầu Giấy',
                  province_name: 'Thành phố Hà Nội',
                  issuing_authority_name: 'Công an Quận Cầu Giấy, TP. Hà Nội',
                },

                // BCA: temporary_residence + address + reference (giả lập join)
                temporary_residence: {
                  address_detail: 'Số 45 Đường Nguyễn Chí Thanh, Tòa nhà ABC, Phòng 101',
                  ward_id: 202, district_id: 22, province_id: 1,
                  registration_date: '05/03/2023',
                  expiry_date: '05/03/2025',
                  purpose: 'Công tác dài hạn',
                  issuing_authority_id: 20, // ID Công an Phường Láng Hạ
                   // Derived/Joined Fields
                  ward_name: 'Phường Láng Hạ',
                  district_name: 'Quận Đống Đa',
                  province_name: 'Thành phố Hà Nội',
                  issuing_authority_name: 'Công an Phường Láng Hạ, Quận Đống Đa, TP. Hà Nội',
                },

                // BTP (Giả lập từ API)
                father_full_name: 'Nguyễn Văn B (BTP)',
                mother_full_name: 'Trần Thị C (BTP)',
                marital_status: 'Đã kết hôn',
                spouse_citizen_id: '012987654321',
                spouse_full_name: 'Lê Thị D (BTP)',
                marriage_date: '10/10/2005',
                // divorce_date: null, // Nếu có ly hôn

                // Reference Data (Giả lập đã join)
                ethnicity_name: 'Kinh',
                religion_name: 'Không',
                nationality_name: 'Việt Nam',
                occupation_name: 'Kỹ sư Công nghệ thông tin',
                card_issuing_authority_name: 'Cục Cảnh sát Quản lý hành chính về trật tự xã hội', // Tên đầy đủ cơ quan cấp CCCD
              };
              resolve({ ok: true, json: () => Promise.resolve(mockData), status: 200 });
            } else {
              // Giả lập không tìm thấy
              resolve({ ok: false, json: () => Promise.resolve({ message: 'Không tìm thấy thông tin công dân.' }), status: 404 });
            }
          }, 1000); // Giả lập độ trễ mạng 1 giây
        });
        // --- Kết thúc Giả lập Fetch ---

        if (!response.ok) {
          const errorData = await response.json();
          throw new Error(errorData.message || `Lỗi ${response.status}`);
        }

        const data: CitizenData = await response.json();
        setCitizenData(data);

      } catch (error: any) {
        console.error("Search error:", error);
        setSearchError(error.message || 'Đã xảy ra lỗi trong quá trình tìm kiếm.');
        setCitizenData(null);
      } finally {
        setIsSearching(false);
      }
    };

    performSearch();

  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [triggerSearch]); // Chỉ chạy lại khi triggerSearch thay đổi

  // --- Hàm xử lý khi bấm nút tìm kiếm ---
  const handleSearchSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (!searchInput.trim()) {
      setSearchError('Vui lòng nhập số CCCD/CMND hoặc thông tin tìm kiếm');
      return;
    }
    // Kích hoạt useEffect để thực hiện tìm kiếm bằng cách tăng triggerSearch
    setTriggerSearch(prev => prev + 1);
  };

  // Function to reset search
  const handleReset = () => {
    setSearchInput('');
    setCitizenData(null);
    setSearchError('');
    setTriggerSearch(0); // Reset trigger
  };

  // Helper component for consistent display of label-value pairs
  const InfoItem = ({ label, value, isHighlighted = false }: { label: string; value?: string | number | null; isHighlighted?: boolean }) => (
    <div className="py-2 flex flex-col sm:flex-row sm:items-start border-b border-gray-100 last:border-b-0">
      <div className="w-full sm:w-2/5 text-gray-600 font-medium">{label}:</div>
      <div className={`w-full sm:w-3/5 ${isHighlighted ? 'font-semibold text-blue-800' : 'text-gray-800'}`}>
        {value !== null && value !== undefined && value !== '' ? value : <span className="text-gray-400 italic">Không có thông tin</span>}
      </div>
    </div>
  );

  // Helper to format address
  const formatAddress = (addr?: { address_detail?: string, ward_name?: string, district_name?: string, province_name?: string }) => {
    if (!addr) return 'Không có thông tin';
    return [addr.address_detail, addr.ward_name, addr.district_name, addr.province_name].filter(Boolean).join(', ');
  }

  return (
    <main className="min-h-screen bg-gray-50">
      {/* Top header */}
      <div className="border-b bg-white">
        <div className="container mx-auto px-4 py-2 flex items-center justify-between">
          <div className="flex items-center">
            <div className="w-16 h-16 relative mr-2">
              <img src="/logo-bocongan.png" alt="Logo Bộ Công An" width={64} height={64} className="object-contain" />
            </div>
            <div>
              <p className="text-xs text-gray-700">BỘ CÔNG AN</p>
              <h1 className="text-3xl font-bold text-red-600">CỔNG DỊCH VỤ CÔNG</h1>
            </div>
          </div>
          <div className="flex items-center space-x-4">
            <span className="text-sm">{formattedDate}</span>
            <div className="flex space-x-2">
              <a href="#" className="text-sm text-blue-700 hover:underline">Tiếng Việt</a>
              <a href="#" className="text-sm text-blue-700 hover:underline">English</a>
            </div>
          </div>
        </div>
      </div>

      {/* Main navigation */}
      <nav className="bg-blue-900 text-white shadow-md">
        <div className="container mx-auto px-4">
           <ul className="flex flex-wrap">
            <li className="flex items-center">
              <Link href="/" className="px-4 py-3 text-white font-medium hover:bg-blue-800 flex items-center">
                 {/* Icon Trang chủ */} TRANG CHỦ
              </Link>
            </li>
            {/* Các mục menu khác */}
          </ul>
        </div>
      </nav>

      {/* Breadcrumb */}
      <div className="bg-gray-100 border-b">
        <div className="container mx-auto px-4 py-2">
          <div className="flex items-center text-sm">
            <Link href="/" className="text-blue-700 hover:underline">Trang chủ</Link>
            <span className="mx-2 text-gray-500">/</span>
            <span className="text-gray-600">Tra cứu thông tin công dân</span>
          </div>
        </div>
      </div>

      {/* Main content */}
      <div className="container mx-auto px-4 py-8">
        <h1 className="text-2xl font-bold text-gray-800 mb-6 flex items-center">
          {/* Icon */} TRA CỨU THÔNG TIN CÔNG DÂN
        </h1>

        {/* Search form */}
        <div className="bg-white rounded-lg shadow-md overflow-hidden mb-8">
          <div className="bg-blue-800 text-white py-3 px-6">
            <h2 className="text-lg font-bold">THÔNG TIN TÌM KIẾM</h2>
          </div>
          <div className="p-6">
             {/* Sử dụng onSubmit trên form */}
            <form onSubmit={handleSearchSubmit} className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <label className="block text-gray-700 font-medium mb-2">Tìm kiếm theo</label>
                  <div className="flex space-x-4">
                    <label className="inline-flex items-center">
                      <input type="radio" value="citizen_id" checked={searchType === 'citizen_id'} onChange={(e) => setSearchType(e.target.value)} className="form-radio h-4 w-4 text-blue-600" />
                      <span className="ml-2 text-gray-700">Số CCCD/CMND</span>
                    </label>
                    <label className="inline-flex items-center">
                      <input type="radio" value="full_name" checked={searchType === 'full_name'} onChange={(e) => setSearchType(e.target.value)} className="form-radio h-4 w-4 text-blue-600" />
                      <span className="ml-2 text-gray-700">Họ tên</span>
                    </label>
                  </div>
                </div>
                <div>
                  <label htmlFor="searchInput" className="block text-gray-700 font-medium mb-2">
                    {searchType === 'citizen_id' ? 'Số CCCD/CMND' : 'Họ tên khai sinh'}
                  </label>
                  <input
                    type="text"
                    id="searchInput"
                    value={searchInput}
                    onChange={(e) => setSearchInput(e.target.value)}
                    placeholder={searchType === 'citizen_id' ? 'Nhập số CCCD/CMND 12 số' : 'Nhập họ tên đầy đủ'}
                    className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>
               {/* Hiển thị lỗi tìm kiếm */}
               {searchError && (
                    <p className="mt-2 text-red-600 text-sm text-center">{searchError}</p>
               )}
              <div className="flex justify-end space-x-4">
                <button type="button" onClick={handleReset} className="px-6 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 font-medium">
                  Làm mới
                </button>
                <button type="submit" disabled={isSearching} className="px-6 py-2 bg-blue-700 text-white rounded-md hover:bg-blue-800 font-medium flex items-center disabled:opacity-50">
                  {isSearching ? (
                    <> {/* Icon Loading */} Đang tìm kiếm... </>
                  ) : (
                    <> {/* Icon Search */} Tìm kiếm </>
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>

        {/* ----- Results section - Cập nhật hiển thị ----- */}
        {isSearching && ( // Hiển thị trạng thái đang tải
             <div className="text-center py-10">
                <p className="text-blue-700 font-semibold">Đang tải dữ liệu...</p>
                {/* Có thể thêm spinner ở đây */}
            </div>
        )}

        {!isSearching && citizenData && ( // Chỉ hiển thị khi không tìm kiếm và có dữ liệu
          <div className="bg-white rounded-lg shadow-md overflow-hidden mb-8">
            <div className="bg-blue-800 text-white py-3 px-6 flex justify-between items-center">
              <h2 className="text-lg font-bold">THÔNG TIN CHI TIẾT CÔNG DÂN</h2>
              <div className="flex space-x-2">
                 {/* Nút Xuất/In */}
              </div>
            </div>

            <div className="p-6 space-y-8">
              {/* --- I. Thông tin định danh & cá nhân --- */}
              <div>
                <h3 className="text-lg font-bold text-blue-900 mb-4 border-b pb-2">I. THÔNG TIN ĐỊNH DANH & CÁ NHÂN</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-x-8">
                  <div>
                    <InfoItem label="Số định danh cá nhân" value={citizenData.citizen_id} isHighlighted={true} />
                    <InfoItem label="Họ và tên" value={citizenData.full_name} isHighlighted={true} />
                    <InfoItem label="Ngày sinh" value={citizenData.date_of_birth} />
                    <InfoItem label="Giới tính" value={citizenData.gender} />
                     {/* Hiển thị Nơi sinh đầy đủ nếu có */}
                    <InfoItem label="Nơi sinh" value={citizenData.place_of_birth_full || citizenData.place_of_birth_detail} />
                    <InfoItem label="Quê quán" value={"Chưa có dữ liệu"} /> {/* Bổ sung nếu có */}
                  </div>
                  <div>
                    <InfoItem label="Dân tộc" value={citizenData.ethnicity_name} />
                    <InfoItem label="Tôn giáo" value={citizenData.religion_name} />
                    <InfoItem label="Quốc tịch" value={citizenData.nationality_name} />
                    <InfoItem label="Nhóm máu" value={citizenData.blood_type} />
                    <InfoItem label="Trạng thái" value={`${citizenData.citizen_status_type}${citizenData.status_date ? ` (Cập nhật: ${citizenData.status_date})` : ''}`} isHighlighted={citizenData.citizen_status_type !== 'Còn sống'} />
                  </div>
                </div>
              </div>

              {/* --- II. Thông tin CCCD/CMND --- */}
              <div>
                <h3 className="text-lg font-bold text-blue-900 mb-4 border-b pb-2">II. THÔNG TIN CCCD/CMND</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-x-8">
                  <div>
                    <InfoItem label="Số thẻ hiện tại" value={citizenData.card_number} isHighlighted={true} />
                    <InfoItem label="Loại thẻ" value={citizenData.card_type} />
                    <InfoItem label="Ngày cấp" value={citizenData.issue_date} />
                    <InfoItem label="Số thẻ trước" value={citizenData.previous_card_number} /> {/* Thêm thẻ cũ */}
                  </div>
                  <div>
                    <InfoItem label="Ngày hết hạn" value={citizenData.expiry_date} />
                    <InfoItem label="Nơi cấp" value={citizenData.card_issuing_authority_name} /> {/* Tên cơ quan cấp */}
                    <InfoItem label="Trạng thái thẻ" value={citizenData.card_status} />
                  </div>
                </div>
              </div>

              {/* --- III. Thông tin cư trú --- */}
              <div>
                <h3 className="text-lg font-bold text-blue-900 mb-4 border-b pb-2">III. THÔNG TIN CƯ TRÚ</h3>
                {/* Thường trú */}
                {citizenData.permanent_residence && (
                  <div className="bg-gray-50 p-4 rounded-lg mb-6">
                    <h4 className="font-semibold text-blue-800 mb-3">Thường trú</h4>
                     <InfoItem label="Địa chỉ" value={formatAddress(citizenData.permanent_residence)} />
                     <InfoItem label="Ngày đăng ký" value={citizenData.permanent_residence.registration_date} />
                     <InfoItem label="Nơi đăng ký" value={citizenData.permanent_residence.issuing_authority_name} />
                  </div>
                )}
                {/* Tạm trú */}
                 {citizenData.temporary_residence && (
                  <div className="bg-gray-50 p-4 rounded-lg">
                    <h4 className="font-semibold text-blue-800 mb-3">Tạm trú</h4>
                    <InfoItem label="Địa chỉ" value={formatAddress(citizenData.temporary_residence)} />
                    <InfoItem label="Ngày đăng ký" value={citizenData.temporary_residence.registration_date} />
                    <InfoItem label="Ngày hết hạn" value={citizenData.temporary_residence.expiry_date} />
                    <InfoItem label="Mục đích" value={citizenData.temporary_residence.purpose} />
                    <InfoItem label="Nơi đăng ký" value={citizenData.temporary_residence.issuing_authority_name} />
                  </div>
                )}
                 {!citizenData.permanent_residence && !citizenData.temporary_residence && (
                     <p className="text-gray-500 italic">Không có thông tin đăng ký cư trú.</p>
                 )}
              </div>

              {/* --- IV. Thông tin gia đình (Tích hợp BTP) --- */}
              <div>
                <h3 className="text-lg font-bold text-blue-900 mb-4 border-b pb-2">IV. THÔNG TIN GIA ĐÌNH & HÔN NHÂN (Nguồn: BTP)</h3>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-x-8">
                  <div>
                    <InfoItem label="Họ tên cha" value={citizenData.father_full_name} />
                    <InfoItem label="Số ĐDCN Cha" value={citizenData.father_citizen_id} />
                    <InfoItem label="Họ tên mẹ" value={citizenData.mother_full_name} />
                    <InfoItem label="Số ĐDCN Mẹ" value={citizenData.mother_citizen_id} />
                  </div>
                  <div>
                    <InfoItem label="Tình trạng hôn nhân" value={citizenData.marital_status} isHighlighted={true}/>
                    <InfoItem label="Họ tên vợ/chồng" value={citizenData.spouse_full_name} />
                    <InfoItem label="Số ĐDCN Vợ/Chồng" value={citizenData.spouse_citizen_id} />
                    <InfoItem label="Ngày kết hôn" value={citizenData.marriage_date} />
                    <InfoItem label="Ngày ly hôn" value={citizenData.divorce_date} />
                  </div>
                </div>
                {/* Có thể thêm phần hiển thị các quan hệ khác từ family_relationship nếu có */}
              </div>

              {/* --- V. Thông tin khác --- */}
              <div>
                <h3 className="text-lg font-bold text-blue-900 mb-4 border-b pb-2">V. THÔNG TIN KHÁC</h3>
                 <div className="grid grid-cols-1 md:grid-cols-2 gap-x-8">
                   <div>
                    <InfoItem label="Trình độ học vấn" value={citizenData.education_level} />
                    <InfoItem label="Nghề nghiệp" value={citizenData.occupation_name} />
                    {/* <InfoItem label="Chi tiết nghề nghiệp" value={citizenData.occupation_detail} /> */}
                    <InfoItem label="Mã số thuế" value={citizenData.tax_code} />
                  </div>
                  <div>
                    <InfoItem label="Số sổ BHXH" value={citizenData.social_insurance_no} />
                    <InfoItem label="Số thẻ BHYT" value={citizenData.health_insurance_no} />
                    <InfoItem label="Email liên hệ" value={citizenData.current_email} />
                    <InfoItem label="Số điện thoại liên hệ" value={citizenData.current_phone_number} />
                  </div>
                </div>
              </div>

              {/* Action buttons */}
              <div className="mt-8 pt-6 border-t border-gray-100 flex justify-end space-x-4">
                 <Link href="/" className="px-6 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 font-medium flex items-center">
                    {/* Icon Back */} Quay lại
                 </Link>
                 {/* Nút In */}
              </div>
            </div>
          </div>
        )}

        {/* Info tips panel */}
        {!isSearching && !citizenData && triggerSearch > 0 && !searchError && ( // Thông báo không tìm thấy
            <div className="text-center py-10">
                <p className="text-gray-600">Không tìm thấy thông tin công dân phù hợp.</p>
            </div>
        )}
         {/* ... (Phần Lưu ý giữ nguyên) ... */}
      </div>

      {/* Footer */}
      {/* ... (Footer giữ nguyên) ... */}
    </main>
  );
};

export default CitizenSearch;