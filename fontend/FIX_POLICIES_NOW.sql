-- ========================================
-- FIX STORAGE POLICIES - COPY & RUN THIS
-- ========================================
-- Chạy script này trong Supabase SQL Editor để fix lỗi 403

-- Bước 1: Xóa policies cũ (cho authenticated users)
drop policy if exists "avatars_authenticated_upload" on storage.objects;
drop policy if exists "avatars_authenticated_update" on storage.objects;
drop policy if exists "avatars_authenticated_delete" on storage.objects;

-- Bước 2: Tạo policies mới (cho anonymous users)
create policy "avatars_anon_upload"
on storage.objects for insert
to anon
with check (bucket_id = 'avatars');

create policy "avatars_anon_update"
on storage.objects for update
to anon
using (bucket_id = 'avatars');

create policy "avatars_anon_delete"
on storage.objects for delete
to anon
using (bucket_id = 'avatars');

-- Bước 3: Kiểm tra policies đã được tạo
select 
  schemaname,
  tablename,
  policyname,
  roles,
  cmd
from pg_policies
where tablename = 'objects' 
  and policyname like 'avatars%'
order by policyname;

-- Kết quả mong đợi:
-- avatars_anon_delete   | {anon}  | DELETE
-- avatars_anon_update   | {anon}  | UPDATE
-- avatars_anon_upload   | {anon}  | INSERT
-- avatars_public_read   | {public}| SELECT

