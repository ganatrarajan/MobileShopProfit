import 'package:flutter/material.dart';
import '../storage/auth_storage.dart';
import '../storage/preferences_storage.dart';

/// Global service managing profit privacy/security mode.
/// Allows shop owners to hide profit numbers from customer sight.
/// Staff/Technician logins are strictly locked: profit is ALWAYS hidden.
/// The preference persists across app launches via SharedPreferences.
class ProfitVisibilityService {
  static final ProfitVisibilityService _instance = ProfitVisibilityService._internal();
  factory ProfitVisibilityService() => _instance;
  ProfitVisibilityService._internal();

  final PreferencesStorage _prefs = PreferencesStorage();
  final ValueNotifier<bool> isHiddenNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<bool> isOwnerNotifier = ValueNotifier<bool>(true);

  bool _isOwner = true;
  bool get isOwner => _isOwner;
  bool get isStaff => !_isOwner;

  /// Whether profit should be hidden:
  /// - Staff logins: ALWAYS true (zero profit visible anywhere).
  /// - Shop owner: follows user toggle preference.
  bool get isHidden => !_isOwner || isHiddenNotifier.value;

  /// Load persisted state on app startup and detect role
  Future<void> init() async {
    final saved = await _prefs.isHideProfitEnabled();
    final owner = await AuthStorage().isOwner();
    _isOwner = owner;
    isOwnerNotifier.value = owner;
    isHiddenNotifier.value = !_isOwner || saved;
  }

  /// Refresh role check (called upon login or profile switch)
  Future<void> refreshRole() async {
    final owner = await AuthStorage().isOwner();
    _isOwner = owner;
    isOwnerNotifier.value = owner;
    if (!owner) {
      isHiddenNotifier.value = true;
    }
  }

  /// Toggle hide/show mode and persist (Only owners can toggle!)
  Future<void> toggle() async {
    if (!_isOwner) return;
    final next = !isHiddenNotifier.value;
    isHiddenNotifier.value = next;
    await _prefs.setHideProfitEnabled(next);
  }

  /// Explicitly set state and persist (Only owners can set)
  Future<void> setHidden(bool value) async {
    if (!_isOwner) return;
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
    final isNegative = amount < 0;
    final absVal = decimals == 0 ? amount.abs().toStringAsFixed(0) : amount.abs().toStringAsFixed(decimals);
    if (isNegative) {
      return '-$prefix$absVal';
    }
    final sign = showSign && amount > 0 ? '+' : '';
    return '$sign$prefix$absVal';
  }
}

/// Reusable Toggle Button for headers/appbars to show/hide profit (Hidden in staff login)
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
      valueListenable: ProfitVisibilityService().isOwnerNotifier,
      builder: (context, isOwner, _) {
        if (!isOwner) return const SizedBox.shrink();

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
      },
    );
  }
}

/// Reusable Widget to display a profit amount that auto-masks when hidden (Hidden in staff login)
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
      valueListenable: ProfitVisibilityService().isOwnerNotifier,
      builder: (context, isOwner, _) {
        if (!isOwner) return const SizedBox.shrink();

        return ValueListenableBuilder<bool>(
          valueListenable: ProfitVisibilityService().isHiddenNotifier,
          builder: (context, isHidden, _) {
            String text;
            if (isHidden) {
              text = prefix.isNotEmpty ? '$prefix$maskedText' : maskedText;
            } else if (amount == null) {
              text = '-';
            } else {
              final isNegative = amount! < 0;
              final absStr = decimals == 0 ? amount!.abs().toStringAsFixed(0) : amount!.abs().toStringAsFixed(decimals);
              if (isNegative) {
                text = '-$prefix$absStr';
              } else {
                final sign = showSign && amount! > 0 ? '+' : '';
                text = '$sign$prefix$absStr';
              }
            }
            return Text(text, style: style);
          },
        );
      },
    );
  }
}

