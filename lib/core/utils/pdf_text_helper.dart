import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfTextHelper {
  /// Sanitize and normalize any text before rendering in PDF documents.
  /// Replaces non-standard quotation marks (curly / smart quotes, primes, backticks),
  /// apostrophes (like "customer's", "buyer’s risk"), dashes, bullets, rupee signs,
  /// and zero-width spaces with standard ASCII characters so standard PDF fonts
  /// render them cleanly without showing missing glyph icons, squares or broken symbols.
  static String sanitize(String? text) {
    if (text == null || text.isEmpty) return '';
    var result = text;

    // 1. Replace smart single quotes, curly apostrophes, primes, grave/acute accents with standard ASCII '
    // e.g. "customer's", "buyer’s risk.", "it’s", "‘hello’"
    result = result.replaceAll(
      RegExp(r"[\u2018\u2019\u201A\u201B\u02BC\u02BD\u02BB\u2032\u2035\u0060\u00B4]"),
      "'",
    );

    // 2. Replace smart double quotes, curly quotes, double primes with standard ASCII "
    // e.g. “buyer’s risk.”, „quote”, ‟quote”
    result = result.replaceAll(
      RegExp(r'[\u201C\u201D\u201E\u201F\u2033\u2036]'),
      '"',
    );

    // 3. Replace en-dash, em-dash, figure dash, horizontal bar with standard ASCII -
    result = result.replaceAll(
      RegExp(r'[\u2010\u2011\u2012\u2013\u2014\u2015\u2212]'),
      '-',
    );

    // 4. Replace bullets, black circle, square with -
    result = result.replaceAll(
      RegExp(r'[\u2022\u25CF\u25AA\u25E6\u2219]'),
      '-',
    );

    // 5. Replace ellipsis
    result = result.replaceAll('\u2026', '...');

    // 6. Replace Indian Rupee symbol with Rs.
    result = result.replaceAll('₹', 'Rs. ');

    // 7. Remove invisible / zero-width characters
    result = result.replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '');

    // 8. Replace non-breaking spaces with standard space
    result = result.replaceAll('\u00A0', ' ');

    return result;
  }

  /// Parse terms and conditions string into a list of sanitized bullet lines
  static List<String> parseTerms(dynamic rawTerms, {List<String>? defaultTerms}) {
    if (rawTerms != null && rawTerms.toString().trim().isNotEmpty) {
      final list = rawTerms
          .toString()
          .split('\n')
          .map((e) => sanitize(e.trim()))
          .where((e) => e.isNotEmpty)
          .toList();
      if (list.isNotEmpty) return list;
    }
    if (defaultTerms != null && defaultTerms.isNotEmpty) {
      return defaultTerms.map((e) => sanitize(e)).toList();
    }
    return [
      '1. Goods once sold will be covered strictly as per warranty terms.',
      '2. Physical damage, liquid exposure, or unauthorized tampering voids all warranty.',
      '3. Please present this bill for any warranty claims or queries.',
    ];
  }

  /// Build a clean, styled Terms & Conditions widget for PDF documents
  static pw.Widget buildTermsWidget({
    required List<String> terms,
    String title = 'Terms & Conditions:',
    PdfColor? titleColor,
    PdfColor? textColor,
    double titleSize = 8.5,
    double textSize = 7.5,
    double itemSpacing = 1.5,
  }) {
    if (terms.isEmpty) return pw.SizedBox.shrink();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: titleSize,
            fontWeight: pw.FontWeight.bold,
            color: titleColor ?? PdfColors.blueGrey900,
          ),
        ),
        pw.SizedBox(height: 2),
        ...terms.map(
          (term) => pw.Padding(
            padding: pw.EdgeInsets.only(bottom: itemSpacing),
            child: pw.Text(
              sanitize(term),
              style: pw.TextStyle(
                fontSize: textSize,
                color: textColor ?? PdfColors.blueGrey700,
                height: 1.25,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
