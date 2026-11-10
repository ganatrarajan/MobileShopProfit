import '../../repair/models/repair.dart';

class TechnicianWorkload {
  final int pendingJobs;
  final int inProgressJobs;
  final int completedJobs;
  final int totalJobs;
  final double totalValueHandled;
  final double totalEarnings;
  final double totalPaid;
  final double totalPayable;

  TechnicianWorkload({
    required this.pendingJobs,
    required this.inProgressJobs,
    required this.completedJobs,
    required this.totalJobs,
    required this.totalValueHandled,
    this.totalEarnings = 0.0,
    this.totalPaid = 0.0,
    this.totalPayable = 0.0,
  });

  factory TechnicianWorkload.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return TechnicianWorkload(
      pendingJobs: parseInt(json['pending_jobs']),
      inProgressJobs: parseInt(json['in_progress_jobs']),
      completedJobs: parseInt(json['completed_jobs']),
      totalJobs: parseInt(json['total_jobs']),
      totalValueHandled: parseDouble(json['total_value_handled']),
      totalEarnings: parseDouble(json['total_earnings']),
      totalPaid: parseDouble(json['total_paid']),
      totalPayable: parseDouble(json['total_payable']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pending_jobs': pendingJobs,
      'in_progress_jobs': inProgressJobs,
      'completed_jobs': completedJobs,
      'total_jobs': totalJobs,
      'total_value_handled': totalValueHandled,
      'total_earnings': totalEarnings,
      'total_paid': totalPaid,
      'total_payable': totalPayable,
    };
  }
}

class Technician {
  final int id;
  final int shopId;
  final String name;
  final String? mobile;
  final String? specialization;
  final bool isActive;
  final String? createdAt;
  final TechnicianWorkload workload;
  final List<Repair> recentJobs;

  Technician({
    required this.id,
    required this.shopId,
    required this.name,
    this.mobile,
    this.specialization,
    required this.isActive,
    this.createdAt,
    required this.workload,
    this.recentJobs = const [],
  });

  factory Technician.fromJson(Map<String, dynamic> json) {
    List<Repair> jobs = [];
    if (json['recent_jobs'] is List) {
      jobs = (json['recent_jobs'] as List)
          .map((item) => Repair.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    return Technician(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      shopId: json['shop_id'] is int ? json['shop_id'] : int.tryParse(json['shop_id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString(),
      specialization: json['specialization']?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      createdAt: json['created_at']?.toString(),
      workload: json['workload'] is Map
          ? TechnicianWorkload.fromJson(Map<String, dynamic>.from(json['workload']))
          : TechnicianWorkload(
              pendingJobs: 0,
              inProgressJobs: 0,
              completedJobs: 0,
              totalJobs: 0,
              totalValueHandled: 0.0,
            ),
      recentJobs: jobs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Technician && other.id == id);

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'name': name,
      'mobile': mobile,
      'specialization': specialization,
      'is_active': isActive,
      'created_at': createdAt,
      'workload': workload.toJson(),
    };
  }
}