import 'package:equatable/equatable.dart';

class AnalyticsData extends Equatable {
  final String id;
  final String adId;
  final Map<String, double> metrics;
  final DateTime date;
  final String period; // daily, weekly, monthly
  final double impressions;
  final double clicks;
  final double conversions;
  final double cost;
  final double revenue;

  const AnalyticsData({
    required this.id,
    required this.adId,
    required this.metrics,
    required this.date,
    required this.period,
    required this.impressions,
    required this.clicks,
    required this.conversions,
    required this.cost,
    required this.revenue,
  });

  // Calculated metrics
  double get ctr => impressions > 0 ? (clicks / impressions) * 100 : 0;
  double get conversionRate => clicks > 0 ? (conversions / clicks) * 100 : 0;
  double get cpc => clicks > 0 ? cost / clicks : 0;
  double get cpa => conversions > 0 ? cost / conversions : 0;
  double get roi => cost > 0 ? ((revenue - cost) / cost) * 100 : 0;
  double get roas => cost > 0 ? revenue / cost : 0;

  AnalyticsData copyWith({
    String? id,
    String? adId,
    Map<String, double>? metrics,
    DateTime? date,
    String? period,
    double? impressions,
    double? clicks,
    double? conversions,
    double? cost,
    double? revenue,
  }) {
    return AnalyticsData(
      id: id ?? this.id,
      adId: adId ?? this.adId,
      metrics: metrics ?? this.metrics,
      date: date ?? this.date,
      period: period ?? this.period,
      impressions: impressions ?? this.impressions,
      clicks: clicks ?? this.clicks,
      conversions: conversions ?? this.conversions,
      cost: cost ?? this.cost,
      revenue: revenue ?? this.revenue,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'adId': adId,
      'metrics': metrics,
      'date': date.toIso8601String(),
      'period': period,
      'impressions': impressions,
      'clicks': clicks,
      'conversions': conversions,
      'cost': cost,
      'revenue': revenue,
      'ctr': ctr,
      'conversionRate': conversionRate,
      'cpc': cpc,
      'cpa': cpa,
      'roi': roi,
      'roas': roas,
    };
  }

  @override
  List<Object?> get props => [
        id,
        adId,
        metrics,
        date,
        period,
        impressions,
        clicks,
        conversions,
        cost,
        revenue,
      ];
}

