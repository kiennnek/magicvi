import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/analytics_data.dart';

part 'analytics_model.g.dart';

@HiveType(typeId: 2)
@JsonSerializable()
class AnalyticsDataModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String adId;

  @HiveField(2)
  final Map<String, double> metrics;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String period;

  @HiveField(5)
  final double impressions;

  @HiveField(6)
  final double clicks;

  @HiveField(7)
  final double conversions;

  @HiveField(8)
  final double cost;

  @HiveField(9)
  final double revenue;

  AnalyticsDataModel({
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

  // Convert from Entity to Model
  factory AnalyticsDataModel.fromEntity(AnalyticsData entity) {
    return AnalyticsDataModel(
      id: entity.id,
      adId: entity.adId,
      metrics: entity.metrics,
      date: entity.date,
      period: entity.period,
      impressions: entity.impressions,
      clicks: entity.clicks,
      conversions: entity.conversions,
      cost: entity.cost,
      revenue: entity.revenue,
    );
  }

  // Convert from Model to Entity
  AnalyticsData toEntity() {
    return AnalyticsData(
      id: id,
      adId: adId,
      metrics: metrics,
      date: date,
      period: period,
      impressions: impressions,
      clicks: clicks,
      conversions: conversions,
      cost: cost,
      revenue: revenue,
    );
  }

  // JSON serialization
  factory AnalyticsDataModel.fromJson(Map<String, dynamic> json) =>
      _$AnalyticsDataModelFromJson(json);

  Map<String, dynamic> toJson() => _$AnalyticsDataModelToJson(this);

  // Calculated metrics (same as entity)
  double get ctr => impressions > 0 ? (clicks / impressions) * 100 : 0;
  double get conversionRate => clicks > 0 ? (conversions / clicks) * 100 : 0;
  double get cpc => clicks > 0 ? cost / clicks : 0;
  double get cpa => conversions > 0 ? cost / conversions : 0;
  double get roi => cost > 0 ? ((revenue - cost) / cost) * 100 : 0;
  double get roas => cost > 0 ? revenue / cost : 0;

  AnalyticsDataModel copyWith({
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
    return AnalyticsDataModel(
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

  @override
  String toString() {
    return 'AnalyticsDataModel(id: $id, adId: $adId, period: $period, impressions: $impressions, clicks: $clicks, cost: $cost, revenue: $revenue)';
  }
}

