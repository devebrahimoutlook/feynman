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

  group('FeynmanSessionDao', () {
    test('watchSessionsByNote returns empty stream initially', () async {
      final sessions = await db.feynmanSessionDao
          .watchSessionsByNote('note1')
          .first;
      expect(sessions, isEmpty);
    });

    test('watchSessionsByUser returns empty stream initially', () async {
      final sessions = await db.feynmanSessionDao
          .watchSessionsByUser('user1')
          .first;
      expect(sessions, isEmpty);
    });

    test('getSessionById returns null for non-existent', () async {
      final session = await db.feynmanSessionDao.getSessionById('nonexistent');
      expect(session, isNull);
    });

    group('write operations', () {
      test('insertSession creates session and sync queue item', () async {
        final now = DateTime.now();
        await db.feynmanSessionDao.insertSession(
          FeynmanSessionTableCompanion.insert(
            id: 'session1',
            noteId: 'note1',
            userId: 'user1',
            topic: 'Test Topic',
            inputType: 'text',
            explanation: const Value('Test explanation'),
            createdAt: now,
          ),
        );

        final session = await db.feynmanSessionDao.getSessionById('session1');
        expect(session, isNotNull);
        expect(session!.topic, equals('Test Topic'));
      });

      test('updateSession updates session', () async {
        final now = DateTime.now();
        await db.feynmanSessionDao.insertSession(
          FeynmanSessionTableCompanion.insert(
            id: 'session1',
            noteId: 'note1',
            userId: 'user1',
            topic: 'Original',
            inputType: 'text',
            explanation: const Value('Original'),
            createdAt: now,
          ),
        );

        await db.feynmanSessionDao.updateSession(
          const FeynmanSessionTableCompanion(
            id: Value('session1'),
            noteId: Value('note1'),
            userId: Value('user1'),
            topic: Value('Updated'),
            inputType: Value('text'),
            explanation: Value('Updated'),
            clarityScore: Value(80),
          ),
        );

        final session = await db.feynmanSessionDao.getSessionById('session1');
        expect(session!.topic, equals('Updated'));
      });

      test('softDeleteSession marks session as deleted', () async {
        final now = DateTime.now();
        await db.feynmanSessionDao.insertSession(
          FeynmanSessionTableCompanion.insert(
            id: 'session1',
            noteId: 'note1',
            userId: 'user1',
            topic: 'Test',
            inputType: 'text',
            explanation: const Value('Test'),
            createdAt: now,
          ),
        );

        await db.feynmanSessionDao.softDeleteSession('session1');

        final session = await db.feynmanSessionDao.getSessionById('session1');
        expect(session!.isDeleted, isTrue);
      });
    });
  });
}
