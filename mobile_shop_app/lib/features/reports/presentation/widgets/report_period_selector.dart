import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ReportPeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final ValueChanged<String> onPeriodSelected;
  final VoidCallback? onCustomDateTap;

  const ReportPeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodSelected,
    this.onCustomDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final periods = [
      {'label': 'Today', 'value': 'today'},
      {'label': 'This Week', 'value': 'this_week'},
      {'label': 'This Month', 'value': 'this_month'},
      {'label': 'Last Month', 'value': 'last_month'},
      {'label': 'This Year', 'value': 'this_year'},
      {'label': 'Custom', 'value': 'custom'},
    ];

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: periods.length,
        itemBuilder: (context, index) {
          final item = periods[index];
          final isSelected = selectedPeriod == item['value'];

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(item['label']!),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  if (item['value'] == 'custom' && onCustomDateTap != null) {
                    onCustomDateTap!();
                  } else {
                    onPeriodSelected(item['value']!);
                  }
                }
              },
              selectedColor: AppColors.primary,
              backgroundColor: Colors.grey.shade100,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }
}
