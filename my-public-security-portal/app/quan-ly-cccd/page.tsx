'use client';

import React, { useState, useEffect, ChangeEvent, FormEvent } from 'react';
import Link from 'next/link';

// --- Kiểu dữ liệu (Đơn giản hóa) ---
interface CitizenInfo {
  citizen_id: string;
  full_name: string;
  date_of_birth: string; // DD/MM/YYYY
}

interface IdCardInfo {
  id_card_id: number | string;
  card_number: string;
  card_type: string;
  issue_date: string; // DD/MM/YYYY
  expiry_date?: string | null; // DD/MM/YYYY
  issuing_authority_name?: string;
  card_status: string;
  is_current?: boolean;
  previous_card_number?: string | null;
  chip_id?: string | null;
  notes?: string | null;
}

interface CCCDFormData {
    citizen_id: string;
    card_number: string;
    card_type: string;
    issue_date: string;
    expiry_date?: string;
    issuing_authority_id?: number | string;
    previous_card_number?: string;
    chip_id?: string;
    notes?: string;
}

// --- Component Chính ---
const CCCDManagement = () => {
  // State Tìm kiếm
  const [searchCitizenInput, setSearchCitizenInput] = useState('');
  const [isSearchingCitizen, setIsSearchingCitizen] = useState(false);
  const [searchCitizenError, setSearchCitizenError] = useState<string | null>(null);
  const [selectedCitizen, setSelectedCitizen] = useState<CitizenInfo | null>(null);

  // State Hiển thị Thông tin CCCD
  const [currentCard, setCurrentCard] = useState<IdCardInfo | null>(null);
  const [cardHistory, setCardHistory] = useState<IdCardInfo[]>([]);
  const [isLoadingDetails, setIsLoadingDetails] = useState(false);
  const [detailsError, setDetailsError] = useState<string | null>(null);

  // State Form Cấp mới/đổi
  const [showForm, setShowForm] = useState(false);
  const [formMode, setFormMode] = useState<'new' | 'replace'>('new');
  const [formData, setFormData] = useState<Partial<CCCDFormData>>({});
  const [isSaving, setIsSaving] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [saveSuccess, setSaveSuccess] = useState<string | null>(null);

   // State giả lập cho dữ liệu tham chiếu (Dropdowns)
   const [referenceData, setReferenceData] = useState({
    cardTypes: ['CCCD gắn chip', 'CCCD mã vạch', 'CMND 9 số', 'CMND 12 số'],
    cardStatuses: ['Đang sử dụng', 'Hết hạn', 'Đã thu hồi', 'Đã hủy', 'Tạm giữ'],
    authorities: [{ id: 1, name: 'Cục Cảnh sát QLHC về TTXH' }, { id: 10, name: 'Công an TP. Hà Nội' }, { id: 11, name: 'Công an TP. Hồ Chí Minh'}]
  });

  // --- Hàm Tìm kiếm Công dân ---
  const handleCitizenSearch = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (!searchCitizenInput.trim()) {
      setSearchCitizenError('Vui lòng nhập Số định danh công dân.');
      return;
    }
    setIsSearchingCitizen(true);
    setSearchCitizenError(null);
    setSelectedCitizen(null);
    setCurrentCard(null);
    setCardHistory([]);
    setDetailsError(null);
    setShowForm(false);

    console.log(`Simulating search for citizenId: ${searchCitizenInput}`);
    try {
      await new Promise(resolve => setTimeout(resolve, 1000));
      let foundCitizen: CitizenInfo | null = null;
      if (searchCitizenInput === '012345678901') {
        foundCitizen = {
          citizen_id: '012345678901',
          full_name: 'Nguyễn Văn A',
          date_of_birth: '15/05/1980'
        };
      }

      if (foundCitizen) {
        setSelectedCitizen(foundCitizen);
        await fetchCCCDDetails(foundCitizen.citizen_id);
      } else {
        setSearchCitizenError('Không tìm thấy công dân với Số định danh này.');
      }
    } catch (err) {
      setSearchCitizenError('Lỗi khi tìm kiếm công dân.');
    } finally {
      setIsSearchingCitizen(false);
    }
  };

  // --- Hàm Tải chi tiết CCCD ---
  const fetchCCCDDetails = async (citizenId: string) => {
    setIsLoadingDetails(true);
    setDetailsError(null);
    setCurrentCard(null);
    setCardHistory([]);
    console.log(`Simulating fetch CCCD details for citizenId: ${citizenId}`);
    try {
      await new Promise(resolve => setTimeout(resolve, 800));
      const mockCurrentCard: IdCardInfo = {
        id_card_id: 101,
        card_number: '012345678901',
        card_type: 'CCCD gắn chip',
        issue_date: '10/06/2021',
        expiry_date: '10/06/2041',
        issuing_authority_name: 'Cục Cảnh sát QLHC về TTXH',
        card_status: 'Đang sử dụng',
        is_current: true,
        previous_card_number: '123456789',
        chip_id: 'CHIPID123XYZ',
        notes: 'Cấp lần đầu'
      };
      const mockOldCard: IdCardInfo = {
        id_card_id: 55,
        card_number: '123456789',
        card_type: 'CMND 9 số',
        issue_date: '15/08/2005',
        expiry_date: '15/08/2020',
        issuing_authority_name: 'Công an TP. Hà Nội',
        card_status: 'Hết hạn',
        is_current: false,
        previous_card_number: null,
        chip_id: null,
        notes: null
      };
      setCurrentCard(mockCurrentCard);
      setCardHistory([mockOldCard]);

    } catch (err) {
      setDetailsError('Lỗi khi tải thông tin CCCD.');
    } finally {
      setIsLoadingDetails(false);
    }
  };

   // --- Hàm mở Form ---
  const handleShowForm = (mode: 'new' | 'replace') => {
      setFormMode(mode);
      setSaveError(null);
      setSaveSuccess(null);
      let initialFormData: Partial<CCCDFormData> = { citizen_id: selectedCitizen?.citizen_id || '' };

      if (mode === 'replace' && currentCard) {
          initialFormData = {
              ...initialFormData,
              previous_card_number: currentCard.card_number,
              card_type: 'CCCD gắn chip',
          };
      } else {
          initialFormData = {
            ...initialFormData,
            card_type: 'CCCD gắn chip',
            previous_card_number: currentCard?.card_number
          }
      }
      setFormData(initialFormData);
      setShowForm(true);
  };

  // --- Hàm xử lý thay đổi Input Form ---
  const handleFormChange = (e: ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
      const { name, value } = e.target;
      setFormData(prev => ({ ...prev, [name]: value }));
      setSaveError(null);
      setSaveSuccess(null);
  };

  // --- Hàm Submit Form Cấp mới/Đổi ---
  const handleFormSubmit = async (e: FormEvent<HTMLFormElement>) => {
      e.preventDefault();
      setIsSaving(true);
      setSaveError(null);
      setSaveSuccess(null);
      console.log(`Simulating save CCCD (${formMode}):`, formData);
      try {
          await new Promise((resolve, reject) => {
              setTimeout(() => {
                  if (Math.random() > 0.1) {
                      resolve({ ok: true });
                  } else {
                      reject(new Error('Lỗi hệ thống khi lưu thông tin CCCD.'));
                  }
              }, 1500);
          });
          setSaveSuccess(`Thực hiện ${formMode === 'new' ? 'cấp mới' : 'cấp đổi/cấp lại'} CCCD thành công!`);
          setShowForm(false);
          if(selectedCitizen) {
              await fetchCCCDDetails(selectedCitizen.citizen_id);
          }
      } catch (err: any) {
          setSaveError(err.message || 'Lỗi không xác định khi lưu.');
      } finally {
          setIsSaving(false);
      }
  };

  // --- Render ---
  return (
    <main className="min-h-screen bg-gray-100">
      {/* Header, Nav, Footer (Copy từ OfficerHomepage) */}
       {/* Top header */}
       <div className="border-b bg-white">
         <div className="container mx-auto px-4 py-2 flex items-center justify-between">
           <div className="flex items-center">
              <div className="w-16 h-16 relative mr-2">
               <img src="/logo-bocongan.png" alt="Logo Bộ Công An" width={64} height={64} className="object-contain" />
             </div>
             <div>
               <p className="text-xs text-gray-700 uppercase">Bộ Công An</p>
               <h1 className="text-2xl font-bold text-blue-800">HỆ THỐNG QUẢN LÝ THÔNG TIN</h1>
             </div>
           </div>
           {/* Header không còn thông tin user */}
         </div>
       </div>
       {/* Main navigation */}
       <nav className="bg-blue-900 text-white shadow-md">
          {/* Nav items */}
          <div className="container mx-auto px-4">
            <ul className="flex flex-wrap">
                {/* ... các nav link khác ... */}
                 <li className="flex items-center">
                    <Link href="/quan-ly-cccd" className="px-4 py-3 text-white font-medium hover:bg-blue-800 flex items-center bg-blue-800"> {/* Active state */}
                        {/* Icon CCCD */} QUẢN LÝ CCCD
                    </Link>
                 </li>
                 {/* ... các nav link khác ... */}
            </ul>
          </div>
       </nav>
       {/* Breadcrumb */}
       <div className="bg-gray-100 border-b">
            <div className="container mx-auto px-4 py-2">
                <div className="flex items-center text-sm">
                    <Link href="/" className="text-blue-700 hover:underline">Bảng điều khiển</Link>
                    <span className="mx-2 text-gray-500">/</span>
                    <span className="text-gray-600">Quản lý Căn cước công dân</span>
                </div>
            </div>
       </div>

      <div className="container mx-auto px-4 py-8 space-y-8">
        <h1 className="text-2xl font-bold text-gray-800">Quản lý Căn cước công dân</h1>

        {/* ----- 1. Phần Tìm kiếm Công dân ----- */}
        <div className="bg-white rounded-lg shadow-md overflow-hidden">
          <div className="bg-blue-800 text-white py-3 px-6">
            <h2 className="text-lg font-bold">Tìm kiếm Công dân</h2>
          </div>
          <form onSubmit={handleCitizenSearch} className="p-6 space-y-4">
             <div className="flex flex-col md:flex-row md:items-end md:space-x-4">
                <div className="flex-grow mb-4 md:mb-0">
                    <label htmlFor="searchCitizenInput" className="block text-sm font-medium text-gray-700 mb-1">Số định danh Công dân (CCCD)</label>
                    <input
                        type="text"
                        id="searchCitizenInput"
                        value={searchCitizenInput}
                        onChange={(e) => setSearchCitizenInput(e.target.value)}
                        placeholder="Nhập 12 số CCCD..."
                        required
                        maxLength={12}
                        pattern="\d{12}"
                        title="Vui lòng nhập đúng 12 số"
                        // Đảm bảo input này cũng có màu chữ đúng
                        className="w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 text-gray-900"
                    />
                </div>
                <div className="flex-shrink-0">
                    <button type="submit" disabled={isSearchingCitizen}
                            className="w-full md:w-auto px-6 py-2 bg-blue-700 text-white rounded-md hover:bg-blue-800 font-medium flex items-center justify-center disabled:opacity-50">
                    {isSearchingCitizen ? 'Đang tìm...' : 'Tìm kiếm'}
                    </button>
                </div>
             </div>
             {searchCitizenError && <p className="text-red-600 text-sm mt-2">{searchCitizenError}</p>}
          </form>
        </div>

        {/* ----- 2. Phần Hiển thị Thông tin & Hành động (Sau khi tìm thấy) ----- */}
        {selectedCitizen && (
          <div className="bg-white rounded-lg shadow-md overflow-hidden">
             {/* ----- ĐÃ SỬA: Thêm màu chữ ----- */}
             <div className="bg-gray-50 p-4 border-b border-gray-200 text-gray-800"> {/* Màu chữ mặc định cho phần header thông tin */}
                <h3 className="text-md font-semibold text-gray-900">Thông tin Công dân</h3> {/* Màu đậm hơn cho tiêu đề */}
                <p><strong className="font-medium text-gray-600">Họ tên:</strong> {selectedCitizen.full_name}</p>
                <p><strong className="font-medium text-gray-600">Số ĐDCN:</strong> {selectedCitizen.citizen_id}</p>
                <p><strong className="font-medium text-gray-600">Ngày sinh:</strong> {selectedCitizen.date_of_birth}</p>
             </div>

             {isLoadingDetails && <div className="p-6 text-center text-gray-700">Đang tải thông tin CCCD...</div>}
             {detailsError && <div className="p-6 text-red-600">{detailsError}</div>}

             {!isLoadingDetails && !detailsError && (
               <div className="p-6 space-y-6">
                 {/* Thông tin thẻ hiện tại */}
                 <div>
                   <h4 className="text-lg font-semibold text-blue-800 mb-3">CCCD/CMND Hiện tại</h4>
                   {currentCard ? (
                     <div className="grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-2 text-sm text-gray-800"> {/* Màu chữ mặc định */}
                       <span><strong className="font-medium text-gray-600">Số thẻ:</strong> {currentCard.card_number}</span>
                       <span><strong className="font-medium text-gray-600">Loại thẻ:</strong> {currentCard.card_type}</span>
                       <span><strong className="font-medium text-gray-600">Ngày cấp:</strong> {currentCard.issue_date}</span>
                       <span><strong className="font-medium text-gray-600">Ngày hết hạn:</strong> {currentCard.expiry_date || 'N/A'}</span>
                       <span className="md:col-span-2"><strong className="font-medium text-gray-600">Nơi cấp:</strong> {currentCard.issuing_authority_name || 'N/A'}</span>
                       <span>
                           <strong className="font-medium text-gray-600">Trạng thái:</strong>
                           {/* Giữ lại màu trạng thái riêng */}
                           <span className={`ml-1 font-medium ${currentCard.card_status === 'Đang sử dụng' ? 'text-green-700' : 'text-red-700'}`}>{currentCard.card_status}</span>
                        </span>
                       <span><strong className="font-medium text-gray-600">Số thẻ trước:</strong> {currentCard.previous_card_number || 'N/A'}</span>
                       <span><strong className="font-medium text-gray-600">Mã chip:</strong> {currentCard.chip_id || 'N/A'}</span>
                       {currentCard.notes && <span className="md:col-span-2"><strong className="font-medium text-gray-600">Ghi chú:</strong> {currentCard.notes}</span>}
                     </div>
                   ) : (
                     <p className="text-gray-500 italic">Chưa có thông tin CCCD/CMND hiện tại.</p>
                   )}
                 </div>

                 {/* Lịch sử thẻ */}
                 <div>
                    <h4 className="text-lg font-semibold text-blue-800 mb-3">Lịch sử CCCD/CMND</h4>
                    {cardHistory.length > 0 ? (
                        <ul className="space-y-3">
                           {cardHistory.map(card => (
                               <li key={card.id_card_id} className="p-3 bg-gray-50 rounded border border-gray-200 text-xs text-gray-700"> {/* Màu chữ mặc định cho li */}
                                   <p><strong className="font-medium text-gray-600">Số thẻ:</strong> {card.card_number} ({card.card_type})</p>
                                   <p><strong className="font-medium text-gray-600">Ngày cấp:</strong> {card.issue_date} - <strong>Hết hạn:</strong> {card.expiry_date || 'N/A'}</p>
                                   <p><strong className="font-medium text-gray-600">Nơi cấp:</strong> {card.issuing_authority_name || 'N/A'}</p>
                                   <p><strong className="font-medium text-gray-600">Trạng thái:</strong> {card.card_status}</p>
                               </li>
                           ))}
                        </ul>
                    ) : (
                        <p className="text-gray-500 italic">Không có lịch sử CCCD/CMND trước đó.</p>
                    )}
                 </div>
                 {/* ----- Kết thúc sửa màu chữ ----- */}

                  {/* Các nút hành động */}
                  <div className="pt-6 border-t flex flex-wrap gap-3">
                      <button onClick={() => handleShowForm('new')}
                              className="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700 text-sm font-medium">
                          Cấp mới CCCD
                      </button>
                      <button onClick={() => handleShowForm('replace')} disabled={!currentCard}
                              className="px-4 py-2 bg-yellow-600 text-white rounded hover:bg-yellow-700 text-sm font-medium disabled:opacity-50 disabled:cursor-not-allowed">
                          Cấp đổi / Cấp lại CCCD
                      </button>
                      <button disabled={!currentCard}
                              className="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 text-sm font-medium disabled:opacity-50 disabled:cursor-not-allowed">
                          Cập nhật Trạng thái thẻ
                      </button>
                  </div>
               </div>
             )}
          </div>
        )}

         {/* ----- 3. Form Cấp mới/Cấp đổi (Modal) ----- */}
         {showForm && selectedCitizen && (
             <div className="fixed inset-0 bg-gray-600 bg-opacity-50 overflow-y-auto h-full w-full z-50 flex items-center justify-center p-4">
                <div className="relative bg-white rounded-lg shadow-xl w-full max-w-2xl">
                   {/* Modal Header */}
                   <div className="flex justify-between items-center p-4 border-b">
                      <h3 className="text-lg font-semibold text-gray-900"> {/* Đảm bảo tiêu đề modal có màu */}
                         {formMode === 'new' ? 'Cấp mới CCCD' : 'Cấp đổi/Cấp lại CCCD'} cho công dân {selectedCitizen.full_name}
                      </h3>
                      <button onClick={() => setShowForm(false)} className="text-gray-400 bg-transparent hover:bg-gray-200 hover:text-gray-900 rounded-lg text-sm p-1.5 ml-auto inline-flex items-center">
                         X
                      </button>
                   </div>
                   {/* Modal Body - Form */}
                   <form onSubmit={handleFormSubmit} className="p-6 space-y-4">
                        {saveError && <p className="text-red-600 text-sm">{saveError}</p>}
                        {saveSuccess && <p className="text-green-600 text-sm">{saveSuccess}</p>}

                        {/* Các trường input đã có CSS toàn cục xử lý màu, không cần thêm class ở đây */}
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                           {/* Số thẻ mới */}
                           <div>
                                <label htmlFor="card_number" className="block text-sm font-medium text-gray-700 mb-1">Số thẻ mới (*)</label>
                                <input type="text" id="card_number" name="card_number" value={formData.card_number || ''} onChange={handleFormChange} required maxLength={12} pattern="\d{12}"
                                    className="w-full px-3 py-2 border border-gray-300 rounded-md"/>
                            </div>
                             {/* Loại thẻ */}
                             <div>
                                <label htmlFor="card_type" className="block text-sm font-medium text-gray-700 mb-1">Loại thẻ (*)</label>
                                <select id="card_type" name="card_type" value={formData.card_type || ''} onChange={handleFormChange} required
                                        className="w-full px-3 py-2 border border-gray-300 rounded-md bg-white">
                                    <option value="" disabled>-- Chọn --</option>
                                    {referenceData.cardTypes.map(t => <option key={t} value={t}>{t}</option>)}
                                </select>
                            </div>
                            {/* Ngày cấp */}
                            <div>
                                <label htmlFor="issue_date" className="block text-sm font-medium text-gray-700 mb-1">Ngày cấp (*)</label>
                                <input type="date" id="issue_date" name="issue_date" value={formData.issue_date || ''} onChange={handleFormChange} required
                                    className="w-full px-3 py-2 border border-gray-300 rounded-md"/>
                            </div>
                            {/* Ngày hết hạn */}
                            <div>
                                <label htmlFor="expiry_date" className="block text-sm font-medium text-gray-700 mb-1">Ngày hết hạn</label>
                                <input type="date" id="expiry_date" name="expiry_date" value={formData.expiry_date || ''} onChange={handleFormChange}
                                    className="w-full px-3 py-2 border border-gray-300 rounded-md"/>
                            </div>
                            {/* Nơi cấp */}
                            <div className="md:col-span-2">
                                <label htmlFor="issuing_authority_id" className="block text-sm font-medium text-gray-700 mb-1">Nơi cấp (*)</label>
                                <select id="issuing_authority_id" name="issuing_authority_id" value={formData.issuing_authority_id || ''} onChange={handleFormChange} required
                                        className="w-full px-3 py-2 border border-gray-300 rounded-md bg-white">
                                    <option value="" disabled>-- Chọn nơi cấp --</option>
                                    {referenceData.authorities.map(a => <option key={a.id} value={a.id}>{a.name}</option>)}
                                </select>
                            </div>
                             {/* Số thẻ cũ */}
                            <div>
                                <label htmlFor="previous_card_number" className="block text-sm font-medium text-gray-700 mb-1">Số thẻ cũ (nếu có)</label>
                                <input type="text" id="previous_card_number" name="previous_card_number" value={formData.previous_card_number || ''} onChange={handleFormChange} maxLength={12}
                                    className="w-full px-3 py-2 border border-gray-300 rounded-md"/>
                            </div>
                             {/* Mã chip */}
                            <div>
                                <label htmlFor="chip_id" className="block text-sm font-medium text-gray-700 mb-1">Mã chip (nếu có)</label>
                                <input type="text" id="chip_id" name="chip_id" value={formData.chip_id || ''} onChange={handleFormChange}
                                    className="w-full px-3 py-2 border border-gray-300 rounded-md"/>
                            </div>
                            {/* Ghi chú */}
                            <div className="md:col-span-2">
                                <label htmlFor="notes" className="block text-sm font-medium text-gray-700 mb-1">Ghi chú</label>
                                <textarea id="notes" name="notes" rows={2} value={formData.notes || ''} onChange={handleFormChange}
                                          className="w-full px-3 py-2 border border-gray-300 rounded-md"/>
                            </div>
                        </div>
                        {/* Modal Footer - Actions */}
                        <div className="flex items-center justify-end p-4 border-t space-x-2">
                             <button type="button" onClick={() => setShowForm(false)}
                                     className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md hover:bg-gray-50">
                                 Hủy bỏ
                             </button>
                             <button type="submit" disabled={isSaving}
                                     className="px-4 py-2 text-sm font-medium text-white bg-blue-700 rounded-md hover:bg-blue-800 disabled:opacity-50">
                                 {isSaving ? 'Đang lưu...' : 'Xác nhận cấp thẻ'}
                             </button>
                        </div>
                   </form>
                </div>
             </div>
         )}

      </div>

      {/* Footer */}
      {/* ... Footer tương tự OfficerHomepage ... */}
       <footer className="bg-gray-800 text-gray-300 py-6 mt-12">
         <div className="container mx-auto px-4 text-center text-sm">
            <p>© {new Date().getFullYear()} Hệ thống quản lý thông tin - Bộ Công An.</p>
          </div>
      </footer>
    </main>
  );
};

export default CCCDManagement;