import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DateRangeEmptyState extends StatelessWidget {
  final IconData icon;
  final String entityName; // e.g. "Purchases", "Repairs", "Sales"
  final String datePreset; // 'today', 'this_month', 'last_month', 'all_time', 'custom', etc.
  final String dateFilterLabel; // e.g. "This Month", "Last Month", "Today"
  final bool hasActiveSearchOrFilter;
  final VoidCallback? onResetFilters;
  final ValueChanged<String>? onSelectDatePreset; // passes 'last_month', 'this_month', 'all_time'
  final String? createActionLabel; // e.g. "+ Add Purchase"
  final VoidCallback? onCreateAction;

  const DateRangeEmptyState({
    super.key,
    required this.icon,
    required this.entityName,
    required this.datePreset,
    required this.dateFilterLabel,
    this.hasActiveSearchOrFilter = false,
    this.onResetFilters,
    this.onSelectDatePreset,
    this.createActionLabel,
    this.onCreateAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    String title;
    String description;
    final List<Widget> actionChips = [];

    if (hasActiveSearchOrFilter) {
      title = 'No Matching $entityName';
      description = 'No $entityName found matching your active search or filters in $dateFilterLabel.';
      if (onResetFilters != null) {
        actionChips.add(
          OutlinedButton.icon(
            onPressed: onResetFilters,
            icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
            label: const Text('Clear Filters'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        );
      }
    } else if (datePreset == 'this_month') {
      title = 'No $entityName in This Month';
      description = 'No $entityName recorded for this month yet.\nIf you have earlier records, select "Last Month" or "All Time".';
      if (onSelectDatePreset != null) {
        actionChips.add(
          ElevatedButton.icon(
            onPressed: () => onSelectDatePreset!('last_month'),
            icon: const Icon(Icons.history_rounded, size: 16, color: Colors.white),
            label: const Text('Check Last Month', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 1,
            ),
          ),
        );
        actionChips.add(
          OutlinedButton.icon(
            onPressed: () => onSelectDatePreset!('all_time'),
            icon: const Icon(Icons.all_inclusive_rounded, size: 16),
            label: const Text('View All Time'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        );
      }
    } else if (datePreset == 'today') {
      title = 'No $entityName Today';
      description = 'No $entityName recorded today.\nSwitch to "This Month" or "All Time" to view previous records.';
      if (onSelectDatePreset != null) {
        actionChips.add(
          ElevatedButton.icon(
            onPressed: () => onSelectDatePreset!('this_month'),
            icon: const Icon(Icons.calendar_view_month_rounded, size: 16, color: Colors.white),
            label: const Text('Check This Month', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 1,
            ),
          ),
        );
        actionChips.add(
          OutlinedButton.icon(
            onPressed: () => onSelectDatePreset!('all_time'),
            icon: const Icon(Icons.all_inclusive_rounded, size: 16),
            label: const Text('View All Time'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        );
      }
    } else if (datePreset == 'last_month') {
      title = 'No $entityName in Last Month';
      description = 'No $entityName found in last month.\nTry "All Time" to view all records, or create a new entry.';
      if (onSelectDatePreset != null) {
        actionChips.add(
          ElevatedButton.icon(
            onPressed: () => onSelectDatePreset!('all_time'),
            icon: const Icon(Icons.all_inclusive_rounded, size: 16, color: Colors.white),
            label: const Text('View All Time', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 1,
            ),
          ),
        );
        actionChips.add(
          OutlinedButton.icon(
            onPressed: () => onSelectDatePreset!('this_month'),
            icon: const Icon(Icons.calendar_month_rounded, size: 16),
            label: const Text('This Month'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        );
      }
    } else {
      title = 'No $entityName Found';
      description = 'No $entityName found for $dateFilterLabel.\nTap below to switch dates or add a new entry.';
      if (onSelectDatePreset != null && datePreset != 'all_time') {
        actionChips.add(
          ElevatedButton.icon(
            onPressed: () => onSelectDatePreset!('all_time'),
            icon: const Icon(Icons.all_inclusive_rounded, size: 16, color: Colors.white),
            label: const Text('View All Time', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 1,
            ),
          ),
        );
      }
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryTextColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontSize: 13, color: secondaryTextColor, height: 1.4),
              textAlign: TextAlign.center,
            ),
            if (actionChips.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: actionChips,
              ),
            ],
            if (createActionLabel != null && onCreateAction != null) ...[
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: onCreateAction,
                icon: const Icon(Icons.add_circle_outline_rounded, size: 16),
                label: Text(createActionLabel!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: TextButton.styleFrom(foregroundColor: AppColors.accent),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

