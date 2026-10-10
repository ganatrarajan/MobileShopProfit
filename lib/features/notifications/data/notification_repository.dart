import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../domain/notification_model.dart';

class NotificationRepository {
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>> fetchNotifications({int page = 1}) async {
    final response = await _apiClient.get<Map<String, dynamic>>('${ApiEndpoints.notifications}?page=$page');
    final rawJson = response.rawJson ?? {};
    final resData = response.data;
    final List<AppNotification> notifications = [];

    dynamic itemsList;
    if (resData != null) {
      if (resData is List) {
        itemsList = resData;
      } else if (resData is Map) {
        if (resData['data'] is List) {
          itemsList = resData['data'];
        } else if (resData['notifications'] is List) {
          itemsList = resData['notifications'];
        }
      }
    }

    if (itemsList is List) {
      for (var item in itemsList) {
        if (item is Map<String, dynamic>) {
          notifications.add(AppNotification.fromJson(item));
        }
      }
    }

    int unreadCount = 0;
    if (rawJson['unread_count'] is int) {
      unreadCount = rawJson['unread_count'] as int;
    } else if (resData is Map<String, dynamic> && resData['unread_count'] is int) {
      unreadCount = resData['unread_count'] as int;
    }

    return {
      'notifications': notifications,
      'unreadCount': unreadCount,
    };
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      final res = await _apiClient.post<Map<String, dynamic>>('${ApiEndpoints.notifications}/$notificationId/read');
      return res.success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final res = await _apiClient.post<Map<String, dynamic>>('${ApiEndpoints.notifications}/read-all');
      return res.success;
    } catch (_) {
      return false;
    }
  }

  Future<void> sendFcmToken(String fcmToken) async {
    try {
      await _apiClient.post(ApiEndpoints.fcmToken, body: {'fcm_token': fcmToken});
    } catch (_) {}
  }

  Future<void> pingAppOpen() async {
    try {
      await _apiClient.post('/auth/ping-open');
    } catch (_) {}
  }
}
