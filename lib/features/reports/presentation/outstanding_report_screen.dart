import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/customer_outstanding_statement_pdf_builder.dart';
import '../../../core/utils/report_export_helper.dart';
import '../../../core/widgets/custom_card.dart';
import '../../customer/data/customer_repository.dart';
import '../../customer/models/customer.dart';
import '../data/reports_repository.dart';
import '../domain/report_models.dart';

class OutstandingReportScreen extends StatefulWidget {
  final String shopName;
  final int? initialCustomerId;
  final String? initialCustomerName;
  final String? initialCustomerPhone;

  const OutstandingReportScreen({
    super.key,
    this.shopName = 'Mobile Repair & Retail Shop',
    this.initialCustomerId,
    this.initialCustomerName,
    this.initialCustomerPhone,
  });

  @override
  State<OutstandingReportScreen> createState() => _OutstandingReportScreenState();
}

class _OutstandingReportScreenState extends State<OutstandingReportScreen> {
  final ReportsRepository _repository = ReportsRepository();

  String _selectedPeriod = 'all_time';
  // Primary flow: 'customers' (money to collect) vs 'vendors' (money we have to pay)
  String _flowTab = 'customers'; // 'customers' or 'vendors'
  String _customerSubCategory = 'all_customers'; // 'all_customers', 'repairs', 'sales'

  int? _selectedCustomerId;
  String? _selectedCustomerName;
  String? _selectedCustomerPhone;

  DateTimeRange? _customDateRange;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;

  OutstandingReportSummary? _summary;
  List<OutstandingReportItem> _detailsList = [];

  @override
  void initState() {
    super.initState();
    _selectedCustomerId = widget.initialCustomerId;
    _selectedCustomerName = widget.initialCustomerName;
    _selectedCustomerPhone = widget.initialCustomerPhone;
    _fetchReport();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String get _effectiveBackendCategory {
    if (_flowTab == 'vendors') {
      return 'purchases';
    }
    // Flow is customers
    if (_customerSubCategory == 'repairs') return 'repairs';
    if (_customerSubCategory == 'sales') return 'sales';
    return 'customers';
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? startStr;
      String? endStr;
      if (_selectedPeriod == 'custom' && _customDateRange != null) {
        startStr = _customDateRange!.start.toIso8601String().split('T')[0];
        endStr = _customDateRange!.end.toIso8601String().split('T')[0];
      }

      final res = await _repository.getOutstandingReport(
        period: _selectedPeriod,
        startDate: startStr,
        endDate: endStr,
        category: _effectiveBackendCategory,
        customerId: _flowTab == 'customers' ? _selectedCustomerId : null,
        search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
      );

      if (mounted) {
        if (res.success && res.data != null) {
          final data = res.data!;
          final summaryJson = data['summary'] is Map ? Map<String, dynamic>.from(data['summary']) : null;
          final detailsData = data['details'];
          List<dynamic> detailsJson = [];
          if (detailsData is List) {
            detailsJson = detailsData;
          }

          setState(() {
            _summary = summaryJson != null ? OutstandingReportSummary.fromJson(summaryJson) : null;
            _detailsList = detailsJson
                .map((x) => OutstandingReportItem.fromJson(Map<String, dynamic>.from(x)))
                .toList();
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = res.message.isNotEmpty ? res.message : 'Failed to load outstanding dues report.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedPeriod = 'custom';
      });
      _fetchReport();
    }
  }

  Future<void> _openWhatsApp(OutstandingReportItem item) async {
    final phone = item.partyPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available for this contact.')),
      );
      return;
    }

    final formattedPhone = phone.length == 10 ? '91$phone' : phone;
    // Differentiate message between customer reminder and vendor communication
    final message = item.partyType == 'customer'
        ? 'Hello ${item.partyName}, gentle reminder from ${widget.shopName} regarding your pending balance of ₹${item.amountDue.toStringAsFixed(2)} for ${item.refNumber} (${item.description}). Please clear this at your earliest convenience. Thank you!'
        : 'Hello ${item.partyName}, this is regarding our purchase order ${item.refNumber} outstanding balance of ₹${item.amountDue.toStringAsFixed(2)} from ${widget.shopName}. We are processing this payment. Thank you!';

    final uri = Uri.parse('https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp.')),
        );
      }
    }
  }

  void _downloadItemCustomerPdf(OutstandingReportItem item) {
    final customerItems = _detailsList
        .where((x) =>
            (item.customerId != null && x.customerId == item.customerId) ||
            (item.partyPhone.isNotEmpty && x.partyPhone == item.partyPhone) ||
            x.partyName == item.partyName)
        .toList();
    if (customerItems.isEmpty) customerItems.add(item);

    CustomerOutstandingStatementPdfBuilder.downloadCustomerStatementPdf(
      context: context,
      customerName: item.partyName,
      customerPhone: item.partyPhone,
      statementPeriod: _selectedPeriod,
      items: customerItems,
    );
  }

  Future<void> _showCustomerShareOptions(OutstandingReportItem item) async {
    final customerItems = _detailsList
        .where((x) =>
            (item.customerId != null && x.customerId == item.customerId) ||
            (item.partyPhone.isNotEmpty && x.partyPhone == item.partyPhone) ||
            x.partyName == item.partyName)
        .toList();
    if (customerItems.isEmpty) customerItems.add(item);

    final totalDue = customerItems.fold(0.0, (s, i) => s + i.amountDue);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF25D366).withOpacity(0.15),
                      child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF25D366)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.partyName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Pending Due: ₹${totalDue.toStringAsFixed(2)} (${customerItems.length} records)',
                            style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 20),
                  ),
                  title: const Text('Send Detailed Statement on WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: const Text('Shares statement PDF + full breakdown of repairs, spare parts & sales', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(ctx);
                    CustomerOutstandingStatementPdfBuilder.sendStatementOnWhatsApp(
                      context: context,
                      customerName: item.partyName,
                      customerPhone: item.partyPhone,
                      statementPeriod: _selectedPeriod,
                      items: customerItems,
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 20),
                  ),
                  title: const Text('Download Statement PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: const Text('Generates itemized PDF with used spare parts & dues', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(ctx);
                    CustomerOutstandingStatementPdfBuilder.downloadCustomerStatementPdf(
                      context: context,
                      customerName: item.partyName,
                      customerPhone: item.partyPhone,
                      statementPeriod: _selectedPeriod,
                      items: customerItems,
                    );
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.message_rounded, color: Colors.blue, size: 20),
                  ),
                  title: const Text('Send Quick Reminder Text Only', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: const Text('Opens WhatsApp with short reminder text without PDF', style: TextStyle(fontSize: 11)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openWhatsApp(item);
                  },
                ),
                if (_selectedCustomerId == null && item.customerId != null)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_search_rounded, color: Colors.purple, size: 20),
                    ),
                    title: const Text('Filter only this Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    subtitle: const Text('Show all pending dues for this customer only', style: TextStyle(fontSize: 11)),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _selectedCustomerId = item.customerId;
                        _selectedCustomerName = item.partyName;
                        _selectedCustomerPhone = item.partyPhone;
                      });
                      _fetchReport();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCustomerSelectDialog() async {
    final customerRepo = CustomerRepository();
    final searchCtrl = TextEditingController();
    List<Customer> customerList = [];
    bool isSearching = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            void loadCustomers([String? query]) async {
              setModalState(() => isSearching = true);
              try {
                final res = await customerRepo.getCustomers(search: query);
                if (res.success && res.data != null) {
                  setModalState(() {
                    customerList = res.data!;
                    isSearching = false;
                  });
                } else {
                  setModalState(() => isSearching = false);
                }
              } catch (_) {
                setModalState(() => isSearching = false);
              }
            }

            if (isSearching && customerList.isEmpty) {
              loadCustomers();
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalCtx).viewInsets.bottom,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(modalCtx).size.height * 0.65,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filter by Customer',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(modalCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search customer name or phone...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (val) {
                        loadCustomers(val.trim());
                      },
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEFF6FF),
                        child: Icon(Icons.people_outline_rounded, color: AppColors.primary),
                      ),
                      title: const Text('All Customers (Clear Filter)', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Show dues across all customers'),
                      selected: _selectedCustomerId == null,
                      onTap: () {
                        Navigator.pop(modalCtx);
                        setState(() {
                          _selectedCustomerId = null;
                          _selectedCustomerName = null;
                          _selectedCustomerPhone = null;
                        });
                        _fetchReport();
                      },
                    ),
                    const Divider(),
                    Expanded(
                      child: isSearching
                          ? const Center(child: CircularProgressIndicator())
                          : customerList.isEmpty
                              ? const Center(
                                  child: Text('No customers found', style: TextStyle(color: Colors.grey)),
                                )
                              : ListView.separated(
                                  itemCount: customerList.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (cCtx, i) {
                                    final cust = customerList[i];
                                    final isSelected = _selectedCustomerId == cust.id;
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: isSelected ? AppColors.primary : Colors.grey.shade200,
                                        child: Text(
                                          cust.name.isNotEmpty ? cust.name[0].toUpperCase() : '?',
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.black87,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      title: Text(cust.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w600)),
                                      subtitle: Text(cust.mobile),
                                      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
                                      onTap: () {
                                        Navigator.pop(modalCtx);
                                        setState(() {
                                          _selectedCustomerId = cust.id;
                                          _selectedCustomerName = cust.name;
                                          _selectedCustomerPhone = cust.mobile;
                                        });
                                        _fetchReport();
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _makePhoneCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available.')),
      );
      return;
    }
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _exportExcel() {
    if (_detailsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No records to export.')),
      );
      return;
    }

    final isVendorFlow = _flowTab == 'vendors';
    final reportTitle = isVendorFlow
        ? 'Vendor Payables (Shop Outgoing Due) Report'
        : 'Customer Receivables (To Collect) Report';

    final headers = [
      '#',
      'Date',
      'Type',
      'Ref Number',
      isVendorFlow ? 'Vendor / Supplier' : 'Customer Name',
      'Phone',
      'Description',
      'Total Bill (₹)',
      'Paid Amount (₹)',
      isVendorFlow ? 'Payable Due to Vendor (₹)' : 'Remaining Due from Customer (₹)',
      'Status',
    ];

    int idx = 1;
    final rows = _detailsList.map((item) {
      return [
        idx++,
        item.date,
        item.categoryLabel,
        item.refNumber,
        item.partyName,
        item.partyPhone,
        item.description,
        item.totalAmount.toStringAsFixed(2),
        item.amountPaid.toStringAsFixed(2),
        item.amountDue.toStringAsFixed(2),
        item.status.toUpperCase(),
      ];
    }).toList();

    final summaryItems = <ReportExportSummaryItem>[
      ReportExportSummaryItem(
        title: 'Customer Receivables (To Collect)',
        value: '₹ ${_summary?.totalCustomerDues.toStringAsFixed(2) ?? '0.00'}',
      ),
      ReportExportSummaryItem(
        title: 'Vendor Payables (To Pay)',
        value: '₹ ${_summary?.totalVendorDues.toStringAsFixed(2) ?? '0.00'}',
      ),
      ReportExportSummaryItem(
        title: 'Net Position Balance',
        value: '₹ ${_summary?.netBalance.toStringAsFixed(2) ?? '0.00'}',
      ),
      ReportExportSummaryItem(
        title: 'Active Tab Records',
        value: '${_detailsList.length} items',
      ),
    ];

    final totalsRow = [
      '',
      'TOTAL PENDING',
      '',
      '',
      '',
      '',
      '',
      '',
      '',
      _detailsList.fold(0.0, (sum, i) => sum + i.amountDue).toStringAsFixed(2),
      '',
    ];

    ReportExportHelper.exportToCsv(
      context: context,
      reportTitle: reportTitle,
      shopName: widget.shopName,
      period: '$_selectedPeriod | ${_flowTab.toUpperCase()}',
      headers: headers,
      rows: rows,
      summaryItems: summaryItems,
      totalsRow: totalsRow,
    );
  }

  void _exportPdf() {
    if (_detailsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No records to export.')),
      );
      return;
    }

    if (_flowTab == 'customers' && _selectedCustomerId != null) {
      CustomerOutstandingStatementPdfBuilder.downloadCustomerStatementPdf(
        context: context,
        customerName: _selectedCustomerName ?? 'Customer',
        customerPhone: _selectedCustomerPhone ?? '',
        statementPeriod: _selectedPeriod,
        items: _detailsList,
      );
      return;
    }

    final isVendorFlow = _flowTab == 'vendors';
    final reportTitle = isVendorFlow
        ? 'Vendor Payables Report (Money Shop Must Pay)'
        : 'Customer Receivables Report (Money To Collect)';

    final headers = [
      '#',
      'Date',
      'Type',
      'Ref #',
      isVendorFlow ? 'Vendor' : 'Customer',
      'Phone',
      'Total',
      'Paid',
      isVendorFlow ? 'Payable Due' : 'Customer Due',
    ];

    int idx = 1;
    final rows = _detailsList.map((item) {
      return [
        idx++,
        item.date,
        item.categoryLabel,
        item.refNumber,
        item.partyName,
        item.partyPhone,
        '₹ ${item.totalAmount.toStringAsFixed(0)}',
        '₹ ${item.amountPaid.toStringAsFixed(0)}',
        '₹ ${item.amountDue.toStringAsFixed(2)}',
      ];
    }).toList();

    final summaryItems = <ReportExportSummaryItem>[
      ReportExportSummaryItem(
        title: 'Customer Dues (To Collect)',
        value: '₹ ${_summary?.totalCustomerDues.toStringAsFixed(0) ?? '0'}',
      ),
      ReportExportSummaryItem(
        title: 'Vendor Dues (To Pay)',
        value: '₹ ${_summary?.totalVendorDues.toStringAsFixed(0) ?? '0'}',
      ),
      ReportExportSummaryItem(
        title: 'Net Position',
        value: '₹ ${_summary?.netBalance.toStringAsFixed(0) ?? '0'}',
      ),
      ReportExportSummaryItem(
        title: 'Total Records',
        value: '${_detailsList.length} items',
      ),
    ];

    final totalDueSum = _detailsList.fold(0.0, (sum, i) => sum + i.amountDue);
    final totalsRow = [
      '',
      'TOTALS',
      '',
      '',
      '',
      '',
      '',
      '',
      '₹ ${totalDueSum.toStringAsFixed(2)}',
    ];

    ReportExportHelper.exportToPdf(
      context: context,
      reportTitle: reportTitle,
      shopName: widget.shopName,
      period: '$_selectedPeriod | ${_flowTab.toUpperCase()}',
      headers: headers,
      rows: rows,
      summaryItems: summaryItems,
      totalsRow: totalsRow,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Outstanding Dues Report'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        actions: [
          ReportExportHelper.buildExportActionButton(
            onExportPdf: _exportPdf,
            onExportExcel: _exportExcel,
          ),
        ],
      ),
      body: Column(
        children: [
          // Period Selector Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildPeriodChip('all_time', 'All Time'),
                  _buildPeriodChip('this_month', 'This Month'),
                  _buildPeriodChip('today', 'Today'),
                  _buildPeriodChip('this_week', 'This Week'),
                  _buildPeriodChip('last_month', 'Last Month'),
                  _buildPeriodChip('this_year', 'This Year'),
                  _buildCustomDateChip(),
                ],
              ),
            ),
          ),

          // Primary Segmented Switch: Customers (To Collect) vs Vendors (To Pay)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  // Tab 1: Customer Receivables
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (_flowTab != 'customers') {
                          setState(() {
                            _flowTab = 'customers';
                          });
                          _fetchReport();
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _flowTab == 'customers' ? const Color(0xFF10B981) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _flowTab == 'customers'
                              ? [BoxShadow(color: const Color(0xFF10B981).withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_downward_rounded,
                                      size: 15,
                                      color: _flowTab == 'customers' ? Colors.white : const Color(0xFF10B981),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'TO COLLECT (Customers)',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: _flowTab == 'customers' ? Colors.white : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹ ${_summary?.totalCustomerDues.toStringAsFixed(0) ?? '0'}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _flowTab == 'customers' ? Colors.white : const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Tab 2: Vendor Payables
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (_flowTab != 'vendors') {
                          setState(() {
                            _flowTab = 'vendors';
                          });
                          _fetchReport();
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _flowTab == 'vendors' ? const Color(0xFFDC2626) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: _flowTab == 'vendors'
                              ? [BoxShadow(color: const Color(0xFFDC2626).withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_upward_rounded,
                                      size: 15,
                                      color: _flowTab == 'vendors' ? Colors.white : const Color(0xFFDC2626),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'TO PAY (Vendors)',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: _flowTab == 'vendors' ? Colors.white : AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹ ${_summary?.totalVendorDues.toStringAsFixed(0) ?? '0'}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _flowTab == 'vendors' ? Colors.white : const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Sub-category filters for Customer Flow (Repairs vs Sales)
          if (_flowTab == 'customers') ...[
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSubCategoryChip(
                      'all_customers',
                      'All Customer Dues',
                      '₹ ${_summary?.totalCustomerDues.toStringAsFixed(0) ?? '0'}',
                      Icons.people_alt_rounded,
                      const Color(0xFF10B981),
                    ),
                    const SizedBox(width: 8),
                    _buildSubCategoryChip(
                      'repairs',
                      'Repair Dues',
                      '₹ ${_summary?.totalRepairDues.toStringAsFixed(0) ?? '0'}',
                      Icons.build_rounded,
                      Colors.amber.shade800,
                    ),
                    const SizedBox(width: 8),
                    _buildSubCategoryChip(
                      'sales',
                      'Sales Dues',
                      '₹ ${_summary?.totalSalesDues.toStringAsFixed(0) ?? '0'}',
                      Icons.receipt_long_rounded,
                      Colors.blue.shade700,
                    ),
                  ],
                ),
              ),
            ),
            _buildCustomerFilterBar(),
          ],

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _flowTab == 'customers'
                    ? 'Search customer name, phone, job ticket, invoice...'
                    : 'Search vendor name, phone, PO number...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _fetchReport();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onSubmitted: (_) => _fetchReport(),
            ),
          ),

          // Main Content List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage!, style: const TextStyle(color: AppColors.error)),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _fetchReport, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchReport,
                        child: ListView(
                          padding: const EdgeInsets.all(16.0),
                          children: [
                            // Overall Net Financial Position Header
                            if (_summary != null) ...[
                              _buildNetPositionBanner(),
                              const SizedBox(height: 14),
                            ],

                            // Section Title & Counter
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _flowTab == 'customers' ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                      size: 18,
                                      color: _flowTab == 'customers' ? const Color(0xFF10B981) : const Color(0xFFDC2626),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _flowTab == 'customers'
                                          ? 'Customers To Collect (${_detailsList.length})'
                                          : 'Vendor Payables To Pay (${_detailsList.length})',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                    ),
                                  ],
                                ),
                                if (_detailsList.isNotEmpty)
                                  Text(
                                    'Total: ₹ ${_detailsList.fold(0.0, (s, i) => s + i.amountDue).toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: _flowTab == 'customers' ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            if (_detailsList.isEmpty)
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                                  child: Column(
                                    children: [
                                      Icon(Icons.check_circle_outline_rounded, size: 56, color: Colors.green.shade400),
                                      const SizedBox(height: 12),
                                      Text(
                                        _flowTab == 'customers'
                                            ? 'No Pending Customer Dues!'
                                            : 'No Outstanding Vendor Payables!',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _flowTab == 'customers'
                                            ? 'All repair jobs and sales invoices are fully paid.'
                                            : 'All vendor purchase orders are settled.',
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _detailsList.length,
                                separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                                itemBuilder: (ctx, idx) {
                                  final item = _detailsList[idx];
                                  return _buildOutstandingCard(item);
                                },
                              ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (val) {
          if (val) {
            setState(() {
              _selectedPeriod = period;
              _customDateRange = null;
            });
            _fetchReport();
          }
        },
      ),
    );
  }

  Widget _buildCustomDateChip() {
    final isSelected = _selectedPeriod == 'custom';
    final label = _customDateRange != null
        ? '${_customDateRange!.start.day}/${_customDateRange!.start.month} - ${_customDateRange!.end.day}/${_customDateRange!.end.month}'
        : 'Custom Range';

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        avatar: Icon(Icons.calendar_today_rounded, size: 13, color: isSelected ? Colors.white : AppColors.primary),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
        backgroundColor: isSelected ? AppColors.primary : Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: _pickCustomDateRange,
      ),
    );
  }

  Widget _buildSubCategoryChip(String cat, String label, String amount, IconData icon, Color color) {
    final isSelected = _customerSubCategory == cat;
    return InkWell(
      onTap: () {
        if (_customerSubCategory != cat) {
          setState(() {
            _customerSubCategory = cat;
          });
          _fetchReport();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? color : AppColors.textMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                amount,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerFilterBar() {
    if (_selectedCustomerId == null) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: InkWell(
          onTap: _showCustomerSelectDialog,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Row(
              children: [
                Icon(Icons.person_search_rounded, size: 18, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Filter by Customer: All Customers',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                ),
                Icon(Icons.arrow_drop_down_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person_rounded, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Customer: ',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                          ),
                          Expanded(
                            child: Text(
                              _selectedCustomerName ?? 'Customer',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (_selectedCustomerPhone != null && _selectedCustomerPhone!.isNotEmpty)
                        Text(
                          _selectedCustomerPhone!,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                  tooltip: 'Clear Customer Filter',
                  onPressed: () {
                    setState(() {
                      _selectedCustomerId = null;
                      _selectedCustomerName = null;
                      _selectedCustomerPhone = null;
                    });
                    _fetchReport();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 15),
                    label: const Text('Download PDF', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      CustomerOutstandingStatementPdfBuilder.downloadCustomerStatementPdf(
                        context: context,
                        customerName: _selectedCustomerName ?? 'Customer',
                        customerPhone: _selectedCustomerPhone ?? '',
                        statementPeriod: _selectedPeriod,
                        items: _detailsList,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.chat_rounded, size: 15),
                    label: const Text('Send on WhatsApp', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      CustomerOutstandingStatementPdfBuilder.sendStatementOnWhatsApp(
                        context: context,
                        customerName: _selectedCustomerName ?? 'Customer',
                        customerPhone: _selectedCustomerPhone ?? '',
                        statementPeriod: _selectedPeriod,
                        items: _detailsList,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetPositionBanner() {
    final net = _summary!.netBalance;
    final isPositive = net >= 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.arrow_downward_rounded, size: 13, color: Color(0xFF10B981)),
                        SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            'To Collect',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹ ${_summary!.totalCustomerDues.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: Colors.grey.shade300),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.arrow_upward_rounded, size: 13, color: Color(0xFFDC2626)),
                        SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            'To Pay',
                            style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹ ${_summary!.totalVendorDues.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 30, color: Colors.grey.shade300),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Net Position', style: TextStyle(fontSize: 11, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      '₹ ${net.abs().toStringAsFixed(0)} ${isPositive ? 'Surplus' : 'Payable'}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isPositive ? Colors.teal.shade700 : Colors.red.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOutstandingCard(OutstandingReportItem item) {
    final isCustomer = item.partyType == 'customer';

    Color flowColor = isCustomer ? const Color(0xFF10B981) : const Color(0xFFDC2626);
    Color flowBg = isCustomer ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
    String flowTitle = isCustomer ? 'RECEIVABLE FROM CUSTOMER' : 'PAYABLE TO VENDOR';
    IconData flowIcon = isCustomer ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded;

    Color badgeColor;
    Color badgeBg;
    IconData badgeIcon;

    if (item.category == 'repairs') {
      badgeColor = Colors.amber.shade900;
      badgeBg = Colors.amber.shade50;
      badgeIcon = Icons.build_rounded;
    } else if (item.category == 'sales') {
      badgeColor = Colors.blue.shade800;
      badgeBg = Colors.blue.shade50;
      badgeIcon = Icons.receipt_long_rounded;
    } else {
      badgeColor = Colors.indigo.shade800;
      badgeBg = Colors.indigo.shade50;
      badgeIcon = Icons.shopping_bag_rounded;
    }

    return CustomCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Flow Header Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: flowBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: flowColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(flowIcon, size: 12, color: flowColor),
                    const SizedBox(width: 4),
                    Text(
                      flowTitle,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: flowColor),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 11, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      item.categoryLabel.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Ref Number & Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.refNumber,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              Text(
                item.date,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Party info (Customer or Vendor)
          Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: flowColor.withOpacity(0.12),
                child: Text(
                  item.partyName.isNotEmpty ? item.partyName[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: flowColor),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isCustomer ? 'Customer: ' : 'Vendor: ',
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                        ),
                        Expanded(
                          child: Text(
                            item.partyName,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (item.partyPhone.isNotEmpty)
                      Text(
                        item.partyPhone,
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
              // Quick Actions: Statement PDF, WhatsApp and Call
              if (item.partyPhone.isNotEmpty || isCustomer) ...[
                if (isCustomer) ...[
                  InkWell(
                    onTap: () => _downloadItemCustomerPdf(item),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.picture_as_pdf_rounded, size: 14, color: Color(0xFFDC2626)),
                          SizedBox(width: 3),
                          Text('PDF', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (item.partyPhone.isNotEmpty) ...[
                  InkWell(
                    onTap: () {
                      if (isCustomer) {
                        _showCustomerShareOptions(item);
                      } else {
                        _openWhatsApp(item);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF25D366).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_rounded, size: 14, color: Color(0xFF25D366)),
                          const SizedBox(width: 4),
                          Text(
                            isCustomer ? 'Share' : 'Notify',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => _makePhoneCall(item.partyPhone),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.phone_rounded, size: 16, color: AppColors.primary),
                    ),
                  ),
                ],
              ],
            ],
          ),

          // Problem Description & Used Spare Parts / Items
          if (item.category == 'repairs') ...[
            if (item.problemDescription != null && item.problemDescription!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Problem: ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                  Expanded(
                    child: Text(
                      item.problemDescription!,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
            if (item.parts.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Used Parts: ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                  Expanded(
                    child: Text(
                      item.parts.map((p) => '${p['part_name']} (x${p['quantity'] ?? 1})').join(', '),
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFFB45309), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ],
          ] else if (item.category == 'sales' && item.items.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Items: ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                Expanded(
                  child: Text(
                    item.items.map((i) => '${i['product_name']} (x${i['quantity'] ?? 1})').join(', '),
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ] else if (item.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.description,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const Divider(height: 18),

          // Financial breakdown row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isCustomer ? 'Total Bill' : 'Purchase Total', style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                  Text('₹ ${item.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isCustomer ? 'Customer Paid' : 'Shop Paid', style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                  Text('₹ ${item.amountPaid.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCustomer ? const Color(0xFFFEF2F2) : const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isCustomer ? const Color(0xFFFCA5A5) : const Color(0xFFFDA4AF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isCustomer ? 'TO COLLECT' : 'YOU MUST PAY',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: isCustomer ? const Color(0xFF991B1B) : const Color(0xFFBE123C),
                      ),
                    ),
                    Text(
                      '₹ ${item.amountDue.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isCustomer ? const Color(0xFFDC2626) : const Color(0xFFE11D48),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
