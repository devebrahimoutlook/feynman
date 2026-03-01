import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:feynman/core/providers/supabase_provider.dart';

void main() {
  group('SupabaseProvider', () {
    test('returns null when credentials not configured', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final supabase = container.read(supabaseProvider);
      expect(supabase, isNull);
    });
  });
}
