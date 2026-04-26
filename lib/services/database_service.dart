// lib/services/database_service.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/warranty.dart';
import '../models/vehicle.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'mygarage.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE warranties (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            category TEXT NOT NULL,
            modelNumber TEXT,
            purchaseDate TEXT NOT NULL,
            expiryDate TEXT NOT NULL,
            imagePath TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE vehicles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            licensePlate TEXT NOT NULL,
            brand TEXT,
            model TEXT,
            year INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE vehicle_documents (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            vehicleId INTEGER NOT NULL,
            type TEXT NOT NULL,
            validFrom TEXT,
            validTo TEXT,
            imagePath TEXT,
            notes TEXT,
            FOREIGN KEY (vehicleId) REFERENCES vehicles (id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');

        // Default settings
        await db.insert('settings', {'key': 'alertDays', 'value': '30'});
      },
    );
  }

  // ─── SETTINGS ───────────────────────────────────────────
  Future<int> getAlertDays() async {
    final db = await database;
    final result = await db.query('settings',
        where: 'key = ?', whereArgs: ['alertDays']);
    if (result.isEmpty) return 30;
    return int.tryParse(result.first['value'] as String) ?? 30;
  }

  Future<void> setAlertDays(int days) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': 'alertDays', 'value': days.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─── WARRANTIES ─────────────────────────────────────────
  Future<List<Warranty>> getWarranties() async {
    final db = await database;
    final maps = await db.query('warranties', orderBy: 'expiryDate ASC');
    return maps.map((m) => Warranty.fromMap(m)).toList();
  }

  Future<int> insertWarranty(Warranty w) async {
    final db = await database;
    return await db.insert('warranties', w.toMap()..remove('id'));
  }

  Future<void> updateWarranty(Warranty w) async {
    final db = await database;
    await db.update('warranties', w.toMap(),
        where: 'id = ?', whereArgs: [w.id]);
  }

  Future<void> deleteWarranty(int id) async {
    final db = await database;
    await db.delete('warranties', where: 'id = ?', whereArgs: [id]);
  }

  // ─── VEHICLES ───────────────────────────────────────────
  Future<List<Vehicle>> getVehicles() async {
    final db = await database;
    final vehicleMaps = await db.query('vehicles');
    final vehicles = <Vehicle>[];

    for (final vm in vehicleMaps) {
      final docMaps = await db.query('vehicle_documents',
          where: 'vehicleId = ?', whereArgs: [vm['id']]);
      final docs = docMaps.map((d) => VehicleDocument.fromMap(d)).toList();
      vehicles.add(Vehicle.fromMap(vm, documents: docs));
    }

    return vehicles;
  }

  Future<int> insertVehicle(Vehicle v) async {
    final db = await database;
    return await db.insert('vehicles', v.toMap()..remove('id'));
  }

  Future<void> updateVehicle(Vehicle v) async {
    final db = await database;
    await db.update('vehicles', v.toMap(),
        where: 'id = ?', whereArgs: [v.id]);
  }

  Future<void> deleteVehicle(int id) async {
    final db = await database;
    await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
    await db.delete('vehicle_documents',
        where: 'vehicleId = ?', whereArgs: [id]);
  }

  // ─── VEHICLE DOCUMENTS ──────────────────────────────────
  Future<int> insertDocument(VehicleDocument doc) async {
    final db = await database;
    return await db.insert('vehicle_documents', doc.toMap()..remove('id'));
  }

  Future<void> updateDocument(VehicleDocument doc) async {
    final db = await database;
    await db.update('vehicle_documents', doc.toMap(),
        where: 'id = ?', whereArgs: [doc.id]);
  }

  Future<void> deleteDocument(int id) async {
    final db = await database;
    await db.delete('vehicle_documents', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<VehicleDocument>> getAllDocuments() async {
    final db = await database;
    final maps = await db.query('vehicle_documents');
    return maps.map((m) => VehicleDocument.fromMap(m)).toList();
  }
}
