import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

class PatternHelper {
  static const String prefix = 'PATTERN:';

  static bool isPattern(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    return trimmed.toUpperCase().startsWith(prefix);
  }

  static List<int> parsePattern(String? value) {
    if (value == null || !isPattern(value)) return [];
    final content = value.trim().substring(prefix.length).trim();
    final parts = content.split(RegExp(r'[\s\-,\>]+'));
    final List<int> points = [];
    for (final part in parts) {
      final p = int.tryParse(part.trim());
      if (p != null && p >= 1 && p <= 9 && !points.contains(p)) {
        points.add(p);
      }
    }
    return points;
  }

  static String formatPattern(List<int> points) {
    return '$prefix ${points.join('-')}';
  }

  static String toReadableString(List<int> points) {
    if (points.isEmpty) return 'No pattern';
    return points.join(' → ');
  }
}

/// Visual 3x3 Pattern Preview Widget
class PatternPreviewWidget extends StatelessWidget {
  final List<int> pattern;
  final double dimension;
  final Color dotColor;
  final Color lineColor;
  final Color activeDotColor;

  const PatternPreviewWidget({
    super.key,
    required this.pattern,
    this.dimension = 140,
    this.dotColor = const Color(0xFFD1D5DB),
    this.lineColor = AppColors.primary,
    this.activeDotColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: dimension,
      height: dimension,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(
        size: Size(dimension, dimension),
        painter: _PatternPainter(
          pattern: pattern,
          dotColor: dotColor,
          lineColor: lineColor,
          activeDotColor: activeDotColor,
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  final List<int> pattern;
  final Color dotColor;
  final Color lineColor;
  final Color activeDotColor;

  _PatternPainter({
    required this.pattern,
    required this.dotColor,
    required this.lineColor,
    required this.activeDotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padding = size.width * 0.16;
    final usableWidth = size.width - padding * 2;
    final spacing = usableWidth / 2;

    Offset getOffset(int index) {
      final col = (index - 1) % 3;
      final row = (index - 1) ~/ 3;
      return Offset(padding + col * spacing, padding + row * spacing);
    }

    // 1. Draw Connecting Lines
    if (pattern.length > 1) {
      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = size.width * 0.045
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(getOffset(pattern[0]).dx, getOffset(pattern[0]).dy);
      for (int i = 1; i < pattern.length; i++) {
        final pt = getOffset(pattern[i]);
        path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path, linePaint);

      // Draw direction arrows on lines
      for (int i = 0; i < pattern.length - 1; i++) {
        final p1 = getOffset(pattern[i]);
        final p2 = getOffset(pattern[i + 1]);
        _drawDirectionIndicator(canvas, p1, p2, size.width * 0.04, lineColor);
      }
    }

    // 2. Draw 9 dots
    final dotRadius = size.width * 0.075;
    for (int i = 1; i <= 9; i++) {
      final pt = getOffset(i);
      final isSelected = pattern.contains(i);

      if (isSelected) {
        // Outer halo
        final haloPaint = Paint()
          ..color = activeDotColor.withOpacity(0.2)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, dotRadius * 1.5, haloPaint);

        // Active node circle
        final activePaint = Paint()
          ..color = activeDotColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, dotRadius, activePaint);

        // Clean inner solid dot (standard Android pattern look)
        final innerDotPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, dotRadius * 0.42, innerDotPaint);
      } else {
        // Inactive dot
        final inactivePaint = Paint()
          ..color = dotColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, dotRadius * 0.55, inactivePaint);
      }
    }
  }

  void _drawDirectionIndicator(Canvas canvas, Offset p1, Offset p2, double arrowSize, Color color) {
    final mid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    final angle = atan2(p2.dy - p1.dy, p2.dx - p1.dx);

    final arrowPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(
      mid.dx + arrowSize * cos(angle),
      mid.dy + arrowSize * sin(angle),
    );
    path.lineTo(
      mid.dx + arrowSize * 0.6 * cos(angle + 2.5),
      mid.dy + arrowSize * 0.6 * sin(angle + 2.5),
    );
    path.lineTo(
      mid.dx + arrowSize * 0.6 * cos(angle - 2.5),
      mid.dy + arrowSize * 0.6 * sin(angle - 2.5),
    );
    path.close();

    canvas.drawPath(path, arrowPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _PatternPainter oldDelegate) {
    return oldDelegate.pattern != pattern || oldDelegate.lineColor != lineColor;
  }
}

/// Interactive Pattern Lock Drawer Dialog - Responsive for All Mobile Screens
class PatternLockDialog extends StatefulWidget {
  final List<int>? initialPattern;

  const PatternLockDialog({super.key, this.initialPattern});

  static Future<List<int>?> show(BuildContext context, {List<int>? initialPattern}) {
    return showDialog<List<int>>(
      context: context,
      barrierDismissible: true,
      builder: (_) => PatternLockDialog(initialPattern: initialPattern),
    );
  }

  @override
  State<PatternLockDialog> createState() => _PatternLockDialogState();
}

class _PatternLockDialogState extends State<PatternLockDialog> {
  final List<int> _selectedDots = [];
  Offset? _currentTouchPoint;

  @override
  void initState() {
    super.initState();
    if (widget.initialPattern != null && widget.initialPattern!.isNotEmpty) {
      _selectedDots.addAll(widget.initialPattern!);
    }
  }

  void _onPanStart(DragStartDetails details, Size size) {
    _handleTouch(details.localPosition, size, isNewDrag: true);
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    _handleTouch(details.localPosition, size, isNewDrag: false);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _currentTouchPoint = null;
    });
  }

  void _handleTouch(Offset localPos, Size size, {required bool isNewDrag}) {
    if (isNewDrag) {
      _selectedDots.clear();
    }

    final padding = size.width * 0.16;
    final usableWidth = size.width - padding * 2;
    final spacing = usableWidth / 2;
    final hitRadius = spacing * 0.42;

    int? hitIndex;
    for (int i = 1; i <= 9; i++) {
      final col = (i - 1) % 3;
      final row = (i - 1) ~/ 3;
      final dotCenter = Offset(padding + col * spacing, padding + row * spacing);
      if ((localPos - dotCenter).distance <= hitRadius) {
        hitIndex = i;
        break;
      }
    }

    setState(() {
      _currentTouchPoint = localPos;
      if (hitIndex != null && !_selectedDots.contains(hitIndex)) {
        HapticFeedback.selectionClick();
        _selectedDots.add(hitIndex);
      }
    });
  }

  void _clear() {
    setState(() {
      _selectedDots.clear();
      _currentTouchPoint = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    // Adapt canvas size responsively so it never overflows or looks squished on any phone
    final double boardSize = (screenWidth - 64).clamp(210.0, 275.0);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pattern_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Draw Device Pattern Lock',
                          style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Connect at least 2 dots with finger',
                          style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Pattern Drawing Canvas
              Center(
                child: Container(
                  width: boardSize,
                  height: boardSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: GestureDetector(
                      onPanStart: (d) => _onPanStart(d, Size(boardSize, boardSize)),
                      onPanUpdate: (d) => _onPanUpdate(d, Size(boardSize, boardSize)),
                      onPanEnd: _onPanEnd,
                      child: CustomPaint(
                        size: Size(boardSize, boardSize),
                        painter: _InteractivePatternPainter(
                          selectedDots: _selectedDots,
                          currentTouchPoint: _currentTouchPoint,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Current Sequence Display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedDots.isNotEmpty ? AppColors.primary.withOpacity(0.08) : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedDots.isNotEmpty ? Icons.check_circle_rounded : Icons.touch_app_rounded,
                      size: 16,
                      color: _selectedDots.isNotEmpty ? AppColors.primary : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedDots.isNotEmpty
                            ? 'Sequence: ${PatternHelper.toReadableString(_selectedDots)} (${_selectedDots.length} dots)'
                            : 'Drag finger across dots to set pattern',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: _selectedDots.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                          color: _selectedDots.isNotEmpty ? AppColors.primary : AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_selectedDots.isNotEmpty)
                      InkWell(
                        onTap: _clear,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text('Clear', style: TextStyle(color: Colors.red, fontSize: 11.5, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Responsive Action Buttons for ALL Mobile Screen Sizes
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      onPressed: _selectedDots.length >= 2
                          ? () {
                              HapticFeedback.mediumImpact();
                              Navigator.pop(context, _selectedDots);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        disabledBackgroundColor: AppColors.primary.withOpacity(0.35),
                      ),
                      child: const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded, size: 16),
                            SizedBox(width: 5),
                            Text(
                              'Confirm Pattern',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InteractivePatternPainter extends CustomPainter {
  final List<int> selectedDots;
  final Offset? currentTouchPoint;

  _InteractivePatternPainter({
    required this.selectedDots,
    this.currentTouchPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final padding = size.width * 0.16;
    final usableWidth = size.width - padding * 2;
    final spacing = usableWidth / 2;

    Offset getOffset(int index) {
      final col = (index - 1) % 3;
      final row = (index - 1) ~/ 3;
      return Offset(padding + col * spacing, padding + row * spacing);
    }

    // 1. Draw Connecting Lines
    if (selectedDots.length > 1) {
      final linePaint = Paint()
        ..color = AppColors.primary
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(getOffset(selectedDots[0]).dx, getOffset(selectedDots[0]).dy);
      for (int i = 1; i < selectedDots.length; i++) {
        final pt = getOffset(selectedDots[i]);
        path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // 2. Draw line from last dot to current touch position
    if (selectedDots.isNotEmpty && currentTouchPoint != null) {
      final lastPt = getOffset(selectedDots.last);
      final dragLinePaint = Paint()
        ..color = AppColors.primary.withOpacity(0.55)
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(lastPt, currentTouchPoint!, dragLinePaint);
    }

    // 3. Draw 9 dots with authentic Android lock styling
    final dotRadius = size.width * 0.085;
    for (int i = 1; i <= 9; i++) {
      final pt = getOffset(i);
      final isSelected = selectedDots.contains(i);

      if (isSelected) {
        // Outer halo
        final haloPaint = Paint()
          ..color = AppColors.primary.withOpacity(0.2)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, dotRadius * 1.5, haloPaint);

        // Active node circle
        final activePaint = Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, dotRadius, activePaint);

        // Inner solid white dot
        final innerDotPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, dotRadius * 0.42, innerDotPaint);
      } else {
        // Inactive dot
        final inactivePaint = Paint()
          ..color = const Color(0xFF94A3B8)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pt, dotRadius * 0.45, inactivePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _InteractivePatternPainter oldDelegate) {
    return oldDelegate.selectedDots != selectedDots || oldDelegate.currentTouchPoint != currentTouchPoint;
  }
}
