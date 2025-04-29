'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import Image from 'next/image';

// --- Mock API Service ---
// (Giữ nguyên phần Mock API Service)
const api = {
  async searchHouseholds(criteria) { console.log("API Mock: Searching households with criteria:", criteria); await new Promise(resolve => setTimeout(resolve, 500)); const allHouseholds = [ { household_id: 1, household_book_no: 'HK123456', head_of_household_id: '001234567890', head_of_household_name: 'Nguyễn Văn A', address: 'Số 10, Ngõ 8, Đường Trần Hưng Đạo, Phường Cửa Nam, Quận Hoàn Kiếm, TP Hà Nội', registration_date: '2020-05-15', household_type: 'KT1', status: 'Đang hoạt động', region_id: 1, province_id: 1, district_id: 2, geographical_region: 'Thành thị' }, { household_id: 2, household_book_no: 'HK789012', head_of_household_id: '001876543210', head_of_household_name: 'Trần Thị B', address: 'Số 25, Ngõ 18, Đường Lê Duẩn, Phường Phan Chu Trinh, Quận Hoàn Kiếm, TP Hà Nội', registration_date: '2019-10-12', household_type: 'KT1', status: 'Đang hoạt động', region_id: 1, province_id: 1, district_id: 2, geographical_region: 'Thành thị' }, { household_id: 3, household_book_no: 'HK987654', head_of_household_id: '001112233445', head_of_household_name: 'Lê Văn C', address: 'Số 5, Đường Nguyễn Trãi, Phường Bến Thành, Quận 1, TP Hồ Chí Minh', registration_date: '2021-01-20', household_type: 'KT1', status: 'Đang hoạt động', region_id: 3, province_id: 2, district_id: 3, geographical_region: 'Thành thị' }, ]; return allHouseholds.filter(h => (!criteria.household_book_no || h.household_book_no.includes(criteria.household_book_no)) && (!criteria.head_of_household_name || h.head_of_household_name.toLowerCase().includes(criteria.head_of_household_name.toLowerCase())) && (!criteria.citizen_id || h.head_of_household_id.includes(criteria.citizen_id)) && (!criteria.province_id || h.province_id === parseInt(criteria.province_id)) && (!criteria.district_id || h.district_id === parseInt(criteria.district_id)) ); },
  async getHouseholdMembers(householdId) { console.log("API Mock: Getting members for household ID:", householdId); await new Promise(resolve => setTimeout(resolve, 300)); if (householdId === 1) { return [ { member_id: 101, citizen_id: '001234567890', full_name: 'Nguyễn Văn A', relationship_with_head: 'Chủ hộ', birth_date: '1980-05-20', gender: 'Nam', join_date: '2020-05-15', status: 'Active' }, { member_id: 102, citizen_id: '001234567891', full_name: 'Nguyễn Thị C', relationship_with_head: 'Vợ/Chồng', birth_date: '1982-08-15', gender: 'Nữ', join_date: '2020-05-15', status: 'Active' }, { member_id: 103, citizen_id: '001234567892', full_name: 'Nguyễn Văn D', relationship_with_head: 'Con', birth_date: '2010-01-10', gender: 'Nam', join_date: '2020-05-15', status: 'Active' }, ]; } else if (householdId === 2) { return [ { member_id: 201, citizen_id: '001876543210', full_name: 'Trần Thị B', relationship_with_head: 'Chủ hộ', birth_date: '1975-03-12', gender: 'Nữ', join_date: '2019-10-12', status: 'Active' }, { member_id: 202, citizen_id: '001876543211', full_name: 'Trần Văn E', relationship_with_head: 'Con', birth_date: '2005-11-25', gender: 'Nam', join_date: '2019-10-12', status: 'Active' }, ]; } else if (householdId === 3) { return [ { member_id: 301, citizen_id: '001112233445', full_name: 'Lê Văn C', relationship_with_head: 'Chủ hộ', birth_date: '1990-02-01', gender: 'Nam', join_date: '2021-01-20', status: 'Active' }, ]; } return []; },
  async addHouseholdMember(memberData) { console.log("API Mock: Adding member:", memberData); await new Promise(resolve => setTimeout(resolve, 500)); return { member_id: Math.floor(Math.random() * 10000) + 1000, citizen_id: memberData.citizen_id, full_name: memberData.full_name, relationship_with_head: memberData.relationship_with_head, birth_date: 'N/A', gender: 'N/A', join_date: memberData.join_date, status: 'Active' }; },
  async removeHouseholdMember(memberId, removalData) { console.log("API Mock: Removing member ID:", memberId, "Data:", removalData); await new Promise(resolve => setTimeout(resolve, 500)); return { success: true }; },
  async changeHeadOfHousehold(changeHeadData) { console.log("API Mock: Changing head of household:", changeHeadData); await new Promise(resolve => setTimeout(resolve, 1000)); return { success: true }; },
  async registerHousehold(householdData) { console.log("API Mock: Registering household:", householdData); await new Promise(resolve => setTimeout(resolve, 800)); return { household_id: Math.floor(Math.random() * 10000) + 100, ...householdData, status: 'Đang hoạt động' }; }
};
// --- End Mock API Service ---

// --- Mock Data for Dropdowns ---
// (Giữ nguyên phần Mock Data for Dropdowns)
const regions = [ { id: 1, name: 'Miền Bắc' }, { id: 2, name: 'Miền Trung' }, { id: 3, name: 'Miền Nam' }, ];
const provinces = [ { id: 1, name: 'Hà Nội', region_id: 1 }, { id: 2, name: 'TP. Hồ Chí Minh', region_id: 3 }, { id: 3, name: 'Đà Nẵng', region_id: 2 }, ];
const districts = [ { id: 1, name: 'Ba Đình', province_id: 1 }, { id: 2, name: 'Hoàn Kiếm', province_id: 1 }, { id: 3, name: 'Quận 1', province_id: 2 }, { id: 4, name: 'Quận 3', province_id: 2 }, { id: 5, name: 'Hải Châu', province_id: 3 }, ];
const householdTypes = [ { value: 'KT1', label: 'KT1 - Thường trú tại địa phương' }, { value: 'KT2', label: 'KT2 - Thường trú tỉnh khác' }, { value: 'KT3', label: 'KT3 - Tạm trú dài hạn' }, { value: 'KT4', label: 'KT4 - Tạm trú ngắn hạn' } ];
const authorities = [ { id: 1, name: 'Công an Phường Cửa Nam' }, { id: 2, name: 'Công an Phường Phan Chu Trinh' }, { id: 3, name: 'Công an Phường Bến Thành' }, ];
const relationshipTypes = [ { value: 'Chủ hộ', label: 'Chủ hộ' }, { value: 'Vợ/Chồng', label: 'Vợ/Chồng' }, { value: 'Con', label: 'Con' }, { value: 'Bố/Mẹ', label: 'Bố/Mẹ' }, { value: 'Ông/Bà', label: 'Ông/Bà' }, { value: 'Cháu', label: 'Cháu' }, { value: 'Anh/Chị/Em ruột', label: 'Anh/Chị/Em ruột' }, { value: 'Anh/Chị/Em họ', label: 'Anh/Chị/Em họ' }, { value: 'Khác', label: 'Khác (ghi rõ)' } ];
// --- End Mock Data ---

// --- Sample Data for Initialization ---
// (Giữ nguyên phần Sample Data)
const initialSelectedHousehold = { household_id: 1, household_book_no: 'HK123456', head_of_household_id: '001234567890', head_of_household_name: 'Nguyễn Văn A', address: 'Số 10, Ngõ 8, Đường Trần Hưng Đạo, Phường Cửa Nam, Quận Hoàn Kiếm, TP Hà Nội', registration_date: '2020-05-15', household_type: 'KT1', status: 'Đang hoạt động', region_id: 1, province_id: 1, district_id: 2, geographical_region: 'Thành thị' };
const initialHouseholdMembers = [ { member_id: 101, citizen_id: '001234567890', full_name: 'Nguyễn Văn A', relationship_with_head: 'Chủ hộ', birth_date: '1980-05-20', gender: 'Nam', join_date: '2020-05-15', status: 'Active' }, { member_id: 102, citizen_id: '001234567891', full_name: 'Nguyễn Thị C', relationship_with_head: 'Vợ/Chồng', birth_date: '1982-08-15', gender: 'Nữ', join_date: '2020-05-15', status: 'Active' }, { member_id: 103, citizen_id: '001234567892', full_name: 'Nguyễn Văn D', relationship_with_head: 'Con', birth_date: '2010-01-10', gender: 'Nam', join_date: '2020-05-15', status: 'Active' }, ];
// --- End Sample Data ---


export default function HoKhauPage() {
  // --- State Variables ---
  // (Giữ nguyên phần State Variables)
  const [activeTab, setActiveTab] = useState('manage');
  const [searchResults, setSearchResults] = useState([]);
  const [selectedHousehold, setSelectedHousehold] = useState(initialSelectedHousehold);
  const [householdMembers, setHouseholdMembers] = useState(initialHouseholdMembers);
  const [isSearching, setIsSearching] = useState(false);
  const [isLoadingMembers, setIsLoadingMembers] = useState(false);
  const [isAddingMember, setIsAddingMember] = useState(false);
  const [removingMemberId, setRemovingMemberId] = useState(null);
  const [isChangingHead, setIsChangingHead] = useState(false);
  const [isRegistering, setIsRegistering] = useState(false);
  const [searchForm, setSearchForm] = useState({ household_book_no: '', head_of_household_name: '', citizen_id: '', province_id: '', district_id: '', });
  const [newHouseholdForm, setNewHouseholdForm] = useState({ household_book_no: '', head_of_household_id: '', head_of_household_name: '', address_id: '', full_address: '', registration_date: '', issuing_authority_id: '', area_code: '', household_type: '', region_id: '', province_id: '', district_id: '', geographical_region: '', notes: '', });
  const [newMemberForm, setNewMemberForm] = useState({ citizen_id: '', full_name: '', relationship_with_head: '', join_date: '', order_in_household: '', });
  const [changeHeadForm, setChangeHeadForm] = useState({ new_head_id: '', effective_date: '', reason: '', });
  const [searchMessage, setSearchMessage] = useState({ type: '', text: '' });
  const [membersMessage, setMembersMessage] = useState({ type: '', text: '' });
  const [addMemberMessage, setAddMemberMessage] = useState({ type: '', text: '' });
  const [removeMemberMessage, setRemoveMemberMessage] = useState({ type: '', text: '' });
  const [changeHeadMessage, setChangeHeadMessage] = useState({ type: '', text: '' });
  const [registerMessage, setRegisterMessage] = useState({ type: '', text: '' });
  // --- End State Variables ---

  // --- Derived State ---
  // (Giữ nguyên phần Derived State)
  const filteredDistrictsForNew = newHouseholdForm.province_id ? districts.filter(district => district.province_id === parseInt(newHouseholdForm.province_id)) : [];
  const filteredDistrictsForSearch = searchForm.province_id ? districts.filter(district => district.province_id === parseInt(searchForm.province_id)) : [];
  // --- End Derived State ---

  // --- Event Handlers ---
  // (Giữ nguyên phần Event Handlers)
  const handleFormChange = (setter) => (e) => { const { name, value } = e.target; setter(prev => ({ ...prev, [name]: value })); };
  useEffect(() => { setSearchMessage({ type: '', text: '' }); setMembersMessage({ type: '', text: '' }); setAddMemberMessage({ type: '', text: '' }); setRemoveMemberMessage({ type: '', text: '' }); setChangeHeadMessage({ type: '', text: '' }); setRegisterMessage({ type: '', text: '' }); }, [activeTab, selectedHousehold]);
  const handleSearch = async (e) => { e.preventDefault(); setSearchMessage({ type: '', text: '' }); setSearchResults([]); setSelectedHousehold(null); setHouseholdMembers([]); setIsSearching(true); console.log('Searching with criteria:', searchForm); try { const results = await api.searchHouseholds(searchForm); setSearchResults(results); if (results.length === 0) { setSearchMessage({ type: 'info', text: 'Không tìm thấy kết quả phù hợp.' }); } else { setSearchMessage({ type: 'success', text: `Tìm thấy ${results.length} kết quả.` }); } } catch (error) { console.error('Error searching households:', error); setSearchMessage({ type: 'error', text: 'Lỗi khi tìm kiếm. Vui lòng thử lại.' }); } finally { setIsSearching(false); } };
  const handleSelectHousehold = async (household) => { if (selectedHousehold?.household_id === household.household_id) { return; } setSelectedHousehold(household); setHouseholdMembers([]); setMembersMessage({ type: '', text: '' }); setIsLoadingMembers(true); console.log('Selected household:', household); setNewMemberForm({ citizen_id: '', full_name: '', relationship_with_head: '', join_date: '', order_in_household: '', }); setChangeHeadForm({ new_head_id: '', effective_date: '', reason: '', }); try { const members = await api.getHouseholdMembers(household.household_id); setHouseholdMembers(members); if (members.length === 0) { setMembersMessage({ type: 'info', text: 'Hộ khẩu này chưa có thành viên nào.' }); } } catch (error) { console.error('Error fetching members:', error); setMembersMessage({ type: 'error', text: 'Lỗi khi tải danh sách thành viên.' }); } finally { setIsLoadingMembers(false); } };
  const handleAddNewHousehold = async (e) => { e.preventDefault(); setRegisterMessage({ type: '', text: '' }); setIsRegistering(true); console.log('Registering new household:', newHouseholdForm); try { if (!newHouseholdForm.household_book_no || !newHouseholdForm.head_of_household_id || !newHouseholdForm.head_of_household_name || !newHouseholdForm.full_address) { throw new Error("Vui lòng điền đầy đủ các trường bắt buộc (*)."); } const result = await api.registerHousehold(newHouseholdForm); setRegisterMessage({ type: 'success', text: `Đã đăng ký thành công hộ khẩu mới với số sổ: ${result.household_book_no}` }); setNewHouseholdForm({ household_book_no: '', head_of_household_id: '', head_of_household_name: '', address_id: '', full_address: '', registration_date: '', issuing_authority_id: '', area_code: '', household_type: '', region_id: '', province_id: '', district_id: '', geographical_region: '', notes: '', }); } catch (error) { console.error('Error registering household:', error); setRegisterMessage({ type: 'error', text: `Lỗi đăng ký: ${error.message}` }); } finally { setIsRegistering(false); } };
  const handleAddNewMember = async (e) => { e.preventDefault(); if (!selectedHousehold) { setAddMemberMessage({ type: 'error', text: 'Vui lòng chọn hộ khẩu trước.' }); return; } setAddMemberMessage({ type: '', text: '' }); setIsAddingMember(true); if (!newMemberForm.citizen_id || !newMemberForm.full_name || !newMemberForm.relationship_with_head || !newMemberForm.join_date) { setAddMemberMessage({ type: 'error', text: 'Vui lòng điền đầy đủ thông tin thành viên mới (*).' }); setIsAddingMember(false); return; } if (householdMembers.some(m => m.citizen_id === newMemberForm.citizen_id)) { setAddMemberMessage({ type: 'error', text: 'Số CCCD/CMND này đã tồn tại trong hộ khẩu.' }); setIsAddingMember(false); return; } const memberData = { household_id: selectedHousehold.household_id, ...newMemberForm, region_id: selectedHousehold.region_id, province_id: selectedHousehold.province_id, geographical_region: selectedHousehold.geographical_region }; console.log('Adding new member:', memberData); try { const newMember = await api.addHouseholdMember(memberData); setHouseholdMembers(prevMembers => [...prevMembers, newMember]); setAddMemberMessage({ type: 'success', text: `Đã thêm thành công thành viên: ${newMember.full_name}` }); setNewMemberForm({ citizen_id: '', full_name: '', relationship_with_head: '', join_date: '', order_in_household: '', }); } catch (error) { console.error('Error adding member:', error); setAddMemberMessage({ type: 'error', text: `Lỗi khi thêm thành viên: ${error.message}` }); } finally { setIsAddingMember(false); } };
  const handleRemoveMember = async (memberIdToRemove, memberName) => { if (!window.confirm(`Bạn có chắc muốn xóa thành viên "${memberName}" khỏi hộ khẩu này?`)) { return; } if (!selectedHousehold) return; setRemoveMemberMessage({ type: '', text: '' }); setRemovingMemberId(memberIdToRemove); const memberToRemove = householdMembers.find(m => m.member_id === memberIdToRemove); if (!memberToRemove) { setRemoveMemberMessage({ type: 'error', text: 'Không tìm thấy thành viên để xóa.' }); setRemovingMemberId(null); return; } const removalData = { household_id: selectedHousehold.household_id, citizen_id: memberToRemove.citizen_id, leave_date: new Date().toISOString().split('T')[0], leave_reason: "Xóa khỏi hộ khẩu (Yêu cầu từ giao diện)" }; console.log('Removing member:', removalData); try { await api.removeHouseholdMember(memberIdToRemove, removalData); setHouseholdMembers(prevMembers => prevMembers.filter(member => member.member_id !== memberIdToRemove)); setRemoveMemberMessage({ type: 'success', text: `Đã xóa thành công thành viên: ${memberName}` }); } catch (error) { console.error('Error removing member:', error); setRemoveMemberMessage({ type: 'error', text: `Lỗi khi xóa thành viên: ${error.message}` }); } finally { setRemovingMemberId(null); } };
  const handleChangeHead = async (e) => { e.preventDefault(); if (!selectedHousehold) { setChangeHeadMessage({ type: 'error', text: 'Vui lòng chọn hộ khẩu trước.' }); return; } setChangeHeadMessage({ type: '', text: '' }); setIsChangingHead(true); if (!changeHeadForm.new_head_id || !changeHeadForm.effective_date || !changeHeadForm.reason) { setChangeHeadMessage({ type: 'error', text: 'Vui lòng chọn chủ hộ mới, ngày thay đổi và nhập lý do (*).' }); setIsChangingHead(false); return; } const newHead = householdMembers.find(m => m.citizen_id === changeHeadForm.new_head_id); const oldHead = householdMembers.find(m => m.relationship_with_head === 'Chủ hộ'); if (!newHead) { setChangeHeadMessage({ type: 'error', text: 'Không tìm thấy thông tin thành viên được chọn làm chủ hộ mới.' }); setIsChangingHead(false); return; } const changeHeadData = { household_id: selectedHousehold.household_id, old_head_id: selectedHousehold.head_of_household_id, new_head_id: changeHeadForm.new_head_id, effective_date: changeHeadForm.effective_date, reason: changeHeadForm.reason, region_id: selectedHousehold.region_id, province_id: selectedHousehold.province_id, geographical_region: selectedHousehold.geographical_region, }; console.log('Changing head of household:', changeHeadData); try { await api.changeHeadOfHousehold(changeHeadData); const updatedSelectedHousehold = { ...selectedHousehold, head_of_household_id: newHead.citizen_id, head_of_household_name: newHead.full_name, }; setSelectedHousehold(updatedSelectedHousehold); setHouseholdMembers(prevMembers => { return prevMembers.map(member => { if (member.citizen_id === newHead.citizen_id) { return { ...member, relationship_with_head: 'Chủ hộ' }; } else if (member.citizen_id === oldHead?.citizen_id) { return { ...member, relationship_with_head: 'Thành viên khác' }; } else { return member; } }); }); setChangeHeadMessage({ type: 'success', text: `Đã thay đổi chủ hộ thành công! Chủ hộ mới: ${newHead.full_name}` }); setChangeHeadForm({ new_head_id: '', effective_date: '', reason: '', }); } catch (error) { console.error('Error changing head:', error); setChangeHeadMessage({ type: 'error', text: `Lỗi khi thay đổi chủ hộ: ${error.message}` }); } finally { setIsChangingHead(false); } };
  // --- End Event Handlers ---

  // --- Helper Function to Render Messages ---
  // (Giữ nguyên phần Render Message)
  const renderMessage = (message) => { if (!message || !message.text) return null; const baseClasses = "px-4 py-3 rounded mb-4 text-sm"; let specificClasses = ""; if (message.type === 'error') { specificClasses = "bg-red-100 border border-red-300 text-red-800"; } else if (message.type === 'success') { specificClasses = "bg-green-100 border border-green-300 text-green-800"; } else { specificClasses = "bg-blue-100 border border-blue-300 text-blue-800"; } return <div className={`${baseClasses} ${specificClasses}`}>{message.text}</div>; };
  // --- End Helper Function ---

  // Define base input classes - REMOVED conflicting bg/text classes
  const baseInputClasses = "w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500 focus:border-transparent text-sm";
  const baseSelectClasses = `${baseInputClasses} bg-white`;
  const baseTextareaClasses = `${baseInputClasses}`;
  const fileInputClasses = "w-full text-sm";
  const disabledInputClasses = `${baseInputClasses} bg-gray-100 cursor-not-allowed`;

  // Define base text classes for tables and details - Ensure dark text
  const tableCellClasses = "py-2 px-3 border-b border-gray-200 text-gray-900"; // Ensure dark text for table cells
  const tableHeaderClasses = "py-2 px-3 border-b text-left font-medium text-gray-600"; // Headers can be slightly lighter gray
  const detailLabelClasses = "font-medium text-gray-600"; // Labels in details section
  const detailValueClasses = "text-gray-900"; // Ensure dark text for values in details section

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Header */}
      {/* (Giữ nguyên Header) */}
      <header className="bg-white shadow-md sticky top-0 z-10"> <div className="container mx-auto px-4 py-4 flex items-center"> <div className="flex items-center"> <div className="w-12 h-12 relative mr-3"> <Image src="/logo.png" alt="Logo Bộ Tư Pháp" width={48} height={48} className="object-contain" onError={(e) => { e.target.onerror = null; e.target.src='https://placehold.co/48x48/d1d5db/374151?text=Logo'; }} /> </div> <div> <h1 className="text-xl font-bold text-red-600">CỔNG DỊCH VỤ CÔNG</h1> <h2 className="text-lg text-blue-800">BỘ TƯ PHÁP VIỆT NAM</h2> </div> </div> <nav className="ml-auto"> <ul className="flex space-x-4 md:space-x-6 text-sm md:text-base"> <li><Link href="/" className="text-gray-700 hover:text-blue-600">Trang chủ</Link></li> <li><a href="#" className="text-gray-700 hover:text-blue-600">Dịch vụ</a></li> <li><a href="#" className="text-gray-700 hover:text-blue-600">Hướng dẫn</a></li> <li><a href="#" className="text-gray-700 hover:text-blue-600">Liên hệ</a></li> </ul> </nav> </div> </header>

      {/* Main Content */}
      <div className="container mx-auto px-4 py-8">
        {/* Breadcrumbs */}
        {/* (Giữ nguyên Breadcrumbs) */}
        <div className="flex items-center mb-6 text-sm"> <Link href="/" className="text-blue-600 hover:text-blue-800"> ← Trang chủ </Link> <span className="mx-2 text-gray-500">/</span> <span className="text-gray-700">Quản lý Hộ khẩu</span> </div>

        {/* Main Card */}
        <div className="bg-white shadow-lg rounded-lg overflow-hidden">
          {/* Card Header */}
          {/* (Giữ nguyên Card Header) */}
          <div className="bg-gradient-to-r from-green-600 to-green-800 text-white p-6"> <h1 className="text-2xl md:text-3xl font-bold">QUẢN LÝ HỘ KHẨU</h1> <p className="text-base md:text-lg mt-1 opacity-90">Tra cứu, đăng ký mới, quản lý thông tin và thành viên hộ khẩu</p> </div>

          {/* Tabs Navigation */}
          {/* (Giữ nguyên Tabs Navigation) */}
          <div className="bg-gray-100 border-b border-gray-200"> <div className="container mx-auto px-2 md:px-0"> <ul className="flex flex-wrap -mb-px"> <li className="mr-1"> <button className={`inline-block px-4 py-3 text-sm md:text-base font-medium rounded-t-lg border-b-2 ${activeTab === 'search' ? 'text-green-600 border-green-600' : 'text-gray-500 border-transparent hover:text-gray-700 hover:border-gray-300'}`} onClick={() => setActiveTab('search')} > Tra cứu hộ khẩu </button> </li> <li className="mr-1"> <button className={`inline-block px-4 py-3 text-sm md:text-base font-medium rounded-t-lg border-b-2 ${activeTab === 'register' ? 'text-green-600 border-green-600' : 'text-gray-500 border-transparent hover:text-gray-700 hover:border-gray-300'}`} onClick={() => setActiveTab('register')} > Đăng ký mới </button> </li> <li className="mr-1"> <button className={`inline-block px-4 py-3 text-sm md:text-base font-medium rounded-t-lg border-b-2 ${activeTab === 'manage' ? 'text-green-600 border-green-600' : 'text-gray-500 border-transparent hover:text-gray-700 hover:border-gray-300'} ${!selectedHousehold ? 'opacity-50 cursor-not-allowed' : ''}`} onClick={() => selectedHousehold && setActiveTab('manage')} disabled={!selectedHousehold} > Quản lý thành viên {!selectedHousehold && <span className="hidden md:inline text-xs text-gray-400 italic ml-1">(Chọn hộ khẩu)</span>} </button> </li> <li className="mr-1"> <button className={`inline-block px-4 py-3 text-sm md:text-base font-medium rounded-t-lg border-b-2 ${activeTab === 'change-head' ? 'text-green-600 border-green-600' : 'text-gray-500 border-transparent hover:text-gray-700 hover:border-gray-300'} ${!selectedHousehold ? 'opacity-50 cursor-not-allowed' : ''}`} onClick={() => selectedHousehold && setActiveTab('change-head')} disabled={!selectedHousehold} > Thay đổi chủ hộ {!selectedHousehold && <span className="hidden md:inline text-xs text-gray-400 italic ml-1">(Chọn hộ khẩu)</span>} </button> </li> </ul> </div> </div>

          {/* Tab Content Area */}
          <div className="p-4 md:p-6">
            {/* --- Search Tab --- */}
            {activeTab === 'search' && (
              <div>
                <h2 className="text-xl font-semibold text-gray-800 mb-4">Tra cứu thông tin hộ khẩu</h2>
                {renderMessage(searchMessage)}

                {/* Search Form */}
                <form onSubmit={handleSearch} className="bg-gray-50 p-4 md:p-6 rounded-lg mb-6 border border-gray-200">
                   {/* Search form fields using base classes */}
                   <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    <div className="form-group"> <label className="block text-gray-700 text-sm font-medium mb-1">Số sổ hộ khẩu:</label> <input type="text" name="household_book_no" value={searchForm.household_book_no} onChange={handleFormChange(setSearchForm)} className={baseInputClasses} placeholder="Nhập số sổ" /> </div>
                    <div className="form-group"> <label className="block text-gray-700 text-sm font-medium mb-1">Họ tên chủ hộ:</label> <input type="text" name="head_of_household_name" value={searchForm.head_of_household_name} onChange={handleFormChange(setSearchForm)} className={baseInputClasses} placeholder="Nhập họ tên" /> </div>
                    <div className="form-group"> <label className="block text-gray-700 text-sm font-medium mb-1">Số CCCD/CMND:</label> <input type="text" name="citizen_id" value={searchForm.citizen_id} onChange={handleFormChange(setSearchForm)} className={baseInputClasses} placeholder="CCCD/CMND chủ hộ/thành viên" /> </div>
                    <div className="form-group"> <label className="block text-gray-700 text-sm font-medium mb-1">Tỉnh/Thành phố:</label> <select name="province_id" value={searchForm.province_id} onChange={handleFormChange(setSearchForm)} className={baseSelectClasses}> <option value="">Tất cả</option> {provinces.map(p => <option key={p.id} value={p.id}>{p.name}</option>)} </select> </div>
                    <div className="form-group"> <label className="block text-gray-700 text-sm font-medium mb-1">Quận/Huyện:</label> <select name="district_id" value={searchForm.district_id} onChange={handleFormChange(setSearchForm)} className={baseSelectClasses} disabled={!searchForm.province_id}> <option value="">Tất cả</option> {filteredDistrictsForSearch.map(d => <option key={d.id} value={d.id}>{d.name}</option>)} </select> </div>
                   </div>
                   <div className="mt-5 text-center"> <button type="submit" className="bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-6 rounded-md shadow-md transition-colors disabled:opacity-50" disabled={isSearching}> {isSearching ? ( <span className="flex items-center justify-center"> <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle><path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg> Đang tìm... </span> ) : "Tìm kiếm"} </button> </div>
                </form>

                {/* Search Results Table - Apply tableCellClasses */}
                {searchResults.length > 0 && (
                  <div className="mt-6">
                    <h3 className="text-lg font-semibold text-gray-800 mb-3">Kết quả tìm kiếm ({searchResults.length})</h3>
                    <div className="overflow-x-auto border border-gray-200 rounded-lg">
                      <table className="min-w-full bg-white text-sm">
                        <thead className="bg-gray-100">
                          <tr>
                            <th className={tableHeaderClasses}>Số sổ HK</th>
                            <th className={tableHeaderClasses}>Chủ hộ</th>
                            <th className={tableHeaderClasses}>Địa chỉ</th>
                            <th className={tableHeaderClasses}>Loại HK</th>
                            <th className={`${tableHeaderClasses} text-center`}>Trạng thái</th>
                            <th className={`${tableHeaderClasses} text-center`}>Thao tác</th>
                          </tr>
                        </thead>
                        <tbody>
                          {searchResults.map((household) => (
                            <tr key={household.household_id} className={`hover:bg-gray-50 ${selectedHousehold?.household_id === household.household_id ? 'bg-green-50' : ''}`}>
                              <td className={tableCellClasses}>{household.household_book_no}</td>
                              <td className={tableCellClasses}>{household.head_of_household_name}</td>
                              <td className={tableCellClasses}>{household.address}</td>
                              <td className={tableCellClasses}>{household.household_type}</td>
                              <td className={`${tableCellClasses} text-center`}>
                                <span className="px-2 py-1 rounded-full text-xs bg-green-100 text-green-800 font-medium">{household.status}</span>
                              </td>
                              <td className={`${tableCellClasses} text-center`}>
                                <button onClick={() => handleSelectHousehold(household)} className="bg-blue-600 hover:bg-blue-700 text-white px-3 py-1 rounded text-xs font-medium transition-colors" >
                                  {selectedHousehold?.household_id === household.household_id ? 'Đã chọn' : 'Chọn'}
                                </button>
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div>
                )}

                {/* Selected Household Details - Apply detail classes */}
                 {selectedHousehold && (
                  <div className="mt-6 p-4 border border-blue-200 bg-blue-50 rounded-lg">
                    <h3 className="text-lg font-semibold text-blue-800 mb-3">Hộ khẩu đang chọn</h3>
                     <div className="grid grid-cols-1 md:grid-cols-2 gap-x-4 gap-y-2 text-sm">
                       <div><span className={detailLabelClasses}>Số sổ HK:</span> <span className={detailValueClasses}>{selectedHousehold.household_book_no}</span></div>
                       <div><span className={detailLabelClasses}>Chủ hộ:</span> <span className={detailValueClasses}>{selectedHousehold.head_of_household_name}</span></div>
                       <div><span className={detailLabelClasses}>CCCD Chủ hộ:</span> <span className={detailValueClasses}>{selectedHousehold.head_of_household_id}</span></div>
                       <div><span className={detailLabelClasses}>Ngày ĐK:</span> <span className={detailValueClasses}>{selectedHousehold.registration_date}</span></div>
                       <div className="md:col-span-2"><span className={detailLabelClasses}>Địa chỉ:</span> <span className={detailValueClasses}>{selectedHousehold.address}</span></div>
                     </div>
                     <div className="mt-3">
                         <button onClick={() => setActiveTab('manage')} className="bg-blue-600 hover:bg-blue-700 text-white font-bold py-1 px-3 rounded-md shadow-sm transition-colors text-xs mr-2" > Xem/Quản lý Thành viên </button>
                         <button onClick={() => setActiveTab('change-head')} className="bg-orange-500 hover:bg-orange-600 text-white font-bold py-1 px-3 rounded-md shadow-sm transition-colors text-xs" > Thay đổi Chủ hộ </button>
                     </div>
                  </div>
                )}
                 {isLoadingMembers && <div className="mt-4 text-center text-gray-600">Đang tải thông tin thành viên...</div>}
                 {renderMessage(membersMessage)}
              </div>
            )}

            {/* --- Register New Household Tab --- */}
            {activeTab === 'register' && (
              <div>
                 {/* Form fields use base classes */}
                 <h2 className="text-xl font-semibold text-gray-800 mb-4">Đăng ký hộ khẩu mới</h2>
                 {renderMessage(registerMessage)}
                 <form onSubmit={handleAddNewHousehold} className="bg-gray-50 p-4 md:p-6 rounded-lg border border-gray-200 space-y-6">
                   <div> <h3 className="text-lg font-medium text-gray-700 border-b pb-2 mb-4">Thông tin cơ bản</h3> <div className="grid grid-cols-1 md:grid-cols-2 gap-4"> <div className="form-group"> <label className="block text-gray-700 text-sm font-medium mb-1">Số sổ hộ khẩu: <span className="text-red-500">*</span></label> <input type="text" name="household_book_no" value={newHouseholdForm.household_book_no} onChange={handleFormChange(setNewHouseholdForm)} className={baseInputClasses} required /> </div> <div className="form-group"> <label className="block text-gray-700 text-sm font-medium mb-1">Loại hộ khẩu: <span className="text-red-500">*</span></label> <select name="household_type" value={newHouseholdForm.household_type} onChange={handleFormChange(setNewHouseholdForm)} className={baseSelectClasses} required> <option value="">Chọn loại</option> {householdTypes.map(t => <option key={t.value} value={t.value}>{t.label}</option>)} </select> </div> <div className="form-group"> <label className="block text-gray-700 text-sm font-medium mb-1">Ngày đăng ký: <span className="text-red-500">*</span></label> <input type="date" name="registration_date" value={newHouseholdForm.registration_date} onChange={handleFormChange(setNewHouseholdForm)} className={baseInputClasses} required /> </div> <div className="form-group"> <label className="block text-gray-700 text-sm font-medium mb-1">Cơ quan cấp: <span className="text-red-500">*</span></label> <select name="issuing_authority_id" value={newHouseholdForm.issuing_authority_id} onChange={handleFormChange(setNewHouseholdForm)} className={baseSelectClasses} required> <option value="">Chọn cơ quan</option> {authorities.map(a => <option key={a.id} value={a.id}>{a.name}</option>)} </select> </div> <div className="form-group"> <label className="block text-gray-700 text-sm font-medium mb-1">Mã khu vực:</label> <input type="text" name="area_code" value={newHouseholdForm.area_code} onChange={handleFormChange(setNewHouseholdForm)} className={baseInputClasses} placeholder="Nếu có"/> </div> </div> </div>
                   <div> <h3 className="text-lg font-medium text-gray-700 border-b pb-2 mb-4">Thông tin chủ hộ</h3> <div className="grid grid-cols-1 md:grid-cols-2 gap-4"> <div className="form-group"> <label className="block text-gray-700 text-sm font-medium mb-1">Số CCCD/CMND: <span className="text-red-500">*</span></label> <input type="text" name="head_of_household_id" value={newHouseholdForm.head_of_household_id} onChange={handleFormChange(setNewHouseholdForm)} className={baseInputClasses} required /> </div> <div className="form-group"> <label className="block text-gray-700 text-sm font-medium mb-1">Họ tên: <span className="text-red-500">*</span></label> <input type="text" name="head_of_household_name" value={newHouseholdForm.head_of_household_name} onChange={handleFormChange(setNewHouseholdForm)} className={baseInputClasses} required /> </div> </div> </div>
                   <div> <h3 className="text-lg font-medium text-gray-700 border-b pb-2 mb-4">Địa chỉ thường trú</h3> <div className="grid grid-cols-1 md:grid-cols-3 gap-4"> <div className="form-group"> <label className="block text-gray-700 text-sm font-medium mb-1">Khu vực: <span className="text-red-500">*</span></label> <select name="region_id" value={newHouseholdForm.region_id} onChange={handleFormChange(setNewHouseholdForm)} className={baseSelectClasses} required> <option value="">Chọn khu vực</option> {regions.map(r => <option key={r.id} value={r.id}>{r.name}</option>)} </select> </div> <div className="form-group"> <label className="block text-gray-700 text-sm font-medium mb-1">Tỉnh/Thành phố: <span className="text-red-500">*</span></label> <select name="province_id" value={newHouseholdForm.province_id} onChange={handleFormChange(setNewHouseholdForm)} className={baseSelectClasses} required> <option value="">Chọn tỉnh/thành</option> {provinces.map(p => <option key={p.id} value={p.id}>{p.name}</option>)} </select> </div> <div className="form-group"> <label className="block text-gray-700 text-sm font-medium mb-1">Quận/Huyện: <span className="text-red-500">*</span></label> <select name="district_id" value={newHouseholdForm.district_id} onChange={handleFormChange(setNewHouseholdForm)} className={baseSelectClasses} required disabled={!newHouseholdForm.province_id}> <option value="">Chọn quận/huyện</option> {filteredDistrictsForNew.map(d => <option key={d.id} value={d.id}>{d.name}</option>)} </select> </div> <div className="form-group"> <label className="block text-gray-700 text-sm font-medium mb-1">Vùng địa lý: <span className="text-red-500">*</span></label> <select name="geographical_region" value={newHouseholdForm.geographical_region} onChange={handleFormChange(setNewHouseholdForm)} className={baseSelectClasses} required> <option value="">Chọn vùng</option> <option value="Đồng bằng">Đồng bằng</option> <option value="Trung du miền núi">Trung du miền núi</option> <option value="Thành thị">Thành thị</option> <option value="Nông thôn">Nông thôn</option> <option value="Hải đảo">Hải đảo</option> </select> </div> <div className="form-group md:col-span-2"> <label className="block text-gray-700 text-sm font-medium mb-1">Địa chỉ chi tiết: <span className="text-red-500">*</span></label> <textarea name="full_address" value={newHouseholdForm.full_address} onChange={handleFormChange(setNewHouseholdForm)} className={baseTextareaClasses} rows="2" placeholder="Số nhà, đường, phường/xã..." required></textarea> </div> </div> </div>
                   <div> <h3 className="text-lg font-medium text-gray-700 border-b pb-2 mb-4">Thông tin bổ sung</h3> <div className="form-group"> <label className="block text-gray-700 text-sm font-medium mb-1">Ghi chú:</label> <textarea name="notes" value={newHouseholdForm.notes} onChange={handleFormChange(setNewHouseholdForm)} className={baseTextareaClasses} rows="3" placeholder="Thông tin thêm (nếu có)"></textarea> </div> </div>
                   <div> <h3 className="text-lg font-medium text-gray-700 border-b pb-2 mb-4">Tài liệu đính kèm</h3> <div className="space-y-3"> <div className="form-group"> <label className="block text-gray-700 text-sm font-medium mb-1">Giấy tờ nhân thân chủ hộ: <span className="text-red-500">*</span></label> <input type="file" className={fileInputClasses} required /> </div> <div className="form-group"> <label className="block text-gray-700 text-sm font-medium mb-1">Giấy tờ chứng minh chỗ ở: <span className="text-red-500">*</span></label> <input type="file" className={fileInputClasses} required /> </div> </div> </div>
                   <div className="flex items-start"> <input id="consent-register" type="checkbox" className="h-4 w-4 text-green-600 mt-0.5 border-gray-300 rounded" required /> <label htmlFor="consent-register" className="ml-2 text-sm text-gray-700"> Tôi xin cam đoan những thông tin khai trên là đúng sự thật và chịu trách nhiệm trước pháp luật. </label> </div>
                   <div className="text-center pt-4"> <button type="submit" className="bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-8 rounded-md shadow-md transition-colors disabled:opacity-50" disabled={isRegistering}> {isRegistering ? ( <span className="flex items-center justify-center"> <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle><path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg> Đang đăng ký... </span> ) : "Đăng ký hộ khẩu"} </button> </div>
                 </form>
              </div>
            )}

            {/* --- Manage Members Tab --- */}
            {activeTab === 'manage' && (
              <div>
                <h2 className="text-xl font-semibold text-gray-800 mb-4">Quản lý thành viên hộ khẩu</h2>

                {!selectedHousehold ? (
                  <div className="bg-yellow-100 border border-yellow-300 text-yellow-800 px-4 py-3 rounded text-sm">
                    Vui lòng chọn một hộ khẩu từ mục "Tra cứu hộ khẩu" để quản lý thành viên.
                  </div>
                ) : (
                  <div className="space-y-6">
                    {/* Selected Household Info - Apply detail classes */}
                    <div className="bg-blue-50 p-4 rounded-lg border border-blue-200">
                      <h3 className="font-semibold mb-2 text-blue-800">Hộ khẩu đang chọn:</h3>
                      <p className="text-sm"><span className={detailLabelClasses}>Số sổ HK:</span> <span className={detailValueClasses}>{selectedHousehold.household_book_no}</span> | <span className={detailLabelClasses}>Chủ hộ:</span> <span className={detailValueClasses}>{selectedHousehold.head_of_household_name}</span></p>
                    </div>

                    {/* Messages for this section */}
                    {renderMessage(addMemberMessage)}
                    {renderMessage(removeMemberMessage)}
                    {renderMessage(membersMessage)}


                    {/* Current Members Table - Apply tableCellClasses */}
                    <div>
                      <h3 className="text-lg font-medium text-gray-700 mb-3">Danh sách thành viên hiện tại</h3>
                       {isLoadingMembers ? ( <div className="text-center text-gray-500 py-4">Đang tải...</div> ) : householdMembers.length === 0 && !membersMessage.text ? ( <div className="text-center text-gray-500 py-4 italic">Hộ khẩu này chưa có thành viên.</div> ) : (
                        <div className="overflow-x-auto border border-gray-200 rounded-lg">
                          <table className="min-w-full bg-white text-sm">
                             <thead className="bg-gray-100">
                              <tr>
                                <th className={tableHeaderClasses}>CCCD/CMND</th>
                                <th className={tableHeaderClasses}>Họ tên</th>
                                <th className={tableHeaderClasses}>Quan hệ</th>
                                <th className={tableHeaderClasses}>Ngày sinh</th>
                                <th className={tableHeaderClasses}>Giới tính</th>
                                <th className={tableHeaderClasses}>Ngày nhập hộ</th>
                                <th className={`${tableHeaderClasses} text-center`}>Thao tác</th>
                              </tr>
                            </thead>
                            <tbody>
                              {householdMembers.map((member) => (
                                <tr key={member.member_id} className="hover:bg-gray-50">
                                  <td className={tableCellClasses}>{member.citizen_id}</td>
                                  <td className={tableCellClasses}>{member.full_name}</td>
                                  <td className={tableCellClasses}>
                                    <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${member.relationship_with_head === 'Chủ hộ' ? 'bg-blue-100 text-blue-800' : 'bg-gray-100 text-gray-800'}`}>
                                      {member.relationship_with_head}
                                    </span>
                                  </td>
                                  <td className={tableCellClasses}>{member.birth_date}</td>
                                  <td className={tableCellClasses}>{member.gender}</td>
                                  <td className={tableCellClasses}>{member.join_date}</td>
                                  <td className={`${tableCellClasses} text-center`}>
                                    {member.relationship_with_head !== 'Chủ hộ' && (
                                      <button onClick={() => handleRemoveMember(member.member_id, member.full_name)} className="text-red-600 hover:text-red-800 text-xs font-medium disabled:opacity-50 disabled:cursor-wait" disabled={removingMemberId === member.member_id} >
                                        {removingMemberId === member.member_id ? 'Đang xóa...' : 'Xóa'}
                                      </button>
                                    )}
                                  </td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>
                       )}
                    </div>

                    {/* Add New Member Form - Apply base classes */}
                    <div className="bg-gray-50 p-4 md:p-6 rounded-lg border border-gray-200">
                      <h3 className="text-lg font-medium text-gray-700 mb-4">Thêm thành viên mới</h3>
                      <form onSubmit={handleAddNewMember} className="space-y-4">
                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                          <div className="form-group"> <label className="block text-gray-700 text-sm font-medium mb-1">Số CCCD/CMND: <span className="text-red-500">*</span></label> <input type="text" name="citizen_id" value={newMemberForm.citizen_id} onChange={handleFormChange(setNewMemberForm)} className={baseInputClasses} required /> </div>
                          <div className="form-group"> <label className="block text-gray-700 text-sm font-medium mb-1">Họ tên: <span className="text-red-500">*</span></label> <input type="text" name="full_name" value={newMemberForm.full_name} onChange={handleFormChange(setNewMemberForm)} className={baseInputClasses} required /> </div>
                          <div className="form-group"> <label className="block text-gray-700 text-sm font-medium mb-1">Quan hệ với chủ hộ: <span className="text-red-500">*</span></label> <select name="relationship_with_head" value={newMemberForm.relationship_with_head} onChange={handleFormChange(setNewMemberForm)} className={baseSelectClasses} required> <option value="">Chọn quan hệ</option> {relationshipTypes.filter(rt => rt.value !== 'Chủ hộ').map(t => <option key={t.value} value={t.value}>{t.label}</option>)} </select> </div>
                          <div className="form-group"> <label className="block text-gray-700 text-sm font-medium mb-1">Ngày nhập hộ: <span className="text-red-500">*</span></label> <input type="date" name="join_date" value={newMemberForm.join_date} onChange={handleFormChange(setNewMemberForm)} className={baseInputClasses} required /> </div>
                          <div className="form-group"> <label className="block text-gray-700 text-sm font-medium mb-1">Thứ tự trong sổ:</label> <input type="number" name="order_in_household" value={newMemberForm.order_in_household} onChange={handleFormChange(setNewMemberForm)} className={baseInputClasses} min="1"/> </div>
                          <div className="form-group lg:col-span-3"> <label className="block text-gray-700 text-sm font-medium mb-1">Giấy tờ đính kèm (CCCD/Giấy khai sinh...):</label> <input type="file" className={fileInputClasses} /> </div>
                        </div>
                        <div className="text-center pt-2"> <button type="submit" className="bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-6 rounded-md shadow-md transition-colors disabled:opacity-50" disabled={isAddingMember}> {isAddingMember ? ( <span className="flex items-center justify-center"> <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle><path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg> Đang thêm... </span> ) : "Thêm thành viên"} </button> </div>
                      </form>
                    </div>
                  </div>
                )}
              </div>
            )}

            {/* --- Change Head of Household Tab --- */}
            {activeTab === 'change-head' && (
              <div>
                <h2 className="text-xl font-semibold text-gray-800 mb-4">Thay đổi chủ hộ</h2>

                 {!selectedHousehold ? (
                  <div className="bg-yellow-100 border border-yellow-300 text-yellow-800 px-4 py-3 rounded text-sm">
                    Vui lòng chọn một hộ khẩu từ mục "Tra cứu hộ khẩu" để thay đổi chủ hộ.
                  </div>
                ) : (
                   <div className="space-y-6">
                     {/* Selected Household Info - Apply detail classes */}
                     <div className="bg-blue-50 p-4 rounded-lg border border-blue-200">
                       <h3 className="font-semibold mb-2 text-blue-800">Hộ khẩu đang chọn:</h3>
                       <p className="text-sm"><span className={detailLabelClasses}>Số sổ HK:</span> <span className={detailValueClasses}>{selectedHousehold.household_book_no}</span> | <span className={detailLabelClasses}>Chủ hộ hiện tại:</span> <span className={detailValueClasses}>{selectedHousehold.head_of_household_name} ({selectedHousehold.head_of_household_id})</span></p>
                     </div>

                     {/* Messages for this section */}
                    {renderMessage(changeHeadMessage)}

                     {/* Member Selection Table - Apply tableCellClasses */}
                    <div>
                      <h3 className="text-lg font-medium text-gray-700 mb-3">Chọn chủ hộ mới</h3>
                      <p className="text-sm text-gray-600 mb-3">Chọn một thành viên trong danh sách dưới đây để làm chủ hộ mới. Thành viên phải có đủ điều kiện theo quy định.</p>
                       {isLoadingMembers ? ( <div className="text-center text-gray-500 py-4">Đang tải danh sách thành viên...</div> ) : householdMembers.filter(m => m.relationship_with_head !== 'Chủ hộ').length === 0 ? ( <div className="text-center text-gray-500 py-4 italic">Không có thành viên nào khác trong hộ khẩu để chọn làm chủ hộ mới.</div> ) : (
                        <div className="overflow-x-auto border border-gray-200 rounded-lg">
                          <table className="min-w-full bg-white text-sm">
                             <thead className="bg-gray-100">
                              <tr>
                                <th className={tableHeaderClasses}>CCCD/CMND</th>
                                <th className={tableHeaderClasses}>Họ tên</th>
                                <th className={tableHeaderClasses}>Quan hệ</th>
                                <th className={tableHeaderClasses}>Ngày sinh</th>
                                <th className={`${tableHeaderClasses} text-center`}>Thao tác</th>
                              </tr>
                            </thead>
                            <tbody>
                              {householdMembers
                                .filter(member => member.relationship_with_head !== 'Chủ hộ')
                                .map((member) => (
                                  <tr key={member.member_id} className={`hover:bg-gray-50 ${changeHeadForm.new_head_id === member.citizen_id ? 'bg-orange-50' : ''}`}>
                                    <td className={tableCellClasses}>{member.citizen_id}</td>
                                    <td className={tableCellClasses}>{member.full_name}</td>
                                    <td className={tableCellClasses}>{member.relationship_with_head}</td>
                                    <td className={tableCellClasses}>{member.birth_date}</td>
                                    <td className={`${tableCellClasses} text-center`}>
                                      <button type="button" onClick={() => setChangeHeadForm(prev => ({ ...prev, new_head_id: member.citizen_id }))} className={`px-3 py-1 rounded text-xs font-medium transition-colors ${changeHeadForm.new_head_id === member.citizen_id ? 'bg-orange-500 text-white cursor-default' : 'bg-orange-100 text-orange-700 hover:bg-orange-200' }`} >
                                        {changeHeadForm.new_head_id === member.citizen_id ? 'Đã chọn' : 'Chọn làm chủ hộ'}
                                      </button>
                                    </td>
                                  </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>
                       )}
                    </div>

                     {/* Change Head Form - Apply base classes */}
                    <div className="bg-gray-50 p-4 md:p-6 rounded-lg border border-gray-200">
                       <h3 className="text-lg font-medium text-gray-700 mb-4">Thông tin thay đổi</h3>
                       <form onSubmit={handleChangeHead} className="space-y-4">
                          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                             <div className="form-group">
                               <label className="block text-gray-700 text-sm font-medium mb-1">Chủ hộ mới đã chọn: <span className="text-red-500">*</span></label>
                               <input
                                 type="text"
                                 name="new_head_id_display"
                                 value={changeHeadForm.new_head_id ? `${householdMembers.find(m => m.citizen_id === changeHeadForm.new_head_id)?.full_name || 'N/A'} (${changeHeadForm.new_head_id})` : '(Vui lòng chọn từ bảng trên)'}
                                 className={disabledInputClasses}
                                 readOnly
                               />
                                <input type="hidden" name="new_head_id" value={changeHeadForm.new_head_id} />
                             </div>
                              <div className="form-group">
                                <label className="block text-gray-700 text-sm font-medium mb-1">Ngày hiệu lực thay đổi: <span className="text-red-500">*</span></label>
                                <input type="date" name="effective_date" value={changeHeadForm.effective_date} onChange={handleFormChange(setChangeHeadForm)} className={baseInputClasses} required />
                              </div>
                          </div>
                           <div className="form-group">
                             <label className="block text-gray-700 text-sm font-medium mb-1">Lý do thay đổi: <span className="text-red-500">*</span></label>
                             <textarea name="reason" value={changeHeadForm.reason} onChange={handleFormChange(setChangeHeadForm)} className={baseTextareaClasses} rows="3" placeholder="Ví dụ: Chủ hộ cũ qua đời, chuyển đi, thỏa thuận gia đình..." required></textarea>
                           </div>
                            <div className="form-group">
                               <label className="block text-gray-700 text-sm font-medium mb-1">Tài liệu đính kèm (Chứng minh lý do): <span className="text-red-500">*</span></label>
                               <input type="file" className={fileInputClasses} required />
                               <p className="text-xs text-gray-500 mt-1">Ví dụ: Giấy chứng tử, giấy xác nhận chuyển đi, biên bản họp gia đình...</p>
                           </div>
                           <div className="text-center pt-2">
                             <button type="submit" className="bg-orange-500 hover:bg-orange-600 text-white font-bold py-2 px-6 rounded-md shadow-md transition-colors disabled:opacity-50" disabled={isChangingHead || !changeHeadForm.new_head_id}>
                                {isChangingHead ? ( <span className="flex items-center justify-center"> <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle><path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg> Đang xử lý... </span> ) : "Xác nhận thay đổi chủ hộ"}
                             </button>
                           </div>
                       </form>
                    </div>
                   </div>
                )}
              </div>
            )}
          </div>

          {/* Card Footer - Notes */}
          {/* (Giữ nguyên Card Footer) */}
          <div className="bg-gray-100 p-4 md:p-6 border-t border-gray-200"> <h3 className="text-base font-semibold text-gray-700 mb-2">Lưu ý quan trọng:</h3> <ul className="list-disc pl-5 text-gray-600 space-y-1 text-sm"> <li>Thông tin khai báo phải chính xác, đầy đủ.</li> <li>Mang theo bản gốc giấy tờ để đối chiếu khi được yêu cầu.</li> <li>Thời gian xử lý hồ sơ: 3-5 ngày làm việc (dự kiến).</li> <li>Việc thay đổi chủ hộ cần tuân thủ quy định pháp luật và có thể cần sự đồng thuận của các thành viên.</li> <li>Đây là giao diện mô phỏng, dữ liệu sẽ không được lưu trữ vĩnh viễn.</li> <li>Mọi thắc mắc xin liên hệ hotline: 1900xxxx hoặc email: hotro@moj.gov.vn</li> </ul> </div>
        </div>
      </div>

      {/* Footer */}
      {/* (Giữ nguyên Footer) */}
       <footer className="bg-blue-900 text-white py-6 mt-12"> <div className="container mx-auto px-4 text-center text-sm"> <p>© {new Date().getFullYear()} Bộ Tư Pháp Việt Nam. Tất cả các quyền được bảo lưu.</p> <p className="mt-1 opacity-80">Cổng Dịch vụ công Bộ Tư pháp - Địa chỉ: 58-60 Trần Phú, Ba Đình, Hà Nội</p> </div> </footer>
    </div>
  );
}
