import 'debt_type.dart';
import 'payment_status.dart';

class DebtModel {
  final int? id;
  final String name;
  final double amount;
  final DebtType type;
  final String? category;
  final String? description;
  final DateTime? dueDate;
  final PaymentStatus status;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  DebtModel({
    this.id,
    required this.name,
    required this.amount,
    required this.type,
    this.category,
    this.description,
    this.dueDate,
    required this.status,
    this.phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'type': type.value,
      'category': category,
      'description': description,
      'due_date': dueDate?.toIso8601String(),
      'status': status.value,
      'phone_number': phoneNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create from Map (database retrieval)
  factory DebtModel.fromMap(Map<String, dynamic> map) {
    return DebtModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: DebtType.fromString(map['type'] as String),
      category: map['category'] as String?,
      description: map['description'] as String?,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      status: PaymentStatus.fromString(map['status'] as String),
      phoneNumber: map['phone_number'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // CopyWith method for updating
  DebtModel copyWith({
    int? id,
    String? name,
    double? amount,
    DebtType? type,
    String? category,
    String? description,
    DateTime? dueDate,
    PaymentStatus? status,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DebtModel(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Check if debt is overdue
  bool get isOverdue {
    if (dueDate == null || status == PaymentStatus.lunas) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  // Get days until due date
  int? get daysUntilDue {
    if (dueDate == null) return null;
    final difference = dueDate!.difference(DateTime.now());
    return difference.inDays;
  }

  // Format amount for WhatsApp message
  String get formattedAmount {
    return 'Rp ${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}';
  }
}
