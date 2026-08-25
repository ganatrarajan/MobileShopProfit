import 'package:flutter/material.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/customer/models/customer.dart';
import '../../features/customer/presentation/add_customer_screen.dart';
import '../../features/customer/presentation/customer_details_screen.dart';
import '../../features/customer/presentation/customer_list_screen.dart';
import '../../features/customer/presentation/edit_customer_screen.dart';

import '../../features/device/models/device.dart';
import '../../features/device/presentation/add_device_screen.dart';
import '../../features/device/presentation/device_details_screen.dart';
import '../../features/device/presentation/device_search_screen.dart';
import '../../features/device/presentation/edit_device_screen.dart';

import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/shop/presentation/shop_profile_screen.dart';
import '../../features/shop/presentation/shop_setup_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String shopSetup = '/shop-setup';
  static const String dashboard = '/dashboard';
  static const String shopProfile = '/shop-profile';
  static const String customers = '/customers';
  static const String addCustomer = '/add-customer';
  static const String customerDetails = '/customer-details';
  static const String editCustomer = '/edit-customer';

  static const String addDevice = '/add-device';
  static const String deviceDetails = '/device-details';
  static const String editDevice = '/edit-device';
  static const String deviceSearch = '/device-search';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case shopSetup:
        return MaterialPageRoute(builder: (_) => const ShopSetupScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const DashboardScreen());
      case shopProfile:
        return MaterialPageRoute(builder: (_) => const ShopProfileScreen());
      case customers:
        return MaterialPageRoute(builder: (_) => const CustomerListScreen());
      case addCustomer:
        return MaterialPageRoute(builder: (_) => const AddCustomerScreen());
      case customerDetails:
        final customer = settings.arguments as Customer;
        return MaterialPageRoute(builder: (_) => CustomerDetailsScreen(customer: customer));
      case editCustomer:
        final customer = settings.arguments as Customer;
        return MaterialPageRoute(builder: (_) => EditCustomerScreen(customer: customer));

      case addDevice:
        final customer = settings.arguments as Customer;
        return MaterialPageRoute(builder: (_) => AddDeviceScreen(customer: customer));
      case deviceDetails:
        final device = settings.arguments as Device;
        return MaterialPageRoute(builder: (_) => DeviceDetailsScreen(device: device));
      case editDevice:
        final device = settings.arguments as Device;
        return MaterialPageRoute(builder: (_) => EditDeviceScreen(device: device));
      case deviceSearch:
        return MaterialPageRoute(builder: (_) => const DeviceSearchScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}