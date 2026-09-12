import 'package:pdf/pdf.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/pdf_invoice_builder.dart';
import '../models/sale.dart';

class SaleInvoicePdfScreen extends StatelessWidget {
  final Sale sale;

  const SaleInvoicePdfScreen({super.key, required this.sale});

  static void show(BuildContext context, Sale sale) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SaleInvoicePdfScreen(sale: sale),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoiceNum = sale.invoiceNumber.isNotEmpty ? sale.invoiceNumber : 'INV-${sale.id}';

    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice #$invoiceNum', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded, color: AppColors.primary),
            tooltip: 'Share Invoice PDF',
            onPressed: () async {
              final pdfBytes = await PdfInvoiceBuilder.generateInvoicePdf(sale);
              await Printing.sharePdf(
                bytes: pdfBytes,
                filename: 'Invoice_$invoiceNum.pdf',
              );
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          return PdfPreview(
            build: (format) => PdfInvoiceBuilder.generateInvoicePdf(sale),
            allowPrinting: true,
            allowSharing: true,
            canChangeOrientation: false,
            canChangePageFormat: false,
            maxPageWidth: screenWidth * 0.96,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            initialPageFormat: PdfPageFormat.a4,
            pdfFileName: 'Invoice_$invoiceNum.pdf',
          );
        },
      ),
    );
  }
}