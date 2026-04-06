import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/book.dart';
import '../models/translation.dart';
import '../models/verse.dart';

class BibleService {
  /// 번역본별 DB 인스턴스 캐시 (dbFileName → Database)
  static final Map<String, Database> _databases = {};

  final Translation translation;

  BibleService(this.translation);

  Future<Database> get database async {
    final key = translation.dbFileName;
    if (_databases.containsKey(key)) return _databases[key]!;
    _databases[key] = await _initDatabase(translation.dbFileName);
    return _databases[key]!;
  }

  Future<Database> _initDatabase(String dbFileName) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, dbFileName);

    await _ensureDbCopied(path, dbFileName);

    return await openDatabase(path, readOnly: true);
  }

  Future<void> _ensureDbCopied(String path, String dbFileName) async {
    final file = File(path);
    bool needsCopy = !file.existsSync();

    if (!needsCopy && file.lengthSync() < 1024) {
      needsCopy = true;
    }

    if (!needsCopy) return;

    try {
      await Directory(dirname(path)).create(recursive: true);
      final data = await rootBundle.load('assets/db/$dbFileName');
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
      if (!file.existsSync()) rethrow;
    }
  }

  Future<List<Book>> getBooks({String? testament}) async {
    final db = await database;
    final where = testament != null ? 'testament = ?' : null;
    final whereArgs = testament != null ? [testament] : null;

    final maps = await db.query('books', where: where, whereArgs: whereArgs);
    return maps.map((m) => Book.fromMap(m)).toList();
  }

  Future<Verse?> getVerse(int bookId, int chapter, int verse) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT v.*, b.name as book_name, b.abbreviation
      FROM verses v
      JOIN books b ON v.book_id = b.id
      WHERE v.book_id = ? AND v.chapter = ? AND v.verse = ?
    ''', [bookId, chapter, verse]);

    if (maps.isEmpty) return null;
    return Verse.fromMap(maps.first);
  }

  Future<Verse?> getVerseById(int id) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT v.*, b.name as book_name, b.abbreviation
      FROM verses v
      JOIN books b ON v.book_id = b.id
      WHERE v.id = ?
    ''', [id]);

    if (maps.isEmpty) return null;
    return Verse.fromMap(maps.first);
  }

  Future<List<Verse>> getPopularVerses({String? category}) async {
    final (query, args) = _popularVersesQuery(category: category);
    final db = await database;
    final maps = await db.rawQuery(query, args);
    return maps.map((m) => Verse.fromMap(m)).toList();
  }

  Future<Verse?> getRandomPopularVerse({String? category}) async {
    final (query, args) = _popularVersesQuery(
      category: category,
      orderBy: 'ORDER BY RANDOM()',
      limit: 1,
    );
    final db = await database;
    final maps = await db.rawQuery(query, args);
    if (maps.isEmpty) return null;
    return Verse.fromMap(maps.first);
  }

  /// popular_verses 쿼리 공통 빌더
  (String, List<Object?>?) _popularVersesQuery({
    String? category,
    String orderBy = '',
    int? limit,
  }) {
    final hasCategory = category != null && category != 'all';
    final where = hasCategory ? 'WHERE pv.category = ?' : '';
    final limitClause = limit != null ? 'LIMIT $limit' : '';
    final query = '''
      SELECT v.*, b.name as book_name, b.abbreviation
      FROM popular_verses pv
      JOIN verses v ON pv.verse_id = v.id
      JOIN books b ON v.book_id = b.id
      $where $orderBy $limitClause
    ''';
    return (query, hasCategory ? [category] : null);
  }

  Future<List<String>> getCategories() async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT DISTINCT category FROM popular_verses ORDER BY category',
    );
    return ['all', ...maps.map((m) => m['category'] as String)];
  }

  Future<int> getChapterCount(int bookId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MAX(chapter) as cnt FROM verses WHERE book_id = ?',
      [bookId],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<int> getVerseCount(int bookId, int chapter) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MAX(verse) as cnt FROM verses WHERE book_id = ? AND chapter = ?',
      [bookId, chapter],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<List<Verse>> getVersesByChapter(int bookId, int chapter) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT v.*, b.name as book_name, b.abbreviation
      FROM verses v
      JOIN books b ON v.book_id = b.id
      WHERE v.book_id = ? AND v.chapter = ?
      ORDER BY v.verse
    ''', [bookId, chapter]);
    return maps.map((m) => Verse.fromMap(m)).toList();
  }

  /// 키워드로 전체 성경 구절 검색 (책 이름, 절 번호 포함)
  Future<List<Verse>> searchVerses(String keyword) async {
    if (keyword.trim().isEmpty) return [];
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT v.*, b.name as book_name, b.abbreviation
      FROM verses v
      JOIN books b ON v.book_id = b.id
      WHERE v.text LIKE ?
      ORDER BY v.book_id, v.chapter, v.verse
      LIMIT 500
    ''', ['%$keyword%']);
    return maps.map((m) => Verse.fromMap(m)).toList();
  }

  /// 번역본 전환 시 해당 DB 캐시 제거
  static void clearCache(String dbFileName) {
    _databases.remove(dbFileName);
  }

  /// 모든 DB 캐시 제거
  static void clearAllCache() {
    _databases.clear();
  }
}
