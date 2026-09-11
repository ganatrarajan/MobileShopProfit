import '../network/api_exception.dart';

class AppErrorMapper {
  /// Alias for toUserFriendlyMessage
  static String mapMessage(dynamic error, {String fallback = 'Something went wrong. Please try again.'}) {
    return toUserFriendlyMessage(error, fallback: fallback);
  }

  /// Converts any exception into a clean, shop-owner-friendly error string.
  static String toUserFriendlyMessage(dynamic error, {String fallback = 'Something went wrong. Please try again.'}) {
    if (error == null) return fallback;

    if (error is ApiException) {
      final msg = error.message.toLowerCase();

      // Check validation error map if present
      if (error.errors != null && error.errors is Map) {
        final Map<String, dynamic> errMap = error.errors;
        if (errMap.isNotEmpty) {
          final firstKey = errMap.keys.first;
          final val = errMap[firstKey];
          if (val is List && val.isNotEmpty) {
            return _cleanTechnicalTerms(val.first.toString());
          } else if (val is String) {
            return _cleanTechnicalTerms(val);
          }
        }
      }

      if (msg.contains('sqlstate') || msg.contains('database') || msg.contains('foreign key') || msg.contains('integrity constraint')) {
        return 'Unable to save data due to a conflict or missing reference. Please check your details and try again.';
      }
      if (msg.contains('failed to connect') || msg.contains('socketexception') || msg.contains('network') || msg.contains('timeout')) {
        return 'Network connection issue. Please check your connection and try again.';
      }
      if (msg.contains('unauthorized') || msg.contains('unauthenticated') || error.statusCode == 401) {
        return 'Session expired. Please log in again.';
      }
      if (msg.contains('forbidden') || error.statusCode == 403) {
        return 'You do not have permission to perform this action.';
      }
      if (error.statusCode == 404 || msg.contains('not found')) {
        return 'The requested record was not found or may have been deleted.';
      }

      return _cleanTechnicalTerms(error.message);
    }

    final str = error.toString().toLowerCase();

    if (str.contains('socketexception') || str.contains('connection refused') || str.contains('handshakeexception')) {
      return 'Could not reach local server. Please ensure server is running and device is connected.';
    }
    if (str.contains('sqlstate') || str.contains('syntax error')) {
      return 'Unable to save details. Please check form entries and try again.';
    }

    return _cleanTechnicalTerms(error.toString().replaceAll('Exception:', '').trim());
  }

  static String _cleanTechnicalTerms(String input) {
    if (input.isEmpty) return 'An unexpected error occurred.';
    String result = input;
    
    // Replace DB technical field names
    result = result.replaceAll('_id is required', ' selection is required');
    result = result.replaceAll('customer_id', 'Customer');
    result = result.replaceAll('device_id', 'Device');
    result = result.replaceAll('technician_id', 'Technician');
    result = result.replaceAll('item_id', 'Item');

    // Remove technical code prefixes
    if (result.startsWith('Exception: ')) {
      result = result.substring(11);
    }

    return result;
  }
}
