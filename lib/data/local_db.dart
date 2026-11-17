import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import 'models.dart';

/// Local SQLite store for documents and their chunk embeddings.
/// Everything lives on the device — nothing is uploaded anywhere.
class LocalDb {
  Database? _db;

  Future<void> open() async {
    if (_db != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'pocketmind.db');
    _db = await openDatabase(
      path,
      version: 2,
      onUpgrade: (db, oldVersion, _) async {
        if (oldVersion < 2) {
          // v2: library metadata for starring, "recent" and file size.
          await db.execute(
              'ALTER TABLE documents ADD COLUMN starred INTEGER NOT NULL DEFAULT 0');
          await db.execute(
              'ALTER TABLE documents ADD COLUMN last_opened_at INTEGER');
          await db.execute('ALTER TABLE documents ADD COLUMN file_size INTEGER');
        }
      },
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE documents(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            source_path TEXT NOT NULL,
            chunk_count INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            file_size INTEGER,
            starred INTEGER NOT NULL DEFAULT 0,
            last_opened_at INTEGER
          )''');
        await db.execute('''
          CREATE TABLE chunks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            document_id INTEGER NOT NULL,
            text TEXT NOT NULL,
            embedding TEXT NOT NULL,
            FOREIGN KEY(document_id) REFERENCES documents(id) ON DELETE CASCADE
          )''');
      },
    );
  }

  Database get _d => _db!;

  Future<int> insertDocument(DocumentItem doc) =>
      _d.insert('documents', doc.toMap()..remove('id'));

  Future<void> insertChunks(List<DocChunk> chunks) async {
    final batch = _d.batch();
    for (final c in chunks) {
      batch.insert('chunks', {
        'document_id': c.documentId,
        'text': c.text,
        'embedding': jsonEncode(c.embedding), // store vector as JSON text
      });
    }
    await batch.commit(noResult: true);
  }

  Future<List<DocumentItem>> getDocuments() async {
    final rows = await _d.query('documents', orderBy: 'created_at DESC');
    return rows.map(DocumentItem.fromMap).toList();
  }

  /// Updates selected metadata columns of one document.
  Future<void> updateDocument(int id, Map<String, Object?> values) =>
      _d.update('documents', values, where: 'id = ?', whereArgs: [id]);

  Future<void> deleteDocument(int id) async {
    await _d.delete('chunks', where: 'document_id = ?', whereArgs: [id]);
    await _d.delete('documents', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAllDocuments() async {
    await _d.delete('chunks');
    await _d.delete('documents');
  }

  /// Returns chunks (optionally for one document) with their vectors decoded.
  Future<List<DocChunk>> getChunks({int? documentId}) async {
    final rows = await _d.query(
      'chunks',
      where: documentId == null ? null : 'document_id = ?',
      whereArgs: documentId == null ? null : [documentId],
    );
    return rows
        .map((r) => DocChunk(
              id: r['id'] as int,
              documentId: r['document_id'] as int,
              text: r['text'] as String,
              embedding: (jsonDecode(r['embedding'] as String) as List)
                  .map((e) => (e as num).toDouble())
                  .toList(),
            ))
        .toList();
  }
}
