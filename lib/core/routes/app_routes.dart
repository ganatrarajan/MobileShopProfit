import '../../features/auth/presentation/force_update_screen.dart';
import '../models/app_version_info.dart';
import 'package:flutter/material.dart';
import '../../features/purchase/models/purchase.dart';
import '../../features/purchase/models/vendor.dart';
import '../../features/purchase/presentation/add_purchase_screen.dart';
import '../../features/purchase/presentation/purchase_details_screen.dart';
import '../../features/purchase/presentation/purchase_list_screen.dart';
import '../../features/purchase/presentation/vendor_details_screen.dart';
import '../../features/purchase/presentation/vendor_list_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/otp_verification_screen.dart';
import '../../features/auth/presentation/splash_screen.dart';
import '../../features/customer/models/customer.dart';
import '../../features/customer/presentation/add_customer_screen.dart';
import '../../features/customer/presentation/customer_details_screen.dart';
import '../../features/customer/presentation/customer_list_screen.dart';
import '../../features/customer/presentation/edit_customer_screen.dart';
import '../../features/dashboard/presentation/main_navigation_screen.dart';
import '../../features/device/models/device.dart';
import '../../features/device/presentation/add_device_screen.dart';
import '../../features/device/presentation/device_details_screen.dart';
import '../../features/device/presentation/device_search_screen.dart';
import '../../features/device/presentation/edit_device_screen.dart';
import '../../features/expenses/models/expense.dart';
import '../../features/expenses/presentation/add_edit_expense_screen.dart';
import '../../features/expenses/presentation/expense_details_screen.dart';
import '../../features/expenses/presentation/expense_list_screen.dart';
import '../../features/inventory/models/inventory_item.dart';
import '../../features/inventory/presentation/add_edit_inventory_item_screen.dart';
import '../../features/inventory/presentation/inventory_details_screen.dart';
import '../../features/inventory/presentation/inventory_list_screen.dart';
import '../../features/profit_intelligence/presentation/profit_intelligence_detail_screen.dart';
import '../../features/profit_intelligence/presentation/profit_intelligence_screen.dart';
import '../../features/repair/models/repair.dart';
import '../../features/repair/presentation/create_repair_screen.dart';
import '../../features/repair/presentation/edit_repair_screen.dart';
import '../../features/repair/presentation/repair_details_screen.dart';
import '../../features/repair/presentation/repair_list_screen.dart';
import '../../features/reports/presentation/customer_report_screen.dart';
import '../../features/reports/presentation/expense_report_screen.dart';
import '../../features/reports/presentation/inventory_report_screen.dart';
import '../../features/reports/presentation/payment_report_screen.dart';
import '../../features/reports/presentation/repair_report_screen.dart';
import '../../features/reports/presentation/reports_hub_screen.dart';
import '../../features/reports/presentation/sales_report_screen.dart';
import '../../features/reports/presentation/warranty_report_screen.dart';
import '../../features/sales/models/sale.dart';
import '../../features/sales/presentation/create_sale_screen.dart';
import '../../features/sales/presentation/quick_sale_screen.dart';
import '../../features/sales/presentation/sale_details_screen.dart';
import '../../features/sales/presentation/sales_list_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shop/presentation/shop_profile_screen.dart';
import '../../features/shop/presentation/shop_setup_screen.dart';
import '../../features/subscription/presentation/subscription_screen.dart';
import '../../features/technician/models/technician.dart';
import '../../features/technician/presentation/technician_details_screen.dart';
import '../../features/technician/presentation/technician_list_screen.dart';
import '../../features/warranty/models/warranty.dart';
import '../../features/warranty/presentation/create_warranty_screen.dart';
import '../../features/warranty/presentation/warranty_claim_list_screen.dart';
import '../../features/warranty/presentation/warranty_details_screen.dart';
import '../../features/warranty/presentation/warranty_list_screen.dart';

class AppRoutes {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String forceUpdate = '/force-update';
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String otpVerification = '/otp-verification';
  static const String forgotPassword = '/forgot-password';
  static const String shopSetup = '/shop-setup';

  static const String dashboard = '/dashboard';
  static const String shopProfile = '/shop-profile';
  static const String settings = '/settings';
  static const String subscription = '/subscription';

  static const String customers = '/customers';
  static const String addCustomer = '/add-customer';
  static const String customerDetails = '/customer-details';
  static const String editCustomer = '/edit-customer';

  static const String addDevice = '/add-device';
  static const String deviceDetails = '/device-details';
  static const String editDevice = '/edit-device';
  static const String deviceSearch = '/device-search';

  static const String sales = '/sales';
  static const String createSale = '/create-sale';
  static const String quickSale = '/quick-sale';
  static const String saleDetails = '/sale-details';

  static const String repairs = '/repairs';
  static const String technicians = '/technicians';
  static const String technicianDetails = '/technician-details';
  static const String createRepair = '/create-repair';
  static const String repairDetails = '/repair-details';
  static const String editRepair = '/edit-repair';

  static const String warranties = '/warranties';
  static const String createWarranty = '/create-warranty';
  static const String warrantyDetails = '/warranty-details';
  static const String warrantyClaims = '/warranty-claims';

  static const String inventory = '/inventory';
  static const String addInventoryItem = '/add-inventory-item';
  static const String inventoryDetails = '/inventory-details';
  static const String editInventoryItem = '/edit-inventory-item';
  static const String purchases = '/purchases';
  static const String addPurchase = '/add-purchase';
  static const String purchaseDetails = '/purchase-details';
  static const String vendors = '/vendors';
  static const String vendorDetails = '/vendor-details';

  static const String expenses = '/expenses';
  static const String addExpense = '/add-expense';
  static const String editExpense = '/edit-expense';
  static const String expenseDetails = '/expense-details';

  static const String reportsHub = '/reports-hub';
  static const String salesReport = '/sales-report';
  static const String repairReport = '/repair-report';
  static const String inventoryReport = '/inventory-report';
  static const String expenseReport = '/expense-report';
  static const String paymentReport = '/payment-report';
  static const String customerReport = '/customer-report';
  static const String warrantyReport = '/warranty-report';

  static const String profitIntelligence = '/profit-intelligence';
  static const String profitIntelligenceDetail = '/profit-intelligence-detail';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case forceUpdate:
        final info = settings.arguments is AppVersionInfo ? settings.arguments as AppVersionInfo : null;
        return MaterialPageRoute(settings: settings, builder: (_) => ForceUpdateScreen(versionInfo: info));
      case splash:
        return MaterialPageRoute(settings: settings, builder: (_) => const SplashScreen());
      case login:
        final errorMsg = settings.arguments is String ? settings.arguments as String : null;
        return MaterialPageRoute(settings: settings, builder: (_) => LoginScreen(errorMessage: errorMsg));
      case register:
        return MaterialPageRoute(settings: settings, builder: (_) => const RegisterScreen());
      case otpVerification:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            verificationId: args['verification_id'].toString(),
            mobile: args['mobile'].toString(),
            cooldownSeconds: (args['cooldown_seconds'] is int) ? args['cooldown_seconds'] as int : 60,
            otpDebug: args['otp_debug']?.toString(),
          ),
        );
      case forgotPassword:
        return MaterialPageRoute(settings: settings, builder: (_) => const ForgotPasswordScreen());
      case shopSetup:
        return MaterialPageRoute(settings: settings, builder: (_) => const ShopSetupScreen());
      case dashboard:
        final initialIdx = settings.arguments is int ? settings.arguments as int : 0;
        return MaterialPageRoute(settings: settings, builder: (_) => MainNavigationScreen(initialIndex: initialIdx));
      case shopProfile:
        return MaterialPageRoute(settings: settings, builder: (_) => const ShopProfileScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(settings: settings, builder: (_) => const SettingsScreen());
      case subscription:
        return MaterialPageRoute(settings: settings, builder: (_) => const SubscriptionScreen());
      case customers:
        return MaterialPageRoute(settings: settings, builder: (_) => const CustomerListScreen());
      case addCustomer:
        return MaterialPageRoute(settings: settings, builder: (_) => const AddCustomerScreen());
      case customerDetails:
        final customer = settings.arguments as Customer;
        return MaterialPageRoute(settings: settings, builder: (_) => CustomerDetailsScreen(customer: customer));
      case editCustomer:
        final customer = settings.arguments as Customer;
        return MaterialPageRoute(settings: settings, builder: (_) => EditCustomerScreen(customer: customer));

      case addDevice:
        final customer = settings.arguments as Customer;
        return MaterialPageRoute(settings: settings, builder: (_) => AddDeviceScreen(customer: customer));
      case deviceDetails:
        final device = settings.arguments as Device;
        return MaterialPageRoute(settings: settings, builder: (_) => DeviceDetailsScreen(device: device));
      case editDevice:
        final device = settings.arguments as Device;
        return MaterialPageRoute(settings: settings, builder: (_) => EditDeviceScreen(device: device));
      case deviceSearch:
        return MaterialPageRoute(settings: settings, builder: (_) => const DeviceSearchScreen());

      case sales:
        return MaterialPageRoute(settings: settings, builder: (_) => const SalesListScreen());
      case createSale:
        return MaterialPageRoute(settings: settings, builder: (_) => const CreateSaleScreen());
      case quickSale:
        return MaterialPageRoute(settings: settings, builder: (_) => const QuickSaleScreen());
      case saleDetails:
        final sale = settings.arguments as Sale;
        return MaterialPageRoute(settings: settings, builder: (_) => SaleDetailsScreen(sale: sale));

      case technicians:
        return MaterialPageRoute(settings: settings, builder: (_) => const TechnicianListScreen());
      case technicianDetails:
        final tech = settings.arguments as Technician;
        return MaterialPageRoute(settings: settings, builder: (_) => TechnicianDetailsScreen(technician: tech));
      case repairs:
        return MaterialPageRoute(settings: settings, builder: (_) => const RepairListScreen());
      case createRepair:
        return MaterialPageRoute(settings: settings, builder: (_) => const CreateRepairScreen());
      case repairDetails:
        final repair = settings.arguments as Repair;
        return MaterialPageRoute(settings: settings, builder: (_) => RepairDetailsScreen(repair: repair));
      case editRepair:
        final repair = settings.arguments as Repair;
        return MaterialPageRoute(settings: settings, builder: (_) => EditRepairScreen(repair: repair));

      case warranties:
        return MaterialPageRoute(settings: settings, builder: (_) => const WarrantyListScreen());
      case createWarranty:
        return MaterialPageRoute(settings: settings, builder: (_) => const CreateWarrantyScreen());
      case warrantyDetails:
        final warranty = settings.arguments as Warranty;
        return MaterialPageRoute(settings: settings, builder: (_) => WarrantyDetailsScreen(warranty: warranty));
      case warrantyClaims:
        return MaterialPageRoute(settings: settings, builder: (_) => const WarrantyClaimListScreen());

            case purchases:
        return MaterialPageRoute(settings: settings, builder: (_) => const PurchaseListScreen());
      case addPurchase:
        return MaterialPageRoute(settings: settings, builder: (_) => const AddPurchaseScreen());
      case purchaseDetails:
        final purchase = settings.arguments as Purchase;
        return MaterialPageRoute(settings: settings, builder: (_) => PurchaseDetailsScreen(purchase: purchase));
      case vendors:
        return MaterialPageRoute(settings: settings, builder: (_) => const VendorListScreen());
      case vendorDetails:
        final vendor = settings.arguments as Vendor;
        return MaterialPageRoute(settings: settings, builder: (_) => VendorDetailsScreen(vendor: vendor));

      case inventory:
        return MaterialPageRoute(settings: settings, builder: (_) => const InventoryListScreen());
      case addInventoryItem:
        return MaterialPageRoute(settings: settings, builder: (_) => const AddEditInventoryItemScreen());
      case inventoryDetails:
        final item = settings.arguments as InventoryItem;
        return MaterialPageRoute(settings: settings, builder: (_) => InventoryDetailsScreen(item: item));
      case editInventoryItem:
        final item = settings.arguments as InventoryItem;
        return MaterialPageRoute(settings: settings, builder: (_) => AddEditInventoryItemScreen(item: item));

      case expenses:
        return MaterialPageRoute(settings: settings, builder: (_) => const ExpenseListScreen());
      case addExpense:
        return MaterialPageRoute(settings: settings, builder: (_) => const AddEditExpenseScreen());
      case editExpense:
        final exp = settings.arguments as Expense;
        return MaterialPageRoute(settings: settings, builder: (_) => AddEditExpenseScreen(expense: exp));
      case expenseDetails:
        final exp = settings.arguments as Expense;
        return MaterialPageRoute(settings: settings, builder: (_) => ExpenseDetailsScreen(expense: exp));

      case reportsHub:
        return MaterialPageRoute(settings: settings, builder: (_) => const ReportsHubScreen());
      case salesReport:
        return MaterialPageRoute(settings: settings, builder: (_) => const SalesReportScreen());
      case repairReport:
        return MaterialPageRoute(settings: settings, builder: (_) => const RepairReportScreen());
      case inventoryReport:
        return MaterialPageRoute(settings: settings, builder: (_) => const InventoryReportScreen());
      case expenseReport:
        return MaterialPageRoute(settings: settings, builder: (_) => const ExpenseReportScreen());
      case paymentReport:
        return MaterialPageRoute(settings: settings, builder: (_) => const PaymentReportScreen());
      case customerReport:
        return MaterialPageRoute(settings: settings, builder: (_) => const CustomerReportScreen());
      case warrantyReport:
        return MaterialPageRoute(settings: settings, builder: (_) => const WarrantyReportScreen());

      case profitIntelligence:
        return MaterialPageRoute(settings: settings, builder: (_) => const ProfitIntelligenceScreen());
      case profitIntelligenceDetail:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ProfitIntelligenceDetailScreen(
            category: args['category'] as String,
            title: args['title'] as String,
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}







