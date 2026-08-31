import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../models/repair.dart';

class UpdateStatusDialog extends StatefulWidget {
  final Repair repair;
  const UpdateStatusDialog({super.key, required this.repair});

  @override
  State<UpdateStatusDialog> createState() => _UpdateStatusDialogState();
}

class _UpdateStatusDialogState extends State<UpdateStatusDialog> {
  late String _selectedStatus;
  final _notesController = TextEditingController();

  final Map<String, String> _statusLabels = {
    'received': 'Received',
    'diagnosing': 'Diagnosing',
    'waiting_customer': 'Waiting for Customer',
    'waiting_parts': 'Waiting for Parts',
    'repairing': 'Repairing',
    'ready': 'Ready',
    'delivered': 'Delivered',
    'cancelled': 'Cancelled',
  };

  final Map<String, Color> _statusColors = {
    'received': Colors.blue.shade700,
    'diagnosing': Colors.purple.shade700,
    'waiting_customer': Colors.orange.shade800,
    'waiting_parts': Colors.amber.shade900,
    'repairing': Colors.indigo.shade700,
    'ready': Colors.teal.shade700,
    'delivered': Colors.green.shade800,
    'cancelled': Colors.red.shade700,
  };

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.repair.repairStatus;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.published_with_changes_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Update Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(widget.repair.jobNumber, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select New Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _statusLabels.entries.map((entry) {
                final isSelected = _selectedStatus == entry.key;
                final color = _statusColors[entry.key] ?? AppColors.primary;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedStatus = entry.key);
                  },
                  selectedColor: color,
                  backgroundColor: Colors.grey.shade100,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Status Change Notes (Optional)',
                hintText: 'e.g. Waiting for customer screen approval',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'status': _selectedStatus,
              'notes': _notesController.text.trim(),
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _statusColors[_selectedStatus] ?? AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Update Status', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
