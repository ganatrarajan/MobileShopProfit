class EnvConfig {
  /// Base API URL configured for live backend server.
  static String get baseUrl => 'https://myrepairhub.noviqe.in/api/v1';
  // static String get baseUrl => 'http://192.168.1.8:8000/api/v1';

  /// Base Web Domain URL derived dynamically from API baseUrl
  static String get webBaseUrl => baseUrl.replaceAll('/api/v1', '');

  /// Public Legal & Policy Web Links
  static String get privacyPolicyWebUrl => '$webBaseUrl/privacy-policy';
  static String get termsWebUrl => '$webBaseUrl/terms-and-conditions';
  static String get deleteAccountWebUrl => '$webBaseUrl/delete-account';

  static const String appName = 'MyRepairHub';
  static const String currentAppVersion = '1.0.9';
}
