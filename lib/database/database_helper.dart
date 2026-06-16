import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_profile.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('real_estate.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 5, onCreate: _createDB, onUpgrade: _upgradeDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE owners (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        address TEXT NOT NULL,
        notes TEXT DEFAULT '',
        looking_for TEXT DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE properties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        owner_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        city TEXT NOT NULL,
        state TEXT NOT NULL,
        zip TEXT NOT NULL,
        type TEXT DEFAULT 'Residential',
        total_units INTEGER DEFAULT 1,
        notes TEXT DEFAULT '',
        status TEXT DEFAULT 'rental',
        created_at TEXT NOT NULL,
        FOREIGN KEY (owner_id) REFERENCES owners (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        property_id INTEGER NOT NULL,
        unit_number TEXT NOT NULL,
        bedrooms INTEGER DEFAULT 1,
        bathrooms INTEGER DEFAULT 1,
        square_feet REAL DEFAULT 0,
        rent_amount REAL DEFAULT 0,
        security_deposit REAL DEFAULT 0,
        is_occupied INTEGER DEFAULT 0,
        notes TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (property_id) REFERENCES properties (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE tenants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        emergency_contact TEXT DEFAULT '',
        emergency_phone TEXT DEFAULT '',
        id_number TEXT DEFAULT '',
        notes TEXT DEFAULT '',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE leases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        unit_id INTEGER NOT NULL,
        tenant_id INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        rent_amount REAL DEFAULT 0,
        security_deposit REAL DEFAULT 0,
        is_active INTEGER DEFAULT 1,
        notes TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (unit_id) REFERENCES units (id) ON DELETE CASCADE,
        FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        lease_id INTEGER NOT NULL,
        tenant_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        payment_type TEXT DEFAULT 'Rent',
        status TEXT DEFAULT 'Paid',
        notes TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (lease_id) REFERENCES leases (id) ON DELETE CASCADE,
        FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE maintenance_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        unit_id INTEGER NOT NULL,
        tenant_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        priority TEXT DEFAULT 'Medium',
        status TEXT DEFAULT 'Pending',
        created_at TEXT NOT NULL,
        resolved_at TEXT,
        FOREIGN KEY (unit_id) REFERENCES units (id) ON DELETE CASCADE,
        FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE
      )
    ''');
    await _createNewTables(db);
  }

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return await db.insert(table, values);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await database;
    return await db.query(table, orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> query(
      String table, String column, dynamic value) async {
    final db = await database;
    return await db.query(table, where: '$column = ?', whereArgs: [value]);
  }

  Future<Map<String, dynamic>?> queryById(String table, int id) async {
    final db = await database;
    final results = await db.query(table, where: 'id = ?', whereArgs: [id]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> update(String table, Map<String, dynamic> values, int id) async {
    final db = await database;
    return await db.update(table, values, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, int id) async {
    final db = await database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getCount(String table) async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM $table');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<double> getTotalRentCollected() async {
    final db = await database;
    final result = await db.rawQuery(
        "SELECT COALESCE(SUM(amount), 0) as total FROM payments WHERE status = 'Paid'");
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<double> getTotalRentDue() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(l.rent_amount), 0) as total
      FROM leases l
      WHERE l.is_active = 1
    ''');
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<List<Map<String, dynamic>>> getDashboardStats() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        (SELECT COUNT(*) FROM properties) as total_properties,
        (SELECT COUNT(*) FROM units) as total_units,
        (SELECT COUNT(*) FROM units WHERE is_occupied = 1) as occupied_units,
        (SELECT COUNT(*) FROM tenants) as total_tenants,
        (SELECT COUNT(*) FROM leases WHERE is_active = 1) as active_leases,
        (SELECT COUNT(*) FROM maintenance_requests WHERE status != 'Completed') as open_maintenance,
        (SELECT COALESCE(SUM(amount), 0) FROM payments WHERE status = 'Paid') as total_collected,
        (SELECT COUNT(*) FROM maintenance_requests) as total_maintenance
    ''');
  }

  Future<List<Map<String, dynamic>>> getRecentPayments(int limit) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT p.*, t.name as tenant_name
      FROM payments p
      LEFT JOIN tenants t ON p.tenant_id = t.id
      ORDER BY p.created_at DESC
      LIMIT $limit
    ''');
  }

  Future<List<Map<String, dynamic>>> getActiveLeasesWithDetails() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT l.*, t.name as tenant_name, u.unit_number, p.name as property_name
      FROM leases l
      LEFT JOIN tenants t ON l.tenant_id = t.id
      LEFT JOIN units u ON l.unit_id = u.id
      LEFT JOIN properties p ON u.property_id = p.id
      WHERE l.is_active = 1
      ORDER BY l.end_date ASC
    ''');
  }

  Future<List<Map<String, dynamic>>> searchProperties(String queryText) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT * FROM properties
      WHERE name LIKE ? OR address LIKE ? OR city LIKE ?
      ORDER BY created_at DESC
    ''', ['%$queryText%', '%$queryText%', '%$queryText%']);
  }

  Future<List<Map<String, dynamic>>> searchTenants(String queryText) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT * FROM tenants
      WHERE name LIKE ? OR email LIKE ? OR phone LIKE ?
      ORDER BY created_at DESC
    ''', ['%$queryText%', '%$queryText%', '%$queryText%']);
  }

  Future<List<Map<String, dynamic>>> getUnitsByProperty(int propertyId) async {
    final db = await database;
    return await db.query('units',
        where: 'property_id = ?', whereArgs: [propertyId], orderBy: 'unit_number ASC');
  }

  Future<List<Map<String, dynamic>>>
      getMaintenanceRequestsByProperty(int propertyId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT mr.*, u.unit_number, t.name as tenant_name
      FROM maintenance_requests mr
      LEFT JOIN units u ON mr.unit_id = u.id
      LEFT JOIN tenants t ON mr.tenant_id = t.id
      WHERE u.property_id = ?
      ORDER BY mr.created_at DESC
    ''', [propertyId]);
  }

  Future<Map<String, dynamic>?> getPropertyWithOwner(int propertyId) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT p.*, o.name as owner_name, o.email as owner_email, o.phone as owner_phone
      FROM properties p
      LEFT JOIN owners o ON p.owner_id = o.id
      WHERE p.id = ?
    ''', [propertyId]);
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getMonthlyRevenue(int year) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        strftime('%m', payment_date) as month,
        COALESCE(SUM(amount), 0) as total
      FROM payments
      WHERE status = 'Paid' AND strftime('%Y', payment_date) = ?
      GROUP BY month
      ORDER BY month
    ''', [year.toString()]);
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createNewTables(db);
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          uid TEXT NOT NULL UNIQUE,
          email TEXT NOT NULL,
          name TEXT DEFAULT '',
          role TEXT DEFAULT 'landlord',
          phone TEXT DEFAULT '',
          is_active INTEGER DEFAULT 1,
          owner_id INTEGER,
          tenant_id INTEGER,
          created_at TEXT NOT NULL,
          FOREIGN KEY (owner_id) REFERENCES owners (id) ON DELETE SET NULL,
          FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE SET NULL
        )
      ''');
    }
    if (oldVersion < 4) {
      try {
        await db.execute(
            "ALTER TABLE owners ADD COLUMN looking_for TEXT DEFAULT ''");
      } catch (_) {}
      try {
        await db.execute(
            "ALTER TABLE properties ADD COLUMN status TEXT DEFAULT 'rental'");
      } catch (_) {}
    }
    if (oldVersion < 5) {
      try {
        await db.execute(
            "ALTER TABLE users ADD COLUMN is_active INTEGER DEFAULT 1");
      } catch (_) {}
    }
  }

  Future<void> _createNewTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        property_id INTEGER,
        unit_id INTEGER,
        tenant_id INTEGER,
        name TEXT NOT NULL,
        file_path TEXT NOT NULL,
        category TEXT DEFAULT 'Other',
        notes TEXT DEFAULT '',
        created_at TEXT NOT NULL,
        FOREIGN KEY (property_id) REFERENCES properties (id) ON DELETE CASCADE,
        FOREIGN KEY (unit_id) REFERENCES units (id) ON DELETE CASCADE,
        FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS inspections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        property_id INTEGER NOT NULL,
        unit_id INTEGER,
        title TEXT NOT NULL,
        type TEXT DEFAULT 'Move-in',
        overall_condition TEXT DEFAULT 'Good',
        notes TEXT DEFAULT '',
        inspection_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (property_id) REFERENCES properties (id) ON DELETE CASCADE,
        FOREIGN KEY (unit_id) REFERENCES units (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS inspection_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inspection_id INTEGER NOT NULL,
        room_name TEXT NOT NULL,
        category TEXT DEFAULT 'General',
        condition TEXT DEFAULT 'Good',
        notes TEXT DEFAULT '',
        photo_path TEXT,
        FOREIGN KEY (inspection_id) REFERENCES inspections (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        property_id INTEGER NOT NULL,
        unit_id INTEGER,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT DEFAULT 'Repairs',
        description TEXT DEFAULT '',
        receipt_path TEXT,
        expense_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (property_id) REFERENCES properties (id) ON DELETE CASCADE,
        FOREIGN KEY (unit_id) REFERENCES units (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS approvals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        reference_type TEXT NOT NULL,
        reference_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        amount REAL,
        requested_by TEXT DEFAULT '',
        requested_by_name TEXT,
        status TEXT DEFAULT 'Pending',
        reviewed_by TEXT,
        review_notes TEXT,
        reviewed_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS communication_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        property_id INTEGER,
        unit_id INTEGER,
        tenant_id INTEGER,
        owner_id INTEGER,
        type TEXT DEFAULT 'Phone',
        subject TEXT DEFAULT '',
        notes TEXT DEFAULT '',
        direction TEXT DEFAULT 'Outbound',
        communication_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (property_id) REFERENCES properties (id) ON DELETE CASCADE,
        FOREIGN KEY (unit_id) REFERENCES units (id) ON DELETE CASCADE,
        FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE,
        FOREIGN KEY (owner_id) REFERENCES owners (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid TEXT NOT NULL UNIQUE,
        email TEXT NOT NULL,
        name TEXT DEFAULT '',
        role TEXT DEFAULT 'landlord',
        phone TEXT DEFAULT '',
        is_active INTEGER DEFAULT 1,
        owner_id INTEGER,
        tenant_id INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (owner_id) REFERENCES owners (id) ON DELETE SET NULL,
        FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tasks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        property_id INTEGER,
        unit_id INTEGER,
        tenant_id INTEGER,
        title TEXT NOT NULL,
        description TEXT DEFAULT '',
        priority TEXT DEFAULT 'Medium',
        status TEXT DEFAULT 'Pending',
        assigned_to TEXT,
        due_date TEXT,
        completed_at TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (property_id) REFERENCES properties (id) ON DELETE CASCADE,
        FOREIGN KEY (unit_id) REFERENCES units (id) ON DELETE CASCADE,
        FOREIGN KEY (tenant_id) REFERENCES tenants (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> getDocumentsByTarget({
    int? propertyId,
    int? unitId,
    int? tenantId,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];
    if (propertyId != null) {
      conditions.add('property_id = ?');
      args.add(propertyId);
    }
    if (unitId != null) {
      conditions.add('unit_id = ?');
      args.add(unitId);
    }
    if (tenantId != null) {
      conditions.add('tenant_id = ?');
      args.add(tenantId);
    }
    final where = conditions.isNotEmpty ? conditions.join(' OR ') : null;
    return await db.query('documents',
        where: where, whereArgs: args, orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getInspectionsByProperty(
      int propertyId) async {
    final db = await database;
    return await db.query('inspections',
        where: 'property_id = ?',
        whereArgs: [propertyId],
        orderBy: 'inspection_date DESC');
  }

  Future<List<Map<String, dynamic>>> getInspectionItems(int inspectionId) async {
    final db = await database;
    return await db.query('inspection_items',
        where: 'inspection_id = ?', whereArgs: [inspectionId]);
  }

  Future<List<Map<String, dynamic>>> getExpensesByProperty(
      int propertyId) async {
    final db = await database;
    return await db.query('expenses',
        where: 'property_id = ?',
        whereArgs: [propertyId],
        orderBy: 'expense_date DESC');
  }

  Future<List<Map<String, dynamic>>> getExpensesByCategory() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT category, COALESCE(SUM(amount), 0) as total
      FROM expenses
      GROUP BY category
      ORDER BY total DESC
    ''');
  }

  Future<double> getTotalExpensesByProperty(int propertyId) async {
    final db = await database;
    final result = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE property_id = ?',
        [propertyId]);
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  Future<List<Map<String, dynamic>>> searchExpenses(String queryText) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT e.*, p.name as property_name
      FROM expenses e
      LEFT JOIN properties p ON e.property_id = p.id
      WHERE e.title LIKE ? OR e.category LIKE ? OR p.name LIKE ?
      ORDER BY e.expense_date DESC
    ''', ['%$queryText%', '%$queryText%', '%$queryText%']);
  }

  Future<List<Map<String, dynamic>>> getPendingApprovals() async {
    final db = await database;
    return await db.query('approvals',
        where: 'status = ?',
        whereArgs: ['Pending'],
        orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getAllApprovals() async {
    final db = await database;
    return await db.query('approvals', orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getCommunicationsByTarget({
    int? propertyId,
    int? tenantId,
    int? ownerId,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];
    if (propertyId != null) {
      conditions.add('property_id = ?');
      args.add(propertyId);
    }
    if (tenantId != null) {
      conditions.add('tenant_id = ?');
      args.add(tenantId);
    }
    if (ownerId != null) {
      conditions.add('owner_id = ?');
      args.add(ownerId);
    }
    final where = conditions.isNotEmpty ? conditions.join(' OR ') : null;
    return await db.query('communication_logs',
        where: where,
        whereArgs: args,
        orderBy: 'communication_date DESC');
  }

  Future<List<Map<String, dynamic>>> getAllCommunications() async {
    final db = await database;
    return await db.query('communication_logs',
        orderBy: 'communication_date DESC');
  }

  Future<List<Map<String, dynamic>>> getTasks({
    String? status,
    int? propertyId,
  }) async {
    final db = await database;
    final conditions = <String>[];
    final args = <dynamic>[];
    if (status != null) {
      conditions.add('status = ?');
      args.add(status);
    }
    if (propertyId != null) {
      conditions.add('property_id = ?');
      args.add(propertyId);
    }
    final where =
        conditions.isNotEmpty ? conditions.join(' AND ') : null;
    return await db.query('tasks',
        where: where,
        whereArgs: args,
        orderBy: 'due_date ASC, created_at DESC');
  }

  Future<List<Map<String, dynamic>>> searchTasks(String queryText) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT t.*, p.name as property_name
      FROM tasks t
      LEFT JOIN properties p ON t.property_id = p.id
      WHERE t.title LIKE ? OR t.assigned_to LIKE ? OR p.name LIKE ?
      ORDER BY t.due_date ASC
    ''', ['%$queryText%', '%$queryText%', '%$queryText%']);
  }

  Future<Map<String, dynamic>> getExpenseSummary() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        COALESCE(SUM(amount), 0) as total_expenses,
        COUNT(*) as expense_count
      FROM expenses
    ''');
    return result.first;
  }

  Future<Map<String, dynamic>> getProfitLoss(int propertyId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT
        (SELECT COALESCE(SUM(p.amount), 0) FROM payments p
         JOIN leases l ON p.lease_id = l.id
         JOIN units u ON l.unit_id = u.id
         WHERE u.property_id = ? AND p.status = 'Paid') as total_income,
        (SELECT COALESCE(SUM(e.amount), 0) FROM expenses e
         WHERE e.property_id = ?) as total_expenses
    ''', [propertyId, propertyId]).then((r) => r.first);
  }

  Future<UserProfile?> getUserByUid(String uid) async {
    final db = await database;
    final results = await db.query('users', where: 'uid = ?', whereArgs: [uid]);
    if (results.isEmpty) return null;
    return UserProfile.fromMap(results.first);
  }

  Future<UserProfile?> getUserByEmail(String email) async {
    final db = await database;
    final results =
        await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (results.isEmpty) return null;
    return UserProfile.fromMap(results.first);
  }

  Future<int> insertUser(UserProfile user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<void> updateUser(UserProfile user) async {
    final db = await database;
    await db.update('users', user.toMap(),
        where: 'uid = ?', whereArgs: [user.uid]);
  }

  Future<void> deleteUser(String uid) async {
    final db = await database;
    await db.delete('users', where: 'uid = ?', whereArgs: [uid]);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}
