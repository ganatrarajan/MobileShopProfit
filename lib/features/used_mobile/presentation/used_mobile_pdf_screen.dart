import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/pdf_used_mobile_builder.dart';
import '../../../core/utils/used_mobile_export_helper.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../core/widgets/whatsapp_icon.dart';
import '../models/used_mobile.dart';

enum UsedMobilePdfType {
  purchaseAgreement,
  saleInvoice,
  purchasesReport,
  salesReport,
}

class UsedMobilePdfScreen extends StatelessWidget {
  final UsedMobile? mobile;
  final List<UsedMobile>? mobilesList;
  final UsedMobilePdfType type;

  const UsedMobilePdfScreen({
    super.key,
    this.mobile,
    this.mobilesList,
    required this.type,
  });

  static void show(BuildContext context, UsedMobile mobile, UsedMobilePdfType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UsedMobilePdfScreen(mobile: mobile, type: type),
      ),
    );
  }

  static void showReport(BuildContext context, List<UsedMobile> list, UsedMobilePdfType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UsedMobilePdfScreen(mobilesList: list, type: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isReport = type == UsedMobilePdfType.purchasesReport || type == UsedMobilePdfType.salesReport;
    final isPurchaseAgreement = type == UsedMobilePdfType.purchaseAgreement;

    String title;
    if (type == UsedMobilePdfType.purchasesReport) {
      title = 'Used Mobiles Purchase Report';
    } else if (type == UsedMobilePdfType.salesReport) {
      title = 'Sales & Net Profit Report';
    } else if (isPurchaseAgreement) {
      title = 'Purchase Voucher #${mobile?.purchaseRefNumber ?? ""}';
    } else {
      title = 'Sale Invoice #${mobile?.saleInvoiceNumber ?? mobile?.id ?? ""}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (!isReport && mobile != null)
            IconButton(
              icon: const WhatsAppIcon(size: 22),
              tooltip: isPurchaseAgreement ? 'Send Receipt on WhatsApp' : 'Send Invoice on WhatsApp',
              onPressed: () async {
                if (isPurchaseAgreement) {
                  await WhatsAppHelper.sendUsedMobilePurchaseWhatsAppMessage(context, mobile!);
                } else {
                  await WhatsAppHelper.sendUsedMobileSaleWhatsAppMessage(context, mobile!);
                }
              },
            ),
          // Direct Download to Local Device
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Download to Device',
            onPressed: () async {
              Uint8List pdfBytes;
              String filename;
              String docTitle;

              if (type == UsedMobilePdfType.purchasesReport) {
                await UsedMobileExportHelper.downloadPurchasesPdf(context, mobilesList ?? []);
                return;
              } else if (type == UsedMobilePdfType.salesReport) {
                await UsedMobileExportHelper.downloadSalesPdf(context, mobilesList ?? []);
                return;
              } else if (isPurchaseAgreement && mobile != null) {
                pdfBytes = await PdfUsedMobileBuilder.generatePurchaseAgreementPdf(mobile!);
                filename = 'Purchase_Agreement_${mobile!.purchaseRefNumber}.pdf';
                docTitle = 'Purchase Agreement';
              } else {
                pdfBytes = await PdfUsedMobileBuilder.generateSaleInvoicePdf(mobile!);
                filename = 'Sale_Invoice_${mobile!.saleInvoiceNumber ?? mobile!.id}.pdf';
                docTitle = 'Sale Invoice';
              }

              if (!context.mounted) return;
              await UsedMobileExportHelper.downloadSingleMobilePdf(
                context,
                fileName: filename,
                pdfBytes: pdfBytes,
                title: docTitle,
              );
            },
          ),
          // Share via Apps (Optional)
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            tooltip: 'Share PDF',
            onPressed: () async {
              Uint8List pdfBytes;
              String filename;

              if (type == UsedMobilePdfType.purchasesReport) {
                pdfBytes = await PdfUsedMobileBuilder.generatePurchasesSummaryPdfReport(mobilesList ?? []);
                filename = 'Used_Mobile_Purchases_Report.pdf';
              } else if (type == UsedMobilePdfType.salesReport) {
                pdfBytes = await PdfUsedMobileBuilder.generateSalesSummaryPdfReport(mobilesList ?? []);
                filename = 'Used_Mobile_Sales_Profit_Report.pdf';
              } else if (isPurchaseAgreement && mobile != null) {
                pdfBytes = await PdfUsedMobileBuilder.generatePurchaseAgreementPdf(mobile!);
                filename = 'Purchase_Agreement_${mobile!.purchaseRefNumber}.pdf';
              } else {
                pdfBytes = await PdfUsedMobileBuilder.generateSaleInvoicePdf(mobile!);
                filename = 'Sale_Invoice_${mobile!.saleInvoiceNumber ?? mobile!.id}.pdf';
              }

              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: filename,
              );
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) {
          if (type == UsedMobilePdfType.purchasesReport) {
            return PdfUsedMobileBuilder.generatePurchasesSummaryPdfReport(mobilesList ?? []);
          } else if (type == UsedMobilePdfType.salesReport) {
            return PdfUsedMobileBuilder.generateSalesSummaryPdfReport(mobilesList ?? []);
          } else if (isPurchaseAgreement && mobile != null) {
            return PdfUsedMobileBuilder.generatePurchaseAgreementPdf(mobile!);
          } else {
            return PdfUsedMobileBuilder.generateSaleInvoicePdf(mobile!);
          }
        },
        allowPrinting: true,
        allowSharing: false, // Owner uses Download button
        canChangePageFormat: false,
        canChangeOrientation: false,
        initialPageFormat: PdfPageFormat.a4,
      ),
    );
  }
}

