class BusinessHealthScore {
  final int score;
  final String rating;
  final List<String> deductionReasons;

  BusinessHealthScore({
    required this.score,
    required this.rating,
    required this.deductionReasons,
  });

  factory BusinessHealthScore.fromJson(Map<String, dynamic> json) {
    return BusinessHealthScore(
      score: int.tryParse(json['score']?.toString() ?? '') ?? 100,
      rating: json['rating']?.toString() ?? 'Good',
      deductionReasons: (json['deduction_reasons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class ProblemCardSummary {
  final String title;
  final String category;
  final int count;
  final double financialImpact;
  final bool hasEnoughData;
  final String message;

  ProblemCardSummary({
    required this.title,
    required this.category,
    required this.count,
    required this.financialImpact,
    required this.hasEnoughData,
    required this.message,
  });

  factory ProblemCardSummary.fromJson(Map<String, dynamic> json) {
    return ProblemCardSummary(
      title: json['title']?.toString() ?? 'Problem',
      category: json['category']?.toString() ?? '',
      count: int.tryParse(json['count']?.toString() ?? '') ?? 0,
      financialImpact: double.tryParse(json['financial_impact']?.toString() ?? '') ?? 0.0,
      hasEnoughData: json['has_enough_data'] == true,
      message: json['message']?.toString() ?? '',
    );
  }
}

class ProfitIntelligenceData {
  final BusinessHealthScore health;
  final double potentialExtraProfit;
  final String potentialExtraProfitFormatted;
  final Map<String, ProblemCardSummary> cards;

  ProfitIntelligenceData({
    required this.health,
    required this.potentialExtraProfit,
    required this.potentialExtraProfitFormatted,
    required this.cards,
  });

  factory ProfitIntelligenceData.fromJson(Map<String, dynamic> json) {
    final cardsMap = <String, ProblemCardSummary>{};
    if (json['cards'] is Map<String, dynamic>) {
      (json['cards'] as Map<String, dynamic>).forEach((key, val) {
        if (val is Map<String, dynamic>) {
          cardsMap[key] = ProblemCardSummary.fromJson(val);
        }
      });
    }

    return ProfitIntelligenceData(
      health: BusinessHealthScore.fromJson((json['business_health'] as Map<String, dynamic>?) ?? {}),
      potentialExtraProfit: double.tryParse(json['potential_extra_profit']?.toString() ?? '') ?? 0.0,
      potentialExtraProfitFormatted: json['potential_extra_profit_formatted']?.toString() ?? '',
      cards: cardsMap,
    );
  }
}
