import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/device.dart';

class DeviceRepository {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<Device>>> getDevicesForCustomer(int customerId) async {
    return await _apiClient.get<List<Device>>(
      '/customers/$customerId/devices',
      fromJson: (data) {
        if (data is List) {
          return data.map((item) => Device.fromJson(item)).toList();
        }
        return <Device>[];
      },
    );
  }

  Future<ApiResponse<List<Device>>> searchDevices({
    String? search,
    int page = 1,
  }) async {
    String path = '/devices?page=$page';
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }

    return await _apiClient.get<List<Device>>(
      path,
      fromJson: (data) {
        if (data is List) {
          return data.map((item) => Device.fromJson(item)).toList();
        }
        return <Device>[];
      },
    );
  }

  Future<ApiResponse<Device>> getDeviceDetails(int id) async {
    return await _apiClient.get<Device>(
      '/devices/$id',
      fromJson: (data) => Device.fromJson(data),
    );
  }

  Future<ApiResponse<dynamic>> createDevice({
    required int customerId,
    required String deviceType,
    required String brand,
    required String model,
    String? variant,
    String? color,
    String? imei1,
    String? imei2,
    String? serialNumber,
    String? purchaseDate,
    String? notes,
  }) async {
    return await _apiClient.post(
      '/customers/$customerId/devices',
      body: {
        'device_type': deviceType,
        'brand': brand,
        'model': model,
        'variant': variant,
        'color': color,
        'imei_1': imei1,
        'imei_2': imei2,
        'serial_number': serialNumber,
        'purchase_date': purchaseDate,
        'notes': notes,
      },
    );
  }

  Future<ApiResponse<dynamic>> updateDevice({
    required int id,
    required String deviceType,
    required String brand,
    required String model,
    String? variant,
    String? color,
    String? imei1,
    String? imei2,
    String? serialNumber,
    String? purchaseDate,
    String? notes,
  }) async {
    return await _apiClient.put(
      '/devices/$id',
      body: {
        'device_type': deviceType,
        'brand': brand,
        'model': model,
        'variant': variant,
        'color': color,
        'imei_1': imei1,
        'imei_2': imei2,
        'serial_number': serialNumber,
        'purchase_date': purchaseDate,
        'notes': notes,
      },
    );
  }

  Future<ApiResponse<dynamic>> deleteDevice(int id) async {
    try {
      return await _apiClient.post(
        '/devices/$id',
        body: {'_method': 'DELETE'},
      );
    } catch (_) {
      return await _apiClient.put('/devices/$id', body: {});
    }
  }
}