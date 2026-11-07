import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';

class SubscriptionRepository {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<dynamic>> getStatus() async {
    return await _apiClient.get(ApiEndpoints.subscriptionStatus);
  }

  Future<ApiResponse<dynamic>> createOrder({int? planId, bool? isUpgrade}) async {
    final Map<String, dynamic> body = {};
    if (planId != null) {
      body['plan_id'] = planId;
    }
    if (isUpgrade != null) {
      body['is_upgrade'] = isUpgrade;
    }
    return await _apiClient.post(
      ApiEndpoints.subscriptionCreateOrder,
      body: body,
    );
  }

  Future<ApiResponse<dynamic>> createStaffAddonOrder({required int staffCount}) async {
    return await _apiClient.post(
      ApiEndpoints.subscriptionCreateStaffAddonOrder,
      body: {'staff_count': staffCount},
    );
  }

  Future<ApiResponse<dynamic>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    return await _apiClient.post(
      ApiEndpoints.subscriptionVerifyPayment,
      body: {
        'razorpay_order_id': razorpayOrderId,
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_signature': razorpaySignature,
      },
    );
  }

  Future<ApiResponse<dynamic>> purchaseStaffAddon({
    required int staffCount,
    String? paymentMethod,
    String? transactionId,
  }) async {
    return await _apiClient.post(
      ApiEndpoints.subscriptionPurchaseStaffAddon,
      body: {
        'staff_count': staffCount,
        if (paymentMethod != null) 'payment_method': paymentMethod,
        if (transactionId != null) 'transaction_id': transactionId,
      },
    );
  }

  Future<ApiResponse<dynamic>> getHistory() async {
    return await _apiClient.get(ApiEndpoints.subscriptionHistory);
  }
}
