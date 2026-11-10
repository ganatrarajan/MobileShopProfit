import 'package:flutter/material.dart';
import '../models/staff.dart';
import 'add_edit_staff_bottom_sheet.dart';

export 'add_edit_staff_bottom_sheet.dart';

/// Legacy alias to maintain backward compatibility while rendering as the modern Bottom Sheet
class AddEditStaffDialog extends StatelessWidget {
  final Staff? staff;

  const AddEditStaffDialog({super.key, this.staff});

  @override
  Widget build(BuildContext context) {
    return AddEditStaffBottomSheet(staff: staff);
  }
}
