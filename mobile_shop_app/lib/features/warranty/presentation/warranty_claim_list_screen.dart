import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/warranty_repository.dart';
import '../models/warranty.dart';
import 'update_claim_status_dialog.dart';

class WarrantyClaimListScreen extends StatefulWidget {
  const WarrantyClaimListScreen({super.key});

  @override
  State<WarrantyClaimListScreen> createState() => _WarrantyClaimListScreenState();
}

class _WarrantyClaimListScreenState extends State<WarrantyClaimListScreen> {
  final WarrantyRepository _warrantyRepository = WarrantyRepository();
  final TextEditingController _searchController = TextEditingController();

  List<WarrantyClaim> _claims = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedStatus = 'all';

  final Map<String, String> _statusLabels = {
    'all': 'All Claims',
    'open': 'Open',
    'checking': 'Checking',
    'approved': 'Approved',
    'rejected': 'Rejected',
    'repairing': 'Repairing',
    'resolved': 'Resolved',
    'closed': 'Closed',
  };

  final Map<String, Color> _statusColors = {
    'open': Colors.blue.shade700,
    'checking': Colors.purple.shade700,
    'approved': Colors.teal.shade700,
    'rejected': Colors.red.shade700,
    'repairing': Colors.indigo.shade700,
    'resolved': Colors.green.shade700,
    'closed': Colors.grey.shade700,
  };

  @override
  void initState() {
    super.initState();
    _fetchClaims();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchClaims() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _warrantyRepository.getClaims(
        search: _searchController.text.trim(),
        claimStatus: _selectedStatus,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _claims = response.data!;
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

  Future<void> _updateStatus(WarrantyClaim claim) async {
    final updatedClaim = await showDialog<WarrantyClaim>(
      context: context,
      builder: (ctx) => UpdateClaimStatusDialog(claim: claim),
    );

    if (updatedClaim != null) {
      _fetchClaims();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Warranty Claims'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search & Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primary,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _fetchClaims(),
              decoration: InputDecoration(
                hintText: 'Search Claim #, Customer, IMEI...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
          Container(
            height: 48,
            color: Colors.white,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: _statusLabels.entries.map((entry) {
                final isSelected = _selectedStatus == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: ChoiceChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedStatus = entry.key);
                        _fetchClaims();
                      }
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textSecondary, fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // Claims List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error)))
                    : _claims.isEmpty
                        ? const Center(child: Text('No warranty claims found'))
                        : RefreshIndicator(
                            onRefresh: _fetchClaims,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _claims.length,
                              itemBuilder: (context, index) {
                                final claim = _claims[index];
                                final statusColor = _statusColors[claim.claimStatus] ?? AppColors.primary;
                                final customerName = claim.customer?.name ?? 'Customer';
                                final deviceName = claim.device != null ? '${claim.device!.brand} ${claim.device!.model}' : 'Device';

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: CustomCard(
                                    onTap: () => _updateStatus(claim),
                                    padding: const EdgeInsets.all(14),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(claim.claimNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
                                            StatusBadge(
                                              label: claim.claimStatus.toUpperCase(),
                                              backgroundColor: statusColor.withOpacity(0.12),
                                              textColor: statusColor,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text('$customerName • $deviceName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(height: 4),
                                        Text('Complaint: ${claim.complaint}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                        if (claim.resolution != null && claim.resolution!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Text('Resolution: ${claim.resolution}', style: TextStyle(fontSize: 12, color: Colors.green.shade800, fontWeight: FontWeight.w500)),
                                          ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Claim Date: ${claim.claimDate}', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                                            ElevatedButton(
                                              onPressed: () => _updateStatus(claim),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: statusColor,
                                                foregroundColor: Colors.white,
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              child: const Text('Update Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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
      ),
    );
  }
}
