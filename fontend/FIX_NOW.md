# 🚨 FIX LỖI AVATAR NGAY BÂY GIỜ

## ❌ Lỗi hiện tại

```
HttpException: Invalid statusCode: 400
URL: https://suavgrsgmlphkvnojrqp.supabase.co/storage/v1/object/public/avatars/demo/member_xxx.jpg
Path: demo/member_1759203630326.jpg
```

**Nguyên nhân:** 
- Bucket "avatars" chưa được tạo hoặc chưa public
- Storage policies chưa được setup
- Code fallback về demo mode và lưu path sai: `demo/member_xxx.jpg`

---

## ✅ GIẢI PHÁP (5 PHÚT)

### Bước 1: Tạo Bucket (2 phút)

1. Mở [Supabase Dashboard](https://app.supabase.com)
2. Chọn project: `suavgrsgmlphkvnojrqp`
3. Click **Storage** (menu bên trái)
4. Click **New bucket**
5. Điền:
   - **Name**: `avatars`
   - **Public bucket**: ✅ **BẬT** (quan trọng!)
6. Click **Create bucket**

### Bước 2: Setup Policies (2 phút)

1. Vẫn ở Supabase Dashboard
2. Click **SQL Editor** (menu bên trái)
3. Click **New query**
4. Copy toàn bộ code dưới đây:

```sql
-- Tạo bucket (nếu chưa có)
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

-- Policy: Public Read
create policy "avatars_public_read"
on storage.objects for select
to public
using (bucket_id = 'avatars');

-- Policy: Anonymous Upload (vì app không dùng auth)
create policy "avatars_anon_upload"
on storage.objects for insert
to anon
with check (bucket_id = 'avatars');

-- Policy: Anonymous Update
create policy "avatars_anon_update"
on storage.objects for update
to anon
using (bucket_id = 'avatars');

-- Policy: Anonymous Delete
create policy "avatars_anon_delete"
on storage.objects for delete
to anon
using (bucket_id = 'avatars');
```

5. Click **Run** (hoặc Ctrl+Enter)
6. Đợi thông báo "Success"

### Bước 3: Fix Data Cũ (1 phút)

1. Vẫn ở SQL Editor
2. Tạo query mới
3. Copy code:

```sql
-- Xóa avatar_path có "demo/" prefix
UPDATE public.members 
SET avatar_path = NULL 
WHERE avatar_path LIKE 'demo/%';

-- Kiểm tra
SELECT id, full_name, avatar_path 
FROM public.members;
```

4. Click **Run**

### Bước 4: Test lại App

1. **Stop app** (nếu đang chạy)
2. **Restart app:**
   ```bash
   flutter run
   ```

3. **Thử upload ảnh mới:**
   - Vào màn hình "Thêm thành viên"
   - Chọn ảnh
   - Điền thông tin
   - Click "Lưu"

4. **Kiểm tra console logs:**
   ```
   ✅ Bucket created: avatars
   ⬆️ Uploading to bucket: avatars/member_xxx.jpg
   📤 Upload response: avatars/member_xxx.jpg
   ✅ Upload successful: member_xxx.jpg
   🔗 Public URL: https://...
   ```

5. **Xem chi tiết member:**
   - Click vào member vừa tạo
   - Ảnh phải hiển thị
   - Scroll xuống xem "Debug Avatar Info"
   - Path phải là: `member_xxx.jpg` (KHÔNG có `demo/`)

---

## 🔍 Kiểm tra đã OK chưa

### ✅ Checklist:

- [ ] Bucket "avatars" đã được tạo
- [ ] Bucket "avatars" có icon 🌐 (public)
- [ ] SQL policies đã chạy thành công
- [ ] Data cũ đã được fix (không còn `demo/` prefix)
- [ ] Upload ảnh mới thành công
- [ ] Console logs không có lỗi
- [ ] Ảnh hiển thị trên detail screen
- [ ] Path trong database: `member_xxx.jpg` (không có `demo/`)

### 🧪 Test nhanh:

1. **Test trên Supabase Dashboard:**
   - Vào Storage → avatars
   - Phải thấy files đã upload
   - Click vào file → Copy URL
   - Paste URL vào browser → Phải hiển thị ảnh

2. **Test trong app:**
   - Upload ảnh mới
   - Xem console logs
   - Vào detail screen
   - Xem "Debug Avatar Info"
   - Copy URL và test trên browser

---

## 🐛 Nếu vẫn lỗi

### Lỗi: "Bucket already exists"
- ✅ OK, bỏ qua lỗi này
- Bucket đã tồn tại rồi

### Lỗi: "Policy already exists"
- ✅ OK, bỏ qua lỗi này
- Policies đã được tạo rồi

### Lỗi: "403 Forbidden" khi upload
- ❌ Policies chưa đúng
- Chạy lại SQL policies
- Đảm bảo có policy cho `anon` role

### Lỗi: "404 Not Found" khi load ảnh
- ❌ File không tồn tại
- Upload lại ảnh
- Kiểm tra path trong database

### Lỗi: Vẫn thấy `demo/` trong path
- ❌ Chưa chạy fix_demo_paths.sql
- Hoặc đang xem member cũ
- Tạo member mới để test

---

## 📞 Cần hỗ trợ?

Gửi cho tôi:

1. **Screenshot Storage:**
   - Supabase Dashboard → Storage → avatars
   - Phải thấy bucket và files

2. **Screenshot Policies:**
   - Storage → avatars → Policies
   - Phải có 4 policies

3. **Console logs:**
   - Copy toàn bộ logs khi upload
   - Từ "🖼️ Starting avatar upload" đến hết

4. **Database data:**
   ```sql
   SELECT id, full_name, avatar_path 
   FROM public.members 
   LIMIT 5;
   ```

---

## 🎯 Tóm tắt

1. ✅ Tạo bucket "avatars" (public = true)
2. ✅ Chạy SQL policies
3. ✅ Fix data cũ (xóa `demo/` prefix)
4. ✅ Restart app
5. ✅ Test upload ảnh mới
6. ✅ Kiểm tra ảnh hiển thị

**Thời gian:** ~5 phút

**Kết quả:** Avatar upload và hiển thị OK ✅

