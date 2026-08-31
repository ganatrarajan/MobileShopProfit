class TechnicianPayment {
  final int id;
  final int shopId;
  final int technicianId;
  final int? repairId;
  final String? repairJobNumber;
  final double amount;
  final String paymentDate;
  final String paymentMethod;
  final String? notes;
  final String? creatorName;

  TechnicianPayment({
    required this.id,
    required this.shopId,
    required this.technicianId,
    this.repairId,
    this.repairJobNumber,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.notes,
    this.creatorName,
  });

  factory TechnicianPayment.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    String? jobNo;
    if (json['repair'] is Map) {
      jobNo = json['repair']['job_number'];
    }

    return TechnicianPayment(
      id: parseInt(json['id']),
      shopId: parseInt(json['shop_id']),
      technicianId: parseInt(json['technician_id']),
      repairId: json['repair_id'] != null ? parseInt(json['repair_id']) : null,
      repairJobNumber: jobNo,
      amount: parseDouble(json['amount']),
      paymentDate: json['payment_date']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      notes: json['notes']?.toString(),
      creatorName: json['creator'] is Map ? json['creator']['name'] : null,
    );
  }
}