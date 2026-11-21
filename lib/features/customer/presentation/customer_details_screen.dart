import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/whatsapp_icon.dart';
import '../../device/data/device_repository.dart';
import '../../device/models/device.dart';
import '../../repair/data/repair_repository.dart';
import '../../repair/models/repair.dart';
import '../../sales/data/sale_repository.dart';
import '../../sales/models/sale.dart';
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
  final RepairRepository _repairRepository = RepairRepository();
  final SaleRepository _saleRepository = SaleRepository();

  List<Device> _devices = [];
  List<Repair> _repairs = [];
  List<Sale> _sales = [];

  bool _isLoadingDevices = true;
  bool _isLoadingRepairs = true;
  bool _isLoadingSales = true;

  @override
  void initState() {
    super.initState();
    _currentCustomer = widget.customer;
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _fetchCustomerDevices(),
      _fetchCustomerRepairs(),
      _fetchCustomerSales(),
    ]);
  }

  Future<void> _fetchCustomerDevices() async {
    setState(() => _isLoadingDevices = true);
    try {
      final response = await _deviceRepository.getDevicesForCustomer(_currentCustomer.id);
      if (mounted && response.success && response.data != null) {
        setState(() => _devices = response.data!);
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isLoadingDevices = false);
    }
  }

  Future<void> _fetchCustomerRepairs() async {
    setState(() => _isLoadingRepairs = true);
    try {
      final response = await _repairRepository.getRepairs(customerId: _currentCustomer.id);
      if (mounted && response.success && response.data != null) {
        setState(() => _repairs = response.data!);
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isLoadingRepairs = false);
    }
  }

  Future<void> _fetchCustomerSales() async {
    setState(() => _isLoadingSales = true);
    try {
      final response = await _saleRepository.getSales(customerId: _currentCustomer.id);
      if (mounted && response.success && response.data != null) {
        setState(() => _sales = response.data!);
      }
    } catch (_) {}
    finally {
      if (mounted) setState(() => _isLoadingSales = false);
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

  void _showSignaturePreview(String sigPath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Customer Signature', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: sigPath.startsWith('http')
                      ? Image.network(sigPath, fit: BoxFit.contain)
                      : Image.file(File(sigPath), fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Signed by: ${_currentCustomer.name}',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'received':
        return Colors.blue;
      case 'diagnosing':
        return Colors.purple;
      case 'repairing':
        return Colors.orange;
      case 'ready':
        return Colors.teal;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sigPath = _currentCustomer.signatureUrl ?? _currentCustomer.signaturePath;
    final hasSignature = sigPath != null && sigPath.isNotEmpty;

    // Financial totals
    double totalRepairsCost = _repairs.fold(0.0, (sum, r) => sum + (r.finalCost > 0 ? r.finalCost : r.estimatedCost));
    double totalSalesCost = _sales.fold(0.0, (sum, s) => sum + s.grandTotal);
    double totalSpent = totalRepairsCost + totalSalesCost;

    double totalRepairsDue = _repairs.fold(0.0, (sum, r) => sum + r.amountDue);
    double totalSalesDue = _sales.fold(0.0, (sum, s) => sum + s.amountDue);
    double totalDue = totalRepairsDue + totalSalesDue;

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
                setState(() => _currentCustomer = updated);
                _refreshAll();
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
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Header Card
              CustomCard(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Avatar or Signature photo
                        GestureDetector(
                          onTap: hasSignature ? () => _showSignaturePreview(sigPath) : null,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: AppColors.accent,
                                child: hasSignature
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(28),
                                        child: sigPath.startsWith('http')
                                            ? Image.network(sigPath, width: 56, height: 56, fit: BoxFit.cover)
                                            : Image.file(File(sigPath), width: 56, height: 56, fit: BoxFit.cover),
                                      )
                                    : Text(
                                        _currentCustomer.name.isNotEmpty ? _currentCustomer.name[0].toUpperCase() : 'C',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
                                      ),
                              ),
                              if (hasSignature)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.draw_rounded, size: 12, color: AppColors.primary),
                                  ),
                                ),
                            ],
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
                              const SizedBox(height: 3),
                              Text(
                                '📱 ${_currentCustomer.mobile}',
                                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                              ),
                              if (_currentCustomer.city != null && _currentCustomer.city!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '📍 ${_currentCustomer.city}',
                                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (_currentCustomer.mobile.isNotEmpty)
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const WhatsAppIcon(size: 20),
                            ),
                            tooltip: 'Chat on WhatsApp',
                            onPressed: () => WhatsAppHelper.showCustomerWhatsAppOptions(context, _currentCustomer),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Quick Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final created = await Navigator.pushNamed(
                                context,
                                AppRoutes.createRepair,
                                arguments: {'customer': _currentCustomer},
                              );
                              if (created == true) _refreshAll();
                            },
                            icon: const Icon(Icons.build_rounded, size: 15),
                            label: const Text('+ Repair', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final created = await Navigator.pushNamed(
                                context,
                                AppRoutes.createSale,
                                arguments: {'customer': _currentCustomer},
                              );
                              if (created == true) _refreshAll();
                            },
                            icon: const Icon(Icons.receipt_long_rounded, size: 15),
                            label: const Text('+ Sale', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final created = await Navigator.pushNamed(
                                context,
                                AppRoutes.addDevice,
                                arguments: _currentCustomer,
                              );
                              if (created == true) _fetchCustomerDevices();
                            },
                            icon: const Icon(Icons.phone_iphone_rounded, size: 15),
                            label: const Text('+ Device', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Financial Ledger Summary Row
              Row(
                children: [
                  Expanded(
                    child: CustomCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Spent', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Text(
                            '₹${totalSpent.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Dues', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                          const SizedBox(height: 4),
                          Text(
                            '₹${totalDue.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: totalDue > 0 ? AppColors.error : AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Contact & Signature Details Card
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Contact & Location Info', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
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
                    if (hasSignature) ...[
                      const Divider(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.gesture_rounded, size: 20, color: AppColors.textMuted),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Customer Signature', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                    GestureDetector(
                                      onTap: () => _showSignaturePreview(sigPath),
                                      child: const Text('View Full 🔍', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () => _showSignaturePreview(sigPath),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    height: 65,
                                    width: 150,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: sigPath.startsWith('http')
                                          ? Image.network(sigPath, fit: BoxFit.contain)
                                          : Image.file(File(sigPath), fit: BoxFit.contain),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 1. Devices Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Registered Devices (${_devices.length})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final created = await Navigator.pushNamed(
                        context,
                        AppRoutes.addDevice,
                        arguments: _currentCustomer,
                      );
                      if (created == true) _fetchCustomerDevices();
                    },
                    icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.accent),
                    label: const Text('Add Device', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _isLoadingDevices
                  ? AppShimmer.cardLoading(height: 60)
                  : _devices.isEmpty
                      ? const CustomCard(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.phone_iphone_rounded, color: AppColors.textMuted, size: 20),
                                SizedBox(width: 10),
                                Text('No registered devices for this customer yet.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: _devices.map((device) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
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
                                    const CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppColors.primaryLight,
                                      child: Icon(Icons.phone_iphone_rounded, color: Colors.white, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${device.brand} ${device.model}',
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            device.imei1 != null && device.imei1!.isNotEmpty
                                                ? 'IMEI: ${device.imei1}'
                                                : (device.serialNumber != null && device.serialNumber!.isNotEmpty
                                                    ? 'Serial: ${device.serialNumber}'
                                                    : 'Type: ${device.deviceType}'),
                                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
              const SizedBox(height: 20),

              // 2. Repairs Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Repair Job Cards (${_repairs.length})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final created = await Navigator.pushNamed(
                        context,
                        AppRoutes.createRepair,
                        arguments: {'customer': _currentCustomer},
                      );
                      if (created == true) _refreshAll();
                    },
                    icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                    label: const Text('New Repair', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _isLoadingRepairs
                  ? AppShimmer.cardLoading(height: 60)
                  : _repairs.isEmpty
                      ? const CustomCard(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.build_circle_outlined, color: AppColors.textMuted, size: 20),
                                SizedBox(width: 10),
                                Text('No repairs recorded for this customer yet.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: _repairs.map((repair) {
                            final cost = repair.finalCost > 0 ? repair.finalCost : repair.estimatedCost;
                            final statusColor = _getStatusColor(repair.repairStatus);
                            final deviceTitle = repair.device != null
                                ? '${repair.device!.brand} ${repair.device!.model}'
                                : 'Device #${repair.deviceId}';

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: CustomCard(
                                onTap: () async {
                                  await Navigator.pushNamed(
                                    context,
                                    AppRoutes.repairDetails,
                                    arguments: repair,
                                  );
                                  _fetchCustomerRepairs();
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          repair.jobNumber,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                        StatusBadge(
                                          label: repair.repairStatus.toUpperCase(),
                                          backgroundColor: statusColor.withOpacity(0.12),
                                          textColor: statusColor,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      deviceTitle,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                    ),
                                    if (repair.problemDescription.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        repair.problemDescription,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateHelper.formatDate(repair.dateReceived),
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        ),
                                        Text(
                                          '₹${cost.toStringAsFixed(0)}',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
              const SizedBox(height: 20),

              // 3. Sales Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sales & Invoices (${_sales.length})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final created = await Navigator.pushNamed(
                        context,
                        AppRoutes.createSale,
                        arguments: {'customer': _currentCustomer},
                      );
                      if (created == true) _refreshAll();
                    },
                    icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.accent),
                    label: const Text('New Sale', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _isLoadingSales
                  ? AppShimmer.cardLoading(height: 60)
                  : _sales.isEmpty
                      ? const CustomCard(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.receipt_long_outlined, color: AppColors.textMuted, size: 20),
                                SizedBox(width: 10),
                                Text('No sales recorded for this customer yet.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: _sales.map((sale) {
                            final isPaid = sale.paymentStatus.toLowerCase() == 'paid' || sale.amountDue <= 0;
                            final paymentColor = isPaid ? AppColors.success : (sale.amountPaid > 0 ? AppColors.warning : AppColors.error);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: CustomCard(
                                onTap: () async {
                                  await Navigator.pushNamed(
                                    context,
                                    AppRoutes.saleDetails,
                                    arguments: sale,
                                  );
                                  _fetchCustomerSales();
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          sale.invoiceNumber,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                                        ),
                                        StatusBadge(
                                          label: sale.paymentStatus.toUpperCase(),
                                          backgroundColor: paymentColor.withOpacity(0.12),
                                          textColor: paymentColor,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      sale.items.isNotEmpty
                                          ? sale.items.map((i) => i.productName).join(', ')
                                          : 'Items (${sale.items.length})',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateHelper.formatDate(sale.saleDate),
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        ),
                                        Text(
                                          '₹${sale.grandTotal.toStringAsFixed(0)}',
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
