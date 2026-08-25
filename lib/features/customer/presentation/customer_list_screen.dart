import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
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
  Timer? _debounce;

  List<Customer> _customers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers({String? query, int page = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _repository.getCustomers(search: query, page: page);
      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _customers = response.data!;
          });
        } else {
          setState(() {
            _errorMessage = response.message;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _fetchCustomers(query: query, page: 1);
    });
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${customer.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response = await _repository.deleteCustomer(customer.id);
      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Customer ${customer.name} deleted')),
          );
          _fetchCustomers(query: _searchController.text);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message)),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = RefreshIndicator(
      onRefresh: () => _fetchCustomers(query: _searchController.text),
      child: Column(
        children: [
          // Search Bar Header
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search customer by name or mobile...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
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
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: const BoxDecoration(
                                      color: AppColors.accentLight,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.accent),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No customers yet',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Add your first customer to start managing your shop.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await Navigator.pushNamed(context, AppRoutes.addCustomer);
                                      _fetchCustomers(query: _searchController.text);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                    icon: const Icon(Icons.person_add_rounded, size: 18),
                                    label: const Text('Add Customer'),
                                  ),
                                ],
                              ),
                            ),
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
      ),
    );

    if (widget.isTab) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: bodyContent,
        floatingActionButton: FloatingActionButton(
          heroTag: 'fab_customer_tab',
          onPressed: () async {
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
          await Navigator.pushNamed(context, AppRoutes.addCustomer);
          _fetchCustomers(query: _searchController.text);
        },
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.person_add_rounded, color: Colors.white),
      ),
    );
  }
}