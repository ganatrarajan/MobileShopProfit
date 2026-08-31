import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../device/data/device_repository.dart';
import '../../device/models/device.dart';
import '../data/customer_repository.dart';
import '../models/customer.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Customer customer;
  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  late Customer _currentCustomer;
  final CustomerRepository _customerRepository = CustomerRepository();
  final DeviceRepository _deviceRepository = DeviceRepository();

  List<Device> _devices = [];
  bool _isLoadingDevices = true;

  @override
  void initState() {
    super.initState();
    _currentCustomer = widget.customer;
    _fetchCustomerDevices();
  }

  Future<void> _fetchCustomerDevices() async {
    setState(() {
      _isLoadingDevices = true;
    });

    try {
      final response = await _deviceRepository.getDevicesForCustomer(_currentCustomer.id);
      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _devices = response.data!;
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDevices = false;
        });
      }
    }
  }

  Future<void> _deleteCustomer() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text('Are you sure you want to delete ${_currentCustomer.name}?'),
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
      final response = await _customerRepository.deleteCustomer(_currentCustomer.id);
      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Customer ${_currentCustomer.name} deleted')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customer Profile'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Customer',
            onPressed: () async {
              final updated = await Navigator.pushNamed(
                context,
                AppRoutes.editCustomer,
                arguments: _currentCustomer,
              );
              if (updated is Customer) {
                setState(() {
                  _currentCustomer = updated;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete Customer',
            onPressed: _deleteCustomer,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Header Card
            CustomCard(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: AppColors.accent,
                        child: Text(
                          _currentCustomer.name.isNotEmpty ? _currentCustomer.name[0].toUpperCase() : 'C',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentCustomer.name,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '📱 ${_currentCustomer.mobile}',
                              style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Contact Info Card
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contact & Location Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 14),
                  _buildDetailRow(Icons.phone_android_rounded, 'Primary Mobile', _currentCustomer.mobile),
                  if (_currentCustomer.alternateMobile != null && _currentCustomer.alternateMobile!.isNotEmpty)
                    _buildDetailRow(Icons.phone_outlined, 'Alternate Mobile', _currentCustomer.alternateMobile!),
                  if (_currentCustomer.email != null && _currentCustomer.email!.isNotEmpty)
                    _buildDetailRow(Icons.email_outlined, 'Email', _currentCustomer.email!),
                  if (_currentCustomer.address != null && _currentCustomer.address!.isNotEmpty)
                    _buildDetailRow(Icons.location_on_outlined, 'Address', _currentCustomer.address!),
                  if (_currentCustomer.city != null && _currentCustomer.city!.isNotEmpty)
                    _buildDetailRow(Icons.location_city_outlined, 'City', _currentCustomer.city!),
                  if (_currentCustomer.notes != null && _currentCustomer.notes!.isNotEmpty)
                    _buildDetailRow(Icons.note_alt_outlined, 'Notes', _currentCustomer.notes!),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Active Devices Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customer Devices (${_devices.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final created = await Navigator.pushNamed(
                      context,
                      AppRoutes.addDevice,
                      arguments: _currentCustomer,
                    );
                    if (created == true) {
                      _fetchCustomerDevices();
                    }
                  },
                  icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.accent),
                  label: const Text('Add Device', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Customer Devices List
            _isLoadingDevices
                ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: AppColors.primary)))
                : _devices.isEmpty
                    ? CustomCard(
                        child: Row(
                          children: [
                            const Icon(Icons.phone_iphone_rounded, color: AppColors.textMuted, size: 24),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'No registered devices yet. Tap "+ Add Device" to register customer phone/tablet.',
                                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: _devices.map((device) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: CustomCard(
                              onTap: () async {
                                await Navigator.pushNamed(
                                  context,
                                  AppRoutes.deviceDetails,
                                  arguments: device,
                                );
                                _fetchCustomerDevices();
                              },
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.primaryLight,
                                    child: const Icon(Icons.phone_iphone_rounded, color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${device.brand} ${device.model}',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          device.imei1 != null && device.imei1!.isNotEmpty
                                              ? 'IMEI: ${device.imei1}'
                                              : (device.serialNumber != null && device.serialNumber!.isNotEmpty
                                                  ? 'Serial: ${device.serialNumber}'
                                                  : 'Type: ${device.deviceType}'),
                                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),

            const SizedBox(height: 24),
            const Text('Customer Activity & Ledger', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),

            // Future Module Placeholders
            _buildPlaceholderSection('Repair Job Cards', Icons.build_circle_rounded),
            const SizedBox(height: 10),
            _buildPlaceholderSection('Sales & Billing Invoices', Icons.receipt_long_rounded),
            const SizedBox(height: 10),
            _buildPlaceholderSection('Payments & Dues Ledger', Icons.account_balance_wallet_rounded),
            const SizedBox(height: 10),
            _buildPlaceholderSection('Warranty Records', Icons.verified_user_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderSection(String title, IconData icon) {
    return CustomCard(
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                const Text('No records yet', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}