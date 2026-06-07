import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Uploads plan cover images to Supabase Storage (`plan-covers` bucket).
class PlanImageService {
  PlanImageService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  static const bucket = 'plan-covers';

  Future<String> uploadCover({
    required String userId,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final ext = _normalizeExt(fileExtension);
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            upsert: false,
            contentType: _contentType(ext),
          ),
        );

    return _client.storage.from(bucket).getPublicUrl(path);
  }

  String _normalizeExt(String ext) {
    final lower = ext.toLowerCase().replaceAll('.', '');
    if (lower == 'jpeg') return 'jpg';
    if (['jpg', 'png', 'webp', 'gif'].contains(lower)) return lower;
    return 'jpg';
  }

  String _contentType(String ext) {
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/jpeg',
    };
  }
}
