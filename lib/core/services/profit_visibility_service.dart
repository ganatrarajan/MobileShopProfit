import 'package:flutter/material.dart';
import '../storage/preferences_storage.dart';

/// Global service managing profit privacy/security mode.
/// Allows shop owners to hide profit numbers from customer sight.
/// The preference persists across app launches via SharedPreferences.
class ProfitVisibilityService {
  static final ProfitVisibilityService _instance = ProfitVisibilityService._internal();
  factory ProfitVisibilityService() => _instance;
  ProfitVisibilityService._internal();

  final PreferencesStorage _prefs = PreferencesStorage();
  final ValueNotifier<bool> isHiddenNotifier = ValueNotifier<bool>(false);

  bool get isHidden => isHiddenNotifier.value;

  /// Load persisted state on app startup
  Future<void> init() async {
    final saved = await _prefs.isHideProfitEnabled();
    isHiddenNotifier.value = saved;
  }

  /// Toggle hide/show mode and persist
  Future<void> toggle() async {
    final next = !isHiddenNotifier.value;
    isHiddenNotifier.value = next;
    await _prefs.setHideProfitEnabled(next);
  }

  /// Explicitly set state and persist
  Future<void> setHidden(bool value) async {
    isHiddenNotifier.value = value;
    await _prefs.setHideProfitEnabled(value);
  }

  /// Formats profit number or returns masked string when hidden.
  String format(
    num? amount, {
    String prefix = '₹',
    int decimals = 2,
    bool showSign = false,
    String maskedText = '••••',
  }) {
    if (isHidden) {
      return prefix.isNotEmpty ? '$prefix$maskedText' : maskedText;
    }
    if (amount == null) return '-';
    final val = decimals == 0 ? amount.toStringAsFixed(0) : amount.toStringAsFixed(decimals);
    final sign = showSign && amount > 0 ? '+' : '';
    return '$sign$prefix$val';
  }
}

/// Reusable Toggle Button for headers/appbars to show/hide profit
class ProfitVisibilityToggle extends StatelessWidget {
  final Color? color;
  final double size;
  final EdgeInsetsGeometry padding;

  const ProfitVisibilityToggle({
    super.key,
    this.color = Colors.white,
    this.size = 22,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ProfitVisibilityService().isHiddenNotifier,
      builder: (context, isHidden, _) {
        return IconButton(
          padding: padding,
          constraints: const BoxConstraints(),
          icon: Icon(
            isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: color,
            size: size,
          ),
          tooltip: isHidden ? 'Show Profit Numbers' : 'Hide Profit Numbers (Security Mode)',
          onPressed: () {
            ProfitVisibilityService().toggle();
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  !isHidden
                      ? '🔒 Profit hidden across all screens (Security Mode)'
                      : '👁 Profit visible across all screens',
                ),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      },
    );
  }
}

/// Reusable Widget to display a profit amount that auto-masks when hidden
class ProfitText extends StatelessWidget {
  final num? amount;
  final String prefix;
  final int decimals;
  final bool showSign;
  final TextStyle? style;
  final String maskedText;

  const ProfitText({
    super.key,
    required this.amount,
    this.prefix = '₹',
    this.decimals = 2,
    this.showSign = false,
    this.style,
    this.maskedText = '••••',
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ProfitVisibilityService().isHiddenNotifier,
      builder: (context, isHidden, _) {
        final text = isHidden
            ? (prefix.isNotEmpty ? '$prefix$maskedText' : maskedText)
            : (amount == null
                ? '-'
                : '${showSign && amount! > 0 ? "+" : ""}$prefix${decimals == 0 ? amount!.toStringAsFixed(0) : amount!.toStringAsFixed(decimals)}');
        return Text(text, style: style);
      },
    );
  }
}

