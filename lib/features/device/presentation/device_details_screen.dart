import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/whatsapp_icon.dart';
import '../../repair/data/repair_repository.dart';
import '../../sales/data/sale_repository.dart';
import '../../warranty/data/warranty_repository.dart';
import '../../warranty/presentation/warranty_details_screen.dart';
import '../../warranty/presentation/widgets/quick_add_warranty_modal.dart';
import '../data/device_repository.dart';
import '../models/device.dart';

class DeviceDetailsScreen extends StatefulWidget {
  final Device device;
  const DeviceDetailsScreen({super.key, required this.device});

  @override
  State<DeviceDetailsScreen> createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends State<DeviceDetailsScreen> {
  late Device _currentDevice;
  final DeviceRepository _repository = DeviceRepository();
  final RepairRepository _repairRepo = RepairRepository();
  final SaleRepository _saleRepo = SaleRepository();
  final WarrantyRepository _warrantyRepo = WarrantyRepository();

  bool _isLoadingDetails = false;
  List<dynamic> _repairs = [];
  List<dynamic> _sales = [];
  List<dynamic> _warranties = [];

  static const Map<String, Color> _repairStatusColors = {
    'received': Colors.blue,
    'diagnosing': Colors.orange,
    'waiting_customer': Colors.purple,
    'waiting_parts': Colors.amber,
    'repairing': Colors.indigo,
    'ready': Colors.green,
    'delivered': Colors.teal,
    'cancelled': Colors.red,
  };

  static const Map<String, String> _repairStatusLabels = {
    'received': 'Received',
    'diagnosing': 'Diagnosing',
    'waiting_customer': 'Waiting Approval',
    'waiting_parts': 'Waiting Parts',
    'repairing': 'Under Repair',
    'ready': 'Ready for Pickup',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
  };

  @override
  void initState() {
    super.initState();
    _currentDevice = widget.device;
    _repairs = widget.device.repairs;
    _sales = widget.device.sales;
    _warranties = widget.device.warranties;
    _loadFullDeviceDetails();
  }

  Future<void> _loadFullDeviceDetails() async {
    setState(() => _isLoadingDetails = true);
    try {
      final res = await _repository.getDeviceDetails(_currentDevice.id);
      if (mounted && res.success && res.data != null) {
        setState(() {
          _currentDevice = res.data!;
          _repairs = res.data!.repairs;
          _sales = res.data!.sales;
          _warranties = res.data!.warranties;
        });
      }
    } catch (_) {
      // Keep existing data on error
    } finally {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    AppFeedback.showSuccess(
      context,
      title: '📋 Copied to Clipboard',
      message: '$label: $text',
    );
  }

  Future<void> _makeCall(String mobile) async {
    final clean = mobile.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _deleteDevice() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Device'),
        content: Text('Are you sure you want to delete ${_currentDevice.brand} ${_currentDevice.model}?\n\nNote: All past repair and sale records will be preserved.'),
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
      final response = await _repository.deleteDevice(_currentDevice.id);
      if (mounted) {
        if (response.success) {
          AppFeedback.showSuccess(context, title: 'Deleted', message: 'Device deleted successfully');
          Navigator.pop(context, true);
        } else {
          AppFeedback.showError(context, error: response.message);
        }
      }
    }
  }

  Future<void> _openRepairDetails(int repairId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
    try {
      final res = await _repairRepo.getRepairDetails(repairId);
      if (mounted) Navigator.pop(context); // Close loading dialog
      if (mounted) {
        if (res.success && res.data != null) {
          await Navigator.pushNamed(context, AppRoutes.repairDetails, arguments: res.data!);
          _loadFullDeviceDetails();
        } else {
          AppFeedback.showError(context, error: res.message);
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) AppFeedback.showError(context, error: 'Could not load repair: $e');
    }
  }

  Future<void> _openSaleDetails(int saleId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
    try {
      final res = await _saleRepo.getSaleDetails(saleId);
      if (mounted) Navigator.pop(context); // Close loading dialog
      if (mounted) {
        if (res.success && res.data != null) {
          await Navigator.pushNamed(context, AppRoutes.saleDetails, arguments: res.data!);
          _loadFullDeviceDetails();
        } else {
          AppFeedback.showError(context, error: res.message);
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) AppFeedback.showError(context, error: 'Could not load sale: $e');
    }
  }

  Future<void> _openWarrantyDetails(int warrantyId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );
    try {
      final res = await _warrantyRepo.getWarrantyDetails(warrantyId);
      if (mounted) Navigator.pop(context);
      if (mounted) {
        if (res.success && res.data != null) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WarrantyDetailsScreen(warranty: res.data!)),
          );
          _loadFullDeviceDetails();
        } else {
          AppFeedback.showError(context, error: res.message);
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) AppFeedback.showError(context, error: 'Could not load warranty: $e');
    }
  }

  IconData _getDeviceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'laptop':
        return Icons.laptop_rounded;
      case 'tablet':
        return Icons.tablet_android_rounded;
      case 'mobile':
      default:
        return Icons.phone_iphone_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasImei1 = _currentDevice.imei1 != null && _currentDevice.imei1!.trim().isNotEmpty;
    final hasImei2 = _currentDevice.imei2 != null && _currentDevice.imei2!.trim().isNotEmpty;
    final hasSerial = _currentDevice.serialNumber != null && _currentDevice.serialNumber!.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text('${_currentDevice.brand} ${_currentDevice.model}'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Device',
            onPressed: () async {
              final updated = await Navigator.pushNamed(
                context,
                AppRoutes.editDevice,
                arguments: _currentDevice,
              );
              if (updated is Device && mounted) {
                setState(() => _currentDevice = updated);
                _loadFullDeviceDetails();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete Device',
            onPressed: _deleteDevice,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFullDeviceDetails,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device Header Banner
              CustomCard(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.accent,
                          child: Icon(_getDeviceIcon(_currentDevice.deviceType), size: 30, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_currentDevice.brand} ${_currentDevice.model}',
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              if (_currentDevice.variant != null && _currentDevice.variant!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '${_currentDevice.variant}${_currentDevice.color != null && _currentDevice.color!.isNotEmpty ? ' • ${_currentDevice.color}' : ''}',
                                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _currentDevice.deviceType,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('Repairs', '${_repairs.length}', Icons.build_circle_rounded),
                          Container(width: 1, height: 24, color: Colors.white24),
                          _buildStatItem('Sales/Invoices', '${_sales.length}', Icons.receipt_long_rounded),
                          Container(width: 1, height: 24, color: Colors.white24),
                          _buildStatItem('Warranties', '${_warranties.length}', Icons.verified_user_rounded),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Quick Action Redirect Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.pushNamed(
                          context,
                          AppRoutes.createRepair,
                          arguments: {
                            'device': _currentDevice,
                            'customer': _currentDevice.customer,
                          },
                        );
                        _loadFullDeviceDetails();
                      },
                      icon: const Icon(Icons.build_rounded, size: 16),
                      label: const Text('Book Repair', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.pushNamed(
                          context,
                          AppRoutes.createSale,
                          arguments: {
                            'device': _currentDevice,
                            'customer': _currentDevice.customer,
                          },
                        );
                        _loadFullDeviceDetails();
                      },
                      icon: const Icon(Icons.receipt_long_rounded, size: 16),
                      label: const Text('New Invoice', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      if (_currentDevice.customer != null) {
                        await QuickWarrantyModal.show(
                          context,
                          customer: _currentDevice.customer,
                          device: _currentDevice,
                        );
                        _loadFullDeviceDetails();
                      } else {
                        AppFeedback.showError(context, error: 'Customer required to issue warranty');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Icon(Icons.verified_user_rounded, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Specifications & Identifiers Card
              CustomCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.perm_device_information_rounded, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Device Specifications & IMEI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.branding_watermark_rounded, 'Brand', _currentDevice.brand),
                    _buildDetailRow(Icons.devices_rounded, 'Model', _currentDevice.model),
                    if (_currentDevice.variant != null && _currentDevice.variant!.isNotEmpty)
                      _buildDetailRow(Icons.memory_rounded, 'RAM & ROM', _currentDevice.variant!),
                    if (_currentDevice.color != null && _currentDevice.color!.isNotEmpty)
                      _buildDetailRow(Icons.color_lens_outlined, 'Color', _currentDevice.color!),
                    if (hasImei1)
                      _buildCopyableRow(Icons.qr_code_2_rounded, 'IMEI 1', _currentDevice.imei1!),
                    if (hasImei2)
                      _buildCopyableRow(Icons.qr_code_2_rounded, 'IMEI 2 (Dual SIM)', _currentDevice.imei2!),
                    if (hasSerial)
                      _buildCopyableRow(Icons.tag_rounded, 'Serial Number', _currentDevice.serialNumber!),
                    if (_currentDevice.purchaseDate != null && _currentDevice.purchaseDate!.isNotEmpty)
                      _buildDetailRow(Icons.calendar_today_rounded, 'Purchase Date', _currentDevice.purchaseDate!),
                    if (_currentDevice.notes != null && _currentDevice.notes!.isNotEmpty)
                      _buildDetailRow(Icons.note_alt_outlined, 'Notes', _currentDevice.notes!),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Customer / Owner Card
              if (_currentDevice.customer != null) ...[
                CustomCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.person_pin_rounded, size: 18, color: AppColors.accent),
                          SizedBox(width: 8),
                          Text('Device Owner Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.primary.withOpacity(0.12),
                            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _currentDevice.customer!.name,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '📱 ${_currentDevice.customer!.mobile}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.phone_rounded, color: AppColors.primary),
                            tooltip: 'Call Customer',
                            onPressed: () => _makeCall(_currentDevice.customer!.mobile),
                          ),
                          IconButton(
                            icon: const WhatsAppIcon(size: 20),
                            tooltip: 'WhatsApp Customer',
                            onPressed: () => WhatsAppHelper.openChat(
                              context,
                              phone: _currentDevice.customer!.mobile,
                              message: 'Hello ${_currentDevice.customer!.name}, regarding your ${_currentDevice.brand} ${_currentDevice.model}...',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.customerDetails,
                              arguments: _currentDevice.customer,
                            );
                          },
                          icon: const Icon(Icons.badge_outlined, size: 16),
                          label: const Text('View Customer Profile & Full Ledger', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            side: const BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // CONNECTED REPAIRS SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.build_circle_rounded, color: Color(0xFFD97706), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Repair Job Cards (${_repairs.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.pushNamed(
                        context,
                        AppRoutes.createRepair,
                        arguments: {
                          'device': _currentDevice,
                          'customer': _currentDevice.customer,
                        },
                      );
                      _loadFullDeviceDetails();
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('+ Book Repair', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_isLoadingDetails)
                AppShimmer.cardLoading(height: 85)
              else if (_repairs.isEmpty)
                CustomCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.build_circle_outlined, size: 28, color: AppColors.textMuted),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'No repair jobs recorded for this device yet.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.createRepair,
                            arguments: {
                              'device': _currentDevice,
                              'customer': _currentDevice.customer,
                            },
                          );
                          _loadFullDeviceDetails();
                        },
                        child: const Text('Book Now'),
                      ),
                    ],
                  ),
                )
              else
                ..._repairs.map((r) {
                  final statusRaw = (r['repair_status'] ?? 'received').toString();
                  final statusColor = _repairStatusColors[statusRaw] ?? AppColors.primary;
                  final statusLabel = _repairStatusLabels[statusRaw] ?? statusRaw.toUpperCase();
                  final cost = (r['final_cost'] != null && (r['final_cost'] as num) > 0)
                      ? (r['final_cost'] as num).toDouble()
                      : ((r['estimated_cost'] as num?)?.toDouble() ?? 0.0);
                  final techName = r['technician']?['name']?.toString();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CustomCard(
                      onTap: () => _openRepairDetails(r['id']),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                r['job_number'] ?? '#REP-${r['id']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: statusColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            r['problem'] ?? 'Repair Service',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (techName != null)
                                Row(
                                  children: [
                                    const Icon(Icons.engineering_rounded, size: 14, color: AppColors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(techName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  ],
                                )
                              else
                                const Text('Unassigned Tech', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                              Row(
                                children: [
                                  Text('₹${cost.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.accent)),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 20),

              // CONNECTED SALES & INVOICES SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_long_rounded, color: Color(0xFF059669), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Sales & Invoices (${_sales.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.pushNamed(
                        context,
                        AppRoutes.createSale,
                        arguments: {
                          'device': _currentDevice,
                          'customer': _currentDevice.customer,
                        },
                      );
                      _loadFullDeviceDetails();
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('+ New Invoice', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_isLoadingDetails)
                AppShimmer.cardLoading(height: 85)
              else if (_sales.isEmpty)
                CustomCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.receipt_outlined, size: 28, color: AppColors.textMuted),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'No sales or invoices recorded for this device.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await Navigator.pushNamed(
                            context,
                            AppRoutes.createSale,
                            arguments: {
                              'device': _currentDevice,
                              'customer': _currentDevice.customer,
                            },
                          );
                          _loadFullDeviceDetails();
                        },
                        child: const Text('Create'),
                      ),
                    ],
                  ),
                )
              else
                ..._sales.map((s) {
                  final total = ((s['grand_total'] as num?)?.toDouble() ?? 0.0);
                  final payStatus = (s['payment_status'] ?? 'paid').toString().toUpperCase();
                  final payMethod = (s['payment_method'] ?? 'cash').toString().toUpperCase();
                  final isPaid = payStatus == 'PAID';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CustomCard(
                      onTap: () => _openSaleDetails(s['id']),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                s['invoice_number'] ?? 'INV-${s['id']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isPaid ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                                ),
                                child: Text(
                                  payStatus,
                                  style: TextStyle(
                                    color: isPaid ? const Color(0xFF047857) : const Color(0xFFB45309),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Mode: $payMethod ${s['sale_date'] != null ? '• ${s['sale_date']}' : ''}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '₹${total.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF059669)),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 20),

              // CONNECTED WARRANTIES SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: Color(0xFF2563EB), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Warranty Records (${_warranties.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  if (_currentDevice.customer != null)
                    TextButton.icon(
                      onPressed: () async {
                        await QuickWarrantyModal.show(
                          context,
                          customer: _currentDevice.customer,
                          device: _currentDevice,
                        );
                        _loadFullDeviceDetails();
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('+ Add Warranty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              if (_isLoadingDetails)
                AppShimmer.cardLoading(height: 70)
              else if (_warranties.isEmpty)
                CustomCard(
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 28, color: AppColors.textMuted),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No active or past warranties registered for this device.',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._warranties.map((w) {
                  final status = (w['status'] ?? 'active').toString().toUpperCase();
                  final isActive = status == 'ACTIVE';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: CustomCard(
                      onTap: () => _openWarrantyDetails(w['id']),
                      child: Row(
                        children: [
                          Icon(Icons.verified_rounded, color: isActive ? Colors.green : Colors.grey, size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  w['code'] ?? 'WAR-${w['id']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Valid: ${w['start_date'] ?? 'N/A'} → ${w['end_date'] ?? 'N/A'}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green.withOpacity(0.12) : Colors.grey.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(color: isActive ? Colors.green.shade800 : Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11)),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: 0.5)),
              ],
            ),
          ),
          InkWell(
            onTap: () => _copyToClipboard(value, label),
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
