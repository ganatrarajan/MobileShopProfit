import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';

class ExpenseListResponse {
  final List<Expense> expenses;
  final double totalExpensesSum;
  final int totalCount;

  ExpenseListResponse({
    required this.expenses,
    required this.totalExpensesSum,
    required this.totalCount,
  });
}

class ExpenseRepository {
  final ApiClient _apiClient = ApiClient();

  /// Get list of system & shop categories
  Future<ApiResponse<List<ExpenseCategory>>> getExpenseCategories() async {
    final response = await _apiClient.get(ApiEndpoints.expenseCategories);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      List rawList = [];
      if (rawData is List) {
        rawList = rawData;
      } else if (rawData is Map && rawData['data'] is List) {
        rawList = rawData['data'];
      }

      final categories = rawList.map((c) => ExpenseCategory.fromJson(Map<String, dynamic>.from(c))).toList();
      return ApiResponse<List<ExpenseCategory>>(success: true, message: response.message, data: categories);
    }

    return ApiResponse<List<ExpenseCategory>>(success: false, message: response.message);
  }

  /// Create custom category
  Future<ApiResponse<ExpenseCategory>> createExpenseCategory(String name) async {
    final response = await _apiClient.post(
      ApiEndpoints.expenseCategories,
      body: {'name': name},
    );

    if (response.success && response.data != null) {
      final category = ExpenseCategory.fromJson(Map<String, dynamic>.from(response.data!));
      return ApiResponse<ExpenseCategory>(success: true, message: response.message, data: category);
    }

    return ApiResponse<ExpenseCategory>(success: false, message: response.message);
  }

  /// Get paginated expenses with filters
  Future<ApiResponse<ExpenseListResponse>> getExpenses({
    String? search,
    String? categoryId,
    String? dateFrom,
    String? dateTo,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') 'category_id': categoryId,
      if (dateFrom != null && dateFrom.isNotEmpty) 'date_from': dateFrom,
      if (dateTo != null && dateTo.isNotEmpty) 'date_to': dateTo,
    };

    final queryString = Uri(queryParameters: queryParams).query;
    final path = '${ApiEndpoints.expenses}?$queryString';

    final response = await _apiClient.get(path);

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      List rawList = [];
      if (rawData is List) {
        rawList = rawData;
      } else if (rawData is Map && rawData['data'] is List) {
        rawList = rawData['data'];
      }

      final expenses = rawList.map((e) => Expense.fromJson(Map<String, dynamic>.from(e))).toList();

      double totalSum = 0.0;
      int count = expenses.length;

      if (rawData is Map && rawData['metrics'] != null) {
        final metrics = rawData['metrics'];
        totalSum = (metrics['total_expenses_sum'] ?? 0.0).toDouble();
        count = (metrics['total_count'] ?? expenses.length).toInt();
      } else {
        for (final exp in expenses) {
          totalSum += exp.amount;
        }
      }

      return ApiResponse<ExpenseListResponse>(
        success: true,
        message: response.message,
        data: ExpenseListResponse(
          expenses: expenses,
          totalExpensesSum: totalSum,
          totalCount: count,
        ),
      );
    }

    return ApiResponse<ExpenseListResponse>(success: false, message: response.message);
  }

  /// Get expense details by ID
  Future<ApiResponse<Expense>> getExpenseDetails(int id) async {
    final response = await _apiClient.get('${ApiEndpoints.expenses}/$id');

    if (response.success && response.data != null) {
      final expense = Expense.fromJson(Map<String, dynamic>.from(response.data!));
      return ApiResponse<Expense>(success: true, message: response.message, data: expense);
    }

    return ApiResponse<Expense>(success: false, message: response.message);
  }

  /// Create a new expense record
  Future<ApiResponse<Expense>> createExpense({
    required int categoryId,
    required String title,
    required double amount,
    required String expenseDate,
    String paymentMethod = 'cash',
    String? notes,
    String? referenceNumber,
    bool isRecurring = false,
    String? recurrenceType,
  }) async {
    final body = {
      'category_id': categoryId,
      'title': title,
      'amount': amount,
      'expense_date': expenseDate,
      'payment_method': paymentMethod,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (referenceNumber != null && referenceNumber.isNotEmpty) 'reference_number': referenceNumber,
      'is_recurring': isRecurring,
      if (recurrenceType != null && recurrenceType.isNotEmpty) 'recurrence_type': recurrenceType,
    };

    final response = await _apiClient.post(ApiEndpoints.expenses, body: body);

    if (response.success && response.data != null) {
      final expense = Expense.fromJson(Map<String, dynamic>.from(response.data!));
      return ApiResponse<Expense>(success: true, message: response.message, data: expense);
    }

    return ApiResponse<Expense>(success: false, message: response.message);
  }

  /// Update an existing expense
  Future<ApiResponse<Expense>> updateExpense(
    int id, {
    int? categoryId,
    String? title,
    double? amount,
    String? expenseDate,
    String? paymentMethod,
    String? notes,
    String? referenceNumber,
    bool? isRecurring,
    String? recurrenceType,
  }) async {
    final body = {
      if (categoryId != null) 'category_id': categoryId,
      if (title != null) 'title': title,
      if (amount != null) 'amount': amount,
      if (expenseDate != null) 'expense_date': expenseDate,
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (notes != null) 'notes': notes,
      if (referenceNumber != null) 'reference_number': referenceNumber,
      if (isRecurring != null) 'is_recurring': isRecurring,
      if (recurrenceType != null) 'recurrence_type': recurrenceType,
    };

    final response = await _apiClient.put('${ApiEndpoints.expenses}/$id', body: body);

    if (response.success && response.data != null) {
      final expense = Expense.fromJson(Map<String, dynamic>.from(response.data!));
      return ApiResponse<Expense>(success: true, message: response.message, data: expense);
    }

    return ApiResponse<Expense>(success: false, message: response.message);
  }

  /// Delete an expense
  Future<ApiResponse<void>> deleteExpense(int id) async {
    final response = await _apiClient.delete('${ApiEndpoints.expenses}/$id');
    return ApiResponse<void>(success: response.success, message: response.message);
  }
}
