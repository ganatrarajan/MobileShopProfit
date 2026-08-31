class BusinessRecommendation {
  final String id;
  final String priority;
  final String priorityBadge;
  final String type;
  final String title;
  final String shortMessage;
  final String reason;
  final String suggestedAction;
  final String? potentialBenefit;
  final String actionType;
  final String actionButtonText;
  final String route;

  const BusinessRecommendation({
    required this.id,
    required this.priority,
    required this.priorityBadge,
    required this.type,
    required this.title,
    required this.shortMessage,
    required this.reason,
    required this.suggestedAction,
    this.potentialBenefit,
    required this.actionType,
    required this.actionButtonText,
    required this.route,
  });

  factory BusinessRecommendation.fromJson(Map<String, dynamic> json) {
    return BusinessRecommendation(
      id: json['id'] as String? ?? '',
      priority: json['priority'] as String? ?? 'low',
      priorityBadge: json['priority_badge'] as String? ?? '🟢 Low',
      type: json['type'] as String? ?? 'general',
      title: json['title'] as String? ?? 'RECOMMENDATION',
      shortMessage: json['short_message'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      suggestedAction: json['suggested_action'] as String? ?? '',
      potentialBenefit: json['potential_benefit'] as String?,
      actionType: json['action_type'] as String? ?? 'navigate',
      actionButtonText: json['action_button_text'] as String? ?? 'View Details',
      route: json['route'] as String? ?? '/dashboard',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'priority': priority,
      'priority_badge': priorityBadge,
      'type': type,
      'title': title,
      'short_message': shortMessage,
      'reason': reason,
      'suggested_action': suggestedAction,
      'potential_benefit': potentialBenefit,
      'action_type': actionType,
      'action_button_text': actionButtonText,
      'route': route,
    };
  }
}

class BusinessAssistantResponse {
  final bool hasSufficientData;
  final String? notice;
  final int totalActionsCount;
  final List<BusinessRecommendation> recommendations;

  const BusinessAssistantResponse({
    required this.hasSufficientData,
    this.notice,
    required this.totalActionsCount,
    required this.recommendations,
  });

  factory BusinessAssistantResponse.fromJson(Map<String, dynamic> json) {
    final list = json['recommendations'] as List<dynamic>? ?? [];
    final recs = list.map((item) => BusinessRecommendation.fromJson(item as Map<String, dynamic>)).toList();

    return BusinessAssistantResponse(
      hasSufficientData: json['has_sufficient_data'] as bool? ?? false,
      notice: json['notice'] as String?,
      totalActionsCount: json['total_actions_count'] as int? ?? 0,
      recommendations: recs,
    );
  }
}
