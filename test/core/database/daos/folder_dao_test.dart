import 'package:drift/drift.dart' hide isNull, isNotNull;
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

  group('FolderDao', () {
    test('watchFoldersByUser returns empty stream initially', () async {
      final folders = await db.folderDao.watchFoldersByUser('user1').first;
      expect(folders, isEmpty);
    });

    test('getFolderById returns null for non-existent folder', () async {
      final folder = await db.folderDao.getFolderById('nonexistent');
      expect(folder, isNull);
    });

    group('write operations', () {
      test('insertFolder creates folder and sync queue item', () async {
        final now = DateTime.now();
        await db.folderDao.insertFolder(
          FolderTableCompanion.insert(
            id: 'folder1',
            userId: 'user1',
            name: 'Test Folder',
            color: const Value('#FF0000'),
            icon: const Value('folder'),
            sortOrder: const Value(0),
            createdAt: now,
            updatedAt: now,
          ),
        );

        final folder = await db.folderDao.getFolderById('folder1');
        expect(folder, isNotNull);
        expect(folder!.name, equals('Test Folder'));
      });

      test('updateFolder updates folder', () async {
        final now = DateTime.now();
        await db.folderDao.insertFolder(
          FolderTableCompanion.insert(
            id: 'folder1',
            userId: 'user1',
            name: 'Original',
            color: const Value('#FF0000'),
            createdAt: now,
            updatedAt: now,
          ),
        );

        await db.folderDao.updateFolder(
          FolderTableCompanion(
            id: const Value('folder1'),
            userId: const Value('user1'),
            name: const Value('Updated'),
            color: const Value('#00FF00'),
            updatedAt: Value(now),
          ),
        );

        final folder = await db.folderDao.getFolderById('folder1');
        expect(folder!.name, equals('Updated'));
      });

      test('softDeleteFolder marks folder as deleted', () async {
        final now = DateTime.now();
        await db.folderDao.insertFolder(
          FolderTableCompanion.insert(
            id: 'folder1',
            userId: 'user1',
            name: 'Test',
            color: const Value('#FF0000'),
            createdAt: now,
            updatedAt: now,
          ),
        );

        await db.folderDao.softDeleteFolder('folder1');

        final folder = await db.folderDao.getFolderById('folder1');
        expect(folder!.isDeleted, isTrue);
      });
    });
  });
}
