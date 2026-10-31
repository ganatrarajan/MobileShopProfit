import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../features/used_mobile/models/used_mobile.dart';
import 'app_feedback.dart';
import 'date_helper.dart';
import 'pdf_used_mobile_builder.dart';

class UsedMobileExportHelper {
  /// Helper to safely escape CSV cells for Microsoft Excel & Google Sheets
  static String _escapeCsv(dynamic value) {
    if (value == null) return '""';
    final str = value.toString().replaceAll('"', '""');
    return '"$str"';
  }

  /// Saves a file directly to the device's public Download or Documents folder
  static Future<File?> saveFileToDevice({
    required String fileName,
    required List<int> bytes,
  }) async {
    // 1. Primary: /storage/emulated/0/Download (Standard Android Public Download directory)
    try {
      final publicDownloadDir = Directory('/storage/emulated/0/Download');
      if (await publicDownloadDir.exists()) {
        final file = File('${publicDownloadDir.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        return file;
      }
    } catch (_) {}

    // 2. Secondary: getDownloadsDirectory()
    try {
      final dlDir = await getDownloadsDirectory();
      if (dlDir != null) {
        final file = File('${dlDir.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        return file;
      }
    } catch (_) {}

    // 3. Tertiary: getExternalStorageDirectory()
    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null) {
        final customDl = Directory('${extDir.path}/Download');
        if (!await customDl.exists()) {
          await customDl.create(recursive: true);
        }
        final file = File('${customDl.path}/$fileName');
        await file.writeAsBytes(bytes, flush: true);
        return file;
      }
    } catch (_) {}

    // 4. Fallback: getApplicationDocumentsDirectory()
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final file = File('${docDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (_) {}

    return null;
  }

  /// Shows download completion dialog with file name, storage path, Open File, and Share
  static void showDownloadSuccessDialog(
    BuildContext context, {
    required String title,
    required String fileName,
    required String filePath,
    required String mimeType,
  }) {
    // 1. Show floating notification banner with OPEN action button (matching app design)
    AppFeedback.showSuccess(
      context,
      title: '📥 Download Complete',
      message: '$fileName saved to device.',
      actionLabel: 'OPEN',
      duration: const Duration(seconds: 8),
      onAction: () async {
        await OpenFilex.open(filePath);
      },
    );

    // 2. Also open the file directly with the default app (PDF Viewer / Excel)
    OpenFilex.open(filePath);

    // 3. Persistent confirmation dialog with "Open File" and "Share" options
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF107C41).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.download_done_rounded, color: Color(0xFF107C41), size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'File saved successfully to device storage. Tap below to view:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                OpenFilex.open(filePath);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF107C41).withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Icon(
                      mimeType == 'text/csv' ? Icons.table_chart_rounded : Icons.picture_as_pdf_rounded,
                      size: 24,
                      color: mimeType == 'text/csv' ? const Color(0xFF107C41) : Colors.red,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fileName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: mimeType == 'text/csv' ? const Color(0xFF107C41) : Colors.red,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Tap to Open File ↗',
                            style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              'Location: $filePath',
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.share_outlined, size: 16),
            label: const Text('Share'),
            onPressed: () {
              Navigator.pop(ctx);
              Share.shareXFiles([XFile(filePath, mimeType: mimeType)]);
            },
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Open File', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              OpenFilex.open(filePath);
            },
          ),
        ],
      ),
    );
  }

  /// Exports list of purchased phones to Excel-compatible CSV file and downloads to device
  static Future<bool> exportPurchasesToExcel(
    BuildContext context,
    List<UsedMobile> mobiles,
  ) async {
    if (mobiles.isEmpty) {
      AppFeedback.showError(
        context,
        title: 'No Records',
        message: 'No purchased mobile records found to export.',
      );
      return false;
    }

    try {
      final buffer = StringBuffer();

      // Excel UTF-8 BOM so Excel opens Hindi / Gujarati / Special characters without corruption
      buffer.write('\uFEFF');

      // CSV Header
      buffer.writeln([
        'Purchase Ref #',
        'Purchase Date',
        'Brand',
        'Model',
        'RAM / Storage',
        'Primary IMEI 1',
        'Secondary IMEI 2',
        'Serial Number',
        'Color',
        'Condition',
        'Purchase Price (INR)',
        'Repair Cost (INR)',
        'Total Cost (INR)',
        'Payment Mode',
        'Seller Name',
        'Seller Phone',
        'Seller Address',
        'ID Proof Type',
        'ID Proof Number',
        'Current Status',
      ].map(_escapeCsv).join(','));

      // CSV Rows
      for (final m in mobiles) {
        final specs = [if (m.ram != null) m.ram, if (m.storage != null) m.storage].join(' / ');
        buffer.writeln([
          m.purchaseRefNumber,
          DateHelper.formatDate(m.purchaseDate.toIso8601String()),
          m.brand,
          m.model,
          specs,
          m.imei1,
          m.imei2 ?? '',
          m.serialNumber ?? '',
          m.color ?? '',
          m.conditionLabel,
          m.purchasePrice.toStringAsFixed(2),
          m.repairCost.toStringAsFixed(2),
          m.totalCost.toStringAsFixed(2),
          m.paymentMode,
          m.sellerName,
          m.sellerPhone,
          m.sellerAddress ?? '',
          m.idProofType ?? '',
          m.idProofNumber ?? '',
          m.isInStock ? 'In Stock' : 'Sold',
        ].map(_escapeCsv).join(','));
      }

      final nowStr = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final fileName = 'Used_Mobile_Purchases_$nowStr.csv';
      final bytes = utf8.encode(buffer.toString());

      final file = await saveFileToDevice(fileName: fileName, bytes: bytes);
      if (file == null) {
        throw Exception('Could not write file to device storage.');
      }

      if (context.mounted) {
        showDownloadSuccessDialog(
          context,
          title: 'Purchases Excel Downloaded',
          fileName: fileName,
          filePath: file.path,
          mimeType: 'text/csv',
        );
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(
          context,
          title: 'Export Failed',
          message: 'Failed to download purchases Excel: $e',
        );
      }
      return false;
    }
  }

  /// Exports list of sold phones & net profit to Excel-compatible CSV file and downloads to device
  static Future<bool> exportSalesToExcel(
    BuildContext context,
    List<UsedMobile> mobiles,
  ) async {
    final soldList = mobiles.where((m) => m.isSold || m.saleDate != null).toList();

    if (soldList.isEmpty) {
      AppFeedback.showError(
        context,
        title: 'No Sold Records',
        message: 'No sold mobile records found to export.',
      );
      return false;
    }

    try {
      final buffer = StringBuffer();
      buffer.write('\uFEFF'); // UTF-8 BOM for Excel

      // CSV Header
      buffer.writeln([
        'Sale Invoice #',
        'Sale Date',
        'Brand',
        'Model',
        'RAM / Storage',
        'IMEI 1',
        'Purchase Ref #',
        'Purchase Cost (INR)',
        'Repair Spent (INR)',
        'Total Cost (INR)',
        'Selling Price (INR)',
        'Net Profit (INR)',
        'ROI (%)',
        'Buyer Name',
        'Buyer Mobile',
        'Buyer Address',
        'Sale Payment Mode',
        'Warranty (Days)',
        'Warranty Terms',
        'Sale Remarks',
      ].map(_escapeCsv).join(','));

      // CSV Rows
      for (final m in soldList) {
        final specs = [if (m.ram != null) m.ram, if (m.storage != null) m.storage].join(' / ');
        final profit = m.profit ?? ((m.sellingPrice ?? 0.0) - m.totalCost);
        final roi = m.profitPercentage;

        buffer.writeln([
          m.saleInvoiceNumber ?? 'UMS-${m.id}',
          m.saleDate != null ? DateHelper.formatDate(m.saleDate!.toIso8601String()) : '',
          m.brand,
          m.model,
          specs,
          m.imei1,
          m.purchaseRefNumber,
          m.purchasePrice.toStringAsFixed(2),
          m.repairCost.toStringAsFixed(2),
          m.totalCost.toStringAsFixed(2),
          (m.sellingPrice ?? 0.0).toStringAsFixed(2),
          profit.toStringAsFixed(2),
          '${roi.toStringAsFixed(1)}%',
          m.buyerName ?? '',
          m.buyerPhone ?? '',
          m.buyerAddress ?? '',
          m.salePaymentMode ?? 'Cash',
          (m.warrantyDays ?? 0).toString(),
          m.warrantyTerms ?? '',
          m.saleNotes ?? '',
        ].map(_escapeCsv).join(','));
      }

      final nowStr = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final fileName = 'Used_Mobile_Sales_Profit_$nowStr.csv';
      final bytes = utf8.encode(buffer.toString());

      final file = await saveFileToDevice(fileName: fileName, bytes: bytes);
      if (file == null) {
        throw Exception('Could not write file to device storage.');
      }

      if (context.mounted) {
        showDownloadSuccessDialog(
          context,
          title: 'Sales & Profit Excel Downloaded',
          fileName: fileName,
          filePath: file.path,
          mimeType: 'text/csv',
        );
      }

      return true;
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(
          context,
          title: 'Export Failed',
          message: 'Failed to download sales Excel: $e',
        );
      }
      return false;
    }
  }

  /// Downloads Purchases Summary PDF Report directly to device storage
  static Future<bool> downloadPurchasesPdf(
    BuildContext context,
    List<UsedMobile> mobiles,
  ) async {
    if (mobiles.isEmpty) {
      AppFeedback.showError(
        context,
        title: 'No Records',
        message: 'No purchased mobile records found to export.',
      );
      return false;
    }

    try {
      final pdfBytes = await PdfUsedMobileBuilder.generatePurchasesSummaryPdfReport(mobiles);
      final nowStr = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final fileName = 'Used_Mobile_Purchases_Report_$nowStr.pdf';

      final file = await saveFileToDevice(fileName: fileName, bytes: pdfBytes);
      if (file == null) {
        throw Exception('Could not write file to device storage.');
      }

      if (context.mounted) {
        showDownloadSuccessDialog(
          context,
          title: 'Purchases PDF Report Downloaded',
          fileName: fileName,
          filePath: file.path,
          mimeType: 'application/pdf',
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(
          context,
          title: 'Download Failed',
          message: 'Failed to download PDF report: $e',
        );
      }
      return false;
    }
  }

  /// Downloads Sales & Profit Summary PDF Report directly to device storage
  static Future<bool> downloadSalesPdf(
    BuildContext context,
    List<UsedMobile> mobiles,
  ) async {
    final soldList = mobiles.where((m) => m.isSold || m.saleDate != null).toList();
    if (soldList.isEmpty) {
      AppFeedback.showError(
        context,
        title: 'No Sold Records',
        message: 'No sold mobile records found to export.',
      );
      return false;
    }

    try {
      final pdfBytes = await PdfUsedMobileBuilder.generateSalesSummaryPdfReport(soldList);
      final nowStr = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final fileName = 'Used_Mobile_Sales_Profit_Report_$nowStr.pdf';

      final file = await saveFileToDevice(fileName: fileName, bytes: pdfBytes);
      if (file == null) {
        throw Exception('Could not write file to device storage.');
      }

      if (context.mounted) {
        showDownloadSuccessDialog(
          context,
          title: 'Sales PDF Report Downloaded',
          fileName: fileName,
          filePath: file.path,
          mimeType: 'application/pdf',
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(
          context,
          title: 'Download Failed',
          message: 'Failed to download PDF report: $e',
        );
      }
      return false;
    }
  }

  /// Downloads single mobile document (Purchase Voucher or Sale Invoice) directly to device storage
  static Future<bool> downloadSingleMobilePdf(
    BuildContext context, {
    required String fileName,
    required Uint8List pdfBytes,
    required String title,
  }) async {
    try {
      final file = await saveFileToDevice(fileName: fileName, bytes: pdfBytes);
      if (file == null) {
        throw Exception('Could not write file to device storage.');
      }

      if (context.mounted) {
        showDownloadSuccessDialog(
          context,
          title: '$title Downloaded',
          fileName: fileName,
          filePath: file.path,
          mimeType: 'application/pdf',
        );
      }
      return true;
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showError(
          context,
          title: 'Download Failed',
          message: 'Failed to download PDF: $e',
        );
      }
      return false;
    }
  }
}
