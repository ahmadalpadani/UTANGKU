import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:utangku_app/database/database_service.dart';
import 'package:utangku_app/models/debt_model.dart';
import 'package:utangku_app/models/debt_type.dart';
import 'package:utangku_app/models/payment_status.dart';
import 'package:utangku_app/services/mock_debt_service.dart';
import 'package:utangku_app/services/notification_service.dart';
import 'package:utangku_app/utils/constants.dart';

class DebtProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final MockDebtService _mockService = MockDebtService();
  final NotificationService _notificationService = NotificationService();

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

  // Stats
  final Map<String, Map<String, double>> _monthlyTotals = {};
  final Map<String, int> _statusCounts = {'LUNAS': 0, 'BELUM_LUNAS': 0};
  final Map<String, int> _typeCounts = {'UTANG': 0, 'PIUTANG': 0};
  int _totalCount = 0;
  double _averageAmount = 0.0;

  // Notification settings
  bool _notificationsEnabled = true;
  bool _dueDateReminders = true;
  bool _overdueAlerts = true;

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

  // Notification getters
  bool get notificationsEnabled => _notificationsEnabled;
  bool get dueDateReminders => _dueDateReminders;
  bool get overdueAlerts => _overdueAlerts;

  // Stats Getters
  Map<String, Map<String, double>> get monthlyTotals => _monthlyTotals;
  Map<String, int> get statusCounts => _statusCounts;
  Map<String, int> get typeCounts => _typeCounts;
  int get totalCount => _totalCount;
  double get averageAmount => _averageAmount;

  int get paidCount => _statusCounts['LUNAS'] ?? 0;
  int get unpaidCount => _statusCounts['BELUM_LUNAS'] ?? 0;
  int get utangCount => _typeCounts['UTANG'] ?? 0;
  int get piutangCount => _typeCounts['PIUTANG'] ?? 0;

  double get paidPercentage {
    if (_totalCount == 0) return 0.0;
    return (paidCount / _totalCount) * 100;
  }

  double get unpaidPercentage {
    if (_totalCount == 0) return 0.0;
    return (unpaidCount / _totalCount) * 100;
  }

  // Load notification settings from SharedPreferences
  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool(AppConstants.keyNotificationsEnabled) ?? true;
      _dueDateReminders = prefs.getBool(AppConstants.keyDueDateReminders) ?? true;
      _overdueAlerts = prefs.getBool(AppConstants.keyOverdueAlerts) ?? true;
    } catch (_) {
      // Use defaults if prefs fail
    }
  }

  // Save notification settings
  Future<void> _saveNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyNotificationsEnabled, _notificationsEnabled);
      await prefs.setBool(AppConstants.keyDueDateReminders, _dueDateReminders);
      await prefs.setBool(AppConstants.keyOverdueAlerts, _overdueAlerts);
    } catch (_) {}
  }

  // Toggle notifications on/off
  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    await _saveNotificationSettings();
    if (value) {
      await _notificationService.scheduleAllReminders(_unpaidDebts);
    } else {
      await _notificationService.cancelAllNotifications();
    }
    notifyListeners();
  }

  // Toggle due date reminders
  Future<void> setDueDateReminders(bool value) async {
    _dueDateReminders = value;
    await _saveNotificationSettings();
    if (_notificationsEnabled) {
      await _notificationService.scheduleAllReminders(_unpaidDebts);
    }
    notifyListeners();
  }

  // Toggle overdue alerts
  Future<void> setOverdueAlerts(bool value) async {
    _overdueAlerts = value;
    await _saveNotificationSettings();
    if (_notificationsEnabled) {
      await _notificationService.scheduleAllReminders(_unpaidDebts);
    }
    notifyListeners();
  }

  // Load all data
  Future<void> loadAllData() async {
    _setLoading(true);
    await _loadNotificationSettings();

    try {
      if (_useMockData) {
        _allDebts = await _mockService.getAllDebts();
        _utangList = await _mockService.getDebtsByType(AppConstants.debtTypeUtang);
        _piutangList = await _mockService.getDebtsByType(AppConstants.debtTypePiutang);
        _unpaidDebts = await _mockService.getUnpaidDebts();
        _totalUnpaidUtang = await _mockService.getTotalUnpaidUtang();
        _totalUnpaidPiutang = await _mockService.getTotalUnpaidPiutang();

        // Load statistics
        final monthly = await _mockService.getMonthlyTotals();
        _monthlyTotals.clear();
        _monthlyTotals.addAll(monthly);

        final statusCounts = await _mockService.getStatusCounts();
        _statusCounts['LUNAS'] = statusCounts['LUNAS'] ?? 0;
        _statusCounts['BELUM_LUNAS'] = statusCounts['BELUM_LUNAS'] ?? 0;

        final typeCounts = await _mockService.getTypeCounts();
        _typeCounts['UTANG'] = typeCounts['UTANG'] ?? 0;
        _typeCounts['PIUTANG'] = typeCounts['PIUTANG'] ?? 0;

        _totalCount = await _mockService.getTotalCount();
        _averageAmount = await _mockService.getAverageAmount();
      } else {
        _allDebts = await _dbService.getAllDebts();
        _utangList = await _dbService.getDebtsByType(AppConstants.debtTypeUtang);
        _piutangList = await _dbService.getDebtsByType(AppConstants.debtTypePiutang);
        _unpaidDebts = await _dbService.getUnpaidDebts();
        _totalUnpaidUtang = await _dbService.getTotalUnpaidUtang();
        _totalUnpaidPiutang = await _dbService.getTotalUnpaidPiutang();

        // Load statistics
        final monthly = await _dbService.getMonthlyTotals();
        _monthlyTotals.clear();
        _monthlyTotals.addAll(monthly);

        final statusCounts = await _dbService.getStatusCounts();
        _statusCounts['LUNAS'] = statusCounts['LUNAS'] ?? 0;
        _statusCounts['BELUM_LUNAS'] = statusCounts['BELUM_LUNAS'] ?? 0;

        final typeCounts = await _dbService.getTypeCounts();
        _typeCounts['UTANG'] = typeCounts['UTANG'] ?? 0;
        _typeCounts['PIUTANG'] = typeCounts['PIUTANG'] ?? 0;

        _totalCount = await _dbService.getTotalCount();
        _averageAmount = await _dbService.getAverageAmount();
      }

      // Schedule notifications for unpaid debts with due dates
      if (_notificationsEnabled && !kIsWeb) {
        await _notificationService.scheduleAllReminders(_unpaidDebts);
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

      // Schedule notification for new debt
      if (_notificationsEnabled && !kIsWeb && debt.dueDate != null) {
        await _notificationService.scheduleDueDateReminder(debt);
      }

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

      // Reschedule notification
      if (debt.id != null) {
        await _notificationService.cancelReminder(debt.id!);
        if (_notificationsEnabled && !kIsWeb && debt.dueDate != null) {
          await _notificationService.scheduleDueDateReminder(debt);
        }
      }

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

      // Cancel notification for deleted debt
      await _notificationService.cancelReminder(id);

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
          // Cancel notification when marked as paid
          await _notificationService.cancelReminder(id);
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
