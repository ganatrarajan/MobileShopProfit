import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/customer.dart';

class CustomerRepository {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<Customer>>> getCustomers({
    String? search,
    int page = 1,
  }) async {
    String path = '${ApiEndpoints.customers}?page=$page';
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }

    final response = await _apiClient.get(
      path,
      fromJson: (data) {
        if (data is List) {
          return data.map((item) => Customer.fromJson(item)).toList();
        }
        return <Customer>[];
      },
    );

    return response;
  }

  Future<ApiResponse<Customer>> getCustomerDetails(int id) async {
    return await _apiClient.get<Customer>(
      '${ApiEndpoints.customers}/$id',
      fromJson: (data) => Customer.fromJson(data),
    );
  }

  Future<ApiResponse<dynamic>> createCustomer({
    required String name,
    required String mobile,
    String? alternateMobile,
    String? email,
    String? address,
    String? city,
    String? notes,
  }) async {
    return await _apiClient.post(
      ApiEndpoints.customers,
      body: {
        'name': name,
        'mobile': mobile,
        'alternate_mobile': alternateMobile,
        'email': email,
        'address': address,
        'city': city,
        'notes': notes,
      },
    );
  }

  Future<ApiResponse<dynamic>> updateCustomer({
    required int id,
    required String name,
    required String mobile,
    String? alternateMobile,
    String? email,
    String? address,
    String? city,
    String? notes,
  }) async {
    return await _apiClient.put(
      '${ApiEndpoints.customers}/$id',
      body: {
        'name': name,
        'mobile': mobile,
        'alternate_mobile': alternateMobile,
        'email': email,
        'address': address,
        'city': city,
        'notes': notes,
      },
    );
  }

  Future<ApiResponse<dynamic>> deleteCustomer(int id) async {
    try {
      final response = await _apiClient.post(
        '${ApiEndpoints.customers}/$id',
        body: {'_method': 'DELETE'},
      );
      return response;
    } catch (_) {
      // Fallback
      return await _apiClient.put('${ApiEndpoints.customers}/$id', body: {});
    }
  }
}