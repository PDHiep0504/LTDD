# Fix: Lỗi API Product khi thêm Category

## Vấn đề
Khi thêm hoặc cập nhật sản phẩm với CategoryId, API gặp lỗi do:
1. **JSON Reference Cycle**: Category có collection Products, Product có reference Category → gây vòng lặp khi serialize
2. **Update Product**: EF Core cố gắng update cả Category object thay vì chỉ update CategoryId

## Giải pháp

### 1. Thêm JSON ReferenceHandler trong Program.cs
**File**: `backend/Program.cs`

```csharp
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.ReferenceHandler = System.Text.Json.Serialization.ReferenceHandler.IgnoreCycles;
    });
```

**Tác dụng**: Bỏ qua các reference cycle khi serialize JSON, tránh lỗi "A possible object cycle was detected"

### 2. Sửa UpdateProductAsync trong ProductRepository
**File**: `backend/Repositories/ProductRepository.cs`

**Trước:**
```csharp
public async Task UpdateProductAsync(Product product)
{
    _context.Entry(product).State = EntityState.Modified;
    await _context.SaveChangesAsync();
}
```

**Sau:**
```csharp
public async Task UpdateProductAsync(Product product)
{
    var existingProduct = await _context.Products.FindAsync(product.Id);
    if (existingProduct != null)
    {
        existingProduct.Name = product.Name;
        existingProduct.Price = product.Price;
        existingProduct.Image = product.Image;
        existingProduct.Description = product.Description;
        existingProduct.CategoryId = product.CategoryId;
        
        await _context.SaveChangesAsync();
    }
}
```

**Tác dụng**: 
- Chỉ update các thuộc tính cần thiết
- Tránh EF Core cố gắng update cả Category navigation property
- An toàn hơn khi nhận Product object từ API

## Kết quả
✅ Thêm sản phẩm với CategoryId hoạt động bình thường
✅ Cập nhật CategoryId của sản phẩm không gây lỗi
✅ API trả về Product kèm Category info không bị cycle

## Test
1. Thêm sản phẩm mới với dropdown chọn category → OK
2. Sửa sản phẩm và thay đổi category → OK
3. GET /api/ProductApi trả về products với category → OK
4. Xóa category → Products có CategoryId = NULL → OK

## Lưu ý
- Backend đã khởi động thành công với cảnh báo về decimal precision (không ảnh hưởng chức năng)
- Nếu còn lỗi, kiểm tra console backend để xem chi tiết error message
