-- ScanNet private image storage and document-image metadata
-- Run once in Supabase SQL Editor after the project database is fully active.

create table if not exists public.document_images (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  document_id text not null,
  storage_path text not null unique,
  original_name text not null,
  created_at timestamptz not null default now()
);

alter table public.document_images enable row level security;

drop policy if exists "Users can view their own document images" on public.document_images;
create policy "Users can view their own document images"
on public.document_images for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can add their own document images" on public.document_images;
create policy "Users can add their own document images"
on public.document_images for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can delete their own document images" on public.document_images;
create policy "Users can delete their own document images"
on public.document_images for delete
to authenticated
using (auth.uid() = user_id);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'scannet-images',
  'scannet-images',
  false,
  10485760,
  array['image/jpeg','image/png','image/webp']
)
on conflict (id) do update
set public = false,
    file_size_limit = 10485760,
    allowed_mime_types = array['image/jpeg','image/png','image/webp'];

drop policy if exists "Users can upload their own ScanNet images" on storage.objects;
create policy "Users can upload their own ScanNet images"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'scannet-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users can view their own ScanNet images" on storage.objects;
create policy "Users can view their own ScanNet images"
on storage.objects for select
to authenticated
using (
  bucket_id = 'scannet-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users can delete their own ScanNet images" on storage.objects;
create policy "Users can delete their own ScanNet images"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'scannet-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);
