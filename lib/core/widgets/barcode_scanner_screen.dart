import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannedBoxResult {
  final String? imei1;
  final String? imei2;
  final String? serialNumber;
  final List<String> allCodes;

  const ScannedBoxResult({
    this.imei1,
    this.imei2,
    this.serialNumber,
    this.allCodes = const [],
  });

  bool get hasAnyImei => (imei1 != null && imei1!.isNotEmpty) || (imei2 != null && imei2!.isNotEmpty);
  bool get hasBothImeis => (imei1 != null && imei1!.isNotEmpty) && (imei2 != null && imei2!.isNotEmpty);
  bool get hasAnyData => hasAnyImei || (serialNumber != null && serialNumber!.isNotEmpty);

  /// Strict validation: A valid mobile IMEI must be 14, 15, or 16 numeric digits only.
  static bool isValidImei(String? value) {
    if (value == null) return false;
    final clean = value.trim();
    final digits = clean.replaceAll(RegExp(r'[^0-9]'), '');
    return (digits.length == 14 || digits.length == 15 || digits.length == 16) && digits == clean;
  }
}

class BarcodeScannerScreen extends StatefulWidget {
  final String title;
  final String instruction;
  final bool isMultiMode;

  const BarcodeScannerScreen({
    super.key,
    this.title = 'Scan Mobile Box (IMEI & Serial)',
    this.instruction = 'Point camera at box sticker to capture all codes',
    this.isMultiMode = true,
  });

  /// Opens the camera barcode scanner and instantly returns the detected code on scan (zero clicks required)
  static Future<String?> scan(
    BuildContext context, {
    String title = 'Scan Barcode or IMEI',
    String instruction = 'Align barcode inside viewfinder to scan instantly',
  }) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => BarcodeScannerScreen(
          title: title,
          instruction: instruction,
          isMultiMode: false,
        ),
      ),
    );
    if (result == null) return null;
    if (result is String) return result.trim();
    if (result is ScannedBoxResult) {
      return result.imei1 ?? result.serialNumber ?? (result.allCodes.isNotEmpty ? result.allCodes.first : null);
    }
    return null;
  }

  /// Opens the camera barcode scanner to capture all box barcodes (IMEI 1, IMEI 2, S/N) in ONE shot
  static Future<ScannedBoxResult?> scanBox(
    BuildContext context, {
    String title = 'Scan Mobile Box (IMEI & Serial)',
    String instruction = 'Point camera at box sticker to capture all codes together',
  }) async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => BarcodeScannerScreen(
          title: title,
          instruction: instruction,
          isMultiMode: true,
        ),
      ),
    );
    if (result == null) return null;
    if (result is ScannedBoxResult) return result;
    if (result is String) {
      final trimmed = result.trim();
      if (ScannedBoxResult.isValidImei(trimmed)) {
        return ScannedBoxResult(imei1: trimmed, allCodes: [trimmed]);
      } else {
        return ScannedBoxResult(serialNumber: trimmed, allCodes: [trimmed]);
      }
    }
    return null;
  }

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _controller;
  late AnimationController _laserController;
  late Animation<double> _laserAnimation;

  // Zoom control (defaults to 1.8x optical-like zoom so small box barcodes are sharp and readable)
  double _currentZoom = 0.25;
  double _baseZoom = 0.25;

  // Real-time detected unique barcodes in frame
  final Set<String> _detectedRawCodes = <String>{};
  ScannedBoxResult _parsedResult = const ScannedBoxResult();

  bool _isFinished = false;

  @override
  void initState() {
    super.initState();

    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.unrestricted,
      facing: CameraFacing.back,
      torchEnabled: false,
      cameraResolution: const Size(1920, 1080),
      autoStart: true,
    );

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _laserController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        try {
          await _controller.setZoomScale(_currentZoom);
        } catch (_) {}
      }
    });
  }

  @override
  void dispose() {
    _laserController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isFinished) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    // Single scan mode: Instant auto-finish on the very first barcode detected (ZERO CLICKS REQUIRED)
    if (!widget.isMultiMode) {
      for (final b in barcodes) {
        final raw = b.rawValue?.trim();
        if (raw != null && raw.isNotEmpty) {
          _finishSingle(raw);
          return;
        }
      }
      return;
    }

    bool newFound = false;
    for (final b in barcodes) {
      final raw = b.rawValue?.trim();
      if (raw != null && raw.isNotEmpty && !_detectedRawCodes.contains(raw)) {
        _detectedRawCodes.add(raw);
        newFound = true;
      }
    }

    if (newFound) {
      HapticFeedback.selectionClick();
      final parsed = _parseDetectedList(_detectedRawCodes.toList());
      setState(() {
        _parsedResult = parsed;
      });

      // Multi-box mode: If both IMEIs captured, auto-finish after short pause without manual clicks
      if (parsed.hasBothImeis) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && !_isFinished) {
            _finishMulti();
          }
        });
      }
    }
  }

  ScannedBoxResult _parseDetectedList(List<String> rawCodes) {
    String? imei1;
    String? imei2;
    String? serial;

    final imeis = <String>[];
    final others = <String>[];

    for (final raw in rawCodes) {
      final clean = raw.trim();
      if (clean.isEmpty) continue;

      // Clean common prefixes
      final withoutPrefix = clean.replaceFirst(
        RegExp(r'^(IMEI\s*[12]?\s*:\s*|IMEI\s*:|MEID\s*:|S\/N\s*:|SN\s*:|P\/N\s*:|PN\s*:|PART\s*NO\s*:|MODEL\s*:)', caseSensitive: false),
        '',
      ).trim();

      // Check explicit labels for IMEI 1
      if (RegExp(r'^(IMEI\s*1\b|IMEI_1|IMEI1)', caseSensitive: false).hasMatch(clean)) {
        final digits = clean.replaceAll(RegExp(r'[^0-9]'), '');
        if (ScannedBoxResult.isValidImei(digits)) {
          imei1 = digits;
          continue;
        }
      }

      // Check explicit labels for IMEI 2
      if (RegExp(r'^(IMEI\s*2\b|IMEI_2|IMEI2)', caseSensitive: false).hasMatch(clean)) {
        final digits = clean.replaceAll(RegExp(r'[^0-9]'), '');
        if (ScannedBoxResult.isValidImei(digits)) {
          imei2 = digits;
          continue;
        }
      }

      if (RegExp(r'^(S\/?N|SERIAL)', caseSensitive: false).hasMatch(clean)) {
        serial = withoutPrefix;
        continue;
      }

      // Check if it's strictly a valid 14-16 digit numeric phone IMEI
      if (ScannedBoxResult.isValidImei(withoutPrefix)) {
        if (!imeis.contains(withoutPrefix)) {
          imeis.add(withoutPrefix);
        }
      } else {
        // Non-IMEI barcode (Serial, S/N, etc.)
        if (!others.contains(withoutPrefix)) {
          others.add(withoutPrefix);
        }
      }
    }

    // Assign IMEIs in natural sequence if not explicitly marked
    if (imei1 == null && imeis.isNotEmpty) {
      imei1 = imeis[0];
    }
    if (imei2 == null && imeis.length > 1) {
      imei2 = imeis[1];
    }

    // Assign Serial Number only if explicitly marked or alphanumeric non-IMEI
    for (final o in others) {
      if (serial == null && o.length >= 6 && o.length <= 25) {
        serial = o;
        break;
      }
    }

    return ScannedBoxResult(
      imei1: imei1,
      imei2: imei2,
      serialNumber: serial,
      allCodes: rawCodes,
    );
  }

  void _finishSingle(String value, {bool forceImei = false}) {
    if (_isFinished || !mounted) return;
    setState(() => _isFinished = true);
    try {
      _controller.stop();
    } catch (_) {}
    HapticFeedback.heavyImpact();

    final trimmed = value.trim();
    final isImei = forceImei || ScannedBoxResult.isValidImei(trimmed);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(
          !widget.isMultiMode
              ? trimmed
              : (isImei
                  ? ScannedBoxResult(imei1: trimmed, allCodes: [trimmed])
                  : ScannedBoxResult(serialNumber: trimmed, allCodes: [trimmed])),
        );
      }
    });
  }

  void _finishMulti() {
    if (_isFinished || !mounted) return;
    setState(() => _isFinished = true);
    try {
      _controller.stop();
    } catch (_) {}
    HapticFeedback.heavyImpact();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(_parsedResult);
      }
    });
  }

  void _setZoom(double zoom) {
    setState(() {
      _currentZoom = zoom.clamp(0.0, 1.0);
    });
    try {
      _controller.setZoomScale(_currentZoom);
    } catch (_) {}
  }

  void _clearDetections() {
    setState(() {
      _detectedRawCodes.clear();
      _parsedResult = const ScannedBoxResult();
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;

    // Viewfinder dimensions: broad slot to comfortably encompass the entire box sticker
    final double scanWidth = size.width * 0.88;
    final double scanHeight = size.height * 0.22;

    final Offset scanCenter = Offset(size.width / 2, size.height * 0.32);
    final Rect scanRect = Rect.fromCenter(
      center: scanCenter,
      width: scanWidth,
      height: scanHeight,
    );

    final hasDetections = _detectedRawCodes.isNotEmpty;

    return PopScope(
      canPop: !_isFinished,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _isFinished = true;
          try {
            _controller.stop();
          } catch (_) {}
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (_isFinished || !mounted) return;
              setState(() => _isFinished = true);
              try {
                _controller.stop();
              } catch (_) {}
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              });
            },
          ),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Auto-Scan Mobile Box',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '1 scan captures IMEI 1, IMEI 2 & Serial together',
                style: TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
          actions: [
            if (hasDetections)
              TextButton.icon(
                onPressed: _clearDetections,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 16),
                label: const Text('Rescan', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            // Torch toggle
            ValueListenableBuilder<MobileScannerState>(
              valueListenable: _controller,
              builder: (context, state, _) {
                final isTorchOn = state.torchState == TorchState.on;
                return IconButton(
                  icon: Icon(
                    isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: isTorchOn ? Colors.amberAccent : Colors.white70,
                  ),
                  tooltip: isTorchOn ? 'Turn Off Flashlight' : 'Turn On Flashlight',
                  onPressed: () => _controller.toggleTorch(),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white70),
              tooltip: 'Switch Camera',
              onPressed: () => _controller.switchCamera(),
            ),
          ],
        ),
        body: Stack(
          children: [
            // 1. Live Camera Feed with Pinch-to-Zoom
            GestureDetector(
              onScaleStart: (_) => _baseZoom = _currentZoom,
              onScaleUpdate: (details) {
                final newZoom = (_baseZoom * details.scale).clamp(0.0, 1.0);
                _setZoom(newZoom);
              },
              child: MobileScanner(
                controller: _controller,
                onDetect: _onDetect,
              ),
            ),

            // 2. Dark Overlay with Cutout Window
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.60),
                BlendMode.srcOut,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    left: scanRect.left,
                    top: scanRect.top,
                    width: scanRect.width,
                    height: scanRect.height,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. Precision Box Reticle & Animated Laser
            Positioned(
              left: scanRect.left,
              top: scanRect.top,
              width: scanRect.width,
              height: scanRect.height,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hasDetections ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                        width: 2.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (hasDetections ? const Color(0xFF10B981) : const Color(0xFF6366F1)).withOpacity(0.25),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  CustomPaint(
                    size: Size(scanRect.width, scanRect.height),
                    painter: _ReticleCornerPainter(
                      color: hasDetections ? const Color(0xFF10B981) : Colors.white,
                      length: 18,
                      thickness: 3.5,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _laserAnimation,
                    builder: (context, _) {
                      final laserY = scanRect.height * _laserAnimation.value;
                      return Positioned(
                        top: laserY,
                        left: 6,
                        right: 6,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: hasDetections ? const Color(0xFF10B981) : const Color(0xFF818CF8),
                            boxShadow: [
                              BoxShadow(
                                color: (hasDetections ? const Color(0xFF10B981) : const Color(0xFF818CF8)).withOpacity(0.8),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    top: 8,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        hasDetections ? '✓ ${_detectedRawCodes.length} barcode(s) captured' : 'Align box sticker here',
                        style: TextStyle(
                          color: hasDetections ? const Color(0xFF10B981) : Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. Quick Zoom Bar
            Positioned(
              top: scanRect.bottom + 12,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.zoom_in_rounded, color: Colors.white70, size: 16),
                      const SizedBox(width: 6),
                      _buildZoomChip('1x', 0.0),
                      const SizedBox(width: 4),
                      _buildZoomChip('1.5x', 0.15),
                      const SizedBox(width: 4),
                      _buildZoomChip('2x', 0.30),
                      const SizedBox(width: 4),
                      _buildZoomChip('3x', 0.55),
                    ],
                  ),
                ),
              ),
            ),

            // 5. Bottom Multi-Barcode Management Sheet
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildBottomPanel(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomPanel() {
    if (!widget.isMultiMode) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          border: Border.all(color: Colors.white12),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, -4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.flash_on_rounded, color: Color(0xFF10B981), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '⚡ Fast 1-Tap Auto Scan',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.instruction,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final hasCodes = _detectedRawCodes.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withOpacity(0.96),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Instructions
          Row(
            children: [
              Icon(
                hasCodes ? Icons.checklist_rounded : Icons.crop_free_rounded,
                color: hasCodes ? const Color(0xFF10B981) : Colors.amberAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _parsedResult.hasBothImeis
                      ? '✓ Both IMEIs Detected from Box!'
                      : (hasCodes
                          ? 'Box Barcodes Detected (${_detectedRawCodes.length})'
                          : widget.instruction),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (hasCodes)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Text(
                    _parsedResult.hasBothImeis ? 'IMEI 1 & 2 Ready' : '1-Scan Auto Fill',
                    style: const TextStyle(color: Color(0xFF10B981), fontSize: 10.5, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          if (!hasCodes) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Colors.white60, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Hold camera at box sticker. All IMEIs and Serial numbers will be captured together in 1 scan.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Structured cards with strict validation badges
            if (_parsedResult.imei1 != null)
              _buildCodeTile(
                type: 'IMEI 1',
                value: _parsedResult.imei1!,
                badgeColor: const Color(0xFF10B981),
                icon: Icons.sim_card_rounded,
                isImei: true,
              ),
            if (_parsedResult.imei2 != null)
              _buildCodeTile(
                type: 'IMEI 2',
                value: _parsedResult.imei2!,
                badgeColor: const Color(0xFF0EA5E9),
                icon: Icons.sim_card_rounded,
                isImei: true,
              ),
            if (_parsedResult.serialNumber != null &&
                _parsedResult.serialNumber != _parsedResult.imei1 &&
                _parsedResult.serialNumber != _parsedResult.imei2)
              _buildCodeTile(
                type: 'Serial #',
                value: _parsedResult.serialNumber!,
                badgeColor: const Color(0xFF8B5CF6),
                icon: Icons.numbers_rounded,
                isImei: false,
              ),

            // Big 1-tap "Apply All to Form" button
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                ),
                icon: const Icon(Icons.flash_on_rounded, size: 20),
                label: Text(
                  _parsedResult.hasBothImeis
                      ? '⚡ Fill Both IMEIs & Serial in Form'
                      : (_parsedResult.hasAnyImei
                          ? '✓ Fill Form with Scanned IMEIs'
                          : '✓ Use Scanned Barcodes'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: _isFinished ? null : _finishMulti,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCodeTile({
    required String type,
    required String value,
    required Color badgeColor,
    required IconData icon,
    required bool isImei,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: badgeColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 13, color: badgeColor),
                const SizedBox(width: 4),
                Text(
                  type,
                  style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                letterSpacing: 0.8,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: badgeColor,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _isFinished ? null : () => _finishSingle(value, forceImei: isImei),
            child: const Text('Use This', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomChip(String label, double zoomValue) {
    final isSelected = (_currentZoom - zoomValue).abs() < 0.08;
    return GestureDetector(
      onTap: () => _setZoom(zoomValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.white12,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ReticleCornerPainter extends CustomPainter {
  final Color color;
  final double length;
  final double thickness;

  _ReticleCornerPainter({
    required this.color,
    required this.length,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-Left
    canvas.drawLine(const Offset(0, 0), Offset(length, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, length), paint);

    // Top-Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - length, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, length), paint);

    // Bottom-Left
    canvas.drawLine(Offset(0, size.height), Offset(length, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - length), paint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - length, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - length, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
