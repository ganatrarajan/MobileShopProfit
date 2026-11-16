enum GstMode {
  exclusive, // Tax added on top of base price (Base + GST = Total)
  inclusive, // Price already contains tax (Total includes Base + GST)
}

class GstCalculationResult {
  final bool isEnabled;
  final GstMode mode;
  final double rate;
  final bool isInterState;
  final double enteredAmount;
  final double taxableAmount; // Base price before tax
  final double taxAmount;     // Total GST amount
  final double cgstAmount;    // Central GST (50% of tax if Intra-State)
  final double sgstAmount;    // State GST (50% of tax if Intra-State)
  final double igstAmount;    // Integrated GST (100% of tax if Inter-State)
  final double totalPayable;  // Net final amount (Base + Tax)

  const GstCalculationResult({
    required this.isEnabled,
    required this.mode,
    required this.rate,
    required this.isInterState,
    required this.enteredAmount,
    required this.taxableAmount,
    required this.taxAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.totalPayable,
  });

  factory GstCalculationResult.disabled({double amount = 0.0}) {
    return GstCalculationResult(
      isEnabled: false,
      mode: GstMode.exclusive,
      rate: 0.0,
      isInterState: false,
      enteredAmount: amount,
      taxableAmount: amount,
      taxAmount: 0.0,
      cgstAmount: 0.0,
      sgstAmount: 0.0,
      igstAmount: 0.0,
      totalPayable: amount,
    );
  }
}

class GstCalculator {
  static const List<double> standardSlabs = [0.0, 5.0, 12.0, 18.0, 28.0];

  /// Calculate GST given the entered amount, rate, mode, and whether it's inter-state.
  static GstCalculationResult calculate({
    required double amount,
    required double rate,
    GstMode mode = GstMode.exclusive,
    bool isInterState = false,
    bool isEnabled = true,
  }) {
    if (!isEnabled || rate <= 0 || amount <= 0) {
      return GstCalculationResult.disabled(amount: amount);
    }

    double taxable = 0.0;
    double tax = 0.0;
    double finalAmount = 0.0;

    if (mode == GstMode.inclusive) {
      // Amount entered already includes GST
      // Formula: Base = Gross / (1 + Rate / 100)
      taxable = amount / (1.0 + (rate / 100.0));
      tax = amount - taxable;
      finalAmount = amount;
    } else {
      // Amount entered is Base/Taxable, GST is added on top
      // Formula: Tax = Base * (Rate / 100), Total = Base + Tax
      taxable = amount;
      tax = amount * (rate / 100.0);
      finalAmount = amount + tax;
    }

    // Rounding to 2 decimal places standard for Indian currency
    taxable = double.parse(taxable.toStringAsFixed(2));
    tax = double.parse(tax.toStringAsFixed(2));
    finalAmount = double.parse(finalAmount.toStringAsFixed(2));

    double cgst = 0.0;
    double sgst = 0.0;
    double igst = 0.0;

    if (isInterState) {
      igst = tax;
    } else {
      // Split 50-50 between Central and State GST
      cgst = double.parse((tax / 2.0).toStringAsFixed(2));
      sgst = double.parse((tax - cgst).toStringAsFixed(2));
    }

    return GstCalculationResult(
      isEnabled: true,
      mode: mode,
      rate: rate,
      isInterState: isInterState,
      enteredAmount: amount,
      taxableAmount: taxable,
      taxAmount: tax,
      cgstAmount: cgst,
      sgstAmount: sgst,
      igstAmount: igst,
      totalPayable: finalAmount,
    );
  }
}

