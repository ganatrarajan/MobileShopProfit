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

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
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
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case login:
        final errorMsg = settings.arguments is String ? settings.arguments as String : null;
        return MaterialPageRoute(builder: (_) => LoginScreen(errorMessage: errorMsg));
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case shopSetup:
        return MaterialPageRoute(builder: (_) => const ShopSetupScreen());
      case dashboard:
        final initialIdx = settings.arguments is int ? settings.arguments as int : 0;
        return MaterialPageRoute(builder: (_) => MainNavigationScreen(initialIndex: initialIdx));
      case shopProfile:
        return MaterialPageRoute(builder: (_) => const ShopProfileScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case subscription:
        return MaterialPageRoute(builder: (_) => const SubscriptionScreen());
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

      case sales:
        return MaterialPageRoute(builder: (_) => const SalesListScreen());
      case createSale:
        return MaterialPageRoute(builder: (_) => const CreateSaleScreen());
      case quickSale:
        return MaterialPageRoute(builder: (_) => const QuickSaleScreen());
      case saleDetails:
        final sale = settings.arguments as Sale;
        return MaterialPageRoute(builder: (_) => SaleDetailsScreen(sale: sale));

      case technicians:
        return MaterialPageRoute(builder: (_) => const TechnicianListScreen());
      case technicianDetails:
        final tech = settings.arguments as Technician;
        return MaterialPageRoute(builder: (_) => TechnicianDetailsScreen(technician: tech));
      case repairs:
        return MaterialPageRoute(builder: (_) => const RepairListScreen());
      case createRepair:
        return MaterialPageRoute(builder: (_) => const CreateRepairScreen());
      case repairDetails:
        final repair = settings.arguments as Repair;
        return MaterialPageRoute(builder: (_) => RepairDetailsScreen(repair: repair));
      case editRepair:
        final repair = settings.arguments as Repair;
        return MaterialPageRoute(builder: (_) => EditRepairScreen(repair: repair));

      case warranties:
        return MaterialPageRoute(builder: (_) => const WarrantyListScreen());
      case createWarranty:
        return MaterialPageRoute(builder: (_) => const CreateWarrantyScreen());
      case warrantyDetails:
        final warranty = settings.arguments as Warranty;
        return MaterialPageRoute(builder: (_) => WarrantyDetailsScreen(warranty: warranty));
      case warrantyClaims:
        return MaterialPageRoute(builder: (_) => const WarrantyClaimListScreen());

      case inventory:
        return MaterialPageRoute(builder: (_) => const InventoryListScreen());
      case addInventoryItem:
        return MaterialPageRoute(builder: (_) => const AddEditInventoryItemScreen());
      case inventoryDetails:
        final item = settings.arguments as InventoryItem;
        return MaterialPageRoute(builder: (_) => InventoryDetailsScreen(item: item));
      case editInventoryItem:
        final item = settings.arguments as InventoryItem;
        return MaterialPageRoute(builder: (_) => AddEditInventoryItemScreen(item: item));

      case expenses:
        return MaterialPageRoute(builder: (_) => const ExpenseListScreen());
      case addExpense:
        return MaterialPageRoute(builder: (_) => const AddEditExpenseScreen());
      case editExpense:
        final exp = settings.arguments as Expense;
        return MaterialPageRoute(builder: (_) => AddEditExpenseScreen(expense: exp));
      case expenseDetails:
        final exp = settings.arguments as Expense;
        return MaterialPageRoute(builder: (_) => ExpenseDetailsScreen(expense: exp));

      case reportsHub:
        return MaterialPageRoute(builder: (_) => const ReportsHubScreen());
      case salesReport:
        return MaterialPageRoute(builder: (_) => const SalesReportScreen());
      case repairReport:
        return MaterialPageRoute(builder: (_) => const RepairReportScreen());
      case inventoryReport:
        return MaterialPageRoute(builder: (_) => const InventoryReportScreen());
      case expenseReport:
        return MaterialPageRoute(builder: (_) => const ExpenseReportScreen());
      case paymentReport:
        return MaterialPageRoute(builder: (_) => const PaymentReportScreen());
      case customerReport:
        return MaterialPageRoute(builder: (_) => const CustomerReportScreen());
      case warrantyReport:
        return MaterialPageRoute(builder: (_) => const WarrantyReportScreen());

      case profitIntelligence:
        return MaterialPageRoute(builder: (_) => const ProfitIntelligenceScreen());
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
