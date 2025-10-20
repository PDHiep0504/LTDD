# ✅ QUICK CHECKLIST - FIX AVATAR UPLOAD

## 🎯 Mục tiêu
Fix lỗi upload và load avatar từ Supabase trong 5 phút

---

## 📋 Checklist

### ☐ Bước 1: Tạo Bucket (2 phút)
1. ☐ Mở https://app.supabase.com
2. ☐ Chọn project: `suavgrsgmlphkvnojrqp`
3. ☐ Click **Storage** (menu trái)
4. ☐ Click **New bucket**
5. ☐ Name: `avatars`
6. ☐ Public bucket: ✅ **BẬT**
7. ☐ Click **Create bucket**
8. ☐ Kiểm tra: Bucket có icon 🌐

### ☐ Bước 2: Setup Policies (2 phút)
1. ☐ Click **SQL Editor** (menu trái)
2. ☐ Click **New query**
3. ☐ Copy SQL từ `lib/database/storage_policies.sql`
4. ☐ Paste vào editor
5. ☐ Click **Run** (hoặc Ctrl+Enter)
6. ☐ Đợi "Success"
7. ☐ Kiểm tra: Storage → avatars → Policies (phải có 4 policies)

### ☐ Bước 3: Fix Data Cũ (1 phút)
1. ☐ Vẫn ở SQL Editor
2. ☐ New query
3. ☐ Copy SQL từ `lib/database/fix_demo_paths.sql`
4. ☐ Paste và Run
5. ☐ Kiểm tra: Không còn record nào có `demo/` prefix

### ☐ Bước 4: Test App
1. ☐ Stop app (nếu đang chạy)
2. ☐ Restart: `flutter run`
3. ☐ Vào "Thêm thành viên"
4. ☐ Upload ảnh mới
5. ☐ Điền thông tin và Lưu
6. ☐ Kiểm tra console logs:
   - ☐ Thấy "✅ Upload successful"
   - ☐ Thấy "🔗 Public URL"
   - ☐ KHÔNG thấy "demo/" trong path
7. ☐ Click vào member vừa tạo
8. ☐ Ảnh phải hiển thị
9. ☐ Scroll xuống xem "Debug Avatar Info"
10. ☐ Path phải là: `member_xxx.jpg`

---

## 🧪 Verification

### ✅ Trên Supabase Dashboard:
- ☐ Storage → avatars: Thấy bucket
- ☐ Bucket có icon 🌐 (public)
- ☐ Storage → avatars → Policies: Có 4 policies
- ☐ Storage → avatars: Thấy files đã upload

### ✅ Trong Database:
```sql
SELECT id, full_name, avatar_path FROM public.members;
```
- ☐ `avatar_path` = `member_xxx.jpg` (KHÔNG có `demo/`)
- ☐ Hoặc `avatar_path` = NULL (nếu chưa upload)

### ✅ Test URL trực tiếp:
1. ☐ Copy URL từ "Debug Avatar Info"
2. ☐ Paste vào browser
3. ☐ Phải hiển thị ảnh

### ✅ Console Logs:
```
✅ Bucket created: avatars
⬆️ Uploading to bucket: avatars/member_xxx.jpg
📤 Upload response: avatars/member_xxx.jpg
✅ Upload successful: member_xxx.jpg
🔗 Public URL: https://suavgrsgmlphkvnojrqp.supabase.co/storage/v1/object/public/avatars/member_xxx.jpg
```

---

## ❌ Common Errors

### "Bucket already exists"
✅ OK - Bỏ qua, bucket đã tồn tại

### "Policy already exists"
✅ OK - Bỏ qua, policies đã được tạo

### "403 Forbidden" khi upload
❌ Policies chưa đúng → Chạy lại SQL policies

### "404 Not Found" khi load ảnh
❌ File không tồn tại → Upload lại

### Vẫn thấy "demo/" trong path
❌ Đang xem member cũ → Tạo member mới

---

## 📞 Need Help?

Nếu vẫn lỗi, gửi:
1. Screenshot Storage → avatars
2. Screenshot Storage → avatars → Policies
3. Console logs khi upload
4. Database query result

---

## 🎯 Success Criteria

✅ Upload ảnh thành công  
✅ Path = `member_xxx.jpg` (không có `demo/`)  
✅ Ảnh hiển thị trên detail screen  
✅ URL test trên browser OK  
✅ Không có lỗi trong console  

---

**Thời gian:** ~5 phút  
**Độ khó:** ⭐⭐☆☆☆ (Dễ)  
**Tài liệu:** `FIX_NOW.md` (chi tiết hơn)

