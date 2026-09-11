import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppSearchableBottomSheet extends StatefulWidget {
  final String title;
  final List<String> options;
  final List<String> selectedValues;
  final bool isMultiSelect;
  final String searchHint;
  final String? addCustomHint;
  final Future<void> Function(String)? onAddCustomOption;

  const AppSearchableBottomSheet({
    super.key,
    required this.title,
    required this.options,
    this.selectedValues = const [],
    this.isMultiSelect = false,
    this.searchHint = 'Search...',
    this.addCustomHint,
    this.onAddCustomOption,
  });

  static Future<dynamic> show(
    BuildContext context, {
    required String title,
    required List<String> options,
    List<String> selectedValues = const [],
    bool isMultiSelect = false,
    String searchHint = 'Search options...',
    String? addCustomHint,
    Future<void> Function(String)? onAddCustomOption,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return AppSearchableBottomSheet(
          title: title,
          options: options,
          selectedValues: selectedValues,
          isMultiSelect: isMultiSelect,
          searchHint: searchHint,
          addCustomHint: addCustomHint,
          onAddCustomOption: onAddCustomOption,
        );
      },
    );
  }

  @override
  State<AppSearchableBottomSheet> createState() => _AppSearchableBottomSheetState();
}

class _AppSearchableBottomSheetState extends State<AppSearchableBottomSheet> {
  late List<String> _allOptions;
  late Set<String> _selectedSet;
  String _searchQuery = '';
  final TextEditingController _customInputController = TextEditingController();
  bool _isAddingCustom = false;
  bool _isSavingCustom = false;

  @override
  void initState() {
    super.initState();
    _allOptions = List.from(widget.options);
    _selectedSet = Set.from(widget.selectedValues);
  }

  @override
  void dispose() {
    _customInputController.dispose();
    super.dispose();
  }

  Future<void> _handleAddCustom() async {
    final text = _customInputController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSavingCustom = true);
    if (widget.onAddCustomOption != null) {
      await widget.onAddCustomOption!(text);
    }

    if (!_allOptions.contains(text)) {
      _allOptions.insert(0, text);
    }
    _selectedSet.add(text);

    _customInputController.clear();
    setState(() {
      _isAddingCustom = false;
      _isSavingCustom = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _allOptions.where((opt) {
      return opt.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.72,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.isMultiSelect)
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context, _selectedSet.toList());
                    },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      'Done (${_selectedSet.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Search input
            TextField(
              onChanged: (q) => setState(() => _searchQuery = q),
              decoration: InputDecoration(
                hintText: widget.searchHint,
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),

            // Custom addition bar (if enabled)
            if (widget.onAddCustomOption != null || widget.addCustomHint != null) ...[
              if (_isAddingCustom) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customInputController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: widget.addCustomHint ?? 'Enter custom option...',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSavingCustom ? null : _handleAddCustom,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isSavingCustom
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Add', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _isAddingCustom = false),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ] else ...[
                InkWell(
                  onTap: () => setState(() => _isAddingCustom = true),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.add_circle_outline_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            widget.addCustomHint ?? '+ Add Custom Combination / Option',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],

            // Options List
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No matching options found',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, idx) {
                        final item = filtered[idx];
                        final isSelected = _selectedSet.contains(item);

                        if (widget.isMultiSelect) {
                          return CheckboxListTile(
                            value: isSelected,
                            activeColor: AppColors.primary,
                            title: Text(
                              item,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppColors.primary : AppColors.textPrimary,
                              ),
                            ),
                            onChanged: (val) {
                              setState(() {
                                if (val == true) {
                                  _selectedSet.add(item);
                                } else {
                                  _selectedSet.remove(item);
                                }
                              });
                            },
                          );
                        }

                        return ListTile(
                          title: Text(
                            item,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                          onTap: () {
                            Navigator.pop(context, item);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
