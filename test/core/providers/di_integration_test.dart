import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:feynman/core/providers/database_provider.dart';
import 'package:feynman/core/providers/logger_provider.dart';
import 'package:feynman/core/providers/supabase_provider.dart';
import 'package:feynman/core/database/app_database.dart';
import 'package:feynman/core/logging/app_logger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('DI Integration', () {
    test('databaseProvider resolves to AppDatabase', () {
      final result = container.read(databaseProvider);
      expect(result, isA<AppDatabase>());
    });

    test('loggerProvider resolves to AppLogger', () {
      final logger = container.read(loggerProvider);
      expect(logger, isA<AppLogger>());
    });

    test('supabaseProvider resolves without throwing', () {
      // Without credentials, should return null (offline mode)
      final client = container.read(supabaseProvider);
      expect(client, isNull);
    });

    test('sample feature provider can depend on core providers', () {
      final sampleFeatureProvider = Provider<String>((ref) {
        final db = ref.read(databaseProvider);
        final logger = ref.read(loggerProvider);
        logger.info('SampleFeature', 'Initialized with DB: ${db.hashCode}');
        return 'feature_ready';
      });

      final result = container.read(sampleFeatureProvider);
      expect(result, 'feature_ready');
    });
  });
}
