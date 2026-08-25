import 'expense_category.dart';

double _parseDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0.0;
}

int _parseInt(dynamic val) {
  if (val == null) return 0;
  if (val is int) return val;
  if (val is num) return val.toInt();
  final d = double.tryParse(val.toString());
  return d != null ? d.toInt() : 0;
}

class Expense {
  final int id;
  final int shopId;
  final int categoryId;
  final String title;
  final double amount;
  final String expenseDate;
  final String paymentMethod; // cash, upi, bank_transfer, card, other
  final String? notes;
  final String? referenceNumber;
  final bool isRecurring;
  final String? recurrenceType; // monthly, yearly
  final int? createdBy;
  final String? creatorName;
  final ExpenseCategory? category;
  final String? createdAt;
  final String? updatedAt;

  Expense({
    required this.id,
    required this.shopId,
    required this.categoryId,
    required this.title,
    required this.amount,
    required this.expenseDate,
    this.paymentMethod = 'cash',
    this.notes,
    this.referenceNumber,
    this.isRecurring = false,
    this.recurrenceType,
    this.createdBy,
    this.creatorName,
    this.category,
    this.createdAt,
    this.updatedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: _parseInt(json['id']),
      shopId: _parseInt(json['shop_id']),
      categoryId: _parseInt(json['category_id']),
      title: json['title']?.toString() ?? '',
      amount: _parseDouble(json['amount']),
      expenseDate: json['expense_date']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      notes: json['notes']?.toString(),
      referenceNumber: json['reference_number']?.toString(),
      isRecurring: json['is_recurring'] == true,
      recurrenceType: json['recurrence_type']?.toString(),
      createdBy: json['created_by'] != null ? _parseInt(json['created_by']) : null,
      creatorName: json['creator_name']?.toString(),
      category: json['category'] != null && json['category'] is Map<String, dynamic>
          ? ExpenseCategory.fromJson(Map<String, dynamic>.from(json['category']))
          : null,
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'category_id': categoryId,
      'title': title,
      'amount': amount,
      'expense_date': expenseDate,
      'payment_method': paymentMethod,
      'notes': notes,
      'reference_number': referenceNumber,
      'is_recurring': isRecurring,
      'recurrence_type': recurrenceType,
    };
  }
}
