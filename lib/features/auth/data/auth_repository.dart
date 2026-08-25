import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/storage/auth_storage.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient();
  final AuthStorage _authStorage = AuthStorage();

  Future<ApiResponse<dynamic>> registerOwner({
    required String name,
    required String mobile,
    required String shopName,
    required String password,
    required String passwordConfirmation,
    String? email,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.register,
      body: {
        'name': name,
        'mobile': mobile,
        'email': email,
        'shop_name': shopName,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      Map<String, dynamic>? dataMap;
      if (rawData is Map<String, dynamic>) {
        dataMap = rawData.containsKey('data') && rawData['data'] is Map<String, dynamic>
            ? rawData['data']
            : rawData;
      }

      if (dataMap != null) {
        final token = dataMap['token'];
        final user = dataMap['user'];
        final dynamic shopRaw = dataMap['shop'] ?? (user is Map ? user['shop'] : null);
        final Map<String, dynamic> shop = (shopRaw is Map)
            ? Map<String, dynamic>.from(shopRaw)
            : ((user is Map && (user['shop_id'] != null || user['shop'] != null))
                ? {'id': user['shop_id'] ?? user['shop']?['id'], 'name': user['shop']?['name'] ?? 'My Shop'}
                : {});

        if (token != null && user != null) {
          await _authStorage.saveSession(
            token: token.toString(),
            user: Map<String, dynamic>.from(user),
            shop: shop,
          );
        }
      }
    }

    return response;
  }

  Future<ApiResponse<dynamic>> login({
    required String login,
    required String password,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.login,
      body: {
        'login': login,
        'password': password,
      },
    );

    if (response.success && response.data != null) {
      final dynamic rawData = response.data;
      Map<String, dynamic>? dataMap;
      if (rawData is Map<String, dynamic>) {
        dataMap = rawData.containsKey('data') && rawData['data'] is Map<String, dynamic>
            ? rawData['data']
            : rawData;
      }

      if (dataMap != null) {
        final token = dataMap['token'];
        final user = dataMap['user'];
        final dynamic shopRaw = dataMap['shop'] ?? (user is Map ? user['shop'] : null);
        final Map<String, dynamic> shop = (shopRaw is Map)
            ? Map<String, dynamic>.from(shopRaw)
            : ((user is Map && (user['shop_id'] != null || user['shop'] != null))
                ? {'id': user['shop_id'] ?? user['shop']?['id'], 'name': user['shop']?['name'] ?? 'My Shop'}
                : {});

        if (token != null && user != null) {
          await _authStorage.saveSession(
            token: token.toString(),
            user: Map<String, dynamic>.from(user),
            shop: shop,
          );
        }
      }
    }

    return response;
  }

  Future<ApiResponse<dynamic>> fetchShop() async {
    final response = await _apiClient.get(ApiEndpoints.shop);
    if (response.success && response.data != null) {
      final user = await _authStorage.getUser();
      final token = await _authStorage.getToken();
      if (user != null && token != null) {
        await _authStorage.saveSession(
          token: token,
          user: user,
          shop: response.data,
        );
      }
    }
    return response;
  }

  Future<ApiResponse<dynamic>> createShop({
    required String name,
    required String ownerName,
    required String mobile,
    required String address,
    required String city,
    required String state,
    required String pincode,
    String? phone,
    String? email,
    String? gstNumber,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.shop,
      body: {
        'name': name,
        'owner_name': ownerName,
        'mobile': mobile,
        'phone': phone ?? mobile,
        'email': email,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'gst_number': gstNumber,
      },
    );

    if (response.success && response.data != null) {
      final user = await _authStorage.getUser();
      final token = await _authStorage.getToken();
      if (user != null && token != null) {
        await _authStorage.saveSession(
          token: token,
          user: user,
          shop: response.data,
        );
      }
    }

    return response;
  }

  Future<ApiResponse<dynamic>> updateShop({
    required String name,
    required String ownerName,
    required String mobile,
    required String address,
    required String city,
    required String state,
    required String pincode,
    String? phone,
    String? email,
    String? gstNumber,
  }) async {
    final response = await _apiClient.put(
      ApiEndpoints.shop,
      body: {
        'name': name,
        'owner_name': ownerName,
        'mobile': mobile,
        'phone': phone ?? mobile,
        'email': email,
        'address': address,
        'city': city,
        'state': state,
        'pincode': pincode,
        'gst_number': gstNumber,
      },
    );

    if (response.success && response.data != null) {
      final user = await _authStorage.getUser();
      final token = await _authStorage.getToken();
      if (user != null && token != null) {
        await _authStorage.saveSession(
          token: token,
          user: user,
          shop: response.data,
        );
      }
    }

    return response;
  }

  Future<ApiResponse<dynamic>> uploadShopLogo(String filePath) async {
    final response = await _apiClient.postMultipart(
      ApiEndpoints.shopLogo,
      filePath: filePath,
      fileFieldName: 'logo',
    );

    if (response.success && response.data != null) {
      final user = await _authStorage.getUser();
      final token = await _authStorage.getToken();
      if (user != null && token != null) {
        await _authStorage.saveSession(
          token: token,
          user: user,
          shop: response.data,
        );
      }
    }

    return response;
  }

  Future<ApiResponse<dynamic>> requestPasswordReset({required String login}) async {
    return await _apiClient.post(
      ApiEndpoints.forgotPassword,
      body: {'login': login},
    );
  }

  Future<ApiResponse<dynamic>> resetPassword({
    required String login,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await _apiClient.post(
      ApiEndpoints.resetPassword,
      body: {
        'login': login,
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  Future<void> logout() async {
    try {
      await _apiClient.post(ApiEndpoints.logout);
    } catch (_) {}
    await _authStorage.clearSession();
  }
}