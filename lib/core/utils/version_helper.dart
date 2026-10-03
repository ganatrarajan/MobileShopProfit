class VersionHelper {
  /// Compares two semver strings (e.g. '1.0.4' vs '1.0.5').
  /// Returns true if [currentVersion] is less than [requiredVersion].
  static bool isVersionLower(String currentVersion, String requiredVersion) {
    if (currentVersion.isEmpty || requiredVersion.isEmpty) return false;
    try {
      final currentClean = currentVersion.split('+').first.trim();
      final requiredClean = requiredVersion.split('+').first.trim();

      final currentParts = currentClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final requiredParts = requiredClean.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final maxLength = currentParts.length > requiredParts.length
          ? currentParts.length
          : requiredParts.length;

      for (int i = 0; i < maxLength; i++) {
        final curr = i < currentParts.length ? currentParts[i] : 0;
        final req = i < requiredParts.length ? requiredParts[i] : 0;

        if (curr < req) return true;
        if (curr > req) return false;
      }

      return false;
    } catch (_) {
      return false;
    }
  }
}
