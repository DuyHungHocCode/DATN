'use client';

import React, { useState, ChangeEvent, FormEvent } from 'react';
import Link from 'next/link';

// --- Định nghĩa kiểu dữ liệu cho Form Update (Thông tin cơ bản) ---
interface CitizenBasicUpdateFormData {
  full_name: string;
  gender: string;
  blood_type?: string;
  current_email: string;
  current_phone_number: string;
  // Có thể thêm Dân tộc, Tôn giáo, Quốc tịch nếu muốn
  // ethnicity_id?: number | string;
  // religion_id?: number | string;
  // nationality_id?: number | string;
}

// --- Component chính ---
const CitizenUpdateWithSearch = () => {
  // State cho việc tìm kiếm
  const [searchType, setSearchType] = useState('citizen_id'); // 'citizen_id' or 'full_name'
  const [searchInput, setSearchInput] = useState('');
  const [isSearchingCitizen, setIsSearchingCitizen] = useState(false);
  const [searchError, setSearchError] = useState<string | null>(null);
  const [foundCitizenId, setFoundCitizenId] = useState<string | null>(null); // ID công dân tìm thấy

  // State cho form cập nhật
  const [formData, setFormData] = useState<Partial<CitizenBasicUpdateFormData>>({});
  const [initialData, setInitialData] = useState<Partial<CitizenBasicUpdateFormData>>({});
  const [isLoadingData, setIsLoadingData] = useState(false); // Tải dữ liệu sau khi tìm thấy
  const [isSaving, setIsSaving] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [saveSuccessMessage, setSaveSuccessMessage] = useState<string | null>(null);

  // State giả lập cho dữ liệu tham chiếu (Dropdowns)
  const [referenceData, setReferenceData] = useState({
    genders: ['Nam', 'Nữ', 'Khác'],
    bloodTypes: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
    // ethnicities: [...], religions: [...], nationalities: [...] // Nên fetch nếu dùng
  });

  // --- Hàm xử lý tìm kiếm công dân ---
  const handleCitizenSearch = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (!searchInput.trim()) {
      setSearchError('Vui lòng nhập thông tin tìm kiếm.');
      return;
    }

    setIsSearchingCitizen(true);
    setSearchError(null);
    setFoundCitizenId(null);
    setFormData({});
    setInitialData({});
    setSaveError(null);
    setSaveSuccessMessage(null);

    console.log(`Simulating citizen search: type=${searchType}, value=${searchInput}`);

    try {
      // --- Giả lập Fetch Search API ---
      await new Promise(resolve => setTimeout(resolve, 1000)); // Giả lập độ trễ

      // Giả lập kết quả tìm kiếm
      let foundId: string | null = null;
      if ((searchType === 'citizen_id' && searchInput === '012345678901') || (searchType === 'full_name' && searchInput.toLowerCase() === 'nguyễn văn a (basic)')) {
        foundId = '012345678901'; // Giả lập tìm thấy ID này
      }
      // --- Kết thúc Giả lập Fetch Search ---

      if (foundId) {
        setFoundCitizenId(foundId);
        // Nếu tìm thấy, gọi hàm tải dữ liệu chi tiết cơ bản
        await fetchBasicCitizenData(foundId);
      } else {
        setSearchError('Không tìm thấy công dân phù hợp.');
      }

    } catch (err: any) {
      console.error("Search error:", err);
      setSearchError('Lỗi trong quá trình tìm kiếm công dân.');
    } finally {
      setIsSearchingCitizen(false);
    }
  };

  // --- Hàm tải dữ liệu cơ bản sau khi tìm thấy ID ---
  const fetchBasicCitizenData = async (citizenId: string) => {
      setIsLoadingData(true);
      setSaveError(null);
      setSaveSuccessMessage(null);
      console.log(`Simulating fetch basic data for citizenId: ${citizenId}`);
      try {
          // --- Giả lập Fetch GET Basic Data ---
          await new Promise(resolve => setTimeout(resolve, 500));
          const mockBasicData: CitizenBasicUpdateFormData = {
              full_name: 'Nguyễn Văn A (Dữ liệu gốc)',
              gender: 'Nam',
              blood_type: 'O+',
              current_email: 'nguyenvana.goc@email.com',
              current_phone_number: '0912345678',
              // ethnicity_id: 1, // Nếu có
              // religion_id: 1,
              // nationality_id: 1,
          };
          setFormData(mockBasicData);
          setInitialData(mockBasicData); // Lưu dữ liệu gốc
          // --- Kết thúc Giả lập Fetch GET Basic Data ---
      } catch (err) {
           console.error("Fetch basic data error:", err);
           setSaveError("Không thể tải dữ liệu chi tiết của công dân.");
           setFoundCitizenId(null); // Reset nếu không tải được data
      } finally {
           setIsLoadingData(false);
      }
  }

  // --- Xử lý thay đổi input trên form cập nhật ---
  const handleFormChange = (e: ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value === '' ? undefined : value
    }));
    setSaveSuccessMessage(null);
    setSaveError(null);
  };

  // --- Xử lý Submit Form Cập nhật ---
  const handleUpdateSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (!foundCitizenId) return; // Không có citizen ID thì không làm gì

    setIsSaving(true);
    setSaveError(null);
    setSaveSuccessMessage(null);

    // Lọc các trường đã thay đổi
    const changedData: Partial<CitizenBasicUpdateFormData> = {};
    for (const key in formData) {
      if (formData[key as keyof CitizenBasicUpdateFormData] !== initialData[key as keyof CitizenBasicUpdateFormData]) {
        changedData[key as keyof CitizenBasicUpdateFormData] = formData[key as keyof CitizenBasicUpdateFormData];
      }
    }

    if (Object.keys(changedData).length === 0) {
      setSaveSuccessMessage("Không có thay đổi nào để lưu.");
      setIsSaving(false);
      return;
    }

    console.log(`Simulating update basic data for citizenId: ${foundCitizenId} with changes:`, changedData);

    try {
      // --- Giả lập Fetch PUT/PATCH Update API ---
      await new Promise((resolve, reject) => {
        setTimeout(() => {
            if (Math.random() > 0.1) { // 90% thành công
                resolve({ ok: true });
            } else {
                reject(new Error('Lỗi không mong muốn khi lưu.'));
            }
        }, 1500);
      });

      setInitialData(formData); // Cập nhật dữ liệu gốc sau khi thành công
      setSaveSuccessMessage('Cập nhật thông tin cơ bản thành công!');
      // --- Kết thúc Giả lập ---

    } catch (err: any) {
      console.error("Save error:", err);
      setSaveError(err.message || "Lỗi khi cập nhật thông tin.");
    } finally {
      setIsSaving(false);
    }
  };

  // --- Hàm để quay lại màn hình tìm kiếm ---
   const resetSearch = () => {
        setSearchInput('');
        setSearchError(null);
        setFoundCitizenId(null);
        setFormData({});
        setInitialData({});
        setSaveError(null);
        setSaveSuccessMessage(null);
        setIsSearchingCitizen(false);
        setIsLoadingData(false);
        setIsSaving(false);
   }

  // --- Render ---
  return (
    <main className="min-h-screen bg-gray-50">
       {/* Header, Nav, Footer (Copy từ các component trước) */}
       {/* ... Header ... */}
       {/* ... Nav ... */}
        {/* Breadcrumb */}
        <div className="bg-gray-100 border-b">
            <div className="container mx-auto px-4 py-2">
            <div className="flex items-center text-sm">
                <Link href="/" className="text-blue-700 hover:underline">Trang chủ</Link>
                <span className="mx-2 text-gray-500">/</span>
                <span className="text-gray-600">Cập nhật thông tin công dân</span>
            </div>
            </div>
        </div>


      <div className="container mx-auto px-4 py-8">
        <h1 className="text-2xl font-bold text-gray-800 mb-6">Cập nhật thông tin công dân</h1>

        {/* ----- Phần Tìm kiếm Công dân ----- */}
        {!foundCitizenId && (
          <div className="bg-white rounded-lg shadow-md overflow-hidden mb-8">
            <div className="bg-blue-800 text-white py-3 px-6">
              <h2 className="text-lg font-bold">1. Tìm kiếm công dân cần cập nhật</h2>
            </div>
            <form onSubmit={handleCitizenSearch} className="p-6 space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 items-end">
                 {/* Chọn loại tìm kiếm */}
                 <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">Tìm kiếm theo</label>
                    <select value={searchType} onChange={(e) => setSearchType(e.target.value)}
                           className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 bg-white">
                      <option value="citizen_id">Số CCCD/CMND</option>
                      <option value="full_name">Họ tên</option>
                    </select>
                 </div>
                 {/* Input tìm kiếm */}
                 <div className="md:col-span-2">
                   <label htmlFor="searchInput" className="block text-sm font-medium text-gray-700 mb-1">
                        {searchType === 'citizen_id' ? 'Nhập Số CCCD/CMND' : 'Nhập Họ tên'}
                   </label>
                    <input
                        type="text"
                        id="searchInput"
                        value={searchInput}
                        onChange={(e) => setSearchInput(e.target.value)}
                        placeholder={searchType === 'citizen_id' ? 'Số CCCD/CMND 12 số' : 'Họ tên đầy đủ'}
                        required
                        className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"
                    />
                 </div>
              </div>
               {/* Thông báo lỗi tìm kiếm */}
              {searchError && <p className="text-red-600 text-sm">{searchError}</p>}
              {/* Nút tìm kiếm */}
              <div className="flex justify-end">
                 <button type="submit" disabled={isSearchingCitizen}
                        className="px-6 py-2 bg-blue-700 text-white rounded-md hover:bg-blue-800 font-medium flex items-center disabled:opacity-50">
                   {isSearchingCitizen ? (
                       <> {/* Icon Loading */} Đang tìm... </>
                    ) : (
                       <> {/* Icon Search */} Tìm kiếm công dân </>
                   )}
                 </button>
              </div>
            </form>
          </div>
        )}

        {/* ----- Phần Form Cập nhật (hiển thị sau khi tìm thấy) ----- */}
        {foundCitizenId && (
             <div className="bg-white rounded-lg shadow-md overflow-hidden">
                 <div className="bg-blue-800 text-white py-3 px-6 flex justify-between items-center">
                    <h2 className="text-lg font-bold">2. Cập nhật thông tin cơ bản cho công dân: {initialData.full_name} ({foundCitizenId})</h2>
                     <button onClick={resetSearch} className="text-sm text-white hover:text-blue-200">Tìm kiếm lại</button>
                 </div>

                 {isLoadingData ? (
                     <div className="p-6 text-center">Đang tải dữ liệu...</div>
                 ) : (
                    <form onSubmit={handleUpdateSubmit} className="p-6 space-y-6">
                        {/* Thông báo lỗi/thành công lưu */}
                        {saveError && <div className="p-3 mb-4 text-sm text-red-700 bg-red-100 rounded-lg" role="alert">{saveError}</div>}
                        {saveSuccessMessage && <div className="p-3 mb-4 text-sm text-green-700 bg-green-100 rounded-lg" role="alert">{saveSuccessMessage}</div>}

                        {/* --- Các trường thông tin cơ bản --- */}
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                            {/* Họ và tên */}
                            <div>
                                <label htmlFor="full_name_update" className="block text-sm font-medium text-gray-700 mb-1">Họ và tên</label>
                                <input type="text" id="full_name_update" name="full_name" value={formData.full_name || ''} onChange={handleFormChange} required
                                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"/>
                            </div>
                            {/* Giới tính */}
                            <div>
                                <label htmlFor="gender_update" className="block text-sm font-medium text-gray-700 mb-1">Giới tính</label>
                                <select id="gender_update" name="gender" value={formData.gender || ''} onChange={handleFormChange} required
                                        className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 bg-white">
                                    <option value="" disabled>-- Chọn --</option>
                                    {referenceData.genders.map(g => <option key={g} value={g}>{g}</option>)}
                                </select>
                            </div>
                            {/* Nhóm máu */}
                            <div>
                                <label htmlFor="blood_type_update" className="block text-sm font-medium text-gray-700 mb-1">Nhóm máu</label>
                                <select id="blood_type_update" name="blood_type" value={formData.blood_type || ''} onChange={handleFormChange}
                                        className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 bg-white">
                                    <option value="">-- Chọn (Nếu có) --</option>
                                    {referenceData.bloodTypes.map(bt => <option key={bt} value={bt}>{bt}</option>)}
                                </select>
                            </div>
                            {/* Email */}
                            <div>
                                <label htmlFor="current_email_update" className="block text-sm font-medium text-gray-700 mb-1">Email</label>
                                <input type="email" id="current_email_update" name="current_email" value={formData.current_email || ''} onChange={handleFormChange}
                                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"/>
                            </div>
                            {/* Số điện thoại */}
                            <div className="md:col-span-2">
                                <label htmlFor="current_phone_number_update" className="block text-sm font-medium text-gray-700 mb-1">Số điện thoại</label>
                                <input type="tel" id="current_phone_number_update" name="current_phone_number" value={formData.current_phone_number || ''} onChange={handleFormChange}
                                    className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500"/>
                            </div>
                        </div>

                        {/* --- Nút Submit Cập nhật --- */}
                        <div className="pt-6 border-t flex justify-end space-x-3">
                            <button type="button" onClick={resetSearch}
                                    className="px-6 py-2 border border-gray-300 rounded-md text-gray-700 hover:bg-gray-50 font-medium">
                            Hủy / Tìm kiếm lại
                            </button>
                            <button type="submit" disabled={isSaving || isLoadingData}
                                    className="px-6 py-2 bg-blue-700 text-white rounded-md hover:bg-blue-800 font-medium flex items-center disabled:opacity-50">
                                {isSaving ? (
                                    <> {/* Icon Loading */} Đang lưu... </>
                                ) : (
                                    <> {/* Icon Save */} Lưu thay đổi cơ bản </>
                                )}
                            </button>
                        </div>
                    </form>
                 )}
             </div>
        )}
      </div>

      {/* Footer */}
      {/* ... (Copy footer từ các component trước) ... */}
    </main>
  );
};

export default CitizenUpdateWithSearch;