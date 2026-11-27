import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/whatsapp_icon.dart';
import '../data/device_repository.dart';
import '../models/device.dart';

class DeviceSearchScreen extends StatefulWidget {
  const DeviceSearchScreen({super.key});

  @override
  State<DeviceSearchScreen> createState() => _DeviceSearchScreenState();
}

class _DeviceSearchScreenState extends State<DeviceSearchScreen> {
  final DeviceRepository _repository = DeviceRepository();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<Device> _devices = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _performSearch('', isInitial: true);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query, {bool isInitial = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _repository.searchDevices(
        search: query.trim().isNotEmpty ? query.trim() : null,
      );
      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _devices = response.data!;
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

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    AppFeedback.showSuccess(
      context,
      title: '📋 Copied to Clipboard',
      message: '$label: $text',
    );
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

  Future<void> _makeCall(String mobile) async {
    final clean = mobile.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: const Text('Device Models & IMEI Database'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Database',
            onPressed: () => _performSearch(_searchController.text),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Summary Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: AppColors.primary,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search IMEI, brand, model, customer name, mobile...',
                    hintStyle: const TextStyle(color: Colors.white60, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: Colors.white70, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.primaryLight.withOpacity(0.4),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.25)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _searchController.text.trim().isEmpty
                          ? 'Showing All Registered Devices (${_devices.length})'
                          : 'Found ${_devices.length} Matching Result(s)',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified_rounded, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'IMEI Linked',
                            style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main List View
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
                              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                              const SizedBox(height: 12),
                              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.error)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _performSearch(_searchController.text),
                                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                child: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _devices.isEmpty
                        ? Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.devices_other_rounded, size: 54, color: AppColors.primary.withOpacity(0.7)),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchController.text.isEmpty
                                        ? 'No Devices Registered Yet'
                                        : 'No Matching Devices or IMEI Found',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _searchController.text.isEmpty
                                        ? 'Devices added through repairs, invoices, or customer profiles will appear here automatically.'
                                        : 'Double-check the IMEI, Model, or customer phone number entered.',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (_searchController.text.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    OutlinedButton.icon(
                                      onPressed: () {
                                        _searchController.clear();
                                        _performSearch('');
                                      },
                                      icon: const Icon(Icons.clear_rounded, size: 16),
                                      label: const Text('Clear Search Filter'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _performSearch(_searchController.text),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _devices.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final device = _devices[index];
                                final hasImei1 = device.imei1 != null && device.imei1!.trim().isNotEmpty;
                                final hasImei2 = device.imei2 != null && device.imei2!.trim().isNotEmpty;
                                final hasSerial = device.serialNumber != null && device.serialNumber!.trim().isNotEmpty;

                                return CustomCard(
                                  padding: const EdgeInsets.all(16),
                                  onTap: () async {
                                    final res = await Navigator.pushNamed(
                                      context,
                                      AppRoutes.deviceDetails,
                                      arguments: device,
                                    );
                                    if (res == true && mounted) {
                                      _performSearch(_searchController.text);
                                    }
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top Header Row
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(
                                              _getDeviceIcon(device.deviceType),
                                              size: 24,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        '${device.brand} ${device.model}',
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.bold,
                                                          color: AppColors.textPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFEFF6FF),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: const Color(0xFFBFDBFE)),
                                                      ),
                                                      child: Text(
                                                        device.deviceType,
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.bold,
                                                          color: Color(0xFF2563EB),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (device.variant != null && device.variant!.trim().isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    '${device.variant}${device.color != null && device.color!.isNotEmpty ? ' • ${device.color}' : ''}',
                                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Identifiers Row (IMEI & Serial)
                                      if (hasImei1 || hasImei2 || hasSerial) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppColors.border),
                                          ),
                                          child: Column(
                                            children: [
                                              if (hasImei1)
                                                Row(
                                                  children: [
                                                    const Icon(Icons.qr_code_2_rounded, size: 16, color: AppColors.primary),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        'IMEI 1: ${device.imei1}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          letterSpacing: 0.5,
                                                          color: AppColors.textPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                    InkWell(
                                                      onTap: () => _copyToClipboard(device.imei1!, 'IMEI 1'),
                                                      borderRadius: BorderRadius.circular(4),
                                                      child: const Padding(
                                                        padding: EdgeInsets.all(4.0),
                                                        child: Icon(Icons.copy_rounded, size: 14, color: AppColors.textMuted),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              if (hasImei2) ...[
                                                if (hasImei1) const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.qr_code_2_rounded, size: 16, color: AppColors.textSecondary),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        'IMEI 2: ${device.imei2}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          letterSpacing: 0.5,
                                                          color: AppColors.textSecondary,
                                                        ),
                                                      ),
                                                    ),
                                                    InkWell(
                                                      onTap: () => _copyToClipboard(device.imei2!, 'IMEI 2'),
                                                      borderRadius: BorderRadius.circular(4),
                                                      child: const Padding(
                                                        padding: EdgeInsets.all(4.0),
                                                        child: Icon(Icons.copy_rounded, size: 14, color: AppColors.textMuted),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                              if (hasSerial && !hasImei1)
                                                Row(
                                                  children: [
                                                    const Icon(Icons.tag_rounded, size: 16, color: AppColors.textSecondary),
                                                    const SizedBox(width: 6),
                                                    Expanded(
                                                      child: Text(
                                                        'Serial: ${device.serialNumber}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: AppColors.textPrimary,
                                                        ),
                                                      ),
                                                    ),
                                                    InkWell(
                                                      onTap: () => _copyToClipboard(device.serialNumber!, 'Serial Number'),
                                                      borderRadius: BorderRadius.circular(4),
                                                      child: const Padding(
                                                        padding: EdgeInsets.all(4.0),
                                                        child: Icon(Icons.copy_rounded, size: 14, color: AppColors.textMuted),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],

                                      // Connected Activity Chips (Repairs, Invoices, Warranties)
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: (device.repairsCount > 0)
                                                  ? const Color(0xFFFEF3C7)
                                                  : Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.build_circle_rounded,
                                                  size: 13,
                                                  color: (device.repairsCount > 0) ? const Color(0xFFD97706) : Colors.grey,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${device.repairsCount} Repairs',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: (device.repairsCount > 0) ? const Color(0xFFB45309) : Colors.grey.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: (device.salesCount > 0)
                                                  ? const Color(0xFFECFDF5)
                                                  : Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.receipt_long_rounded,
                                                  size: 13,
                                                  color: (device.salesCount > 0) ? const Color(0xFF059669) : Colors.grey,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${device.salesCount} Sales',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: (device.salesCount > 0) ? const Color(0xFF047857) : Colors.grey.shade700,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (device.warrantiesCount > 0) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFF6FF),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.verified_user_rounded, size: 13, color: Color(0xFF2563EB)),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${device.warrantiesCount} Warranty',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF1D4ED8),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                          const Spacer(),
                                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                                        ],
                                      ),

                                      // Owner Section with Call / WhatsApp
                                      if (device.customer != null) ...[
                                        const SizedBox(height: 10),
                                        Divider(height: 1, color: AppColors.border),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 12,
                                              backgroundColor: AppColors.primary.withOpacity(0.12),
                                              child: const Icon(Icons.person_rounded, size: 14, color: AppColors.primary),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    device.customer!.name,
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                                  ),
                                                  Text(
                                                    device.customer!.mobile,
                                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.primary),
                                              tooltip: 'Call Customer',
                                              constraints: const BoxConstraints(),
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              onPressed: () => _makeCall(device.customer!.mobile),
                                            ),
                                            IconButton(
                                              icon: const WhatsAppIcon(size: 18),
                                              tooltip: 'WhatsApp Customer',
                                              constraints: const BoxConstraints(),
                                              padding: const EdgeInsets.symmetric(horizontal: 8),
                                              onPressed: () => WhatsAppHelper.openChat(
                                                context,
                                                phone: device.customer!.mobile,
                                                message: 'Hello ${device.customer!.name}, regarding your ${device.brand} ${device.model}...',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
