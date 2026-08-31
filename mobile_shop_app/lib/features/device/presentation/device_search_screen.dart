import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
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

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _devices = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _repository.searchDevices(search: query);
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

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Search Devices & IMEI'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by IMEI, Model, Serial, or Customer Name/Mobile...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.white70, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
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
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)))
                    : _devices.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.devices_other_rounded, size: 48, color: AppColors.textMuted),
                                const SizedBox(height: 12),
                                Text(
                                  _searchController.text.isEmpty
                                      ? 'Enter IMEI, Model or Customer to search'
                                      : 'No matching devices found',
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _devices.length,
                            itemBuilder: (context, index) {
                              final device = _devices[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: CustomCard(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.deviceDetails,
                                      arguments: device,
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.phone_iphone_rounded, size: 20, color: AppColors.primary),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              '${device.brand} ${device.model}',
                                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                            ),
                                          ),
                                          Text(
                                            device.deviceType,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accent),
                                          ),
                                        ],
                                      ),
                                      if (device.imei1 != null && device.imei1!.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text('IMEI: ${device.imei1}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                      ],
                                      if (device.customer != null) ...[
                                        const SizedBox(height: 6),
                                        const Divider(color: AppColors.border),
                                        Row(
                                          children: [
                                            const Icon(Icons.person_outline_rounded, size: 14, color: AppColors.textSecondary),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Owner: ${device.customer!.name} (${device.customer!.mobile})',
                                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                            ),
                                          ],
                                        ),
                                      ],
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
  }
}