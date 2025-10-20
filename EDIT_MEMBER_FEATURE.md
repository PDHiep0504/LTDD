# ✏️ Tính năng Chỉnh sửa Thành viên

## 📋 Tổng quan

Đã thêm tính năng chỉnh sửa thông tin thành viên với các chức năng:
- ✅ Chỉnh sửa thông tin cơ bản (tên, email, phone, vai trò, mô tả)
- ✅ Thay đổi ảnh đại diện
- ✅ Xóa ảnh đại diện
- ✅ Tự động reload sau khi cập nhật

## 🎯 Cách sử dụng

### 1. Từ màn hình Team Info

1. Vào **Team Info** (màn hình danh sách thành viên)
2. Click vào **menu 3 chấm** bên cạnh member
3. Chọn **"Xem chi tiết"**
4. Trong màn hình chi tiết, click **icon Edit** (✏️) ở góc trên bên phải
5. Chỉnh sửa thông tin
6. Click **"Cập nhật"**

### 2. Các thao tác có thể làm

#### Thay đổi ảnh đại diện:
- Click vào ảnh đại diện
- Chọn:
  - **Chụp ảnh** - Chụp ảnh mới bằng camera
  - **Chọn từ thư viện** - Chọn ảnh có sẵn
  - **Xóa ảnh** - Xóa ảnh hiện tại (chỉ hiện nếu đã có ảnh)

#### Chỉnh sửa thông tin:
- **Họ và tên** (*bắt buộc*)
- **Email** (tùy chọn, phải hợp lệ)
- **Số điện thoại** (tùy chọn)
- **Vai trò** (chọn từ dropdown)
- **Mô tả** (tùy chọn, tối đa 500 ký tự)

#### Lưu thay đổi:
- Click **"Cập nhật"** để lưu
- Click **"Hủy"** để bỏ qua thay đổi

## 📁 Files đã tạo/sửa

### ✨ NEW:
```
lib/screens/edit_member_screen.dart    # Màn hình chỉnh sửa member
```

### ✏️ MODIFIED:
```
lib/screens/detail_member_screen.dart  # Thêm nút Edit và reload logic
lib/screens/team_info_screen.dart      # Thêm reload sau khi edit
```

## 🔧 Chi tiết kỹ thuật

### 1. EditMemberScreen

**File:** `lib/screens/edit_member_screen.dart`

**Features:**
- Form validation
- Image picker (camera/gallery)
- Upload ảnh mới lên Supabase Storage
- Update thông tin member qua API
- Loading state
- Error handling

**Constructor:**
```dart
EditMemberScreen({
  required Member member,  // Member cần edit
})
```

**Return value:**
- `true` - Nếu update thành công
- `null` - Nếu cancel hoặc lỗi

### 2. DetailMemberScreen Updates

**Changes:**
- Đổi từ `StatelessWidget` → `StatefulWidget`
- Thêm state `_currentMember` để lưu member hiện tại
- Thêm method `_navigateToEdit()` để navigate đến EditMemberScreen
- Thêm nút Edit trong AppBar
- Thay tất cả `member` → `_currentMember`
- Pop về màn hình trước khi update thành công (để reload)

**AppBar actions:**
```dart
actions: [
  IconButton(
    icon: const Icon(Icons.edit),
    tooltip: 'Chỉnh sửa',
    onPressed: _navigateToEdit,
  ),
],
```

### 3. TeamInfoScreen Updates

**Changes:**
- Thêm `async` cho `onSelected` callback
- Nhận return value từ DetailMemberScreen
- Reload members nếu có thay đổi

**Code:**
```dart
onSelected: (value) async {
  switch (value) {
    case 'view':
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => DetailMemberScreen(member: member),
        ),
      );
      // Reload nếu có thay đổi
      if (result == true) {
        _loadMembers();
      }
      break;
    // ...
  }
},
```

## 🔄 Flow hoạt động

```
TeamInfoScreen
    ↓ (Click menu → Xem chi tiết)
DetailMemberScreen
    ↓ (Click icon Edit)
EditMemberScreen
    ↓ (Chỉnh sửa thông tin)
    ↓ (Click Cập nhật)
    ↓ (Upload ảnh nếu có)
    ↓ (Call API updateMember)
    ↓ (Return true)
DetailMemberScreen
    ↓ (Nhận true → Pop về)
    ↓ (Return true)
TeamInfoScreen
    ↓ (Nhận true → Reload)
    ↓ (Hiển thị data mới)
```

## 🎨 UI Components

### EditMemberScreen Layout:

```
┌─────────────────────────────┐
│  ← Chỉnh sửa thành viên     │
├─────────────────────────────┤
│                             │
│      ┌─────────────┐        │
│      │   Avatar    │        │  ← Click để thay đổi
│      │  (120x120)  │        │
│      └─────────────┘        │
│                             │
│  ┌─────────────────────┐   │
│  │ 👤 Họ và tên *      │   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │ 📧 Email            │   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │ 📱 Số điện thoại    │   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │ 💼 Vai trò ▼        │   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │ 📝 Mô tả            │   │
│  │                     │   │
│  │                     │   │
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │   Cập nhật          │   │  ← Orange button
│  └─────────────────────┘   │
│                             │
│  ┌─────────────────────┐   │
│  │   Hủy               │   │  ← Outlined button
│  └─────────────────────┘   │
│                             │
└─────────────────────────────┘
```

### Image Picker Bottom Sheet:

```
┌─────────────────────────────┐
│  📷 Chụp ảnh                │
├─────────────────────────────┤
│  🖼️  Chọn từ thư viện       │
├─────────────────────────────┤
│  🗑️  Xóa ảnh (red)          │  ← Chỉ hiện nếu có ảnh
└─────────────────────────────┘
```

## ✅ Validation Rules

### Họ và tên:
- ✅ Bắt buộc
- ❌ Không được để trống

### Email:
- ✅ Tùy chọn
- ❌ Nếu nhập phải có dấu `@`

### Số điện thoại:
- ✅ Tùy chọn
- ✅ Không validate format

### Vai trò:
- ✅ Bắt buộc chọn từ dropdown
- Options:
  - `leader` → Trưởng nhóm
  - `co_lead` → Phó nhóm
  - `member` → Thành viên
  - `mentor` → Cố vấn
  - `guest` → Khách mời

### Mô tả:
- ✅ Tùy chọn
- ✅ Tối đa 500 ký tự

## 🐛 Error Handling

### Upload ảnh thất bại:
```dart
try {
  avatarPath = await SupabaseService.uploadAvatar(...);
} catch (e) {
  // Hiển thị SnackBar với lỗi
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('❌ Lỗi: $e')),
  );
}
```

### Update member thất bại:
```dart
try {
  await SupabaseService.updateMember(updatedMember);
} catch (e) {
  // Hiển thị SnackBar với lỗi
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('❌ Lỗi: $e')),
  );
}
```

## 🎯 Testing Checklist

### ✅ Test Cases:

- [ ] Click nút Edit trong DetailMemberScreen
- [ ] Màn hình EditMemberScreen hiển thị đúng thông tin hiện tại
- [ ] Thay đổi tên và lưu → Cập nhật thành công
- [ ] Thay đổi email và lưu → Cập nhật thành công
- [ ] Nhập email không hợp lệ → Hiển thị lỗi validation
- [ ] Xóa tên và lưu → Hiển thị lỗi validation
- [ ] Thay đổi vai trò → Cập nhật thành công
- [ ] Chụp ảnh mới → Upload và cập nhật thành công
- [ ] Chọn ảnh từ thư viện → Upload và cập nhật thành công
- [ ] Xóa ảnh → Cập nhật avatar_path = null
- [ ] Click Hủy → Quay về không lưu thay đổi
- [ ] Sau khi update → TeamInfoScreen reload và hiển thị data mới
- [ ] Loading state hiển thị khi đang upload/update
- [ ] Error handling hoạt động đúng

## 📝 Notes

### Image Upload:
- Ảnh được resize về 1024x1024 max
- Quality: 85%
- Format: JPG
- Filename: `member_[timestamp].jpg`

### Performance:
- Chỉ upload ảnh mới nếu có thay đổi (`_imageChanged` flag)
- Nếu không thay đổi ảnh → Giữ nguyên `avatar_path`
- Reload members sau khi update để đảm bảo data mới nhất

### Future Improvements:
- [ ] Crop ảnh trước khi upload
- [ ] Preview ảnh full screen
- [ ] Undo changes
- [ ] Confirm dialog khi có thay đổi chưa lưu
- [ ] Optimistic UI update (update UI trước, call API sau)
- [ ] Cache invalidation cho CachedNetworkImage

## 🔗 Related Files

- `lib/models/member.dart` - Member model với `copyWith` method
- `lib/services/supabase_service.dart` - `updateMember()` và `uploadAvatar()` methods
- `lib/config/constants.dart` - Constants và config

---

**Tóm tắt:** Đã thêm tính năng chỉnh sửa member với UI đầy đủ, validation, image upload, và auto-reload. ✅

