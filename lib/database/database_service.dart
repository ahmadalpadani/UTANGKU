import 'package:sqflite/sqflite.dart';
import 'package:utangku_app/models/debt_model.dart';
import 'package:utangku_app/utils/constants.dart';
import 'database_helper.dart';

class DatabaseService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Create - Add new debt
  Future<int> createDebt(DebtModel debt) async {
    final db = await _dbHelper.database;
    return await db.insert(
      AppConstants.tableDebts,
      debt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Read - Get all debts
  Future<List<DebtModel>> getAllDebts() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableDebts,
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => DebtModel.fromMap(maps[i]));
  }

  // Read - Get debts by type (Utang or Piutang)
  Future<List<DebtModel>> getDebtsByType(String type) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableDebts,
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => DebtModel.fromMap(maps[i]));
  }

  // Read - Get debts by status (Lunas or Belum Lunas)
  Future<List<DebtModel>> getDebtsByStatus(String status) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableDebts,
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => DebtModel.fromMap(maps[i]));
  }

  // Read - Get debts by type and status
  Future<List<DebtModel>> getDebtsByTypeAndStatus(String type, String status) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableDebts,
      where: 'type = ? AND status = ?',
      whereArgs: [type, status],
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => DebtModel.fromMap(maps[i]));
  }

  // Read - Get unpaid debts (Belum Lunas)
  Future<List<DebtModel>> getUnpaidDebts() async {
    return await getDebtsByStatus(AppConstants.statusBelumLunas);
  }

  // Read - Get overdue debts
  Future<List<DebtModel>> getOverdueDebts() async {
    final allDebts = await getUnpaidDebts();
    return allDebts.where((debt) => debt.isOverdue).toList();
  }

  // Read - Get single debt by ID
  Future<DebtModel?> getDebtById(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableDebts,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return DebtModel.fromMap(maps.first);
  }

  // Update - Update existing debt
  Future<int> updateDebt(DebtModel debt) async {
    final db = await _dbHelper.database;
    return await db.update(
      AppConstants.tableDebts,
      debt.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [debt.id],
    );
  }

  // Update - Mark debt as paid
  Future<int> markAsPaid(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      AppConstants.tableDebts,
      {
        'status': AppConstants.statusLunas,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update - Mark debt as unpaid
  Future<int> markAsUnpaid(int id) async {
    final db = await _dbHelper.database;
    return await db.update(
      AppConstants.tableDebts,
      {
        'status': AppConstants.statusBelumLunas,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete - Delete debt by ID
  Future<int> deleteDebt(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      AppConstants.tableDebts,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Statistics - Get total amount by type and status
  Future<double> getTotalAmount(String type, String status) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total
      FROM ${AppConstants.tableDebts}
      WHERE type = ? AND status = ?
    ''', [type, status]);

    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  // Statistics - Get total unpaid utang
  Future<double> getTotalUnpaidUtang() async {
    return await getTotalAmount(
      AppConstants.debtTypeUtang,
      AppConstants.statusBelumLunas,
    );
  }

  // Statistics - Get total unpaid piutang
  Future<double> getTotalUnpaidPiutang() async {
    return await getTotalAmount(
      AppConstants.debtTypePiutang,
      AppConstants.statusBelumLunas,
    );
  }

  // Search - Search debts by name or description
  Future<List<DebtModel>> searchDebts(String query) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      AppConstants.tableDebts,
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => DebtModel.fromMap(maps[i]));
  }

  // Statistics - Monthly totals grouped by month (last 6 months)
  Future<Map<String, Map<String, double>>> getMonthlyTotals() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

    final result = await db.rawQuery('''
      SELECT
        strftime('%Y-%m', created_at) as month,
        type,
        SUM(amount) as total
      FROM ${AppConstants.tableDebts}
      WHERE created_at >= ?
      GROUP BY month, type
      ORDER BY month ASC
    ''', [sixMonthsAgo.toIso8601String()]);

    final Map<String, Map<String, double>> monthlyData = {};
    for (final row in result) {
      final month = row['month'] as String;
      final type = row['type'] as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0.0;
      monthlyData[month] ??= {'UTANG': 0.0, 'PIUTANG': 0.0};
      monthlyData[month]![type] = total;
    }
    return monthlyData;
  }

  // Statistics - Count by status
  Future<Map<String, int>> getStatusCounts() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT status, COUNT(*) as count
      FROM ${AppConstants.tableDebts}
      GROUP BY status
    ''');

    final Map<String, int> counts = {'LUNAS': 0, 'BELUM_LUNAS': 0};
    for (final row in result) {
      counts[row['status'] as String] = row['count'] as int;
    }
    return counts;
  }

  // Statistics - Count by type
  Future<Map<String, int>> getTypeCounts() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT type, COUNT(*) as count
      FROM ${AppConstants.tableDebts}
      GROUP BY type
    ''');

    final Map<String, int> counts = {'UTANG': 0, 'PIUTANG': 0};
    for (final row in result) {
      counts[row['type'] as String] = row['count'] as int;
    }
    return counts;
  }

  // Statistics - Total counts
  Future<int> getTotalCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${AppConstants.tableDebts}',
    );
    return (result.first['count'] as int?) ?? 0;
  }

  // Statistics - Average debt amount
  Future<double> getAverageAmount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT AVG(amount) as avg FROM ${AppConstants.tableDebts}',
    );
    return (result.first['avg'] as num?)?.toDouble() ?? 0.0;
  }
}
