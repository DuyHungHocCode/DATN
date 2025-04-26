'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import Image from 'next/image';

export default function HoKhauPage() {
  const [activeTab, setActiveTab] = useState('search');
  const [searchResults, setSearchResults] = useState([]);
  const [selectedHousehold, setSelectedHousehold] = useState(null);
  const [householdMembers, setHouseholdMembers] = useState([]);
  const [isLoading, setIsLoading] = useState(false);
  
  // API service layer - Can be moved to a separate file in the future
  const api = {
    // Household search
    async searchHouseholds(criteria) {
      // In real implementation, this would be replaced with:
      // const response = await fetch('/api/households/search', {
      //   method: 'POST',
      //   headers: { 'Content-Type': 'application/json' },
      //   body: JSON.stringify(criteria)
      // });
      // return await response.json();
      
      // Mock implementation for now
      return new Promise((resolve) => {
        setTimeout(() => {
          resolve([
            {
              household_id: 1,
              household_book_no: 'HK123456',
              head_of_household_id: '001234567890',
              head_of_household_name: 'Nguyễn Văn A',
              address: 'Số 10, Ngõ 8, Đường Trần Hưng Đạo, Phường Cửa Nam, Quận Hoàn Kiếm, TP Hà Nội',
              registration_date: '2020-05-15',
              household_type: 'KT1',
              status: 'Đang hoạt động',
              region_id: 1,
              province_id: 1,
              district_id: 1,
              geographical_region: 'Thành thị'
            },
            {
              household_id: 2,
              household_book_no: 'HK789012',
              head_of_household_id: '001876543210',
              head_of_household_name: 'Trần Thị B',
              address: 'Số 25, Ngõ 18, Đường Lê Duẩn, Phường Phan Chu Trinh, Quận Hoàn Kiếm, TP Hà Nội',
              registration_date: '2019-10-12',
              household_type: 'KT1',
              status: 'Đang hoạt động',
              region_id: 1,
              province_id: 1,
              district_id: 2,
              geographical_region: 'Thành thị'
            }
          ]);
        }, 500);
      });
    },
    
    // Household members
    async getHouseholdMembers(householdId) {
      // In real implementation, this would be replaced with:
      // const response = await fetch(`/api/households/${householdId}/members`);
      // return await response.json();
      
      // Mock implementation
      return new Promise((resolve) => {
        setTimeout(() => {
          resolve([
            {
              member_id: 101,
              citizen_id: '001234567890',
              full_name: 'Nguyễn Văn A',
              relationship_with_head: 'Chủ hộ',
              birth_date: '1980-05-20',
              gender: 'Nam',
              join_date: '2020-05-15',
              status: 'Active'
            },
            {
              member_id: 102,
              citizen_id: '001234567891',
              full_name: 'Nguyễn Thị C',
              relationship_with_head: 'Vợ/Chồng',
              birth_date: '1982-08-15',
              gender: 'Nữ',
              join_date: '2020-05-15',
              status: 'Active'
            },
            {
              member_id: 103,
              citizen_id: '001234567892',
              full_name: 'Nguyễn Văn D',
              relationship_with_head: 'Con',
              birth_date: '2010-01-10',
              gender: 'Nam',
              join_date: '2020-05-15',
              status: 'Active'
            }
          ]);
        }, 300);
      });
    },
    
    // Add member
    async addHouseholdMember(memberData) {
      // In real implementation, this would be replaced with:
      // const response = await fetch('/api/household-members', {
      //   method: 'POST',
      //   headers: { 'Content-Type': 'application/json' },
      //   body: JSON.stringify(memberData)
      // });
      // return await response.json();
      
      // Mock implementation
      return new Promise((resolve) => {
        setTimeout(() => {
          resolve({
            member_id: Math.floor(Math.random() * 1000),
            citizen_id: memberData.citizen_id,
            full_name: memberData.full_name,
            relationship_with_head: memberData.relationship_with_head,
            birth_date: '1990-01-01', // Placeholder
            gender: 'Nam', // Placeholder
            join_date: memberData.join_date,
            status: 'Active'
          });
        }, 500);
      });
    },
    
    // Remove member
    async removeHouseholdMember(memberId, removalData) {
      // In real implementation, this would be replaced with:
      // const response = await fetch(`/api/household-members/${memberId}`, {
      //   method: 'DELETE',
      //   headers: { 'Content-Type': 'application/json' },
      //   body: JSON.stringify(removalData)
      // });
      // return await response.json();
      
      // Mock implementation
      return new Promise((resolve) => {
        setTimeout(() => {
          resolve({ success: true });
        }, 500);
      });
    },
    
    // Change head of household
    async changeHeadOfHousehold(changeHeadData) {
      // In real implementation, this would be replaced with:
      // const response = await fetch('/api/households/change-head', {
      //   method: 'POST',
      //   headers: { 'Content-Type': 'application/json' },
      //   body: JSON.stringify(changeHeadData)
      // });
      // return await response.json();
      
      // Mock implementation
      return new Promise((resolve) => {
        setTimeout(() => {
          resolve({ success: true });
        }, 1000);
      });
    },
    
    // Register new household
    async registerHousehold(householdData) {
      // In real implementation, this would be replaced with:
      // const response = await fetch('/api/households', {
      //   method: 'POST',
      //   headers: { 'Content-Type': 'application/json' },
      //   body: JSON.stringify(householdData)
      // });
      // return await response.json();
      
      // Mock implementation
      return new Promise((resolve) => {
        setTimeout(() => {
          resolve({
            household_id: Math.floor(Math.random() * 1000),
            ...householdData,
            status: 'Đang hoạt động'
          });
        }, 800);
      });
    }
  };
  
  // Form states
  const [searchForm, setSearchForm] = useState({
    household_book_no: '',
    head_of_household_name: '',
    citizen_id: '',
    province_id: '',
    district_id: '',
  });
  
  const [newHouseholdForm, setNewHouseholdForm] = useState({
    household_book_no: '',
    head_of_household_id: '',
    head_of_household_name: '',
    address_id: '',
    full_address: '',
    registration_date: '',
    issuing_authority_id: '',
    area_code: '',
    household_type: '',
    region_id: '',
    province_id: '',
    district_id: '',
    geographical_region: '',
    notes: '',
  });
  
  const [newMemberForm, setNewMemberForm] = useState({
    citizen_id: '',
    full_name: '',
    relationship_with_head: '',
    join_date: '',
    order_in_household: '',
  });
  
  const [changeHeadForm, setChangeHeadForm] = useState({
    new_head_id: '',
    effective_date: '',
    reason: '',
  });
  
  // Mock data for dropdowns
  const regions = [
    { id: 1, name: 'Miền Bắc' },
    { id: 2, name: 'Miền Trung' },
    { id: 3, name: 'Miền Nam' },
  ];

  const provinces = [
    { id: 1, name: 'Hà Nội', region_id: 1 },
    { id: 2, name: 'TP. Hồ Chí Minh', region_id: 3 },
    { id: 3, name: 'Đà Nẵng', region_id: 2 },
    // More provinces...
  ];

  const districts = [
    { id: 1, name: 'Ba Đình', province_id: 1 },
    { id: 2, name: 'Hoàn Kiếm', province_id: 1 },
    { id: 3, name: 'Quận 1', province_id: 2 },
    { id: 4, name: 'Quận 2', province_id: 2 },
    { id: 5, name: 'Hải Châu', province_id: 3 },
    // More districts...
  ];

  const householdTypes = [
    { value: 'KT1', label: 'KT1 - Thường trú tại địa phương' },
    { value: 'KT2', label: 'KT2 - Thường trú tại tỉnh/thành khác thuộc cùng hộ khẩu' },
    { value: 'KT3', label: 'KT3 - Tạm trú dài hạn' },
    { value: 'KT4', label: 'KT4 - Tạm trú ngắn hạn' }
  ];

  const authorities = [
    { id: 1, name: 'Công an Phường Liễu Giai' },
    { id: 2, name: 'Công an Phường Cống Vị' },
    { id: 3, name: 'Công an Phường Nguyễn Trung Trực' },
    // More authorities...
  ];

  const relationshipTypes = [
    { value: 'Chủ hộ', label: 'Chủ hộ' },
    { value: 'Vợ/Chồng', label: 'Vợ/Chồng' },
    { value: 'Con', label: 'Con' },
    { value: 'Bố/Mẹ', label: 'Bố/Mẹ' },
    { value: 'Ông/Bà', label: 'Ông/Bà' },
    { value: 'Cháu', label: 'Cháu' },
    { value: 'Anh/Chị/Em', label: 'Anh/Chị/Em' },
    { value: 'Khác', label: 'Khác' }
  ];

  // Filter districts based on selected province
  const filteredDistricts = newHouseholdForm.province_id 
    ? districts.filter(district => district.province_id === parseInt(newHouseholdForm.province_id))
    : [];

  // Updated search function with API integration
  const [isSearching, setIsSearching] = useState(false);
  const [searchError, setSearchError] = useState(null);
  
  const handleSearch = async (e) => {
    e.preventDefault();
    setSearchError(null);
    setSearchResults([]);
    
    console.log('Searching with criteria:', searchForm);
    
    try {
      setIsSearching(true);
      
      // Call the API service
      const results = await api.searchHouseholds(searchForm);
      
      // Update state with results
      setSearchResults(results);
      
      // Clear selected household if there was one
      if (selectedHousehold) {
        setSelectedHousehold(null);
        setHouseholdMembers([]);
      }
      
      // Show message if no results
      if (results.length === 0) {
        setSearchError('Không tìm thấy kết quả phù hợp với tiêu chí tìm kiếm.');
      }
      
    } catch (error) {
      console.error('Error searching for households:', error);
      setSearchError('Có lỗi xảy ra trong quá trình tìm kiếm. Vui lòng thử lại sau.');
    } finally {
      setIsSearching(false);
    }
  };

  // Updated household selection function with API integration
  const [isLoadingMembers, setIsLoadingMembers] = useState(false);
  const [membersError, setMembersError] = useState(null);
  
  const handleSelectHousehold = async (household) => {
    setSelectedHousehold(household);
    setMembersError(null);
    console.log('Selected household:', household);
    
    try {
      // Loading state
      setIsLoadingMembers(true);
      setHouseholdMembers([]);
      
      // Call the API service
      const members = await api.getHouseholdMembers(household.household_id);
      
      // Update state with members
      setHouseholdMembers(members);
      
      // Switch to the details view
      // We stay on the same tab for now, but could automatically switch to manage members
      // setActiveTab('manage');
      
    } catch (error) {
      console.error('Error fetching household members:', error);
      setMembersError('Có lỗi xảy ra khi tải danh sách thành viên. Vui lòng thử lại sau.');
    } finally {
      setIsLoadingMembers(false);
    }
  };

  // Handle form changes
  const handleSearchFormChange = (e) => {
    const { name, value } = e.target;
    setSearchForm(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleNewHouseholdFormChange = (e) => {
    const { name, value } = e.target;
    setNewHouseholdForm(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleNewMemberFormChange = (e) => {
    const { name, value } = e.target;
    setNewMemberForm(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleChangeHeadFormChange = (e) => {
    const { name, value } = e.target;
    setChangeHeadForm(prev => ({
      ...prev,
      [name]: value
    }));
  };

  // Form submission handlers
  const handleAddNewHousehold = (e) => {
    e.preventDefault();
    console.log('Adding new household:', newHouseholdForm);
    alert('Đã thêm hộ khẩu mới thành công!');
    setNewHouseholdForm({
      household_book_no: '',
      head_of_household_id: '',
      head_of_household_name: '',
      address_id: '',
      full_address: '',
      registration_date: '',
      issuing_authority_id: '',
      area_code: '',
      household_type: '',
      region_id: '',
      province_id: '',
      district_id: '',
      geographical_region: '',
      notes: '',
    });
  };

  // Updated add member function with API service
  const [isAddingMember, setIsAddingMember] = useState(false);
  const [addMemberError, setAddMemberError] = useState(null);
  const [addMemberSuccess, setAddMemberSuccess] = useState(false);
  
  const handleAddNewMember = async (e) => {
    e.preventDefault();
    if (!selectedHousehold) {
      alert('Vui lòng chọn hộ khẩu trước khi thêm thành viên!');
      return;
    }
    
    // Reset states
    setAddMemberError(null);
    setAddMemberSuccess(false);
    
    // Validate form
    if (!newMemberForm.citizen_id) {
      setAddMemberError('Vui lòng nhập số CCCD/CMND của thành viên mới.');
      return;
    }
    
    if (!newMemberForm.full_name) {
      setAddMemberError('Vui lòng nhập họ tên của thành viên mới.');
      return;
    }
    
    if (!newMemberForm.relationship_with_head) {
      setAddMemberError('Vui lòng chọn mối quan hệ với chủ hộ.');
      return;
    }
    
    if (!newMemberForm.join_date) {
      setAddMemberError('Vui lòng chọn ngày nhập hộ.');
      return;
    }
    
    try {
      setIsAddingMember(true);
      
      // Check if this member already exists in the household
      const existingMember = householdMembers.find(m => m.citizen_id === newMemberForm.citizen_id);
      if (existingMember) {
        throw new Error('Thành viên này đã tồn tại trong hộ khẩu (CCCD/CMND đã được sử dụng).');
      }
      
      // Prepare the data for API submission
      const memberData = {
        household_id: selectedHousehold.household_id,
        citizen_id: newMemberForm.citizen_id,
        full_name: newMemberForm.full_name,
        relationship_with_head: newMemberForm.relationship_with_head,
        join_date: newMemberForm.join_date,
        order_in_household: newMemberForm.order_in_household || null,
        region_id: selectedHousehold.region_id || 1,
        province_id: selectedHousehold.province_id || 1, 
        geographical_region: selectedHousehold.geographical_region || 'Thành thị'
      };
      
      console.log('Adding new member to household:', memberData);
      
      // Call the API service
      const newMember = await api.addHouseholdMember(memberData);
      
      // Update the local state
      setHouseholdMembers([...householdMembers, newMember]);
      
      // Show success message
      setAddMemberSuccess(true);
      
      // Reset the form
      setNewMemberForm({
        citizen_id: '',
        full_name: '',
        relationship_with_head: '',
        join_date: '',
        order_in_household: '',
      });
      
    } catch (error) {
      console.error('Error adding household member:', error);
      setAddMemberError(`Có lỗi xảy ra khi thêm thành viên: ${error.message}`);
    } finally {
      setIsAddingMember(false);
    }
  };

  // API integration for changing the head of household
  const [isChangingHead, setIsChangingHead] = useState(false);
  const [changeHeadError, setChangeHeadError] = useState(null);
  const [changeHeadSuccess, setChangeHeadSuccess] = useState(false);
  
  const handleChangeHead = async (e) => {
    e.preventDefault();
    if (!selectedHousehold) {
      alert('Vui lòng chọn hộ khẩu trước khi thay đổi chủ hộ!');
      return;
    }
    
    // Reset state
    setChangeHeadError(null);
    setChangeHeadSuccess(false);
    
    // Validate form
    if (!changeHeadForm.new_head_id) {
      setChangeHeadError('Vui lòng chọn thành viên làm chủ hộ mới');
      return;
    }
    
    if (!changeHeadForm.effective_date) {
      setChangeHeadError('Vui lòng chọn ngày thay đổi');
      return;
    }
    
    if (!changeHeadForm.reason || changeHeadForm.reason.trim() === '') {
      setChangeHeadError('Vui lòng nhập lý do thay đổi chủ hộ');
      return;
    }
    
    try {
      setIsChangingHead(true);
      
      // Get information about the new head
      const newHead = householdMembers.find(m => m.citizen_id === changeHeadForm.new_head_id);
      if (!newHead) throw new Error('Không tìm thấy thông tin thành viên được chọn làm chủ hộ mới');
      
      // Prepare the data for API submission
      const changeHeadData = {
        household_id: selectedHousehold.household_id,
        old_head_id: selectedHousehold.head_of_household_id,
        new_head_id: changeHeadForm.new_head_id,
        effective_date: changeHeadForm.effective_date,
        reason: changeHeadForm.reason,
        // Additional metadata fields that might be needed by the API
        region_id: selectedHousehold.region_id || 1,
        province_id: selectedHousehold.province_id || 1,
        geographical_region: selectedHousehold.geographical_region || 'Thành thị',
      };
      
      console.log('Changing head of household with data:', changeHeadData);
      
      // In the future, this will be an actual API call
      // const response = await fetch('/api/households/change-head', {
      //   method: 'POST',
      //   headers: {
      //     'Content-Type': 'application/json',
      //   },
      //   body: JSON.stringify(changeHeadData),
      // });
      // 
      // if (!response.ok) {
      //   const errorData = await response.json();
      //   throw new Error(errorData.message || 'Failed to change head of household');
      // }
      // 
      // const result = await response.json();
      
      // For now, simulate API delay
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Update the local state to reflect the change
      // 1. Update the selected household
      const updatedHousehold = {
        ...selectedHousehold,
        head_of_household_id: changeHeadForm.new_head_id,
        head_of_household_name: newHead.full_name
      };
      setSelectedHousehold(updatedHousehold);
      
      // 2. Update the member relationships
      const updatedMembers = householdMembers.map(member => {
        if (member.citizen_id === changeHeadForm.new_head_id) {
          return {...member, relationship_with_head: 'Chủ hộ'};
        } else if (member.relationship_with_head === 'Chủ hộ') {
          // The old head - we'll just set a generic relationship for now
          return {...member, relationship_with_head: 'Thành viên khác'};
        } else {
          return member;
        }
      });
      setHouseholdMembers(updatedMembers);
      
      // Set success state
      setChangeHeadSuccess(true);
      
      // Reset form
      setChangeHeadForm({
        new_head_id: '',
        effective_date: '',
        reason: '',
      });
      
      // Show success message
      alert('Đã thay đổi chủ hộ thành công!');
      
    } catch (error) {
      console.error('Error changing head of household:', error);
      setChangeHeadError(`Có lỗi xảy ra: ${error.message}`);
    } finally {
      setIsChangingHead(false);
    }
  };

  // API integration for removing a household member
  const [removingMemberId, setRemovingMemberId] = useState(null);
  
  const handleRemoveMember = async (memberId) => {
    if (!window.confirm('Bạn có chắc muốn xóa thành viên này khỏi hộ khẩu?')) {
      return;
    }
    
    try {
      setRemovingMemberId(memberId);
      
      // Get the member information
      const memberToRemove = householdMembers.find(m => m.member_id === memberId);
      if (!memberToRemove) throw new Error('Không tìm thấy thông tin thành viên');
      
      // Prepare data for removal
      const removalData = {
        household_id: selectedHousehold.household_id,
        citizen_id: memberToRemove.citizen_id,
        leave_date: new Date().toISOString().split('T')[0], // Current date
        leave_reason: "Xóa khỏi hộ khẩu theo yêu cầu"
      };
      
      console.log('Removing member with data:', removalData);
      
      // In the future, this will be an actual API call
      // const response = await fetch(`/api/household-members/${memberId}`, {
      //   method: 'DELETE',
      //   headers: {
      //     'Content-Type': 'application/json',
      //   },
      //   body: JSON.stringify(removalData),
      // });
      // 
      // if (!response.ok) {
      //   const errorData = await response.json();
      //   throw new Error(errorData.message || 'Failed to remove member');
      // }
      
      // For now, simulate API delay
      await new Promise(resolve => setTimeout(resolve, 500));
      
      // Update the local state
      setHouseholdMembers(householdMembers.filter(member => member.member_id !== memberId));
      
      // Show success message
      alert('Đã xóa thành viên khỏi hộ khẩu thành công!');
      
    } catch (error) {
      console.error('Error removing household member:', error);
      alert(`Có lỗi xảy ra khi xóa thành viên: ${error.message}`);
    } finally {
      setRemovingMemberId(null);
    }
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-white shadow-md">
        <div className="container mx-auto px-4 py-6 flex items-center">
          <div className="flex items-center">
            <div className="w-16 h-16 relative mr-4">
              <Image
                src="/logo.png"
                alt="Logo Bộ Tư Pháp"
                width={64}
                height={64}
                className="object-contain"
              />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-red-600">CỔNG DỊCH VỤ CÔNG</h1>
              <h2 className="text-xl text-blue-800">BỘ TƯ PHÁP VIỆT NAM</h2>
            </div>
          </div>
          <nav className="ml-auto">
            <ul className="flex space-x-6">
              <li><Link href="/" className="text-gray-700 hover:text-blue-600">Trang chủ</Link></li>
              <li><a href="#" className="text-gray-700 hover:text-blue-600">Dịch vụ</a></li>
              <li><a href="#" className="text-gray-700 hover:text-blue-600">Hướng dẫn</a></li>
              <li><a href="#" className="text-gray-700 hover:text-blue-600">Liên hệ</a></li>
            </ul>
          </nav>
        </div>
      </header>

      <div className="container mx-auto px-4 py-8">
        <div className="flex items-center mb-6">
          <Link href="/" className="text-blue-600 hover:text-blue-800">
            ← Trang chủ
          </Link>
          <span className="mx-2 text-gray-500">/</span>
          <span className="text-gray-700">Quản lý Hộ khẩu</span>
        </div>

        <div className="bg-white shadow-lg rounded-lg overflow-hidden">
          <div className="bg-green-700 text-white p-6">
            <h1 className="text-3xl font-bold">QUẢN LÝ HỘ KHẨU</h1>
            <p className="text-lg mt-2">Tra cứu, đăng ký mới, quản lý thông tin và thành viên hộ khẩu</p>
          </div>

          {/* Tabs navigation */}
          <div className="bg-gray-100 border-b">
            <div className="container mx-auto">
              <ul className="flex">
                <li className={`cursor-pointer ${activeTab === 'search' ? 'bg-white border-t-2 border-green-600' : 'bg-gray-100'}`}>
                  <button 
                    className="px-6 py-3 font-medium" 
                    onClick={() => setActiveTab('search')}
                  >
                    Tra cứu hộ khẩu
                  </button>
                </li>
                <li className={`cursor-pointer ${activeTab === 'register' ? 'bg-white border-t-2 border-green-600' : 'bg-gray-100'}`}>
                  <button 
                    className="px-6 py-3 font-medium" 
                    onClick={() => setActiveTab('register')}
                  >
                    Đăng ký hộ khẩu mới
                  </button>
                </li>
                <li className={`cursor-pointer ${activeTab === 'manage' ? 'bg-white border-t-2 border-green-600' : 'bg-gray-100'}`}>
                  <button 
                    className="px-6 py-3 font-medium" 
                    onClick={() => setActiveTab('manage')}
                    disabled={!selectedHousehold}
                  >
                    Quản lý thành viên
                  </button>
                </li>
                <li className={`cursor-pointer ${activeTab === 'change-head' ? 'bg-white border-t-2 border-green-600' : 'bg-gray-100'}`}>
                  <button 
                    className="px-6 py-3 font-medium" 
                    onClick={() => setActiveTab('change-head')}
                    disabled={!selectedHousehold}
                  >
                    Thay đổi chủ hộ
                  </button>
                </li>
              </ul>
            </div>
          </div>

          {/* Tab content */}
          <div className="p-6">
            {/* Search Tab */}
            {activeTab === 'search' && (
              <div>
                <h2 className="text-xl font-bold text-gray-800 mb-4">Tra cứu thông tin hộ khẩu</h2>
                
                <form onSubmit={handleSearch} className="bg-gray-50 p-6 rounded-lg mb-6">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                    <div className="form-group">
                      <label className="block text-gray-700 font-medium mb-2">
                        Số sổ hộ khẩu:
                      </label>
                      <input
                        type="text"
                        name="household_book_no"
                        value={searchForm.household_book_no}
                        onChange={handleSearchFormChange}
                        className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                        placeholder="Nhập số sổ hộ khẩu"
                      />
                    </div>

                    <div className="form-group">
                      <label className="block text-gray-700 font-medium mb-2">
                        Họ tên chủ hộ:
                      </label>
                      <input
                        type="text"
                        name="head_of_household_name"
                        value={searchForm.head_of_household_name}
                        onChange={handleSearchFormChange}
                        className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                        placeholder="Nhập họ tên chủ hộ"
                      />
                    </div>

                    <div className="form-group">
                      <label className="block text-gray-700 font-medium mb-2">
                        Số CCCD/CMND (của chủ hộ hoặc thành viên):
                      </label>
                      <input
                        type="text"
                        name="citizen_id"
                        value={searchForm.citizen_id}
                        onChange={handleSearchFormChange}
                        className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                        placeholder="Nhập số CCCD/CMND"
                      />
                    </div>

                    <div className="form-group">
                      <label className="block text-gray-700 font-medium mb-2">
                        Tỉnh/Thành phố:
                      </label>
                      <select
                        name="province_id"
                        value={searchForm.province_id}
                        onChange={handleSearchFormChange}
                        className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                      >
                        <option value="">Chọn tỉnh/thành phố</option>
                        {provinces.map(province => (
                          <option key={province.id} value={province.id}>
                            {province.name}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div className="form-group">
                      <label className="block text-gray-700 font-medium mb-2">
                        Quận/Huyện:
                      </label>
                      <select
                        name="district_id"
                        value={searchForm.district_id}
                        onChange={handleSearchFormChange}
                        className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                        disabled={!searchForm.province_id}
                      >
                        <option value="">Chọn quận/huyện</option>
                        {districts
                          .filter(district => !searchForm.province_id || district.province_id === parseInt(searchForm.province_id))
                          .map(district => (
                            <option key={district.id} value={district.id}>
                              {district.name}
                            </option>
                          ))
                        }
                      </select>
                    </div>
                  </div>

                  <div className="mt-6 text-center">
                    <button
                      type="submit"
                      className="bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-6 rounded-md shadow-md transition-colors"
                      disabled={isSearching}
                    >
                      {isSearching ? (
                        <span className="flex items-center justify-center">
                          <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                          </svg>
                          Đang tìm kiếm...
                        </span>
                      ) : "Tìm kiếm"}
                    </button>
                  </div>
                  
                  {searchError && (
                    <div className="mt-4 p-3 bg-yellow-50 border border-yellow-200 text-yellow-800 rounded">
                      {searchError}
                    </div>
                  )}
                </form>

                {/* Search Results */}
                {searchResults.length > 0 && (
                  <div className="mt-8">
                    <h3 className="text-lg font-bold text-gray-800 mb-4">Kết quả tìm kiếm</h3>
                    <div className="overflow-x-auto">
                      <table className="min-w-full bg-white border border-gray-300">
                        <thead>
                          <tr className="bg-gray-100">
                            <th className="py-3 px-4 border-b text-left">Số sổ HK</th>
                            <th className="py-3 px-4 border-b text-left">Chủ hộ</th>
                            <th className="py-3 px-4 border-b text-left">Địa chỉ</th>
                            <th className="py-3 px-4 border-b text-left">Loại HK</th>
                            <th className="py-3 px-4 border-b text-left">Trạng thái</th>
                            <th className="py-3 px-4 border-b text-left">Thao tác</th>
                          </tr>
                        </thead>
                        <tbody>
                          {searchResults.map((household) => (
                            <tr 
                              key={household.household_id} 
                              className={`hover:bg-gray-50 ${selectedHousehold?.household_id === household.household_id ? 'bg-green-50' : ''}`}
                            >
                              <td className="py-3 px-4 border-b">{household.household_book_no}</td>
                              <td className="py-3 px-4 border-b">{household.head_of_household_name}</td>
                              <td className="py-3 px-4 border-b">{household.address}</td>
                              <td className="py-3 px-4 border-b">{household.household_type}</td>
                              <td className="py-3 px-4 border-b">
                                <span className="px-2 py-1 rounded-full text-xs bg-green-100 text-green-800">
                                  {household.status}
                                </span>
                              </td>
                              <td className="py-3 px-4 border-b">
                                <button
                                  onClick={() => handleSelectHousehold(household)}
                                  className="text-blue-600 hover:text-blue-800 mr-2"
                                >
                                  Chọn
                                </button>
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div>
                )}

                {/* Selected Household Details */}
                {selectedHousehold && (
                  <div className="mt-8">
                    <div className="flex justify-between items-center">
                      <h3 className="text-lg font-bold text-gray-800 mb-4">Chi tiết hộ khẩu</h3>
                      <div>
                        <button 
                          onClick={() => setActiveTab('manage')}
                          className="bg-blue-600 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-md shadow-md transition-colors mr-2"
                        >
                          Quản lý thành viên
                        </button>
                        <button 
                          onClick={() => setActiveTab('change-head')}
                          className="bg-orange-600 hover:bg-orange-700 text-white font-bold py-2 px-4 rounded-md shadow-md transition-colors"
                        >
                          Đổi chủ hộ
                        </button>
                      </div>
                    </div>
                    
                    <div className="bg-white border rounded-lg p-6 mb-6">
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div className="mb-4">
                          <span className="text-gray-600 font-medium">Số sổ hộ khẩu:</span>
                          <span className="ml-2">{selectedHousehold.household_book_no}</span>
                        </div>
                        <div className="mb-4">
                          <span className="text-gray-600 font-medium">Chủ hộ:</span>
                          <span className="ml-2">{selectedHousehold.head_of_household_name}</span>
                        </div>
                        <div className="mb-4">
                          <span className="text-gray-600 font-medium">CCCD/CMND chủ hộ:</span>
                          <span className="ml-2">{selectedHousehold.head_of_household_id}</span>
                        </div>
                        <div className="mb-4">
                          <span className="text-gray-600 font-medium">Ngày đăng ký:</span>
                          <span className="ml-2">{selectedHousehold.registration_date}</span>
                        </div>
                        <div className="mb-4 md:col-span-2">
                          <span className="text-gray-600 font-medium">Địa chỉ thường trú:</span>
                          <span className="ml-2">{selectedHousehold.address}</span>
                        </div>
                        <div className="mb-4">
                          <span className="text-gray-600 font-medium">Loại hộ khẩu:</span>
                          <span className="ml-2">{selectedHousehold.household_type}</span>
                        </div>
                        <div className="mb-4">
                          <span className="text-gray-600 font-medium">Trạng thái:</span>
                          <span className="ml-2 px-2 py-1 rounded-full text-xs bg-green-100 text-green-800">
                            {selectedHousehold.status}
                          </span>
                        </div>
                      </div>
                    </div>

                    {/* Household Members List */}
                    <h4 className="text-md font-bold text-gray-800 mb-4">Danh sách thành viên</h4>
                    <div className="overflow-x-auto">
                      <table className="min-w-full bg-white border border-gray-300">
                        <thead>
                          <tr className="bg-gray-100">
                            <th className="py-3 px-4 border-b text-left">CCCD/CMND</th>
                            <th className="py-3 px-4 border-b text-left">Họ tên</th>
                            <th className="py-3 px-4 border-b text-left">Quan hệ với chủ hộ</th>
                            <th className="py-3 px-4 border-b text-left">Ngày sinh</th>
                            <th className="py-3 px-4 border-b text-left">Giới tính</th>
                            <th className="py-3 px-4 border-b text-left">Ngày nhập hộ</th>
                            <th className="py-3 px-4 border-b text-left">Thao tác</th>
                          </tr>
                        </thead>
                        <tbody>
                          {householdMembers.map((member) => (
                            <tr key={member.member_id} className="hover:bg-gray-50">
                              <td className="py-3 px-4 border-b">{member.citizen_id}</td>
                              <td className="py-3 px-4 border-b">{member.full_name}</td>
                              <td className="py-3 px-4 border-b">
                                <span className={`${member.relationship_with_head === 'Chủ hộ' ? 'bg-blue-100 text-blue-800' : 'bg-gray-100 text-gray-800'} px-2 py-1 rounded-full text-xs`}>
                                  {member.relationship_with_head}
                                </span>
                              </td>
                              <td className="py-3 px-4 border-b">{member.birth_date}</td>
                              <td className="py-3 px-4 border-b">{member.gender}</td>
                              <td className="py-3 px-4 border-b">{member.join_date}</td>
                              <td className="py-3 px-4 border-b">
                                {member.relationship_with_head !== 'Chủ hộ' && (
                                  <button
                                    onClick={() => handleRemoveMember(member.member_id)}
                                    className="text-red-600 hover:text-red-800"
                                  >
                                    Xóa
                                  </button>
                                )}
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  </div>
                )}
              </div>
            )}

            {/* Register New Household Tab */}
            {activeTab === 'register' && (
              <div>
                <h2 className="text-xl font-bold text-gray-800 mb-4">Đăng ký hộ khẩu mới</h2>
                
                <form onSubmit={handleAddNewHousehold} className="bg-gray-50 p-6 rounded-lg">
                  <div className="mb-6">
                    <h3 className="text-lg font-semibold text-gray-700 border-b pb-2 mb-4">Thông tin cơ bản</h3>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                      <div className="form-group">
                        <label className="block text-gray-700 font-medium mb-2">
                          Số sổ hộ khẩu: <span className="text-red-500">*</span>
                        </label>
                        <input
                          type="text"
                          name="household_book_no"
                          value={newHouseholdForm.household_book_no}
                          onChange={handleNewHouseholdFormChange}
                          className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                          required
                        />
                      </div>

                      <div className="form-group">
                        <label className="block text-gray-700 font-medium mb-2">
                          Loại hộ khẩu: <span className="text-red-500">*</span>
                        </label>
                        <select
                          name="household_type"
                          value={newHouseholdForm.household_type}
                          onChange={handleNewHouseholdFormChange}
                          className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                          required
                        >
                          <option value="">Chọn loại hộ khẩu</option>
                          {householdTypes.map(type => (
                            <option key={type.value} value={type.value}>
                              {type.label}
                            </option>
                          ))}
                        </select>
                      </div>

                      <div className="form-group">
                        <label className="block text-gray-700 font-medium mb-2">
                          Ngày đăng ký: <span className="text-red-500">*</span>
                        </label>
                        <input
                          type="date"
                          name="registration_date"
                          value={newHouseholdForm.registration_date}
                          onChange={handleNewHouseholdFormChange}
                          className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                          required
                        />
                      </div>

                      <div className="form-group">
                        <label className="block text-gray-700 font-medium mb-2">
                          Cơ quan cấp: <span className="text-red-500">*</span>
                        </label>
                        <select
                          name="issuing_authority_id"
                          value={newHouseholdForm.issuing_authority_id}
                          onChange={handleNewHouseholdFormChange}
                          className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                          required
                        >
                          <option value="">Chọn cơ quan cấp</option>
                          {authorities.map(authority => (
                            <option key={authority.id} value={authority.id}>
                              {authority.name}
                            </option>
                          ))}
                        </select>
                      </div>

                      <div className="form-group">
                        <label className="block text-gray-700 font-medium mb-2">
                          Mã khu vực:
                        </label>
                        <input
                          type="text"
                          name="area_code"
                          value={newHouseholdForm.area_code}
                          onChange={handleNewHouseholdFormChange}
                          className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                          placeholder="Nhập mã khu vực nếu có"
                        />
                      </div>
                    </div>
                  </div>

                  <div className="mb-6">
                    <h3 className="text-lg font-semibold text-gray-700 border-b pb-2 mb-4">Thông tin chủ hộ</h3>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                      <div className="form-group">
                        <label className="block text-gray-700 font-medium mb-2">
                          Số CCCD/CMND: <span className="text-red-500">*</span>
                        </label>
                        <input
                          type="text"
                          name="head_of_household_id"
                          value={newHouseholdForm.head_of_household_id}
                          onChange={handleNewHouseholdFormChange}
                          className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                          required
                        />
                      </div>

                      <div className="form-group">
                        <label className="block text-gray-700 font-medium mb-2">
                          Họ tên: <span className="text-red-500">*</span>
                        </label>
                        <input
                          type="text"
                          name="head_of_household_name"
                          value={newHouseholdForm.head_of_household_name}
                          onChange={handleNewHouseholdFormChange}
                          className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                          required
                        />
                      </div>
                    </div>
                  </div>

                  <div className="mb-6">
                    <h3 className="text-lg font-semibold text-gray-700 border-b pb-2 mb-4">Địa chỉ thường trú</h3>
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                      <div className="form-group">
                        <label className="block text-gray-700 font-medium mb-2">
                          Khu vực: <span className="text-red-500">*</span>
                        </label>
                        <select
                          name="region_id"
                          value={newHouseholdForm.region_id}
                          onChange={handleNewHouseholdFormChange}
                          className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                          required
                        >
                          <option value="">Chọn khu vực</option>
                          {regions.map(region => (
                            <option key={region.id} value={region.id}>
                              {region.name}
                            </option>
                          ))}
                        </select>
                      </div>

                      <div className="form-group">
                        <label className="block text-gray-700 font-medium mb-2">
                          Tỉnh/Thành phố: <span className="text-red-500">*</span>
                        </label>
                        <select
                          name="province_id"
                          value={newHouseholdForm.province_id}
                          onChange={handleNewHouseholdFormChange}
                          className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                          required
                        >
                          <option value="">Chọn tỉnh/thành phố</option>
                          {provinces.map(province => (
                            <option key={province.id} value={province.id}>
                              {province.name}
                            </option>
                          ))}
                        </select>
                      </div>

                      <div className="form-group">
                        <label className="block text-gray-700 font-medium mb-2">
                          Quận/Huyện: <span className="text-red-500">*</span>
                        </label>
                        <select
                          name="district_id"
                          value={newHouseholdForm.district_id}
                          onChange={handleNewHouseholdFormChange}
                          className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                          required
                          disabled={!newHouseholdForm.province_id}
                        >
                          <option value="">Chọn quận/huyện</option>
                          {filteredDistricts.map(district => (
                            <option key={district.id} value={district.id}>
                              {district.name}
                            </option>
                          ))}
                        </select>
                      </div>

                      <div className="form-group">
                        <label className="block text-gray-700 font-medium mb-2">
                          Vùng địa lý: <span className="text-red-500">*</span>
                        </label>
                        <select
                          name="geographical_region"
                          value={newHouseholdForm.geographical_region}
                          onChange={handleNewHouseholdFormChange}
                          className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                          required
                        >
                          <option value="">Chọn vùng địa lý</option>
                          <option value="Đồng bằng">Đồng bằng</option>
                          <option value="Trung du miền núi">Trung du miền núi</option>
                          <option value="Thành thị">Thành thị</option>
                          <option value="Nông thôn">Nông thôn</option>
                          <option value="Hải đảo">Hải đảo</option>
                        </select>
                      </div>

                      <div className="form-group md:col-span-3">
                        <label className="block text-gray-700 font-medium mb-2">
                          Địa chỉ chi tiết: <span className="text-red-500">*</span>
                        </label>
                        <textarea
                          name="full_address"
                          value={newHouseholdForm.full_address}
                          onChange={handleNewHouseholdFormChange}
                          className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                          rows="2"
                          placeholder="Số nhà, đường, phường/xã..."
                          required
                        ></textarea>
                      </div>
                    </div>
                  </div>

                  <div className="mb-6">
                    <h3 className="text-lg font-semibold text-gray-700 border-b pb-2 mb-4">Thông tin bổ sung</h3>
                    <div className="form-group">
                      <label className="block text-gray-700 font-medium mb-2">
                        Ghi chú:
                      </label>
                      <textarea
                        name="notes"
                        value={newHouseholdForm.notes}
                        onChange={handleNewHouseholdFormChange}
                        className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                        rows="3"
                        placeholder="Thông tin bổ sung (nếu có)"
                      ></textarea>
                    </div>
                  </div>

                  {/* Attachment section */}
                  <div className="mb-6">
                    <h3 className="text-lg font-semibold text-gray-700 border-b pb-2 mb-4">Tài liệu đính kèm</h3>
                    <div className="mb-4">
                      <label className="block text-gray-700 font-medium mb-2">
                        Giấy tờ chứng minh nhân thân của chủ hộ: <span className="text-red-500">*</span>
                      </label>
                      <input
                        type="file"
                        className="w-full"
                        required
                      />
                    </div>
                    
                    <div className="mb-4">
                      <label className="block text-gray-700 font-medium mb-2">
                        Giấy tờ chứng minh chỗ ở hợp pháp: <span className="text-red-500">*</span>
                      </label>
                      <input
                        type="file"
                        className="w-full"
                        required
                      />
                    </div>
                  </div>

                  {/* Consent section */}
                  <div className="mb-6">
                    <div className="flex items-start">
                      <input
                        id="consent"
                        type="checkbox"
                        className="h-5 w-5 text-green-600 mt-1"
                        required
                      />
                      <label htmlFor="consent" className="ml-2 text-gray-700">
                        Tôi xin cam đoan những thông tin khai trên là đúng sự thật và chịu trách nhiệm trước pháp luật về
                        lời khai của mình.
                      </label>
                    </div>
                  </div>

                  {/* Submit button */}
                  <div className="text-center">
                    <button
                      type="submit"
                      className="bg-green-600 hover:bg-green-700 text-white font-bold py-3 px-8 rounded-md shadow-md transition-colors"
                    >
                      Đăng ký hộ khẩu mới
                    </button>
                  </div>
                </form>
              </div>
            )}

            {/* Manage Members Tab */}
            {activeTab === 'manage' && (
              <div>
                <h2 className="text-xl font-bold text-gray-800 mb-4">Quản lý thành viên hộ khẩu</h2>
                
                {!selectedHousehold ? (
                  <div className="bg-yellow-50 border border-yellow-200 text-yellow-800 px-4 py-3 rounded">
                    Vui lòng chọn hộ khẩu từ mục "Tra cứu hộ khẩu" trước khi thực hiện chức năng này.
                  </div>
                ) : (
                  <>
                    <div className="bg-gray-50 p-4 rounded mb-6">
                      <h3 className="font-semibold mb-2">Thông tin hộ khẩu đang chọn:</h3>
                      <p><span className="font-medium">Số sổ HK:</span> {selectedHousehold.household_book_no} | <span className="font-medium">Chủ hộ:</span> {selectedHousehold.head_of_household_name}</p>
                    </div>
                    
                    {/* Current members */}
                    <div className="mb-8">
                      <h3 className="text-lg font-semibold text-gray-700 mb-4">Danh sách thành viên hiện tại</h3>
                      <div className="overflow-x-auto">
                        <table className="min-w-full bg-white border border-gray-300">
                          <thead>
                            <tr className="bg-gray-100">
                              <th className="py-3 px-4 border-b text-left">CCCD/CMND</th>
                              <th className="py-3 px-4 border-b text-left">Họ tên</th>
                              <th className="py-3 px-4 border-b text-left">Quan hệ với chủ hộ</th>
                              <th className="py-3 px-4 border-b text-left">Ngày sinh</th>
                              <th className="py-3 px-4 border-b text-left">Giới tính</th>
                              <th className="py-3 px-4 border-b text-left">Ngày nhập hộ</th>
                              <th className="py-3 px-4 border-b text-left">Thao tác</th>
                            </tr>
                          </thead>
                          <tbody>
                            {householdMembers.map((member) => (
                              <tr key={member.member_id} className="hover:bg-gray-50">
                                <td className="py-3 px-4 border-b">{member.citizen_id}</td>
                                <td className="py-3 px-4 border-b">{member.full_name}</td>
                                <td className="py-3 px-4 border-b">
                                  <span className={`${member.relationship_with_head === 'Chủ hộ' ? 'bg-blue-100 text-blue-800' : 'bg-gray-100 text-gray-800'} px-2 py-1 rounded-full text-xs`}>
                                    {member.relationship_with_head}
                                  </span>
                                </td>
                                <td className="py-3 px-4 border-b">{member.birth_date}</td>
                                <td className="py-3 px-4 border-b">{member.gender}</td>
                                <td className="py-3 px-4 border-b">{member.join_date}</td>
                                <td className="py-3 px-4 border-b">
                                  {member.relationship_with_head !== 'Chủ hộ' && (
                                    <button
                                      onClick={() => handleRemoveMember(member.member_id)}
                                      className="text-red-600 hover:text-red-800"
                                      disabled={removingMemberId === member.member_id}
                                    >
                                      {removingMemberId === member.member_id ? (
                                        <span className="flex items-center text-gray-500">
                                          <svg className="animate-spin -ml-1 mr-1 h-3 w-3" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                                            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                                            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                                          </svg>
                                          Đang xóa...
                                        </span>
                                      ) : "Xóa"}
                                    </button>
                                  )}
                                </td>
                              </tr>
                            ))}
                          </tbody>
                        </table>
                      </div>
                    </div>
                    
                    {/* Add new member form */}
                    <div className="bg-gray-50 p-6 rounded-lg">
                      <h3 className="text-lg font-semibold text-gray-700 mb-4">Thêm thành viên mới</h3>
                      <form onSubmit={handleAddNewMember}>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                          <div className="form-group">
                            <label className="block text-gray-700 font-medium mb-2">
                              Số CCCD/CMND: <span className="text-red-500">*</span>
                            </label>
                            <input
                              type="text"
                              name="citizen_id"
                              value={newMemberForm.citizen_id}
                              onChange={handleNewMemberFormChange}
                              className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                              required
                            />
                          </div>

                          <div className="form-group">
                            <label className="block text-gray-700 font-medium mb-2">
                              Họ tên: <span className="text-red-500">*</span>
                            </label>
                            <input
                              type="text"
                              name="full_name"
                              value={newMemberForm.full_name}
                              onChange={handleNewMemberFormChange}
                              className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                              required
                            />
                          </div>

                          <div className="form-group">
                            <label className="block text-gray-700 font-medium mb-2">
                              Quan hệ với chủ hộ: <span className="text-red-500">*</span>
                            </label>
                            <select
                              name="relationship_with_head"
                              value={newMemberForm.relationship_with_head}
                              onChange={handleNewMemberFormChange}
                              className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                              required
                            >
                              <option value="">Chọn quan hệ</option>
                              {relationshipTypes
                                .filter(rt => rt.value !== 'Chủ hộ')
                                .map(type => (
                                  <option key={type.value} value={type.value}>
                                    {type.label}
                                  </option>
                                ))
                              }
                            </select>
                          </div>

                          <div className="form-group">
                            <label className="block text-gray-700 font-medium mb-2">
                              Ngày nhập hộ: <span className="text-red-500">*</span>
                            </label>
                            <input
                              type="date"
                              name="join_date"
                              value={newMemberForm.join_date}
                              onChange={handleNewMemberFormChange}
                              className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                              required
                            />
                          </div>

                          <div className="form-group">
                            <label className="block text-gray-700 font-medium mb-2">
                              Thứ tự trong sổ:
                            </label>
                            <input
                              type="number"
                              name="order_in_household"
                              value={newMemberForm.order_in_household}
                              onChange={handleNewMemberFormChange}
                              className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                              min="1"
                            />
                          </div>
                          
                          <div className="form-group md:col-span-2">
                            <label className="block text-gray-700 font-medium mb-2">
                              Giấy tờ đính kèm:
                            </label>
                            <input
                              type="file"
                              className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                            />
                            <p className="text-sm text-gray-500 mt-1">CCCD/CMND hoặc giấy tờ tùy thân của thành viên</p>
                          </div>
                        </div>
                        
                        {addMemberError && (
                          <div className="mt-4 p-3 bg-red-50 border border-red-200 text-red-700 rounded">
                            {addMemberError}
                          </div>
                        )}
                        
                        {addMemberSuccess && (
                          <div className="mt-4 p-3 bg-green-50 border border-green-200 text-green-700 rounded">
                            Đã thêm thành viên mới vào hộ khẩu thành công!
                          </div>
                        )}

                        <div className="mt-6 text-center">
                          <button
                            type="submit"
                            className="bg-green-600 hover:bg-green-700 text-white font-bold py-2 px-6 rounded-md shadow-md transition-colors"
                            disabled={isAddingMember}
                          >
                            {isAddingMember ? (
                              <span className="flex items-center justify-center">
                                <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                                </svg>
                                Đang xử lý...
                              </span>
                            ) : "Thêm thành viên"}
                          </button>
                        </div>
                      </form>
                    </div>
                  </>
                )}
              </div>
            )}

            {/* Change Head of Household Tab */}
            {activeTab === 'change-head' && (
              <div>
                <h2 className="text-xl font-bold text-gray-800 mb-4">Thay đổi chủ hộ</h2>
                
                {!selectedHousehold ? (
                  <div className="bg-yellow-50 border border-yellow-200 text-yellow-800 px-4 py-3 rounded">
                    Vui lòng chọn hộ khẩu từ mục "Tra cứu hộ khẩu" trước khi thực hiện chức năng này.
                  </div>
                ) : (
                  <>
                    <div className="bg-gray-50 p-4 rounded mb-6">
                      <h3 className="font-semibold mb-2">Thông tin hộ khẩu đang chọn:</h3>
                      <p><span className="font-medium">Số sổ HK:</span> {selectedHousehold.household_book_no} | <span className="font-medium">Chủ hộ hiện tại:</span> {selectedHousehold.head_of_household_name}</p>
                    </div>
                    
                    {/* Current members to choose from */}
                    <div className="mb-8">
                      <h3 className="text-lg font-semibold text-gray-700 mb-4">Danh sách thành viên</h3>
                      <p className="text-sm text-gray-600 mb-4">Chọn thành viên sẽ trở thành chủ hộ mới. Nếu người sẽ trở thành chủ hộ mới chưa có trong danh sách, vui lòng thêm thành viên trước.</p>
                      <div className="overflow-x-auto">
                        <table className="min-w-full bg-white border border-gray-300">
                          <thead>
                            <tr className="bg-gray-100">
                              <th className="py-3 px-4 border-b text-left">CCCD/CMND</th>
                              <th className="py-3 px-4 border-b text-left">Họ tên</th>
                              <th className="py-3 px-4 border-b text-left">Quan hệ với chủ hộ</th>
                              <th className="py-3 px-4 border-b text-left">Ngày sinh</th>
                              <th className="py-3 px-4 border-b text-left">Thao tác</th>
                            </tr>
                          </thead>
                          <tbody>
                            {householdMembers
                              .filter(member => member.relationship_with_head !== 'Chủ hộ')
                              .map((member) => (
                                <tr key={member.member_id} className="hover:bg-gray-50">
                                  <td className="py-3 px-4 border-b">{member.citizen_id}</td>
                                  <td className="py-3 px-4 border-b">{member.full_name}</td>
                                  <td className="py-3 px-4 border-b">{member.relationship_with_head}</td>
                                  <td className="py-3 px-4 border-b">{member.birth_date}</td>
                                  <td className="py-3 px-4 border-b">
                                    <button
                                      onClick={() => setChangeHeadForm({
                                        ...changeHeadForm, 
                                        new_head_id: member.citizen_id
                                      })}
                                      className="text-blue-600 hover:text-blue-800"
                                    >
                                      Chọn làm chủ hộ
                                    </button>
                                  </td>
                                </tr>
                              ))}
                          </tbody>
                        </table>
                      </div>
                    </div>
                    
                    {/* Change head form */}
                    <div className="bg-gray-50 p-6 rounded-lg">
                      <h3 className="text-lg font-semibold text-gray-700 mb-4">Thông tin thay đổi chủ hộ</h3>
                      <form onSubmit={handleChangeHead}>
                        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                          <div className="form-group">
                            <label className="block text-gray-700 font-medium mb-2">
                              Số CCCD/CMND chủ hộ mới: <span className="text-red-500">*</span>
                            </label>
                            <input
                              type="text"
                              name="new_head_id"
                              value={changeHeadForm.new_head_id}
                              onChange={handleChangeHeadFormChange}
                              className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                              required
                              readOnly={changeHeadForm.new_head_id !== ''}
                            />
                            {changeHeadForm.new_head_id && (
                              <p className="text-sm text-green-600 mt-1">
                                Đã chọn: {householdMembers.find(m => m.citizen_id === changeHeadForm.new_head_id)?.full_name}
                              </p>
                            )}
                          </div>

                          <div className="form-group">
                            <label className="block text-gray-700 font-medium mb-2">
                              Ngày thay đổi: <span className="text-red-500">*</span>
                            </label>
                            <input
                              type="date"
                              name="effective_date"
                              value={changeHeadForm.effective_date}
                              onChange={handleChangeHeadFormChange}
                              className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                              required
                            />
                          </div>

                          <div className="form-group md:col-span-2">
                            <label className="block text-gray-700 font-medium mb-2">
                              Lý do thay đổi: <span className="text-red-500">*</span>
                            </label>
                            <textarea
                              name="reason"
                              value={changeHeadForm.reason}
                              onChange={handleChangeHeadFormChange}
                              className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-green-500"
                              rows="3"
                              required
                              placeholder="Lý do thay đổi chủ hộ, ví dụ: Chủ hộ cũ qua đời, chuyển đi nơi khác, ..."
                            ></textarea>
                          </div>
                        </div>

                        {/* Attachment section */}
                        <div className="mt-6">
                          <h4 className="text-md font-medium text-gray-700 mb-2">Tài liệu đính kèm</h4>
                          <div className="mb-4">
                            <label className="block text-gray-700 font-medium mb-2">
                              Giấy tờ chứng minh lý do thay đổi: <span className="text-red-500">*</span>
                            </label>
                            <input
                              type="file"
                              className="w-full"
                              required
                            />
                            <p className="text-sm text-gray-500 mt-1">Ví dụ: Giấy chứng tử, giấy xác nhận chuyển đi, ...</p>
                          </div>
                        </div>

                        {changeHeadError && (
                          <div className="mt-4 p-3 bg-red-50 border border-red-200 text-red-700 rounded">
                            {changeHeadError}
                          </div>
                        )}
                        
                        {changeHeadSuccess && (
                          <div className="mt-4 p-3 bg-green-50 border border-green-200 text-green-700 rounded">
                            Thay đổi chủ hộ thành công! Chủ hộ mới: {householdMembers.find(m => m.citizen_id === changeHeadForm.new_head_id)?.full_name}
                          </div>
                        )}
                        
                        <div className="mt-6 text-center">
                          <button
                            type="submit"
                            className="bg-orange-600 hover:bg-orange-700 text-white font-bold py-2 px-6 rounded-md shadow-md transition-colors"
                            disabled={isChangingHead}
                          >
                            {isChangingHead ? (
                              <span className="flex items-center justify-center">
                                <svg className="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                                </svg>
                                Đang xử lý...
                              </span>
                            ) : "Xác nhận thay đổi chủ hộ"}
                          </button>
                        </div>
                      </form>
                    </div>
                  </>
                )}
              </div>
            )}
          </div>

          <div className="bg-gray-100 p-6">
            <h3 className="text-lg font-bold text-gray-700 mb-2">Lưu ý quan trọng:</h3>
            <ul className="list-disc pl-5 text-gray-600 space-y-1">
              <li>Các thông tin khai báo phải chính xác, đầy đủ và phù hợp với hồ sơ giấy tờ thực tế.</li>
              <li>Sau khi nộp hồ sơ trực tuyến, người dân cần mang theo bản gốc các giấy tờ cần thiết để đối chiếu tại cơ quan có thẩm quyền.</li>
              <li>Thời gian xử lý hồ sơ: 3-5 ngày làm việc kể từ ngày nhận đủ hồ sơ hợp lệ.</li>
              <li>Trường hợp hộ khẩu có nhiều thành viên, việc thay đổi chủ hộ cần có sự đồng thuận của các thành viên trong hộ.</li>
              <li>Mọi thắc mắc xin liên hệ hotline: 1900xxxx hoặc email: hotro@moj.gov.vn</li>
            </ul>
          </div>
        </div>
      </div>

      <footer className="bg-blue-900 text-white py-6 mt-12">
        <div className="container mx-auto px-4">
          <div className="text-center">
            <p>© {new Date().getFullYear()} Bộ Tư Pháp Việt Nam. Tất cả các quyền được bảo lưu.</p>
            <p className="mt-2">Cổng Dịch vụ công Bộ Tư pháp - Địa chỉ: 58-60 Trần Phú, Ba Đình, Hà Nội</p>
          </div>
        </div>
      </footer>
    </div>
  );
}