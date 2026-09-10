import 'package:flutter/material.dart';

/// Premium official vector WhatsApp logo icon widget.
class WhatsAppIcon extends StatelessWidget {
  final double size;
  final Color color;
  final Color backgroundColor;
  final bool showBackground;

  const WhatsAppIcon({
    super.key,
    this.size = 20,
    this.color = Colors.white,
    this.backgroundColor = const Color(0xFF25D366),
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBackground) {
      return SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          size: Size(size, size),
          painter: _WhatsAppLogoPainter(color: color),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF25D366), Color(0xFF128C7E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF25D366).withOpacity(0.35),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: CustomPaint(
        size: Size(size * 0.62, size * 0.62),
        painter: _WhatsAppLogoPainter(color: color),
      ),
    );
  }
}

class _WhatsAppLogoPainter extends CustomPainter {
  final Color color;
  _WhatsAppLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final scaleX = size.width / 24.0;
    final scaleY = size.height / 24.0;
    canvas.scale(scaleX, scaleY);

    // Official WhatsApp vector bubble path
    final path = Path();
    path.moveTo(12.01, 2.0);
    path.cubicTo(6.48, 2.0, 2.0, 6.48, 2.0, 12.01);
    path.cubicTo(2.0, 13.78, 2.46, 15.45, 3.27, 16.91);
    path.lineTo(2.0, 22.0);
    path.lineTo(7.22, 20.75);
    path.cubicTo(8.64, 21.52, 10.27, 21.96, 12.01, 21.96);
    path.cubicTo(17.53, 21.96, 22.01, 17.53, 22.01, 12.01);
    path.cubicTo(22.01, 6.48, 17.53, 2.0, 12.01, 2.0);
    path.close();

    // Handset cutout path
    final handset = Path();
    handset.moveTo(17.47, 14.36);
    handset.cubicTo(17.2, 14.23, 15.86, 13.57, 15.61, 13.48);
    handset.cubicTo(15.36, 13.39, 15.18, 13.34, 15.0, 13.61);
    handset.cubicTo(14.82, 13.88, 14.3, 14.49, 14.14, 14.67);
    handset.cubicTo(13.98, 14.85, 13.82, 14.87, 13.55, 14.74);
    handset.cubicTo(13.28, 14.6, 12.41, 14.32, 11.38, 13.4);
    handset.cubicTo(10.58, 12.69, 10.04, 11.81, 9.88, 11.54);
    handset.cubicTo(9.72, 11.27, 9.86, 11.13, 10.0, 10.99);
    handset.cubicTo(10.12, 10.87, 10.27, 10.67, 10.41, 10.51);
    handset.cubicTo(10.55, 10.35, 10.6, 10.23, 10.69, 10.05);
    handset.cubicTo(10.78, 9.87, 10.73, 9.72, 10.67, 9.58);
    handset.cubicTo(10.6, 9.45, 10.06, 8.12, 9.84, 7.58);
    handset.cubicTo(9.62, 7.05, 9.4, 7.13, 9.24, 7.12);
    handset.cubicTo(9.09, 7.11, 8.91, 7.11, 8.73, 7.11);
    handset.cubicTo(8.55, 7.11, 8.26, 7.18, 8.01, 7.45);
    handset.cubicTo(7.76, 7.72, 7.05, 8.39, 7.05, 9.75);
    handset.cubicTo(7.05, 11.11, 8.04, 12.42, 8.18, 12.61);
    handset.cubicTo(8.32, 12.8, 10.13, 15.58, 12.9, 16.78);
    handset.cubicTo(13.56, 17.07, 14.07, 17.23, 14.47, 17.36);
    handset.cubicTo(15.13, 17.57, 15.74, 17.54, 16.22, 17.47);
    handset.cubicTo(16.75, 17.39, 17.86, 16.8, 18.09, 16.15);
    handset.cubicTo(18.32, 15.5, 18.32, 14.94, 18.25, 14.82);
    handset.cubicTo(18.18, 14.7, 18.0, 14.63, 17.47, 14.36);
    handset.close();

    final combinedPath = Path.combine(PathOperation.difference, path, handset);
    canvas.drawPath(combinedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _WhatsAppLogoPainter oldDelegate) => oldDelegate.color != color;
}