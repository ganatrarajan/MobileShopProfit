class RecommendationItem {
  final String id;
  final String category;
  final String priority; // 'High', 'Medium', 'Low'
  final String priorityLabel; // '🔴 High', '🟠 Medium', '🟢 Low'
  final String title;
  final String problem;
  final String whyItMatters;
  final String recommendation;
  final String potentialBenefit;
  final String relatedModule; // 'customers', 'repairs', 'inventory', 'warranty', 'expenses'
  final String actionTitle;
  final String actionRoute;
  final List<dynamic>? topCustomers;
  final List<dynamic>? details;

  RecommendationItem({
    required this.id,
    required this.category,
    required this.priority,
    required this.priorityLabel,
    required this.title,
    required this.problem,
    required this.whyItMatters,
    required this.recommendation,
    required this.potentialBenefit,
    required this.relatedModule,
    required this.actionTitle,
    required this.actionRoute,
    this.topCustomers,
    this.details,
  });

  factory RecommendationItem.fromJson(Map<String, dynamic> json) {
    return RecommendationItem(
      id: json['id'] ?? '',
      category: json['category'] ?? '',
      priority: json['priority'] ?? 'Low',
      priorityLabel: json['priority_label'] ?? '🟢 Low',
      title: json['title'] ?? '',
      problem: json['problem'] ?? '',
      whyItMatters: json['why_it_matters'] ?? '',
      recommendation: json['recommendation'] ?? '',
      potentialBenefit: json['potential_benefit'] ?? '',
      relatedModule: json['related_module'] ?? '',
      actionTitle: json['action_title'] ?? 'View Details',
      actionRoute: json['action_route'] ?? '',
      topCustomers: json['top_customers'],
      details: json['details'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'priority': priority,
      'priority_label': priorityLabel,
      'title': title,
      'problem': problem,
      'why_it_matters': whyItMatters,
      'recommendation': recommendation,
      'potential_benefit': potentialBenefit,
      'related_module': relatedModule,
      'action_title': actionTitle,
      'action_route': actionRoute,
      'top_customers': topCustomers,
      'details': details,
    };
  }
}
