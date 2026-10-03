class AppVersionInfo {
  final String minVersion;
  final String latestVersion;
  final bool forceUpdate;
  final String updateUrl;
  final String updateTitle;
  final String updateMessage;

  AppVersionInfo({
    required this.minVersion,
    required this.latestVersion,
    required this.forceUpdate,
    required this.updateUrl,
    required this.updateTitle,
    required this.updateMessage,
  });

  factory AppVersionInfo.fromJson(Map<String, dynamic> json) {
    return AppVersionInfo(
      minVersion: json['min_version']?.toString() ?? '1.0.0',
      latestVersion: json['latest_version']?.toString() ?? '1.0.0',
      forceUpdate: json['force_update'] == true ||
          json['force_update'] == '1' ||
          json['force_update'] == 1,
      updateUrl: json['update_url']?.toString() ?? '',
      updateTitle: json['update_title']?.toString() ??
          'Update Required',
      updateMessage: json['update_message']?.toString() ??
          'A new version of Mobile Shop Profit is available. Please update your app to continue.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min_version': minVersion,
      'latest_version': latestVersion,
      'force_update': forceUpdate,
      'update_url': updateUrl,
      'update_title': updateTitle,
      'update_message': updateMessage,
    };
  }
}
