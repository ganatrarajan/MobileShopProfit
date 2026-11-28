import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../models/customer.dart';

class CustomerListResult {
  final List<Customer> customers;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;

  CustomerListResult({
    required this.customers,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
  });

  bool get hasMore => currentPage < lastPage;
}

class CustomerRepository {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<CustomerListResult>> getCustomersPaged({
    String? search,
    int page = 1,
    int perPage = 15,
    String filter = 'all',
    String sort = 'newest',
    bool all = false,
  }) async {
    String path = '${ApiEndpoints.customers}?page=$page&per_page=${all ? 'all' : perPage}&filter=$filter&sort=$sort';
    if (search != null && search.trim().isNotEmpty) {
      path += '&search=${Uri.encodeComponent(search.trim())}';
    }
    if (all) {
      path += '&all=true';
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

    if (response.success && response.data != null) {
      final meta = response.rawJson?['meta'] as Map<String, dynamic>?;
      final result = CustomerListResult(
        customers: response.data as List<Customer>,
        currentPage: meta?['current_page'] is int ? meta!['current_page'] as int : page,
        lastPage: meta?['last_page'] is int ? meta!['last_page'] as int : 1,
        total: meta?['total'] is int ? meta!['total'] as int : (response.data as List<Customer>).length,
        perPage: meta?['per_page'] is int ? meta!['per_page'] as int : perPage,
      );
      return ApiResponse<CustomerListResult>(
        success: true,
        message: response.message,
        data: result,
        rawJson: response.rawJson,
      );
    }

    return ApiResponse<CustomerListResult>(
      success: response.success,
      message: response.message,
      data: null,
      rawJson: response.rawJson,
      errors: response.errors,
    );
  }

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

  Future<ApiResponse<dynamic>> importCustomersFile(String filePath) async {
    return await _apiClient.postMultipart(
      '${ApiEndpoints.customers}/import',
      filePath: filePath,
      fileFieldName: 'file',
    );
  }

  Future<ApiResponse<dynamic>> importCustomersRows(List<Map<String, dynamic>> customers) async {
    return await _apiClient.post(
      '${ApiEndpoints.customers}/import',
      body: {'customers': customers},
    );
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
    String? signature,
  }) async {
    if (signature != null && signature.isNotEmpty && !signature.startsWith('data:image') && !signature.startsWith('http')) {
      final fields = <String, String>{
        'name': name,
        'mobile': mobile,
      };
      if (alternateMobile != null && alternateMobile.isNotEmpty) fields['alternate_mobile'] = alternateMobile;
      if (email != null && email.isNotEmpty) fields['email'] = email;
      if (address != null && address.isNotEmpty) fields['address'] = address;
      if (city != null && city.isNotEmpty) fields['city'] = city;
      if (notes != null && notes.isNotEmpty) fields['notes'] = notes;

      return await _apiClient.postMultipart(
        ApiEndpoints.customers,
        filePath: signature,
        fileFieldName: 'signature',
        fields: fields,
      );
    }

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
        if (signature != null) 'signature': signature,
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
    String? signature,
  }) async {
    if (signature != null && signature.isNotEmpty && !signature.startsWith('data:image') && !signature.startsWith('http')) {
      final fields = <String, String>{
        '_method': 'PUT',
        'name': name,
        'mobile': mobile,
      };
      if (alternateMobile != null && alternateMobile.isNotEmpty) fields['alternate_mobile'] = alternateMobile;
      if (email != null && email.isNotEmpty) fields['email'] = email;
      if (address != null && address.isNotEmpty) fields['address'] = address;
      if (city != null && city.isNotEmpty) fields['city'] = city;
      if (notes != null && notes.isNotEmpty) fields['notes'] = notes;

      return await _apiClient.postMultipart(
        '${ApiEndpoints.customers}/$id',
        filePath: signature,
        fileFieldName: 'signature',
        fields: fields,
      );
    }

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
        if (signature != null) 'signature': signature,
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