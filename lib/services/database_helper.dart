import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../domain/entities/nodes/composed_node.dart';

class DatabaseHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    if (!kIsWeb &&
        (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'logic_lab.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE saved_ics (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            definition_json TEXT NOT NULL
          )
        ''');
      },
    );
  }

  static Future<void> saveIC(SubCircuitDefinition definition) async {
    try {
      final db = await database;
      final jsonStr = jsonEncode(definition.toMap(includeNodes: true));
      await db.insert('saved_ics', {
        'id': definition.id,
        'name': definition.name,
        'definition_json': jsonStr,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      debugPrint('Error saving IC to database: $e');
    }
  }

  static Future<void> deleteIC(String id) async {
    try {
      final db = await database;
      await db.delete('saved_ics', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint('Error deleting IC from database: $e');
    }
  }

  static Future<List<SubCircuitDefinition>> loadAllICs() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query('saved_ics');
      final List<SubCircuitDefinition> results = [];
      for (final map in maps) {
        try {
          final jsonStr = map['definition_json'] as String;
          final decoded = jsonDecode(jsonStr);
          final definition = SubCircuitDefinition.fromMap(decoded);
          results.add(definition);
        } catch (e) {
          debugPrint('Error decoding IC from database: $e');
        }
      }
      return results;
    } catch (e) {
      debugPrint('Error loading ICs from database: $e');
      return [];
    }
  }
}
