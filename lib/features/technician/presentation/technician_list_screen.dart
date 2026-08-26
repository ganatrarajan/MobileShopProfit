import 'package:flutter/material.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_card.dart';
import '../data/technician_repository.dart';
import '../models/technician.dart';
import 'add_edit_technician_dialog.dart';

class TechnicianListScreen extends StatefulWidget {
  const TechnicianListScreen({super.key});

  @override
  State<TechnicianListScreen> createState() => _TechnicianListScreenState();
}

class _TechnicianListScreenState extends State<TechnicianListScreen> {
  final TechnicianRepository _repository = TechnicianRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Technician> _technicians = [];
  TechnicianSummary? _summary;
  bool _isLoading = true;
  String? _errorMessage;

  String _selectedStatus = 'all'; // all, active, inactive

  final Map<String, String> _statusLabels = {
    'all': 'All Technicians',
    'active': 'Active Only',
    'inactive': 'Inactive',
  };

  @override
  void initState() {
    super.initState();
    _fetchTechnicians();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTechnicians() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _repository.getTechnicians(
        search: _searchController.text.trim(),
        status: _selectedStatus,
      );

      if (mounted) {
        if (response.success && response.data != null) {
          setState(() {
            _technicians = response.data!.technicians;
            _summary = response.data!.summary;
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

  Future<void> _openAddDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => const AddEditTechnicianDialog(),
    );

    if (result == true) {
      _fetchTechnicians();
    }
  }

  Future<void> _openEditDialog(Technician tech) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AddEditTechnicianDialog(technician: tech),
    );

    if (result == true) {
      _fetchTechnicians();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Technician Management', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
            onPressed: _openAddDialog,
            tooltip: 'Add Technician',
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Summary Metrics Bar
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric(
                    title: 'Technicians',
                    value: _summary != null ? '${_summary!.totalTechnicians}' : '0',
                    icon: Icons.people_alt_rounded,
                    color: Colors.lightBlueAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryMetric(
                    title: 'Active',
                    value: _summary != null ? '${_summary!.activeTechnicians}' : '0',
                    icon: Icons.check_circle_rounded,
                    color: Colors.lightGreenAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryMetric(
                    title: 'In Progress',
                    value: _summary != null ? '${_summary!.inProgressJobs}' : '0',
                    icon: Icons.engineering_rounded,
                    color: Colors.amberAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryMetric(
                    title: 'Pending',
                    value: _summary != null ? '${_summary!.pendingJobs}' : '0',
                    icon: Icons.pending_actions_rounded,
                    color: Colors.orangeAccent,
                  ),
                ),
              ],
            ),
          ),

          // 2. Search Field
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => _fetchTechnicians(),
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search Name, Mobile, Specialization...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _fetchTechnicians();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),

          // 3. Status Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _statusLabels.entries.map((entry) {
                  final isSelected = _selectedStatus == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(entry.value),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedStatus = entry.key);
                          _fetchTechnicians();
                        }
                      },
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      checkmarkColor: Colors.white,
                      showCheckmark: isSelected,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.grey.shade300,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // 4. Technician List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade300),
                            const SizedBox(height: 12),
                            Text(_errorMessage!, style: const TextStyle(color: AppColors.textSecondary)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _fetchTechnicians,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      )
                    : _technicians.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.engineering_rounded, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 12),
                                const Text(
                                  'No technicians found',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Add technicians to assign repair job cards',
                                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: _openAddDialog,
                                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                                  label: const Text('Add Technician', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchTechnicians,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _technicians.length,
                              itemBuilder: (context, index) {
                                final tech = _technicians[index];
                                final wl = tech.workload;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: CustomCard(
                                    onTap: () async {
                                      final result = await Navigator.pushNamed(
                                        context,
                                        AppRoutes.technicianDetails,
                                        arguments: tech,
                                      );
                                      if (result == true) _fetchTechnicians();
                                    },
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: tech.isActive ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade200,
                                              child: Icon(
                                                Icons.engineering_rounded,
                                                color: tech.isActive ? AppColors.primary : Colors.grey,
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
                                                          tech.name,
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.bold,
                                                            color: AppColors.textPrimary,
                                                          ),
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: tech.isActive ? Colors.green.shade50 : Colors.grey.shade100,
                                                          borderRadius: BorderRadius.circular(12),
                                                          border: Border.all(color: tech.isActive ? Colors.green.shade300 : Colors.grey.shade300),
                                                        ),
                                                        child: Text(
                                                          tech.isActive ? 'Active' : 'Inactive',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: tech.isActive ? Colors.green.shade800 : Colors.grey.shade700,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    tech.specialization != null && tech.specialization!.isNotEmpty
                                                        ? tech.specialization!
                                                        : 'General Technician',
                                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                                  ),
                                                  if (tech.mobile != null && tech.mobile!.isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    Row(
                                                      children: [
                                                        const Icon(Icons.phone_rounded, size: 12, color: AppColors.textMuted),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          tech.mobile!,
                                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.edit_rounded, size: 20, color: AppColors.primary),
                                              onPressed: () => _openEditDialog(tech),
                                              tooltip: 'Edit Technician',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        const Divider(height: 1),
                                        const SizedBox(height: 8),

                                        // Workload Badges Wrap (Prevents horizontal overflow!)
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            _buildBadge('Pending: ${wl.pendingJobs}', Colors.orange),
                                            _buildBadge('In Progress: ${wl.inProgressJobs}', Colors.blue),
                                            _buildBadge('Completed: ${wl.completedJobs}', Colors.green),
                                            _buildBadge('Total: ${wl.totalJobs}', Colors.purple),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddDialog,
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Add Technician', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSummaryMetric({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.shade200),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color.shade900),
      ),
    );
  }
}