-- Event cover images for hosted_events.img_url
-- Run in Supabase SQL editor if the bucket is not created yet.

insert into storage.buckets (id, name, public)
values ('event-images', 'event-images', true)
on conflict (id) do nothing;

create policy "Authenticated users can upload event images"
on storage.objects for insert
to authenticated
with check (bucket_id = 'event-images');

create policy "Public read access for event images"
on storage.objects for select
to public
using (bucket_id = 'event-images');
