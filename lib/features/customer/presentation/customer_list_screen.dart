import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/custom_card.dart';
import '../../subscription/utils/subscription_guard.dart';
import '../data/customer_repository.dart';
import '../models/customer.dart';

class CustomerListScreen extends StatefulWidget {
  final bool isTab;
  const CustomerListScreen({super.key, this.isTab = false});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final CustomerRepository _repository = CustomerRepository();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  List<Customer> _customers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomers({String query = ''}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _repository.getCustomers(search: query);
      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _customers = response.data!;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = response.message;
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

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _fetchCustomers(query: query);
    });
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final confirm = await AppDialogs.showConfirmation(
      context,
      title: 'Delete Customer?',
      message: 'This will remove ${customer.name} from your active customer list.',
      confirmLabel: 'Delete Customer',
    );

    if (confirm) {
      try {
        final res = await _repository.deleteCustomer(customer.id);
        if (mounted) {
          if (res.success) {
            AppFeedback.showSuccess(
              context,
              title: '✅ Customer Deleted',
              message: '${customer.name} has been deleted successfully.',
            );
            _fetchCustomers(query: _searchController.text);
          } else {
            AppFeedback.showError(context, error: res.message);
          }
        }
      } catch (e) {
        if (mounted) AppFeedback.showError(context, error: e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget bodyContent = Column(
      children: [
        // Header Bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          color: AppColors.primary,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Customers Directory',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    '${_customers.length} total',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by name, mobile number, or city...',
                  hintStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Colors.white70, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _fetchCustomers(query: '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.primaryLight,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Main List / States
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _fetchCustomers(query: _searchController.text),
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _customers.isEmpty
                      ? AppEmptyState(
                          icon: Icons.people_outline_rounded,
                          title: 'No customers yet',
                          description: 'Add your first customer to manage their devices, repairs and billing.',
                          actionLabel: '+ Add Customer',
                          onActionPressed: () async {
                            final ok = await SubscriptionGuard.checkAndGuard(context, actionName: 'add customers');
                            if (!ok) return;
                            await Navigator.pushNamed(context, AppRoutes.addCustomer);
                            _fetchCustomers(query: _searchController.text);
                          },
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _customers.length,
                          itemBuilder: (context, index) {
                            final customer = _customers[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: CustomCard(
                                onTap: () async {
                                  await Navigator.pushNamed(
                                    context,
                                    AppRoutes.customerDetails,
                                    arguments: customer,
                                  );
                                  _fetchCustomers(query: _searchController.text);
                                },
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: AppColors.primaryLight,
                                      child: Text(
                                        customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            customer.name,
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '📱 ${customer.mobile}',
                                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                          ),
                                          if (customer.city != null && customer.city!.isNotEmpty) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              '📍 ${customer.city}',
                                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                      onPressed: () => _deleteCustomer(customer),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ],
    );

    if (widget.isTab) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: bodyContent,
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_customer_tab',
          onPressed: () async {
            final ok = await SubscriptionGuard.checkAndGuard(context, actionName: 'add customers');
            if (!ok) return;
            await Navigator.pushNamed(context, AppRoutes.addCustomer);
            _fetchCustomers(query: _searchController.text);
          },
          backgroundColor: AppColors.accent,
          child: const Icon(Icons.person_add_rounded, color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customer Management'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: bodyContent,
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_customer_list',
        onPressed: () async {
          final ok = await SubscriptionGuard.checkAndGuard(context, actionName: 'add customers');
          if (!ok) return;
          await Navigator.pushNamed(context, AppRoutes.addCustomer);
          _fetchCustomers(query: _searchController.text);
        },
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
    );
  }
}