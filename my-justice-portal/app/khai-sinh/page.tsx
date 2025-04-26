'use client';

import { useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';

export default function KhaiSinhPage() {
  const [formData, setFormData] = useState({
    fullName: '',
    dateOfBirth: '',
    dateOfBirthWords: '',
    gender: '',
    ethnicity: '',
    nationality: '',
    placeOfBirth: '',
    hometown: '',
    personalId: '',
    motherName: '',
    motherBirthYear: '',
    motherEthnicity: '',
    motherNationality: '',
    motherResidence: '',
    fatherName: '',
    fatherBirthYear: '',
    fatherEthnicity: '',
    fatherNationality: '',
    fatherResidence: '',
    declarerName: '',
    declarerDocuments: '',
    registrationPlace: '',
    registrationDate: '',
  });

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({
      ...prev,
      [name]: value
    }));
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    // Here you would typically send the data to an API
    console.log('Form submitted:', formData);
    alert('Đã gửi đơn đăng ký khai sinh thành công!');
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
          <span className="text-gray-700">Đăng ký khai sinh</span>
        </div>

        <div className="bg-white shadow-lg rounded-lg overflow-hidden">
          <div className="bg-red-600 text-white p-6 text-center">
            <h1 className="text-3xl font-bold">GIẤY KHAI SINH</h1>
            <p className="text-lg">(Đăng ký trực tuyến)</p>
          </div>

          <form onSubmit={handleSubmit} className="p-6">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Personal Information Section */}
              <div className="md:col-span-2">
                <h2 className="text-xl font-bold text-gray-700 mb-4 border-b pb-2">Thông tin người được khai sinh</h2>
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Họ, chữ đệm, tên:
                </label>
                <input
                  type="text"
                  name="fullName"
                  value={formData.fullName}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Ngày, tháng, năm sinh:
                </label>
                <input
                  type="date"
                  name="dateOfBirth"
                  value={formData.dateOfBirth}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Ghi bằng chữ:
                </label>
                <input
                  type="text"
                  name="dateOfBirthWords"
                  value={formData.dateOfBirthWords}
                  onChange={handleChange}
                  placeholder="Ví dụ: Ngày mười hai tháng năm năm hai nghìn hai mươi lăm"
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Giới tính:
                </label>
                <select
                  name="gender"
                  value={formData.gender}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                >
                  <option value="">Chọn giới tính</option>
                  <option value="Nam">Nam</option>
                  <option value="Nữ">Nữ</option>
                </select>
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Dân tộc:
                </label>
                <input
                  type="text"
                  name="ethnicity"
                  value={formData.ethnicity}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Quốc tịch:
                </label>
                <input
                  type="text"
                  name="nationality"
                  value={formData.nationality}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="form-group md:col-span-2">
                <label className="block text-gray-700 font-medium mb-2">
                  Nơi sinh:
                </label>
                <input
                  type="text"
                  name="placeOfBirth"
                  value={formData.placeOfBirth}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="form-group md:col-span-2">
                <label className="block text-gray-700 font-medium mb-2">
                  Quê quán:
                </label>
                <input
                  type="text"
                  name="hometown"
                  value={formData.hometown}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="form-group md:col-span-2">
                <label className="block text-gray-700 font-medium mb-2">
                  Số định danh cá nhân:
                </label>
                <input
                  type="text"
                  name="personalId"
                  value={formData.personalId}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              {/* Mother's Information Section */}
              <div className="md:col-span-2">
                <h2 className="text-xl font-bold text-gray-700 mt-6 mb-4 border-b pb-2">Thông tin người mẹ</h2>
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Họ, chữ đệm, tên người mẹ:
                </label>
                <input
                  type="text"
                  name="motherName"
                  value={formData.motherName}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Năm sinh:
                </label>
                <input
                  type="text"
                  name="motherBirthYear"
                  value={formData.motherBirthYear}
                  onChange={handleChange}
                  placeholder="Ví dụ: 1980"
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Dân tộc:
                </label>
                <input
                  type="text"
                  name="motherEthnicity"
                  value={formData.motherEthnicity}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Quốc tịch:
                </label>
                <input
                  type="text"
                  name="motherNationality"
                  value={formData.motherNationality}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="form-group md:col-span-2">
                <label className="block text-gray-700 font-medium mb-2">
                  Nơi cư trú:
                </label>
                <input
                  type="text"
                  name="motherResidence"
                  value={formData.motherResidence}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              {/* Father's Information Section */}
              <div className="md:col-span-2">
                <h2 className="text-xl font-bold text-gray-700 mt-6 mb-4 border-b pb-2">Thông tin người cha</h2>
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Họ, chữ đệm, tên người cha:
                </label>
                <input
                  type="text"
                  name="fatherName"
                  value={formData.fatherName}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Năm sinh:
                </label>
                <input
                  type="text"
                  name="fatherBirthYear"
                  value={formData.fatherBirthYear}
                  onChange={handleChange}
                  placeholder="Ví dụ: 1978"
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Dân tộc:
                </label>
                <input
                  type="text"
                  name="fatherEthnicity"
                  value={formData.fatherEthnicity}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="form-group">
                <label className="block text-gray-700 font-medium mb-2">
                  Quốc tịch:
                </label>
                <input
                  type="text"
                  name="fatherNationality"
                  value={formData.fatherNationality}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="form-group md:col-span-2">
                <label className="block text-gray-700 font-medium mb-2">
                  Nơi cư trú:
                </label>
                <input
                  type="text"
                  name="fatherResidence"
                  value={formData.fatherResidence}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              {/* Declarer's Information Section */}
              <div className="md:col-span-2">
                <h2 className="text-xl font-bold text-gray-700 mt-6 mb-4 border-b pb-2">Thông tin người đi khai sinh</h2>
              </div>

              <div className="form-group md:col-span-2">
                <label className="block text-gray-700 font-medium mb-2">
                  Họ, chữ đệm, tên người đi khai sinh:
                </label>
                <input
                  type="text"
                  name="declarerName"
                  value={formData.declarerName}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="form-group md:col-span-2">
                <label className="block text-gray-700 font-medium mb-2">
                  Giấy tờ tùy thân:
                </label>
                <input
                  type="text"
                  name="declarerDocuments"
                  value={formData.declarerDocuments}
                  onChange={handleChange}
                  placeholder="Số CCCD/Hộ chiếu"
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              {/* Registration Information Section */}
              <div className="md:col-span-2">
                <h2 className="text-xl font-bold text-gray-700 mt-6 mb-4 border-b pb-2">Thông tin đăng ký</h2>
              </div>

              <div className="form-group md:col-span-2">
                <label className="block text-gray-700 font-medium mb-2">
                  Nơi đăng ký khai sinh:
                </label>
                <input
                  type="text"
                  name="registrationPlace"
                  value={formData.registrationPlace}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>

              <div className="form-group md:col-span-2">
                <label className="block text-gray-700 font-medium mb-2">
                  Ngày, tháng, năm đăng ký:
                </label>
                <input
                  type="date"
                  name="registrationDate"
                  value={formData.registrationDate}
                  onChange={handleChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>
            </div>

            {/* Attachments Section */}
            <div className="mt-8">
              <h2 className="text-xl font-bold text-gray-700 mb-4 border-b pb-2">Tài liệu đính kèm</h2>
              
              <div className="mb-4">
                <label className="block text-gray-700 font-medium mb-2">
                  Giấy chứng sinh (Bắt buộc):
                </label>
                <input
                  type="file"
                  className="w-full"
                  required
                />
              </div>
              
              <div className="mb-4">
                <label className="block text-gray-700 font-medium mb-2">
                  Giấy chứng nhận kết hôn (nếu có):
                </label>
                <input
                  type="file"
                  className="w-full"
                />
              </div>
              
              <div className="mb-4">
                <label className="block text-gray-700 font-medium mb-2">
                  Giấy ủy quyền (nếu người đi khai sinh không phải cha/mẹ):
                </label>
                <input
                  type="file"
                  className="w-full"
                />
              </div>
            </div>

            {/* Consent Section */}
            <div className="mt-6">
              <div className="flex items-start">
                <input
                  id="consent"
                  type="checkbox"
                  className="h-5 w-5 text-blue-600 mt-1"
                  required
                />
                <label htmlFor="consent" className="ml-2 text-gray-700">
                  Tôi xin cam đoan những nội dung khai trên đây là đúng sự thật và chịu trách nhiệm trước pháp luật về
                  cam đoan của mình.
                </label>
              </div>
            </div>

            {/* Submit Button */}
            <div className="mt-8 text-center">
              <button
                type="submit"
                className="bg-red-600 hover:bg-red-700 text-white font-bold py-3 px-8 rounded-md shadow-md transition-colors"
              >
                Gửi đơn đăng ký khai sinh
              </button>
            </div>
          </form>

          <div className="bg-gray-100 p-6">
            <h3 className="text-lg font-bold text-gray-700 mb-2">Lưu ý quan trọng:</h3>
            <ul className="list-disc pl-5 text-gray-600 space-y-1">
              <li>Vui lòng điền đầy đủ và chính xác các thông tin theo yêu cầu.</li>
              <li>Sau khi gửi đơn, bạn sẽ nhận được mã hồ sơ để theo dõi trạng thái xử lý.</li>
              <li>Thời gian xử lý hồ sơ: 5 ngày làm việc kể từ ngày nhận đủ hồ sơ hợp lệ.</li>
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