class Recommendation {
  final String id;
  final String priority; // 'high', 'medium', 'low'
  final String type;
  final String title;
  final String shortMessage;
  final String reason;
  final String suggestedAction;
  final String? potentialBenefit;
  final String actionType;
  final String actionRoute;
  final String? actionFilter;
  final String buttonText;

  Recommendation({
    required this.id,
    required this.priority,
    required this.type,
    required this.title,
    required this.shortMessage,
    required this.reason,
    required this.suggestedAction,
    this.potentialBenefit,
    required this.actionType,
    required this.actionRoute,
    this.actionFilter,
    required this.buttonText,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json['id'] ?? '',
      priority: json['priority'] ?? 'medium',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      shortMessage: json['short_message'] ?? '',
      reason: json['reason'] ?? '',
      suggestedAction: json['suggested_action'] ?? '',
      potentialBenefit: json['potential_benefit'],
      actionType: json['action_type'] ?? 'navigate',
      actionRoute: json['action_route'] ?? '',
      actionFilter: json['action_filter'],
      buttonText: json['button_text'] ?? 'View Details',
    );
  }
}

class BusinessAssistantData {
  final bool hasEnoughData;
  final String message;
  final int totalCount;
  final Map<String, int> priorityCounts;
  final List<Recommendation> recommendations;

  BusinessAssistantData({
    required this.hasEnoughData,
    required this.message,
    required this.totalCount,
    required this.priorityCounts,
    required this.recommendations,
  });

  factory BusinessAssistantData.fromJson(Map<String, dynamic> json) {
    final list = (json['recommendations'] as List<dynamic>?)
            ?.map((e) => Recommendation.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final pCounts = (json['priority_counts'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ) ??
        {'high': 0, 'medium': 0, 'low': 0};

    return BusinessAssistantData(
      hasEnoughData: json['has_enough_data'] ?? false,
      message: json['message'] ?? '',
      totalCount: json['total_count'] ?? list.length,
      priorityCounts: pCounts,
      recommendations: list,
    );
  }
}
