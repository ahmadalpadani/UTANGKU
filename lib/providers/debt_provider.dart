import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:utangku_app/database/database_service.dart';
import 'package:utangku_app/models/debt_model.dart';
import 'package:utangku_app/models/debt_type.dart';
import 'package:utangku_app/models/payment_status.dart';
import 'package:utangku_app/services/notification_service.dart';
import 'package:utangku_app/utils/constants.dart';

class DebtProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final NotificationService _notificationService = NotificationService();

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

  Future<void> _loadNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationsEnabled = prefs.getBool(AppConstants.keyNotificationsEnabled) ?? true;
      _dueDateReminders = prefs.getBool(AppConstants.keyDueDateReminders) ?? true;
      _overdueAlerts = prefs.getBool(AppConstants.keyOverdueAlerts) ?? true;
    } catch (_) {}
  }

  Future<void> _saveNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.keyNotificationsEnabled, _notificationsEnabled);
      await prefs.setBool(AppConstants.keyDueDateReminders, _dueDateReminders);
      await prefs.setBool(AppConstants.keyOverdueAlerts, _overdueAlerts);
    } catch (_) {}
  }

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

  Future<void> setDueDateReminders(bool value) async {
    _dueDateReminders = value;
    await _saveNotificationSettings();
    if (_notificationsEnabled) {
      await _notificationService.scheduleAllReminders(_unpaidDebts);
    }
    notifyListeners();
  }

  Future<void> setOverdueAlerts(bool value) async {
    _overdueAlerts = value;
    await _saveNotificationSettings();
    if (_notificationsEnabled) {
      await _notificationService.scheduleAllReminders(_unpaidDebts);
    }
    notifyListeners();
  }

  Future<void> loadAllData() async {
    _setLoading(true);
    await _loadNotificationSettings();

    try {
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

      // Schedule notifications for unpaid debts with due dates (native only)
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

  Future<bool> addDebt(DebtModel debt) async {
    _setLoading(true);
    try {
      await _dbService.createDebt(debt);
      await loadAllData();

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

  Future<bool> updateDebt(DebtModel debt) async {
    _setLoading(true);
    try {
      await _dbService.updateDebt(debt);
      await loadAllData();

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

  Future<bool> deleteDebt(int id) async {
    _setLoading(true);
    try {
      await _dbService.deleteDebt(id);
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

  Future<bool> togglePaymentStatus(int id, PaymentStatus currentStatus) async {
    _setLoading(true);
    try {
      if (currentStatus == PaymentStatus.belumLunas) {
        await _dbService.markAsPaid(id);
        await _notificationService.cancelReminder(id);
      } else {
        await _dbService.markAsUnpaid(id);
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

  Future<List<DebtModel>> searchDebts(String query) async {
    if (query.isEmpty) return _allDebts;
    return await _dbService.searchDebts(query);
  }

  Future<List<DebtModel>> getOverdueDebts() async {
    return await _dbService.getOverdueDebts();
  }

  Future<List<DebtModel>> getDebtsByType(DebtType type) async {
    if (type == DebtType.utang) return _utangList;
    return _piutangList;
  }

  Future<List<DebtModel>> getDebtsByStatus(PaymentStatus status) async {
    return await _dbService.getDebtsByStatus(status.value);
  }

  Map<String, double> getStatistics() {
    return {
      'totalUtang': _totalUnpaidUtang,
      'totalPiutang': _totalUnpaidPiutang,
      'balance': _totalUnpaidPiutang - _totalUnpaidUtang,
    };
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
