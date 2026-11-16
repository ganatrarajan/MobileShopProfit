import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/storage/auth_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../auth/data/auth_repository.dart';
import 'shop_profile_screen.dart';

class CardThemeConfig {
  final String name;
  final String emoji;
  final List<Color> gradientColors;
  final Color borderColor;
  final Color primaryGlow;
  final Color secondaryGlow;
  final Color accentTextColor;
  final Color phoneColor;

  const CardThemeConfig({
    required this.name,
    required this.emoji,
    required this.gradientColors,
    required this.borderColor,
    required this.primaryGlow,
    required this.secondaryGlow,
    required this.accentTextColor,
    required this.phoneColor,
  });
}

const List<CardThemeConfig> kCardThemes = [
  CardThemeConfig(
    name: 'Midnight Slate',
    emoji: '🖤',
    gradientColors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF1E293B)],
    borderColor: Color(0xFF38BDF8),
    primaryGlow: Color(0xFF6366F1),
    secondaryGlow: Color(0xFF06B6D4),
    accentTextColor: Color(0xFFA5F3FC),
    phoneColor: Color(0xFF4ADE80),
  ),
  CardThemeConfig(
    name: 'Royal Emerald',
    emoji: '💚',
    gradientColors: [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF022C22)],
    borderColor: Color(0xFF34D399),
    primaryGlow: Color(0xFF10B981),
    secondaryGlow: Color(0xFFFBBF24),
    accentTextColor: Color(0xFFFDE68A),
    phoneColor: Color(0xFFFBBF24),
  ),
  CardThemeConfig(
    name: 'Luxury Violet',
    emoji: '💜',
    gradientColors: [Color(0xFF2E1065), Color(0xFF4C1D95), Color(0xFF1E1B4B)],
    borderColor: Color(0xFFA78BFA),
    primaryGlow: Color(0xFFC084FC),
    secondaryGlow: Color(0xFFF43F5E),
    accentTextColor: Color(0xFFFBCFE8),
    phoneColor: Color(0xFF38BDF8),
  ),
  CardThemeConfig(
    name: 'Crimson Ruby',
    emoji: '❤️',
    gradientColors: [Color(0xFF4C0519), Color(0xFF881337), Color(0xFF1C1917)],
    borderColor: Color(0xFFFB7185),
    primaryGlow: Color(0xFFF43F5E),
    secondaryGlow: Color(0xFFF59E0B),
    accentTextColor: Color(0xFFFED7AA),
    phoneColor: Color(0xFF4ADE80),
  ),
  CardThemeConfig(
    name: 'Titanium Classic',
    emoji: '⚙️',
    gradientColors: [Color(0xFF18181B), Color(0xFF27272A), Color(0xFF09090B)],
    borderColor: Color(0xFFE4E4E7),
    primaryGlow: Color(0xFF94A3B8),
    secondaryGlow: Color(0xFF38BDF8),
    accentTextColor: Color(0xFFE2E8F0),
    phoneColor: Color(0xFF34D399),
  ),
];

class DigitalVisitingCardScreen extends StatefulWidget {
  const DigitalVisitingCardScreen({super.key});

  @override
  State<DigitalVisitingCardScreen> createState() => _DigitalVisitingCardScreenState();
}

class _DigitalVisitingCardScreenState extends State<DigitalVisitingCardScreen> {
  final GlobalKey _cardKey = GlobalKey();
  final AuthRepository _authRepository = AuthRepository();

  bool _isLoading = true;
  bool _isExporting = false;
  bool _isDetectingGps = false;
  bool _isSharingWhatsApp = false;
  Map<String, dynamic> _shop = {};
  int _selectedQrMode = 0; // 0: Google Maps Location, 1: UPI Payment
  int _selectedThemeIndex = 0; // 0 to 4

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
    _loadShopData();
  }

  Future<void> _loadSavedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getInt('visiting_card_selected_theme_index');
      final savedQr = prefs.getInt('visiting_card_selected_qr_mode');
      if (mounted) {
        setState(() {
          if (savedTheme != null && savedTheme >= 0 && savedTheme < kCardThemes.length) {
            _selectedThemeIndex = savedTheme;
          }
          if (savedQr != null && (savedQr == 0 || savedQr == 1)) {
            _selectedQrMode = savedQr;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _onThemeSelected(int idx) async {
    setState(() => _selectedThemeIndex = idx);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('visiting_card_selected_theme_index', idx);
    } catch (_) {}
  }

  Future<void> _onQrModeSelected(int mode) async {
    setState(() => _selectedQrMode = mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('visiting_card_selected_qr_mode', mode);
    } catch (_) {}
  }

  Future<void> _loadShopData() async {
    setState(() => _isLoading = true);
    try {
      final localShop = await AuthStorage().getShop();
      if (localShop != null) {
        setState(() => _shop = Map<String, dynamic>.from(localShop));
      }
      final response = await _authRepository.fetchShop();
      if (response.success && response.data != null) {
        final serverShop = response.data as Map<String, dynamic>;
        setState(() {
          _shop = Map<String, dynamic>.from(serverShop);
          if (localShop != null && (_shop['logo_url'] == null || _shop['logo_url'].toString().isEmpty)) {
            _shop['logo_url'] = localShop['logo_path'] ?? localShop['logo_url'];
          }
        });
      }
    } catch (_) {
      // Local cache fallback
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _shopName => (_shop['name'] ?? 'My Mobile Shop').toString().trim();
  String get _ownerName => (_shop['owner_name'] ?? 'Shop Owner').toString().trim();
  String get _mobile => (_shop['mobile'] ?? _shop['phone'] ?? '').toString().trim();
  String get _email => (_shop['email'] ?? '').toString().trim();
  String get _address => (_shop['address'] ?? '').toString().trim();
  String get _city => (_shop['city'] ?? '').toString().trim();
  String get _state => (_shop['state'] ?? '').toString().trim();
  String get _pincode => (_shop['pincode'] ?? '').toString().trim();
  String get _gstin => (_shop['gst_number'] ?? _shop['gstin'] ?? '').toString().trim();
  String? get _logoUrl => _shop['logo_url']?.toString();
  String get _tagline {
    final t = (_shop['tagline'] ?? '').toString().trim();
    return t.isNotEmpty ? t : 'Smartphone Repair • All Brand Accessories • Buy & Sell';
  }
  String get _upiId => (_shop['upi_id'] ?? '').toString().trim();

  String get _mapsUrl {
    final explicitUrl = (_shop['google_maps_url'] ?? '').toString().trim();
    if (explicitUrl.isNotEmpty) return explicitUrl;

    final lat = _shop['latitude'];
    final lng = _shop['longitude'];
    if (lat != null && lng != null) {
      return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    }

    final query = Uri.encodeComponent('$_shopName $_address $_city $_pincode'.trim());
    return 'https://www.google.com/maps/search/?api=1&query=$query';
  }

  String get _upiPayload {
    if (_upiId.isEmpty) return '';
    final nameEncoded = Uri.encodeComponent(_shopName);
    return 'upi://pay?pa=$_upiId&pn=$nameEncoded&cu=INR';
  }

  Future<void> _detectGpsLocation() async {
    setState(() => _isDetectingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          AppFeedback.showError(
            context,
            title: 'GPS Disabled',
            message: 'Please enable Location / GPS in your phone settings.',
          );
        }
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            AppFeedback.showError(
              context,
              title: 'Permission Denied',
              message: 'Location permission is required to detect shop GPS.',
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          AppFeedback.showError(
            context,
            title: 'Permission Denied',
            message: 'Please enable Location permission in App Settings.',
          );
        }
        await Geolocator.openAppSettings();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      final lat = position.latitude;
      final lng = position.longitude;
      final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

      // Save to backend and local storage
      await _authRepository.updateShop(
        googleMapsUrl: mapsUrl,
        latitude: lat,
        longitude: lng,
      );

      final localShop = await AuthStorage().getShop() ?? {};
      localShop['google_maps_url'] = mapsUrl;
      localShop['latitude'] = lat;
      localShop['longitude'] = lng;
      await AuthStorage().saveSession(
        token: (await AuthStorage().getToken()) ?? '',
        user: (await AuthStorage().getUser()) ?? {},
        shop: localShop,
      );

      setState(() {
        _shop['google_maps_url'] = mapsUrl;
        _shop['latitude'] = lat;
        _shop['longitude'] = lng;
      });

      if (mounted) {
        AppFeedback.showSuccess(
          context,
          title: 'Shop Location Locked! 📍',
          message: 'Exact GPS coordinates saved! Customers scanning this card will navigate straight to your shop.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          title: 'GPS Detection Failed',
          error: e.toString(),
        );
      }
    } finally {
      if (mounted) setState(() => _isDetectingGps = false);
    }
  }

  /// High-resolution image capture of the digital visiting card
  Future<File?> _captureCardImage() async {
    try {
      final boundary = _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final sanitizedName = _shopName.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final fileName = 'visiting_card_${sanitizedName}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);
      return file;
    } catch (_) {
      return null;
    }
  }

  Future<void> _shareOnWhatsApp() async {
    if (_isSharingWhatsApp) return;
    setState(() => _isSharingWhatsApp = true);

    try {
      // 1. Capture the HD visiting card image
      final cardFile = await _captureCardImage();

      // 2. Build complete shop details & location text
      final buffer = StringBuffer();
      buffer.writeln('🌟 *Welcome to $_shopName!* 📱');
      if (_tagline.isNotEmpty) {
        buffer.writeln('_${_tagline}_');
      }
      buffer.writeln('');
      buffer.writeln('📍 *Shop Address:*');
      if (_address.isNotEmpty) buffer.writeln(_address);
      final locationParts = [_city, _state, _pincode].where((s) => s.isNotEmpty).join(', ');
      if (locationParts.isNotEmpty) buffer.writeln(locationParts);
      buffer.writeln('');
      buffer.writeln('🗺️ *Google Maps Navigation / Location:*');
      buffer.writeln(_mapsUrl);
      buffer.writeln('');
      if (_mobile.isNotEmpty) {
        buffer.writeln('📞 *Contact / WhatsApp:* +91 $_mobile');
      }
      if (_upiId.isNotEmpty) {
        buffer.writeln('💳 *UPI ID for Payments:* $_upiId');
      }
      buffer.writeln('');
      buffer.writeln('💬 _Need mobile repair, original accessories, or used phone? Visit or message us anytime!_');

      final text = buffer.toString();

      // 3. Share with attached Card Image + Message Text
      if (cardFile != null) {
        await Share.shareXFiles(
          [XFile(cardFile.path, mimeType: 'image/png')],
          text: text,
          subject: '$_shopName - Visiting Card & Location',
        );
      } else {
        await Share.share(text, subject: '$_shopName - Shop Location & Contact');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          title: 'Share Failed',
          message: 'Could not share visiting card: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isSharingWhatsApp = false);
    }
  }

  Future<void> _openMaps() async {
    final uri = Uri.parse(_mapsUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          AppFeedback.showError(context, title: 'Could Not Open Maps', message: 'Unable to open Google Maps link.');
        }
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, title: 'Maps Error', error: e.toString());
      }
    }
  }

  Future<void> _makePhoneCall() async {
    if (_mobile.isEmpty) return;
    final uri = Uri.parse('tel:$_mobile');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _exportAndShareImage() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final cardFile = await _captureCardImage();
      if (cardFile == null) {
        throw Exception('Could not capture visiting card image');
      }

      await Share.shareXFiles(
        [XFile(cardFile.path, mimeType: 'image/png')],
        text: '📍 $_shopName - Visiting Card & Location\nDirections: $_mapsUrl',
        subject: '$_shopName Digital Visiting Card',
      );
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(
          context,
          title: 'Share Failed',
          message: 'Could not export visiting card image: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Visiting Card'),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Auto-Detect Shop GPS',
            icon: _isDetectingGps
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.my_location_rounded),
            onPressed: _isDetectingGps ? null : _detectGpsLocation,
          ),
          IconButton(
            tooltip: 'Edit Shop Details',
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ShopProfileScreen()),
              );
              _loadShopData();
            },
          ),
          IconButton(
            tooltip: 'Share Card Image',
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.share_rounded),
            onPressed: _exportAndShareImage,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadShopData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Theme Switcher Selector (5 Card Styles)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Card Style (5 Themes)',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        ),
                        Text(
                          kCardThemes[_selectedThemeIndex].name,
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 38,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: kCardThemes.length,
                        itemBuilder: (context, idx) {
                          final theme = kCardThemes[idx];
                          final isSelected = _selectedThemeIndex == idx;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: InkWell(
                              onTap: () => _onThemeSelected(idx),
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? theme.gradientColors.first : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? theme.borderColor : (isDark ? AppColors.darkBorder : AppColors.border),
                                    width: isSelected ? 1.8 : 1.0,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: theme.borderColor.withOpacity(0.35),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  children: [
                                    Text(theme.emoji, style: const TextStyle(fontSize: 13)),
                                    const SizedBox(width: 5),
                                    Text(
                                      theme.name,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isSelected ? Colors.white : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // QR Switcher Tabs (Location vs UPI)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildQrTab(
                              index: 0,
                              label: '📍 Location QR (Maps)',
                              icon: Icons.location_on_rounded,
                              isSelected: _selectedQrMode == 0,
                            ),
                          ),
                          Expanded(
                            child: _buildQrTab(
                              index: 1,
                              label: '💳 UPI Pay QR',
                              icon: Icons.account_balance_wallet_rounded,
                              isSelected: _selectedQrMode == 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // The RepaintBoundary Visiting Card (Exportable to Image)
                    Center(
                      child: RepaintBoundary(
                        key: _cardKey,
                        child: _buildVisitingCardWidget(context),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Actions Row (4-5 Action Options)
                    Text(
                      'Quick Actions & Sharing',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),

                    // 1. WhatsApp Button (Primary full width with attached Card Image)
                    ElevatedButton.icon(
                      onPressed: _isSharingWhatsApp ? null : _shareOnWhatsApp,
                      icon: _isSharingWhatsApp
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.chat_rounded, color: Colors.white, size: 20),
                      label: Text(
                        _isSharingWhatsApp ? 'Preparing Card & Location...' : 'Share Location & Card on WhatsApp',
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 2. Action Grid / Pills (Auto-Detect GPS, Open Maps, Save Image, Call)
                    Row(
                      children: [
                        // Auto-Detect GPS (1-Tap)
                        Expanded(
                          child: InkWell(
                            onTap: _isDetectingGps ? null : _detectGpsLocation,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _isDetectingGps
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF059669)),
                                        )
                                      : const Icon(Icons.my_location_rounded, size: 20, color: Color(0xFF059669)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isDetectingGps ? 'Locking...' : '📍 GPS Lock',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF047857)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Open in Maps
                        Expanded(
                          child: InkWell(
                            onTap: _openMaps,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F46E5).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.35)),
                              ),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.map_rounded, size: 20, color: Color(0xFF4F46E5)),
                                  SizedBox(height: 4),
                                  Text(
                                    '🗺️ Test Map',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Save / Share Image
                        Expanded(
                          child: InkWell(
                            onTap: _exportAndShareImage,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF0284C7).withOpacity(0.35)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _isExporting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0284C7)),
                                        )
                                      : const Icon(Icons.download_rounded, size: 20, color: Color(0xFF0284C7)),
                                  const SizedBox(height: 4),
                                  const Text(
                                    '📸 HD Image',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0369A1)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Row: Call Owner & Edit Shop Details
                    Row(
                      children: [
                        if (_mobile.isNotEmpty) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _makePhoneCall,
                              icon: const Icon(Icons.call_rounded, size: 16, color: Color(0xFF10B981)),
                              label: const Text('Call Shop', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)), overflow: TextOverflow.ellipsis),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF10B981)),
                                padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ShopProfileScreen()),
                              );
                              _loadShopData();
                            },
                            icon: const Icon(Icons.edit_note_rounded, size: 17, color: AppColors.textSecondary),
                            label: const Text('Edit Card', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.border),
                              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Information Details Card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text(
                                'Card Information Summary',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          _buildInfoRow(
                            label: 'Google Maps Link',
                            value: _mapsUrl,
                            isLink: true,
                            onTap: _openMaps,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            label: 'Shop Address',
                            value: '$_address, $_city, $_state - $_pincode'.trim(),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            label: 'UPI ID for Payment',
                            value: _upiId.isNotEmpty ? _upiId : 'Not configured (Tap Edit Card Details to add)',
                            isWarning: _upiId.isEmpty,
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            label: 'Owner Contact',
                            value: '$_ownerName • +91 $_mobile',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildQrTab({
    required int index,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => _onQrModeSelected(index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? const Color(0xFF4F46E5) : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF4F46E5) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitingCardWidget(BuildContext context) {
    final theme = kCardThemes[_selectedThemeIndex];
    final qrData = _selectedQrMode == 0 ? _mapsUrl : (_upiPayload.isNotEmpty ? _upiPayload : _mapsUrl);
    final qrTitle = _selectedQrMode == 0 ? 'SCAN FOR MAPS LOCATION' : 'SCAN TO PAY VIA UPI';
    final qrSubtitle = _selectedQrMode == 0 ? 'Google Maps Navigation' : (_upiId.isNotEmpty ? _upiId : 'Configure UPI in Edit Card');

    return Container(
      width: 360,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: theme.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.gradientColors.first.withOpacity(0.45),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: theme.borderColor.withOpacity(0.45), width: 1.3),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Decorative background glowing accents
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primaryGlow.withOpacity(0.20),
                ),
              ),
            ),
            Positioned(
              left: -40,
              bottom: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.secondaryGlow.withOpacity(0.18),
                ),
              ),
            ),

            // Card Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Row: Shop Logo/Badge + Shop Name + Category
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: theme.borderColor, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _logoUrl != null && _logoUrl!.isNotEmpty
                              ? (_logoUrl!.startsWith('http')
                                  ? Image.network(
                                      _logoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, color: Color(0xFF0F172A), size: 28),
                                    )
                                  : Image.file(
                                      File(_logoUrl!),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, color: Color(0xFF0F172A), size: 28),
                                    ))
                              : const Icon(Icons.storefront_rounded, color: Color(0xFF0F172A), size: 28),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _shopName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _tagline,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: theme.accentTextColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Divider with theme gradient glow
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          theme.borderColor.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Middle Row: QR Code Box + Quick Contact Details
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // QR Code Container
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 108,
                              gapless: false,
                              backgroundColor: Colors.white,
                              errorStateBuilder: (c, err) => const SizedBox(
                                width: 108,
                                height: 108,
                                child: Center(child: Text('QR Error', style: TextStyle(fontSize: 10))),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedQrMode == 0 ? 'SCAN MAPS' : 'SCAN TO PAY',
                              style: const TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Contact Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_ownerName.isNotEmpty) ...[
                              Row(
                                children: [
                                  Icon(Icons.person_rounded, size: 14, color: theme.borderColor),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _ownerName,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                            ],
                            if (_mobile.isNotEmpty) ...[
                              Row(
                                children: [
                                  Icon(Icons.phone_rounded, size: 14, color: theme.phoneColor),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '+91 $_mobile',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFF1F5F9),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                            ],
                            if (_email.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(Icons.email_outlined, size: 13, color: Color(0xFFA78BFA)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _email,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: Color(0xFFCBD5E1),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                            ],
                            if (_gstin.isNotEmpty) ...[
                              Row(
                                children: [
                                  const Icon(Icons.verified_outlined, size: 13, color: Color(0xFFFACC15)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'GST: $_gstin',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFFDE047),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                            ],
                            // QR mode label in card
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white.withOpacity(0.12)),
                              ),
                              child: Text(
                                '$qrTitle\n$qrSubtitle',
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Color(0xFFE2E8F0),
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Bottom Bar: Address & Google Maps Navigation link
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on_rounded, size: 15, color: Color(0xFFF87171)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '$_address, $_city, $_state - $_pincode'.trim(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFE2E8F0),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    bool isLink = false,
    bool isWarning = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        InkWell(
          onTap: onTap,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isLink
                  ? const Color(0xFF4F46E5)
                  : (isWarning ? Colors.orange.shade800 : AppColors.textPrimary),
              decoration: isLink ? TextDecoration.underline : null,
            ),
          ),
        ),
      ],
    );
  }
}
