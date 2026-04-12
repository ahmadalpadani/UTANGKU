import 'package:flutter/foundation.dart';
import 'package:utangku_app/database/database_service.dart';
import 'package:utangku_app/models/debt_model.dart';
import 'package:utangku_app/models/debt_type.dart';
import 'package:utangku_app/models/payment_status.dart';
import 'package:utangku_app/services/mock_debt_service.dart';
import 'package:utangku_app/utils/constants.dart';

class DebtProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final MockDebtService _mockService = MockDebtService();

  // Use mock data for web platform
  bool get _useMockData {
    if (kIsWeb) return true;
    return false;
  }

  List<DebtModel> _allDebts = [];
  List<DebtModel> _utangList = [];
  List<DebtModel> _piutangList = [];
  List<DebtModel> _unpaidDebts = [];
  double _totalUnpaidUtang = 0.0;
  double _totalUnpaidPiutang = 0.0;

  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<DebtModel> get allDebts => _allDebts;
  List<DebtModel> get utangList => _utangList;
  List<DebtModel> get piutangList => _piutangList;
  List<DebtModel> get unpaidDebts => _unpaidDebts;
  double get totalUnpaidUtang => _totalUnpaidUtang;
  double get totalUnpaidPiutang => _totalUnpaidPiutang;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load all data
  Future<void> loadAllData() async {
    _setLoading(true);
    try {
      if (_useMockData) {
        _allDebts = await _mockService.getAllDebts();
        _utangList = await _mockService.getDebtsByType(AppConstants.debtTypeUtang);
        _piutangList = await _mockService.getDebtsByType(AppConstants.debtTypePiutang);
        _unpaidDebts = await _mockService.getUnpaidDebts();
        _totalUnpaidUtang = await _mockService.getTotalUnpaidUtang();
        _totalUnpaidPiutang = await _mockService.getTotalUnpaidPiutang();
      } else {
        _allDebts = await _dbService.getAllDebts();
        _utangList = await _dbService.getDebtsByType(AppConstants.debtTypeUtang);
        _piutangList = await _dbService.getDebtsByType(AppConstants.debtTypePiutang);
        _unpaidDebts = await _dbService.getUnpaidDebts();
        _totalUnpaidUtang = await _dbService.getTotalUnpaidUtang();
        _totalUnpaidPiutang = await _dbService.getTotalUnpaidPiutang();
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Gagal memuat data: $e';
    } finally {
      _setLoading(false);
    }
  }

  // Add new debt
  Future<bool> addDebt(DebtModel debt) async {
    _setLoading(true);
    try {
      if (_useMockData) {
        await _mockService.createDebt(debt);
      } else {
        await _dbService.createDebt(debt);
      }
      await loadAllData();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menambah data: $e';
      _setLoading(false);
      return false;
    }
  }

  // Update existing debt
  Future<bool> updateDebt(DebtModel debt) async {
    _setLoading(true);
    try {
      if (_useMockData) {
        await _mockService.updateDebt(debt);
      } else {
        await _dbService.updateDebt(debt);
      }
      await loadAllData();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengupdate data: $e';
      _setLoading(false);
      return false;
    }
  }

  // Delete debt
  Future<bool> deleteDebt(int id) async {
    _setLoading(true);
    try {
      if (_useMockData) {
        await _mockService.deleteDebt(id);
      } else {
        await _dbService.deleteDebt(id);
      }
      await loadAllData();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Gagal menghapus data: $e';
      _setLoading(false);
      return false;
    }
  }

  // Toggle payment status
  Future<bool> togglePaymentStatus(int id, PaymentStatus currentStatus) async {
    _setLoading(true);
    try {
      if (_useMockData) {
        if (currentStatus == PaymentStatus.belumLunas) {
          await _mockService.markAsPaid(id);
        } else {
          await _mockService.markAsUnpaid(id);
        }
      } else {
        if (currentStatus == PaymentStatus.belumLunas) {
          await _dbService.markAsPaid(id);
        } else {
          await _dbService.markAsUnpaid(id);
        }
      }
      await loadAllData();
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Gagal mengubah status: $e';
      _setLoading(false);
      return false;
    }
  }

  // Search debts
  Future<List<DebtModel>> searchDebts(String query) async {
    if (query.isEmpty) return _allDebts;
    if (_useMockData) {
      return await _mockService.searchDebts(query);
    }
    return await _dbService.searchDebts(query);
  }

  // Get overdue debts
  Future<List<DebtModel>> getOverdueDebts() async {
    if (_useMockData) {
      return await _mockService.getOverdueDebts();
    }
    return await _dbService.getOverdueDebts();
  }

  // Get debts by type
  Future<List<DebtModel>> getDebtsByType(DebtType type) async {
    if (type == DebtType.utang) return _utangList;
    return _piutangList;
  }

  // Get debts by status
  Future<List<DebtModel>> getDebtsByStatus(PaymentStatus status) async {
    if (_useMockData) {
      return await _mockService.getDebtsByStatus(status.value);
    }
    return await _dbService.getDebtsByStatus(status.value);
  }

  // Get statistics
  Map<String, double> getStatistics() {
    return {
      'totalUtang': _totalUnpaidUtang,
      'totalPiutang': _totalUnpaidPiutang,
      'balance': _totalUnpaidPiutang - _totalUnpaidUtang,
    };
  }

  // Helper method to set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
