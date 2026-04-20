import 'package:utangku_app/models/debt_model.dart';
import 'package:utangku_app/models/debt_type.dart';
import 'package:utangku_app/models/payment_status.dart';

/// Mock data service untuk web browser
/// Menggunakan data dummy instead of SQLite database
class MockDebtService {
  static final MockDebtService _instance = MockDebtService._internal();
  factory MockDebtService() => _instance;
  MockDebtService._internal() {
    _initializeMockData();
  }

  final List<DebtModel> _mockDebts = [];

  void _initializeMockData() {
    _mockDebts.addAll([
      DebtModel(
        id: 1,
        name: 'Budi Santoso',
        amount: 1500000,
        type: DebtType.utang,
        category: 'Pinjaman',
        description: 'Utang untuk modal usaha',
        dueDate: DateTime.now().add(const Duration(days: 30)),
        status: PaymentStatus.belumLunas,
        phoneNumber: '081234567890',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      DebtModel(
        id: 2,
        name: 'Toko Maju Jaya',
        amount: 750000,
        type: DebtType.utang,
        category: 'Belanja',
        description: 'Belanja barang untuk warung',
        dueDate: DateTime.now().add(const Duration(days: 15)),
        status: PaymentStatus.belumLunas,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      DebtModel(
        id: 3,
        name: 'Andi Wijaya',
        amount: 2000000,
        type: DebtType.piutang,
        category: 'Pinjaman',
        description: 'Piutang pribadi',
        dueDate: DateTime.now().add(const Duration(days: 60)),
        status: PaymentStatus.belumLunas,
        phoneNumber: '081987654321',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      DebtModel(
        id: 4,
        name: 'Warung Serba Ada',
        amount: 500000,
        type: DebtType.piutang,
        category: 'Usaha',
        description: 'Piutang dagang',
        dueDate: DateTime.now().add(const Duration(days: 7)),
        status: PaymentStatus.lunas,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      DebtModel(
        id: 5,
        name: 'CV Abadi',
        amount: 3500000,
        type: DebtType.piutang,
        category: 'Usaha',
        description: 'Piutang fornecimento',
        dueDate: DateTime.now().subtract(const Duration(days: 3)),
        status: PaymentStatus.belumLunas,
        phoneNumber: '085678901234',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      DebtModel(
        id: 6,
        name: 'PT Maju Mundur',
        amount: 1000000,
        type: DebtType.utang,
        category: 'Tagihan',
        description: 'Tagihan listrik bulan ini',
        dueDate: DateTime.now().add(const Duration(days: 5)),
        status: PaymentStatus.lunas,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ]);
  }

  int _nextId() {
    if (_mockDebts.isEmpty) return 1;
    int maxId = 1;
    for (var d in _mockDebts) {
      if (d.id != null && d.id! > maxId) maxId = d.id!;
    }
    return maxId + 1;
  }

  Future<List<DebtModel>> getAllDebts() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.from(_mockDebts)..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<List<DebtModel>> getDebtsByType(String type) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _mockDebts.where((d) => d.type.value == type).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<List<DebtModel>> getDebtsByStatus(String status) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _mockDebts.where((d) => d.status.value == status).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<List<DebtModel>> getUnpaidDebts() async {
    return getDebtsByStatus('BELUM_LUNAS');
  }

  Future<List<DebtModel>> getOverdueDebts() async {
    final unpaid = await getUnpaidDebts();
    return unpaid.where((d) => d.isOverdue).toList();
  }

  Future<DebtModel?> getDebtById(int id) async {
    try {
      return _mockDebts.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<int> createDebt(DebtModel debt) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final newDebt = debt.copyWith(id: _nextId());
    _mockDebts.insert(0, newDebt);
    return newDebt.id!;
  }

  Future<int> updateDebt(DebtModel debt) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _mockDebts.indexWhere((d) => d.id == debt.id);
    if (index != -1) {
      _mockDebts[index] = debt.copyWith(updatedAt: DateTime.now());
    }
    return 1;
  }

  Future<int> markAsPaid(int id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _mockDebts.indexWhere((d) => d.id == id);
    if (index != -1) {
      _mockDebts[index] = _mockDebts[index].copyWith(
        status: PaymentStatus.lunas,
        updatedAt: DateTime.now(),
      );
    }
    return 1;
  }

  Future<int> markAsUnpaid(int id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _mockDebts.indexWhere((d) => d.id == id);
    if (index != -1) {
      _mockDebts[index] = _mockDebts[index].copyWith(
        status: PaymentStatus.belumLunas,
        updatedAt: DateTime.now(),
      );
    }
    return 1;
  }

  Future<int> deleteDebt(int id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _mockDebts.removeWhere((d) => d.id == id);
    return 1;
  }

  Future<double> getTotalAmount(String type, String status) async {
    await Future.delayed(const Duration(milliseconds: 50));
    final filtered = _mockDebts.where(
      (d) => d.type.value == type && d.status.value == status,
    );
    double total = 0.0;
    for (var d in filtered) {
      total += d.amount;
    }
    return total;
  }

  Future<double> getTotalUnpaidUtang() async {
    return getTotalAmount('UTANG', 'BELUM_LUNAS');
  }

  Future<double> getTotalUnpaidPiutang() async {
    return getTotalAmount('PIUTANG', 'BELUM_LUNAS');
  }

  Future<List<DebtModel>> searchDebts(String query) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final q = query.toLowerCase();
    return _mockDebts.where((d) {
      return d.name.toLowerCase().contains(q) ||
          (d.description?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  // Stats - Monthly totals (last 6 months)
  Future<Map<String, Map<String, double>>> getMonthlyTotals() async {
    await Future.delayed(const Duration(milliseconds: 50));
    final now = DateTime.now();
    final Map<String, Map<String, double>> result = {};
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      result[key] = {'UTANG': 0.0, 'PIUTANG': 0.0};
    }
    for (final debt in _mockDebts) {
      final key = '${debt.createdAt.year}-${debt.createdAt.month.toString().padLeft(2, '0')}';
      if (result.containsKey(key)) {
        result[key]![debt.type.value] =
            (result[key]![debt.type.value] ?? 0.0) + debt.amount;
      }
    }
    return result;
  }

  // Stats - Count by status
  Future<Map<String, int>> getStatusCounts() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return {
      'LUNAS': _mockDebts.where((d) => d.status == PaymentStatus.lunas).length,
      'BELUM_LUNAS': _mockDebts.where((d) => d.status == PaymentStatus.belumLunas).length,
    };
  }

  // Stats - Count by type
  Future<Map<String, int>> getTypeCounts() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return {
      'UTANG': _mockDebts.where((d) => d.type == DebtType.utang).length,
      'PIUTANG': _mockDebts.where((d) => d.type == DebtType.piutang).length,
    };
  }

  // Stats - Total count
  Future<int> getTotalCount() async {
    return _mockDebts.length;
  }

  // Stats - Average amount
  Future<double> getAverageAmount() async {
    if (_mockDebts.isEmpty) return 0.0;
    final total = _mockDebts.fold<double>(0.0, (sum, d) => sum + d.amount);
    return total / _mockDebts.length;
  }
}
