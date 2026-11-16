import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/gst_calculator.dart';

class GstInputCard extends StatefulWidget {
  final double amount;
  final bool initialEnabled;
  final GstMode initialMode;
  final double initialRate;
  final bool initialInterState;
  final String title;
  final ValueChanged<GstCalculationResult> onChanged;

  const GstInputCard({
    super.key,
    required this.amount,
    this.initialEnabled = false,
    this.initialMode = GstMode.exclusive,
    this.initialRate = 18.0,
    this.initialInterState = false,
    this.title = 'Apply GST / Tax',
    required this.onChanged,
  });

  @override
  State<GstInputCard> createState() => _GstInputCardState();
}

class _GstInputCardState extends State<GstInputCard> {
  late bool _isEnabled;
  late GstMode _mode;
  late double _rate;
  late bool _isInterState;
  late TextEditingController _customRateController;
  bool _isCustomRate = false;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.initialEnabled;
    _mode = widget.initialMode;
    _rate = widget.initialRate;
    _isInterState = widget.initialInterState;
    _isCustomRate = !GstCalculator.standardSlabs.contains(_rate);
    _customRateController = TextEditingController(
      text: _isCustomRate ? _rate.toString() : '',
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyParent());
  }

  @override
  void didUpdateWidget(covariant GstInputCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool shouldNotify = false;
    if (oldWidget.initialEnabled != widget.initialEnabled && _isEnabled != widget.initialEnabled) {
      _isEnabled = widget.initialEnabled;
      shouldNotify = true;
    }
    if (oldWidget.initialRate != widget.initialRate && _rate != widget.initialRate) {
      _rate = widget.initialRate;
      _isCustomRate = !GstCalculator.standardSlabs.contains(_rate);
      _customRateController.text = _isCustomRate ? _rate.toString() : '';
      shouldNotify = true;
    }
    if (oldWidget.initialMode != widget.initialMode && _mode != widget.initialMode) {
      _mode = widget.initialMode;
      shouldNotify = true;
    }
    if (oldWidget.initialInterState != widget.initialInterState && _isInterState != widget.initialInterState) {
      _isInterState = widget.initialInterState;
      shouldNotify = true;
    }
    if (oldWidget.amount != widget.amount || shouldNotify) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _notifyParent());
    }
  }

  @override
  void dispose() {
    _customRateController.dispose();
    super.dispose();
  }

  void _notifyParent() {
    final result = GstCalculator.calculate(
      amount: widget.amount,
      rate: _rate,
      mode: _mode,
      isInterState: _isInterState,
      isEnabled: _isEnabled,
    );
    widget.onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final result = GstCalculator.calculate(
      amount: widget.amount,
      rate: _rate,
      mode: _mode,
      isInterState: _isInterState,
      isEnabled: _isEnabled,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _isEnabled ? const Color(0xFFF8FAFC) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isEnabled ? AppColors.primary.withOpacity(0.35) : Colors.grey.shade300,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Clean Header Row
          InkWell(
            onTap: () {
              setState(() => _isEnabled = !_isEnabled);
              _notifyParent();
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _isEnabled ? AppColors.primary : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    size: 18,
                    color: _isEnabled ? Colors.white : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _isEnabled
                            ? '${_rate.toStringAsFixed(_rate % 1 == 0 ? 0 : 1)}% ${_mode == GstMode.exclusive ? "GST Extra (+)" : "GST Included"} • ${_isInterState ? "IGST" : "CGST+SGST"}'
                            : 'Enable to calculate CGST, SGST, or IGST',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: _isEnabled ? AppColors.primary : Colors.grey.shade600,
                          fontWeight: _isEnabled ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _isEnabled,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    setState(() => _isEnabled = val);
                    _notifyParent();
                  },
                ),
              ],
            ),
          ),

          if (_isEnabled) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 0.8),
            const SizedBox(height: 12),

            // 2. Segmented Mode Switcher (Exclusive vs Inclusive)
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildModeTab(
                      label: 'Exclusive (+Tax)',
                      icon: Icons.add_circle_outline_rounded,
                      isSelected: _mode == GstMode.exclusive,
                      onTap: () {
                        setState(() => _mode = GstMode.exclusive);
                        _notifyParent();
                      },
                    ),
                  ),
                  Expanded(
                    child: _buildModeTab(
                      label: 'Inclusive (In Price)',
                      icon: Icons.check_circle_outline_rounded,
                      isSelected: _mode == GstMode.inclusive,
                      onTap: () {
                        setState(() => _mode = GstMode.inclusive);
                        _notifyParent();
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 3. Tax Rate Slabs
            Row(
              children: [
                Text(
                  'Tax Rate:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final slab in [0.0, 5.0, 12.0, 18.0, 28.0]) ...[
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _buildRateChip(
                              label: '${slab.toInt()}%',
                              isSelected: !_isCustomRate && _rate == slab,
                              onTap: () {
                                setState(() {
                                  _isCustomRate = false;
                                  _rate = slab;
                                  _customRateController.clear();
                                });
                                _notifyParent();
                              },
                            ),
                          ),
                        ],
                        _buildRateChip(
                          label: _isCustomRate ? '${_rate.toStringAsFixed(1)}%' : 'Custom',
                          isSelected: _isCustomRate,
                          onTap: () {
                            setState(() => _isCustomRate = true);
                            _showCustomRateDialog();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // 4. Region Switcher (Intra-State vs Inter-State)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'GST Type:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: InkWell(
                    onTap: () {
                      setState(() => _isInterState = !_isInterState);
                      _notifyParent();
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: _isInterState ? Colors.purple.shade50 : Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: _isInterState ? Colors.purple.shade300 : Colors.teal.shade300,
                          width: 1,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isInterState ? Icons.public_rounded : Icons.home_work_rounded,
                              size: 13,
                              color: _isInterState ? Colors.purple.shade800 : Colors.teal.shade800,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isInterState ? 'Inter-State (IGST)' : 'Intra-State (CGST + SGST)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _isInterState ? Colors.purple.shade900 : Colors.teal.shade900,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              Icons.swap_horiz_rounded,
                              size: 13,
                              color: _isInterState ? Colors.purple.shade800 : Colors.teal.shade800,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (widget.amount > 0 && result.taxAmount > 0) ...[
              const SizedBox(height: 10),
              // 5. Clean Structured Info Note (No Cut-off, Full Details)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: Colors.blue.shade800),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _isInterState
                                ? 'IGST (${result.rate.toStringAsFixed(0)}%): ₹${result.igstAmount.toStringAsFixed(2)}'
                                : 'CGST (${(result.rate / 2).toStringAsFixed(1)}%): ₹${result.cgstAmount.toStringAsFixed(2)} | SGST (${(result.rate / 2).toStringAsFixed(1)}%): ₹${result.sgstAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 8, thickness: 0.5, color: Color(0xFFBFDBFE)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _mode == GstMode.exclusive ? 'Total Tax Extra (+):' : 'Total Tax Included:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                        Text(
                          '₹${result.taxAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Final Payable:',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Text(
                          '₹${result.totalPayable.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(7),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? AppColors.primary : Colors.grey.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRateChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  void _showCustomRateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Custom GST Rate (%)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _customRateController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Enter GST %',
            hintText: 'e.g. 18.5',
            suffixText: '%',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final customVal = double.tryParse(_customRateController.text.trim()) ?? 0.0;
              if (customVal >= 0 && customVal <= 100) {
                setState(() {
                  _rate = customVal;
                  _isCustomRate = true;
                });
                _notifyParent();
                Navigator.pop(ctx);
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
