import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../data/expense_repository.dart';
import '../../subscription/utils/subscription_guard.dart';
import '../models/expense.dart';
import '../models/expense_category.dart';

class ExpenseListScreen extends StatefulWidget {
  final bool isTab;
  const ExpenseListScreen({super.key, this.isTab = false});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Expense> _expenses = [];
  List<ExpenseCategory> _categories = [];

  bool _isLoading = true;
  String? _errorMessage;

  String _datePreset = 'this_month'; // 'today', 'this_week', 'this_month', 'last_month', 'all_time', 'custom'
  DateTimeRange? _customDateRange;

  String _selectedCategoryId = 'all';
  double _totalExpensesSum = 0.0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchExpenses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final res = await _expenseRepository.getExpenseCategories();
      if (mounted && res.success && res.data != null) {
        setState(() => _categories = res.data!);
      }
    } catch (_) {}
  }

  String? get _dateFrom {
    final now = DateTime.now();
    if (_datePreset == 'today') {
      return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    } else if (_datePreset == 'this_week') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      return '${startOfWeek.year}-${startOfWeek.month.toString().padLeft(2, '0')}-${startOfWeek.day.toString().padLeft(2, '0')}';
    } else if (_datePreset == 'this_month') {
      return '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
    } else if (_datePreset == 'last_month') {
      final lastMonth = DateTime(now.year, now.month - 1, 1);
      return '${lastMonth.year}-${lastMonth.month.toString().padLeft(2, '0')}-01';
    } else if (_datePreset == 'custom' && _customDateRange != null) {
      final s = _customDateRange!.start;
      return '${s.year}-${s.month.toString().padLeft(2, '0')}-${s.day.toString().padLeft(2, '0')}';
    }
    return null; // all_time
  }

  String? get _dateTo {
    final now = DateTime.now();
    if (_datePreset == 'today' || _datePreset == 'this_week' || _datePreset == 'this_month') {
      return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    } else if (_datePreset == 'last_month') {
      final lastDayLastMonth = DateTime(now.year, now.month, 0);
      return '${lastDayLastMonth.year}-${lastDayLastMonth.month.toString().padLeft(2, '0')}-${lastDayLastMonth.day.toString().padLeft(2, '0')}';
    } else if (_datePreset == 'custom' && _customDateRange != null) {
      final e = _customDateRange!.end;
      return '${e.year}-${e.month.toString().padLeft(2, '0')}-${e.day.toString().padLeft(2, '0')}';
    }
    return null; // all_time
  }

  String get _dateFilterLabel {
    switch (_datePreset) {
      case 'today':
        return 'Today';
      case 'this_week':
        return 'This Week';
      case 'this_month':
        return 'This Month';
      case 'last_month':
        return 'Last Month';
      case 'all_time':
        return 'All Time';
      case 'custom':
        if (_customDateRange != null) {
          return '${_customDateRange!.start.day}/${_customDateRange!.start.month} - ${_customDateRange!.end.day}/${_customDateRange!.end.month}';
        }
        return 'Custom';
      default:
        return 'This Month';
    }
  }

  Future<void> _fetchExpenses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _expenseRepository.getExpenses(
        search: _searchController.text.trim(),
        categoryId: _selectedCategoryId,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );

      if (mounted) {
        if (res.success && res.data != null) {
          setState(() {
            _expenses = res.data!.expenses;
            _totalExpensesSum = res.data!.totalExpensesSum;
            _totalCount = res.data!.totalCount;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = res.message;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showDateFilterPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Select Expense Date Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Today'),
                trailing: _datePreset == 'today' ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                onTap: () {
                  setState(() => _datePreset = 'today');
                  Navigator.pop(ctx);
                  _fetchExpenses();
                },
              ),
              ListTile(
                title: const Text('This Week'),
                trailing: _datePreset == 'this_week' ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                onTap: () {
                  setState(() => _datePreset = 'this_week');
                  Navigator.pop(ctx);
                  _fetchExpenses();
                },
              ),
              ListTile(
                title: const Text('This Month'),
                trailing: _datePreset == 'this_month' ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                onTap: () {
                  setState(() => _datePreset = 'this_month');
                  Navigator.pop(ctx);
                  _fetchExpenses();
                },
              ),
              ListTile(
                title: const Text('Last Month'),
                trailing: _datePreset == 'last_month' ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                onTap: () {
                  setState(() => _datePreset = 'last_month');
                  Navigator.pop(ctx);
                  _fetchExpenses();
                },
              ),
              ListTile(
                title: const Text('All Time'),
                trailing: _datePreset == 'all_time' ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                onTap: () {
                  setState(() => _datePreset = 'all_time');
                  Navigator.pop(ctx);
                  _fetchExpenses();
                },
              ),
              ListTile(
                title: const Text('Custom Date Range'),
                trailing: _datePreset == 'custom' ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDateRange: _customDateRange ?? DateTimeRange(
                      start: DateTime.now().subtract(const Duration(days: 30)),
                      end: DateTime.now(),
                    ),
                  );
                  if (picked != null) {
                    setState(() {
                      _datePreset = 'custom';
                      _customDateRange = picked;
                    });
                    _fetchExpenses();
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        // 1. Metric Header Card & Date Preset selector
        Container(
          color: AppColors.primary,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              // Search Field
              TextField(
                controller: _searchController,
                onChanged: (_) => _fetchExpenses(),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search title, notes, reference #...',
                  hintStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.15),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Expenses', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text(
                        '₹${_totalExpensesSum.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      Text('$_totalCount records', style: const TextStyle(color: Colors.white60, fontSize: 10)),
                    ],
                  ),

                  // Date Filter Chip
                  InkWell(
                    onTap: _showDateFilterPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _dateFilterLabel,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Category Filter Bar
        Container(
          height: 48,
          color: Colors.white,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildCategoryChip('All Categories', 'all'),
              ..._categories.map((cat) => _buildCategoryChip(cat.name, cat.id.toString())),
            ],
          ),
        ),
        const Divider(height: 1),

        // 3. Expense List Body
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
                          const SizedBox(height: 12),
                          ElevatedButton(onPressed: _fetchExpenses, child: const Text('Retry')),
                        ],
                      ),
                    )
                  : _expenses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.receipt_outlined, size: 60, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                'No expenses found for $_dateFilterLabel',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              const Text('Tap (+ Add Expense) to record your shop expenses', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchExpenses,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: _expenses.length,
                            itemBuilder: (context, index) {
                              final exp = _expenses[index];
                              final categoryName = exp.category?.name ?? 'Expense';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: CustomCard(
                                  onTap: () async {
                                    final refreshed = await Navigator.pushNamed(
                                      context,
                                      AppRoutes.expenseDetails,
                                      arguments: exp,
                                    );
                                    if (refreshed == true) _fetchExpenses();
                                  },
                                  padding: const EdgeInsets.all(14.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              exp.title,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Text(
                                            '₹${exp.amount.toStringAsFixed(2)}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.error),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  categoryName,
                                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Paid via ${exp.paymentMethod.toUpperCase()}',
                                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            exp.expenseDate,
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );

    if (widget.isTab) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: content,
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'fab_expense_tab',
          onPressed: () async {
            final ok = await SubscriptionGuard.checkAndGuard(context, actionName: 'manage expenses');
            if (!ok) return;
            final res = await Navigator.pushNamed(context, AppRoutes.addExpense);
            if (res == true) _fetchExpenses();
          },
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Add Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Expense Management'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: content,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_expense_list',
        onPressed: () async {
          final ok = await SubscriptionGuard.checkAndGuard(context, actionName: 'manage expenses');
          if (!ok) return;
          final res = await Navigator.pushNamed(context, AppRoutes.addExpense);
          if (res == true) _fetchExpenses();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Expense', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String value) {
    final isSelected = _selectedCategoryId == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedCategoryId = value);
            _fetchExpenses();
          }
        },
        selectedColor: AppColors.primary,
        backgroundColor: Colors.grey.shade100,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
