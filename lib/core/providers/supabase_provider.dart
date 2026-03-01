import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseProvider = Provider<SupabaseClient?>((ref) {
  ref.keepAlive();
  try {
    return Supabase.instance.client;
  } catch (_) {
    // Supabase not initialized (offline mode)
    return null;
  }
});
