import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../theme/app_colors.dart';

/// Interactive Digital Signature Drawing Pad Dialog
class DigitalSignaturePadDialog extends StatefulWidget {
  final String title;

  const DigitalSignaturePadDialog({
    super.key,
    this.title = 'Digital Signature Pad',
  });

  static Future<File?> show(BuildContext context, {String title = 'Draw Digital Signature'}) async {
    return await showDialog<File?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DigitalSignaturePadDialog(title: title),
    );
  }

  @override
  State<DigitalSignaturePadDialog> createState() => _DigitalSignaturePadDialogState();
}

class _DigitalSignaturePadDialogState extends State<DigitalSignaturePadDialog> {
  final GlobalKey _repaintKey = GlobalKey();
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _isSaving = false;

  void _onPanStart(DragStartDetails details) {
    final RenderBox? box = _repaintKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final local = box.globalToLocal(details.globalPosition);
      setState(() {
        _currentStroke = [local];
        _strokes.add(_currentStroke);
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final RenderBox? box = _repaintKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final local = box.globalToLocal(details.globalPosition);
      // Constrain within the canvas box
      if (local.dx >= 0 && local.dx <= box.size.width && local.dy >= 0 && local.dy <= box.size.height) {
        setState(() {
          _currentStroke.add(local);
        });
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    _currentStroke = [];
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
    });
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
        _currentStroke = [];
      });
    }
  }

  Future<void> _saveSignature() async {
    int totalPoints = 0;
    for (var stroke in _strokes) {
      totalPoints += stroke.length;
    }

    if (totalPoints < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign on the canvas before saving.'),
          duration: Duration(seconds: 2),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Canvas not ready');

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Failed to encode signature image');

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final fileName = 'sig_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        Navigator.pop(context, file);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save signature: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final canvasWidth = (size.width - 48).clamp(280.0, 520.0);
    final canvasHeight = (canvasWidth * 0.55).clamp(180.0, 260.0);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: canvasWidth,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.draw_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Cancel',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Canvas Area with RepaintBoundary
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: canvasWidth,
                height: canvasHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Stack(
                  children: [
                    // Dotted baseline guide
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 40,
                      child: Container(
                        height: 1,
                        color: Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    const Positioned(
                      right: 24,
                      bottom: 12,
                      child: Text(
                        'Sign above line ✍️',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    // Drawing Canvas
                    RepaintBoundary(
                      key: _repaintKey,
                      child: Container(
                        color: Colors.white,
                        child: GestureDetector(
                          onPanStart: _onPanStart,
                          onPanUpdate: _onPanUpdate,
                          onPanEnd: _onPanEnd,
                          child: CustomPaint(
                            painter: _SignaturePainter(strokes: _strokes),
                            size: Size(canvasWidth, canvasHeight),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Controls (Clear, Undo, Save)
            Row(
              children: [
                TextButton.icon(
                  onPressed: _strokes.isEmpty ? null : _undo,
                  icon: const Icon(Icons.undo_rounded, size: 18),
                  label: const Text('Undo'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
                TextButton.icon(
                  onPressed: _strokes.isEmpty ? null : _clear,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveSignature,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(_isSaving ? 'Saving...' : 'Done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _SignaturePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1E293B) // Premium dark navy ink
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      if (stroke.length == 1) {
        canvas.drawCircle(stroke[0], 1.6, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
      } else {
        final path = Path();
        path.moveTo(stroke[0].dx, stroke[0].dy);
        for (int i = 1; i < stroke.length; i++) {
          path.lineTo(stroke[i].dx, stroke[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

/// Helper sheet to allow user to pick:
/// 1. Draw digital signature
/// 2. Pick from gallery
/// 3. Take photo with camera
/// 4. Clear/remove signature (if exists)
class SignaturePickerHelper {
  static Future<void> showOptions({
    required BuildContext context,
    required String title,
    required Function(File file) onSignaturePicked,
    VoidCallback? onSignatureCleared,
    bool hasExistingSignature = false,
  }) async {
    final ImagePicker picker = ImagePicker();

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),

                // 1. Draw Digital Signature
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.draw_rounded, color: AppColors.primary),
                  ),
                  title: const Text('Draw Digital Signature', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Sign directly with your finger or stylus'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final File? signedFile = await DigitalSignaturePadDialog.show(
                      context,
                      title: 'Draw Signature',
                    );
                    if (signedFile != null) {
                      onSignaturePicked(signedFile);
                    }
                  },
                ),

                // 2. Choose Photo from Gallery
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: Colors.blue),
                  ),
                  title: const Text('Upload from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Choose signature image from your photo album'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    try {
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1000,
                        maxHeight: 500,
                        imageQuality: 90,
                      );
                      if (image != null) {
                        onSignaturePicked(File(image.path));
                      }
                    } catch (_) {}
                  },
                ),

                // 3. Take Photo with Camera
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: Colors.teal),
                  ),
                  title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Snap paper signature using camera'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    try {
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.camera,
                        maxWidth: 1000,
                        maxHeight: 500,
                        imageQuality: 90,
                      );
                      if (image != null) {
                        onSignaturePicked(File(image.path));
                      }
                    } catch (_) {}
                  },
                ),

                // 4. Clear/Delete option if already present
                if (hasExistingSignature && onSignatureCleared != null) ...[
                  const Divider(),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                    ),
                    title: const Text(
                      'Remove Signature',
                      style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onSignatureCleared();
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
