import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:feynman/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncQueueDao', () {
    test('watchPendingItems returns empty stream initially', () async {
      final items = await db.syncQueueDao.watchPendingItems().first;
      expect(items, isEmpty);
    });

    test('getPendingCount returns 0 initially', () async {
      final count = await db.syncQueueDao.getPendingCount();
      expect(count, equals(0));
    });

    test('getItemById returns null for non-existent', () async {
      final item = await db.syncQueueDao.getItemById(1);
      expect(item, isNull);
    });

    group('write operations', () {
      test('enqueue creates sync queue item', () async {
        await db.syncQueueDao.enqueue(
          'note',
          'note1',
          'create',
          '{"title":"Test"}',
        );

        final count = await db.syncQueueDao.getPendingCount();
        expect(count, equals(1));

        final items = await db.syncQueueDao.watchPendingItems().first;
        expect(items.first.entityType, equals('note'));
        expect(items.first.operation, equals('create'));
      });

      test('markProcessing updates status', () async {
        await db.syncQueueDao.enqueue('note', 'note1', 'create', '{}');

        final items = await db.syncQueueDao.watchPendingItems().first;
        await db.syncQueueDao.markProcessing(items.first.id);

        final updatedItems = await db.syncQueueDao.watchPendingItems().first;
        expect(updatedItems, isEmpty);
      });

      test('markCompleted updates status and adds processedAt', () async {
        await db.syncQueueDao.enqueue('note', 'note1', 'create', '{}');

        final items = await db.syncQueueDao.watchPendingItems().first;
        await db.syncQueueDao.markCompleted(items.first.id);

        final item = await db.syncQueueDao.getItemById(items.first.id);
        expect(item!.status, equals('completed'));
        expect(item.processedAt, isNotNull);
      });

      test('markFailed increments retryCount', () async {
        await db.syncQueueDao.enqueue('note', 'note1', 'create', '{}');

        final items = await db.syncQueueDao.watchPendingItems().first;
        await db.syncQueueDao.markFailed(items.first.id);

        final item = await db.syncQueueDao.getItemById(items.first.id);
        expect(item!.status, equals('failed'));
        expect(item.retryCount, equals(1));
      });
    });
  });
}
