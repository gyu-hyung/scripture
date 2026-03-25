import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/book.dart';
import '../models/verse.dart';

class BibleService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'bible.db');

    await _ensureDbCopied(path);

    return await openDatabase(path, readOnly: true);
  }

  Future<void> _ensureDbCopied(String path) async {
    final file = File(path);
    bool needsCopy = !file.existsSync();

    // 파일이 있어도 너무 작으면(헤더 미만) 손상된 것으로 간주
    if (!needsCopy && file.lengthSync() < 1024) {
      needsCopy = true;
    }

    if (!needsCopy) return;

    try {
      await Directory(dirname(path)).create(recursive: true);
      final data = await rootBundle.load('assets/db/bible.db');
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
      // 배경 isolate 등에서 rootBundle을 못 쓸 경우 기존 파일이 있으면 그냥 진행
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
    final db = await database;
    String query;
    List<Object?>? args;

    if (category != null && category != '전체') {
      query = '''
        SELECT v.*, b.name as book_name, b.abbreviation
        FROM popular_verses pv
        JOIN verses v ON pv.verse_id = v.id
        JOIN books b ON v.book_id = b.id
        WHERE pv.category = ?
      ''';
      args = [category];
    } else {
      query = '''
        SELECT v.*, b.name as book_name, b.abbreviation
        FROM popular_verses pv
        JOIN verses v ON pv.verse_id = v.id
        JOIN books b ON v.book_id = b.id
      ''';
    }

    final maps = await db.rawQuery(query, args);
    return maps.map((m) => Verse.fromMap(m)).toList();
  }

  Future<Verse?> getRandomPopularVerse({String? category}) async {
    final db = await database;
    String query;
    List<Object?>? args;

    if (category != null && category != '전체') {
      query = '''
        SELECT v.*, b.name as book_name, b.abbreviation
        FROM popular_verses pv
        JOIN verses v ON pv.verse_id = v.id
        JOIN books b ON v.book_id = b.id
        WHERE pv.category = ?
        ORDER BY RANDOM()
        LIMIT 1
      ''';
      args = [category];
    } else {
      query = '''
        SELECT v.*, b.name as book_name, b.abbreviation
        FROM popular_verses pv
        JOIN verses v ON pv.verse_id = v.id
        JOIN books b ON v.book_id = b.id
        ORDER BY RANDOM()
        LIMIT 1
      ''';
    }

    final maps = await db.rawQuery(query, args);
    if (maps.isEmpty) return null;
    return Verse.fromMap(maps.first);
  }

  Future<List<String>> getCategories() async {
    final db = await database;
    final maps = await db.rawQuery(
      'SELECT DISTINCT category FROM popular_verses ORDER BY category',
    );
    return ['전체', ...maps.map((m) => m['category'] as String)];
  }

  Future<int> getChapterCount(int bookId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MAX(chapter) as cnt FROM verses WHERE book_id = ?',
      [bookId],
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
}
