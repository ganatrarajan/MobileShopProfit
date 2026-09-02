import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_card.dart';

class DynamicPageScreen extends StatefulWidget {
  final String slug;
  final String defaultTitle;

  const DynamicPageScreen({
    super.key,
    required this.slug,
    required this.defaultTitle,
  });

  @override
  State<DynamicPageScreen> createState() => _DynamicPageScreenState();
}

class _DynamicPageScreenState extends State<DynamicPageScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  String? _errorMessage;
  String? _title;
  String? _content;
  String? _updatedAt;

  @override
  void initState() {
    super.initState();
    _fetchPageContent();
  }

  Future<void> _fetchPageContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.get<Map<String, dynamic>>('/public/pages/${widget.slug}');
      if (response.success && response.data != null) {
        final data = response.data!;
        setState(() {
          _title = data['title'] ?? widget.defaultTitle;
          _content = data['content'] ?? 'No content available.';
          _updatedAt = data['updated_at'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message.isNotEmpty ? response.message : 'Failed to load content.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network connection error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _cleanHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<h[1-6]>'), '\n\n')
        .replaceAll(RegExp(r'</h[1-6]>'), '\n')
        .replaceAll(RegExp(r'<p>'), '\n')
        .replaceAll(RegExp(r'</p>'), '\n')
        .replaceAll(RegExp(r'<li>'), '\n• ')
        .replaceAll(RegExp(r'</li>'), '')
        .replaceAll(RegExp(r'<ul[^>]*>'), '')
        .replaceAll(RegExp(r'</ul>'), '\n')
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title ?? widget.defaultTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchPageContent,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchPageContent,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_outlined, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              _updatedAt != null ? 'Official Policy • Updated ${_updatedAt!.substring(0, 10)}' : 'Official Policy • Dynamic Cloud Content',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Content Card
                      CustomCard(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          _cleanHtmlTags(_content ?? ''),
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Footer
                      const Center(
                        child: Text(
                          'Mobile Profits SaaS Legal & Policy Engine',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
