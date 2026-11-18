import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../../core/storage/auth_storage.dart';

class AuthRepository {
  Future<ApiResponse<dynamic>> sendRegisterOtp({
    required String name,
    required String mobile,
    required String shopName,
    required String password,
    required String passwordConfirmation,
    String? email,
    String? referralCode,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.sendRegisterOtp,
      body: {
        'name': name,
        'mobile': mobile,
        'email': email,
        'shop_name': shopName,
        'password': password,
        'password_confirmation': passwordConfirmation,
        if (referralCode != null && referralCode.trim().isNotEmpty)
          'referral_code': referralCode.trim(),
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
      if (dataMap != null && dataMap['otp_skipped'] == true) {
        final token = dataMap['token'];
        final user = dataMap['user'];
        final dynamic shopRaw = dataMap['shop'] ?? (user is Map ? user['shop'] : null);
        final Map<String, dynamic> shop = (shopRaw is Map)
            ? Map<String, dynamic>.from(shopRaw)
            : {};
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

  Future<ApiResponse<dynamic>> validateReferralCode(String referralCode) async {
    return await _apiClient.post(
      ApiEndpoints.referralValidate,
      body: {'referral_code': referralCode.trim()},
    );
  }

  Future<ApiResponse<dynamic>> verifyRegisterOtp({
    required String verificationId,
    required String otp,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.verifyRegisterOtp,
      body: {
        'verification_id': verificationId,
        'otp': otp,
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

  Future<ApiResponse<dynamic>> resendRegisterOtp({
    required String verificationId,
  }) async {
    return await _apiClient.post(
      ApiEndpoints.resendRegisterOtp,
      body: {
        'verification_id': verificationId,
      },
    );
  }
  final ApiClient _apiClient = ApiClient();
  final AuthStorage _authStorage = AuthStorage();

  Future<ApiResponse<dynamic>> registerOwner({
    required String name,
    required String mobile,
    required String shopName,
    required String password,
    required String passwordConfirmation,
    String? email,
    String? referralCode,
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
        if (referralCode != null && referralCode.trim().isNotEmpty)
          'referral_code': referralCode.trim(),
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
    String? googleMapsUrl,
    double? latitude,
    double? longitude,
    String? upiId,
    String? tagline,
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
        'google_maps_url': googleMapsUrl,
        'latitude': latitude,
        'longitude': longitude,
        'upi_id': upiId,
        'tagline': tagline,
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
    String? name,
    String? ownerName,
    String? mobile,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? phone,
    String? email,
    String? gstNumber,
    String? googleMapsUrl,
    double? latitude,
    double? longitude,
    String? upiId,
    String? tagline,
  }) async {
    final currentShop = await _authStorage.getShop() ?? {};

    // Prioritize passed value, then existing stored value (never fallback to dummy static strings)
    final shopName = (name != null && name.trim().isNotEmpty)
        ? name.trim()
        : (currentShop['name']?.toString().trim());

    final shopOwner = (ownerName != null && ownerName.trim().isNotEmpty)
        ? ownerName.trim()
        : (currentShop['owner_name']?.toString().trim());

    final shopMobile = (mobile != null && mobile.trim().isNotEmpty)
        ? mobile.trim()
        : (phone != null && phone.trim().isNotEmpty)
            ? phone.trim()
            : (currentShop['phone']?.toString().trim() ?? currentShop['mobile']?.toString().trim());

    final shopPhone = (phone != null && phone.trim().isNotEmpty)
        ? phone.trim()
        : shopMobile;

    final shopEmail = (email != null && email.trim().isNotEmpty)
        ? email.trim()
        : (currentShop['email']?.toString().trim());

    final shopAddress = (address != null && address.trim().isNotEmpty)
        ? address.trim()
        : (currentShop['address']?.toString().trim());

    final shopCity = (city != null && city.trim().isNotEmpty)
        ? city.trim()
        : (currentShop['city']?.toString().trim());

    final shopState = (state != null && state.trim().isNotEmpty)
        ? state.trim()
        : (currentShop['state']?.toString().trim());

    final shopPincode = (pincode != null && pincode.trim().isNotEmpty)
        ? pincode.trim()
        : (currentShop['pincode']?.toString().trim());

    final shopMapsUrl = (googleMapsUrl != null && googleMapsUrl.trim().isNotEmpty)
        ? googleMapsUrl.trim()
        : (currentShop['google_maps_url']?.toString().trim());

    final shopLat = latitude ?? (currentShop['latitude'] != null ? double.tryParse(currentShop['latitude'].toString()) : null);
    final shopLng = longitude ?? (currentShop['longitude'] != null ? double.tryParse(currentShop['longitude'].toString()) : null);

    final shopUpiId = (upiId != null && upiId.trim().isNotEmpty)
        ? upiId.trim()
        : (currentShop['upi_id']?.toString().trim());

    final shopTagline = (tagline != null && tagline.trim().isNotEmpty)
        ? tagline.trim()
        : (currentShop['tagline']?.toString().trim());

    final shopGst = (gstNumber != null && gstNumber.trim().isNotEmpty)
        ? gstNumber.trim()
        : (currentShop['gst_number']?.toString().trim() ?? currentShop['gstin']?.toString().trim());

    final body = <String, dynamic>{};
    if (shopName != null && shopName.isNotEmpty) body['name'] = shopName;
    if (shopOwner != null && shopOwner.isNotEmpty) body['owner_name'] = shopOwner;
    if (shopMobile != null && shopMobile.isNotEmpty) {
      body['mobile'] = shopMobile;
      body['phone'] = shopPhone ?? shopMobile;
    }
    if (shopEmail != null && shopEmail.isNotEmpty) body['email'] = shopEmail;
    if (shopAddress != null && shopAddress.isNotEmpty) body['address'] = shopAddress;
    if (shopCity != null && shopCity.isNotEmpty) body['city'] = shopCity;
    if (shopState != null && shopState.isNotEmpty) body['state'] = shopState;
    if (shopPincode != null && shopPincode.isNotEmpty) body['pincode'] = shopPincode;
    if (shopMapsUrl != null && shopMapsUrl.isNotEmpty) body['google_maps_url'] = shopMapsUrl;
    if (shopLat != null) body['latitude'] = shopLat;
    if (shopLng != null) body['longitude'] = shopLng;
    if (shopUpiId != null && shopUpiId.isNotEmpty) body['upi_id'] = shopUpiId;
    if (shopTagline != null && shopTagline.isNotEmpty) body['tagline'] = shopTagline;
    if (shopGst != null && shopGst.isNotEmpty) body['gst_number'] = shopGst;

    final response = await _apiClient.put(
      ApiEndpoints.shop,
      body: body,
    );

    if (response.success && response.data != null) {
      final user = await _authStorage.getUser();
      final token = await _authStorage.getToken();
      if (user != null && token != null) {
        final current = await _authStorage.getShop() ?? {};
        final Map<String, dynamic> merged = Map<String, dynamic>.from(current);
        if (response.data is Map<String, dynamic>) {
          merged.addAll(response.data as Map<String, dynamic>);
        } else if (response.data is Map) {
          merged.addAll(Map<String, dynamic>.from(response.data as Map));
        }
        await _authStorage.saveSession(
          token: token,
          user: user,
          shop: merged,
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

  Future<ApiResponse<dynamic>> sendProfileOtp({
    required String name,
    required String mobile,
    String? email,
  }) async {
    return await _apiClient.post(
      ApiEndpoints.sendProfileOtp,
      body: {
        'name': name,
        'mobile': mobile,
        if (email != null && email.isNotEmpty) 'email': email,
      },
    );
  }

  Future<ApiResponse<dynamic>> verifyProfileOtp({
    required String verificationId,
    required String otp,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.verifyProfileOtp,
      body: {
        'verification_id': verificationId,
        'otp': otp,
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
        final token = await _authStorage.getToken();
        final user = dataMap['user'];
        final dynamic shopRaw = dataMap['shop'] ?? (user is Map ? user['shop'] : null);
        final Map<String, dynamic> shop = (shopRaw is Map)
            ? Map<String, dynamic>.from(shopRaw)
            : {};

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

  Future<ApiResponse<dynamic>> sendForgotPasswordOtp({
    required String mobile,
  }) async {
    return await _apiClient.post(
      ApiEndpoints.sendForgotPasswordOtp,
      body: {
        'mobile': mobile,
      },
    );
  }

  Future<ApiResponse<dynamic>> verifyForgotPasswordOtp({
    required String verificationId,
    required String otp,
  }) async {
    return await _apiClient.post(
      ApiEndpoints.verifyForgotPasswordOtp,
      body: {
        'verification_id': verificationId,
        'otp': otp,
      },
    );
  }

  Future<ApiResponse<dynamic>> resetPasswordWithOtp({
    required String verificationId,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await _apiClient.post(
      ApiEndpoints.resetPasswordWithOtp,
      body: {
        'verification_id': verificationId,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  Future<ApiResponse<dynamic>> requestPasswordReset({required String login, String? password, String? passwordConfirmation}) async {
    return await _apiClient.post(
      ApiEndpoints.forgotPassword,
      body: {'login': login, if (password != null) 'password': password, if (passwordConfirmation != null) 'password_confirmation': passwordConfirmation},
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

  Future<ApiResponse<dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    return await _apiClient.post(
      ApiEndpoints.changePassword,
      body: {
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPasswordConfirmation,
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

