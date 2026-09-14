import '../../../core/utils/whatsapp_helper.dart';
import '../../../core/widgets/whatsapp_icon.dart';
import 'package:pdf/pdf.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/pdf_invoice_builder.dart';
import '../models/repair.dart';

class RepairInvoicePdfScreen extends StatelessWidget {
  final Repair repair;

  const RepairInvoicePdfScreen({super.key, required this.repair});

  static void show(BuildContext context, Repair repair) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RepairInvoicePdfScreen(repair: repair),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final jobNum = repair.jobNumber.isNotEmpty ? repair.jobNumber : 'REP-${repair.id}';

    return Scaffold(
      appBar: AppBar(
        title: Text('Repair Ticket #$jobNum', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const WhatsAppIcon(size: 22),
            tooltip: 'Send PDF on WhatsApp',
            onPressed: () async {
              await WhatsAppHelper.shareRepairPdfInvoice(context, repair);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.primary),
            tooltip: 'Share Repair Ticket PDF',
            onPressed: () async {
              final pdfBytes = await PdfInvoiceBuilder.generateRepairPdf(repair);
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: 'Repair_Ticket_$jobNum.pdf',
              );
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          return PdfPreview(
            build: (format) => PdfInvoiceBuilder.generateRepairPdf(repair),
            allowPrinting: true,
            allowSharing: true,
            canChangeOrientation: false,
            canChangePageFormat: false,
            maxPageWidth: screenWidth * 0.96,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            initialPageFormat: PdfPageFormat.a4,
            pdfFileName: 'Repair_Ticket_$jobNum.pdf',
          );
        },
      ),
    );
  }
}
