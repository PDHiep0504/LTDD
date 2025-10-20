# Tính năng: Lọc sản phẩm theo danh mục

## Tổng quan
Đã thêm nút lọc sản phẩm theo danh mục trên thanh AppBar của Market screen.

## Các thay đổi

### 1. Thêm state lọc
```dart
int? _selectedCategoryId; // null = hiển thị tất cả sản phẩm
```

### 2. Dialog chọn danh mục
- Hiển thị danh sách tất cả categories
- Radio button để chọn
- Tùy chọn "Tất cả sản phẩm" ở đầu
- Icon thay đổi theo lựa chọn hiện tại

### 3. Hàm lọc sản phẩm
```dart
List<Product> _filterProducts(List<Product> products) {
  if (_selectedCategoryId == null) {
    return products; // Hiển thị tất cả
  }
  return products
      .where((product) => product.categoryId == _selectedCategoryId)
      .toList();
}
```

### 4. Nút lọc trên AppBar
- **Icon**: 
  - `filter_list_outlined` khi chưa lọc
  - `filter_list` (solid) khi đang lọc
- **Vị trí**: Đầu tiên bên trái các nút khác
- **Tooltip**: "Lọc theo danh mục"
- **Hiển thị**: Cho tất cả user (không chỉ Admin)

### 5. Empty state khi lọc
Thêm `_EmptyFilterView` widget:
- Hiển thị khi không có sản phẩm trong danh mục đã chọn
- 2 nút: "Xóa bộ lọc" và "Tải lại"
- Icon: `filter_list_off`

## Cách sử dụng

### Người dùng:
1. Vào **Market**
2. Nhấn icon **filter** trên AppBar (góc trái)
3. Chọn danh mục muốn xem
4. Danh sách sản phẩm được lọc theo danh mục đã chọn
5. Để xem tất cả: nhấn filter → chọn "Tất cả sản phẩm"

### Tính năng:
- ✅ Icon thay đổi khi đang lọc (solid icon)
- ✅ Lọc realtime (không cần reload)
- ✅ Empty state riêng cho trạng thái lọc
- ✅ Có thể xóa bộ lọc dễ dàng
- ✅ Pull-to-refresh vẫn hoạt động bình thường
- ✅ Hoạt động với cả Admin và User

## UI Flow

```
AppBar
┌────────────────────────────────────────┐
│ Market                    🔍 📂 ➕     │ (filter, category mgmt, add)
└────────────────────────────────────────┘

Nhấn 🔍 (filter icon)
    ↓
┌────────────────────────┐
│ Lọc theo danh mục      │
├────────────────────────┤
│ ⦿ Tất cả sản phẩm     │
├────────────────────────┤
│ ○ Điện thoại          │
│ ○ Laptop              │
│ ○ Phụ kiện            │
│ ...                    │
└────────────────────────┘

Chọn danh mục
    ↓
Icon thay đổi: 🔍 → 📋
Danh sách lọc theo danh mục
```

## Code locations

**File**: `fontend/lib/screens/market_screen.dart`

- **Line ~23**: `_selectedCategoryId` state
- **Line ~458**: `_showFilterDialog()` - dialog chọn category
- **Line ~523**: `_filterProducts()` - logic lọc
- **Line ~545**: AppBar với filter button
- **Line ~581**: Áp dụng filter vào danh sách
- **Line ~798**: `_EmptyFilterView` widget

## Lưu ý
- Filter được thực hiện trên client-side (không gọi API mới)
- Categories được fetch từ API mỗi khi mở dialog
- State lọc không persist khi thoát khỏi màn hình
- Có thể mở rộng thêm: lưu filter preference, multi-select categories, etc.
