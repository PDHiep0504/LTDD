# Tóm tắt: Hệ thống Danh mục Sản phẩm

## Tổng quan
Đã hoàn thành việc thêm hệ thống danh mục sản phẩm với đầy đủ chức năng CRUD cho Admin.

## Các thay đổi Backend

### 1. Models mới
- **Category.cs**: Entity danh mục với các thuộc tính:
  - Id (int)
  - Name (string)
  - Description (string?)
  - CreatedAt (DateTime)
  - Products (ICollection<Product>) - navigation property

### 2. Cập nhật Product.cs
- Thêm `CategoryId` (int?) - khóa ngoại nullable
- Thêm `Category` (Category?) - navigation property

### 3. Cập nhật ApplicationDbContext.cs
- Thêm `DbSet<Category> Categories`
- Cấu hình relationship với `DeleteBehavior.SetNull`:
  - Khi xóa danh mục → CategoryId của các sản phẩm tự động = NULL

### 4. CategoryController.cs (mới)
Các endpoint:
- `GET /api/Category` - [Authorize] Lấy danh sách danh mục (tất cả user)
- `GET /api/Category/{id}` - [Authorize] Lấy chi tiết danh mục
- `POST /api/Category` - [Authorize(Roles="Admin")] Thêm danh mục
- `PUT /api/Category/{id}` - [Authorize(Roles="Admin")] Sửa danh mục
- `DELETE /api/Category/{id}` - [Authorize(Roles="Admin")] Xóa danh mục

Validation:
- Kiểm tra tên không được trống
- Kiểm tra tên không bị trùng (case-insensitive)
- Xử lý lỗi với message chi tiết

### 5. Cập nhật ProductRepository.cs
- Thêm `.Include(p => p.Category)` vào GetProductsAsync() và GetProductByIdAsync()
- Đảm bảo API trả về thông tin category kèm product

### 6. Migration
- Migration: `20251020120014_AddCategoryToProduct`
- Tạo bảng Categories
- Thêm cột CategoryId vào Products
- Tạo foreign key constraint với ON DELETE SET NULL

## Các thay đổi Frontend

### 1. Models mới
- **category.dart**: Model danh mục với fromJson/toJson
  - Hỗ trợ cả camelCase và PascalCase từ API

### 2. Cập nhật product.dart
- Thêm `categoryId` (int?)
- Thêm `categoryName` (String?)
- Parse category từ nested object trong API response

### 3. Services mới
- **category_service.dart**: CategoryService với các method:
  - `fetchCategories()` - Lấy danh sách
  - `addCategory(Category)` - Thêm mới
  - `updateCategory(Category)` - Cập nhật
  - `deleteCategory(int)` - Xóa
  - Tự động thêm JWT token vào header
  - Parse error message từ API

### 4. Screens mới
- **category_management_screen.dart**: Màn hình quản lý danh mục (Admin only)
  - ListView hiển thị danh mục
  - Dialog thêm/sửa danh mục
  - Xác nhận xóa với cảnh báo về sản phẩm
  - Pull-to-refresh
  - FloatingActionButton để thêm nhanh
  - Error và Empty state handling

### 5. Cập nhật market_screen.dart
- Thêm nút "Quản lý danh mục" trên AppBar (Admin only)
- Thêm dropdown chọn danh mục trong dialog thêm/sửa sản phẩm
  - Load danh sách category từ API
  - Tùy chọn "Không có danh mục"
  - Sử dụng StatefulBuilder để cập nhật dropdown
- Hiển thị tên danh mục trên product card (badge nhỏ)
- Hiển thị danh mục trong dialog chi tiết sản phẩm

## Luồng hoạt động

### 1. Admin thêm danh mục
1. Vào Market → Nhấn icon Category trên AppBar
2. Màn hình Category Management hiện ra
3. Nhấn FAB hoặc icon + → Dialog thêm danh mục
4. Nhập tên (bắt buộc) và mô tả (tùy chọn)
5. Backend validate và lưu vào DB
6. Danh sách reload tự động

### 2. Admin gán danh mục cho sản phẩm
1. Thêm hoặc sửa sản phẩm
2. Chọn danh mục từ dropdown (hoặc "Không có danh mục")
3. Lưu → CategoryId được gửi lên API
4. Backend lưu relationship

### 3. Admin xóa danh mục
1. Nhấn icon xóa trên danh mục
2. Dialog xác nhận với cảnh báo:
   "Các sản phẩm trong danh mục này sẽ không thuộc danh mục nào"
3. Xác nhận xóa
4. Backend xóa category → SQL tự động SET NULL cho Product.CategoryId

### 4. User xem sản phẩm
1. Vào Market
2. Thấy badge danh mục trên mỗi sản phẩm (nếu có)
3. Long-press → Xem chi tiết → Thấy thông tin danh mục

## Testing checklist

### Backend
- [x] Migration applied thành công
- [x] Foreign key constraint hoạt động
- [x] DELETE Category → Product.CategoryId = NULL
- [x] Admin có thể CRUD categories
- [x] User chỉ có thể GET categories
- [x] Validation tên danh mục

### Frontend
- [x] Category Management screen chỉ Admin truy cập
- [x] Load categories thành công
- [x] Add/Edit/Delete category hoạt động
- [x] Dropdown category trong product dialog
- [x] Hiển thị category name trên product card
- [x] API lỗi được xử lý và hiển thị message

## Các file đã tạo/sửa

### Backend
- ✅ backend/Models/Category.cs (mới)
- ✅ backend/Models/Product.cs (sửa)
- ✅ backend/Models/ApplicationDbContext.cs (sửa)
- ✅ backend/Controllers/CategoryController.cs (mới)
- ✅ backend/Repositories/ProductRepository.cs (sửa)
- ✅ backend/Migrations/20251020120014_AddCategoryToProduct.cs (mới)

### Frontend
- ✅ fontend/lib/models/category.dart (mới)
- ✅ fontend/lib/models/product.dart (sửa)
- ✅ fontend/lib/services/category_service.dart (mới)
- ✅ fontend/lib/screens/category_management_screen.dart (mới)
- ✅ fontend/lib/screens/market_screen.dart (sửa)

## Lưu ý
- Tất cả API yêu cầu JWT token (đã được tự động thêm bởi services)
- Chỉ Admin có quyền thêm/sửa/xóa danh mục
- Xóa danh mục KHÔNG xóa sản phẩm, chỉ set CategoryId = NULL
- Category name phải unique (case-insensitive)
- Support cả camelCase và PascalCase từ API
