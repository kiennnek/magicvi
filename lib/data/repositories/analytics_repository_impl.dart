import 'dart:async';
import '../../domain/entities/analytics_data.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../datasources/local/hive_database.dart';
import '../models/analytics_model.dart';
import '../../core/errors/exceptions.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final StreamController<List<AnalyticsData>> _analyticsController = 
      StreamController<List<AnalyticsData>>.broadcast();

  @override
  Future<List<AnalyticsData>> getAllAnalytics() async {
    try {
      final models = HiveDatabase.getAllAnalytics();
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw DatabaseException('Failed to get all analytics: $e');
    }
  }

  @override
  Future<void> saveAnalyticsData(AnalyticsData data) async {
    try {
      final model = AnalyticsDataModel.fromEntity(data);
      await HiveDatabase.saveAnalyticsData(model);
      _notifyAnalyticsChanged();
    } catch (e) {
      throw DatabaseException('Failed to save analytics data: $e');
    }
  }

  @override
  Future<void> deleteAnalyticsData(String id) async {
    try {
      await HiveDatabase.deleteAnalyticsData(id);
      _notifyAnalyticsChanged();
    } catch (e) {
      throw DatabaseException('Failed to delete analytics data: $e');
    }
  }

  @override
  Future<void> updateAnalyticsData(AnalyticsData data) async {
    try {
      final model = AnalyticsDataModel.fromEntity(data);
      await HiveDatabase.saveAnalyticsData(model);
      _notifyAnalyticsChanged();
    } catch (e) {
      throw DatabaseException('Failed to update analytics data: $e');
    }
  }

  @override
  Future<AnalyticsData?> getAnalyticsById(String id) async {
    try {
      final model = HiveDatabase.analyticsBox.get(id);
      return model?.toEntity();
    } catch (e) {
      throw DatabaseException('Failed to get analytics by id: $e');
    }
  }

  @override
  Future<List<AnalyticsData>> getAnalyticsByAdId(String adId) async {
    try {
      final models = HiveDatabase.getAnalyticsByAdId(adId);
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw DatabaseException('Failed to get analytics by ad id: $e');
    }
  }

  @override
  Future<List<AnalyticsData>> getAnalyticsByPeriod(String period) async {
    try {
      final allAnalytics = await getAllAnalytics();
      return allAnalytics.where((data) => data.period == period).toList();
    } catch (e) {
      throw DatabaseException('Failed to get analytics by period: $e');
    }
  }

  @override
  Future<List<AnalyticsData>> getAnalyticsByDateRange(
      DateTime start, DateTime end) async {
    try {
      final allAnalytics = await getAllAnalytics();
      return allAnalytics
          .where((data) =>
              data.date.isAfter(start.subtract(Duration(days: 1))) &&
              data.date.isBefore(end.add(Duration(days: 1))))
          .toList();
    } catch (e) {
      throw DatabaseException('Failed to get analytics by date range: $e');
    }
  }

  @override
  Stream<List<AnalyticsData>> watchAnalytics() {
    // Initial load
    getAllAnalytics().then((analytics) {
      if (!_analyticsController.isClosed) {
        _analyticsController.add(analytics);
      }
    });
    
    return _analyticsController.stream;
  }

  @override
  Future<Map<String, double>> getTotalMetrics() async {
    try {
      final allAnalytics = await getAllAnalytics();
      final totals = <String, double>{
        'impressions': 0,
        'clicks': 0,
        'conversions': 0,
        'cost': 0,
        'revenue': 0,
      };

      for (final data in allAnalytics) {
        totals['impressions'] = (totals['impressions'] ?? 0) + data.impressions;
        totals['clicks'] = (totals['clicks'] ?? 0) + data.clicks;
        totals['conversions'] = (totals['conversions'] ?? 0) + data.conversions;
        totals['cost'] = (totals['cost'] ?? 0) + data.cost;
        totals['revenue'] = (totals['revenue'] ?? 0) + data.revenue;
      }

      // Calculate derived metrics
      totals['ctr'] = totals['impressions']! > 0 
          ? (totals['clicks']! / totals['impressions']!) * 100 
          : 0;
      totals['conversion_rate'] = totals['clicks']! > 0 
          ? (totals['conversions']! / totals['clicks']!) * 100 
          : 0;
      totals['cpc'] = totals['clicks']! > 0 
          ? totals['cost']! / totals['clicks']! 
          : 0;
      totals['cpa'] = totals['conversions']! > 0 
          ? totals['cost']! / totals['conversions']! 
          : 0;
      totals['roi'] = totals['cost']! > 0 
          ? ((totals['revenue']! - totals['cost']!) / totals['cost']!) * 100 
          : 0;
      totals['roas'] = totals['cost']! > 0 
          ? totals['revenue']! / totals['cost']! 
          : 0;

      return totals;
    } catch (e) {
      throw DatabaseException('Failed to get total metrics: $e');
    }
  }

  @override
  Future<Map<String, double>> getMetricsByAdId(String adId) async {
    try {
      final analytics = await getAnalyticsByAdId(adId);
      final totals = <String, double>{
        'impressions': 0,
        'clicks': 0,
        'conversions': 0,
        'cost': 0,
        'revenue': 0,
      };

      for (final data in analytics) {
        totals['impressions'] = (totals['impressions'] ?? 0) + data.impressions;
        totals['clicks'] = (totals['clicks'] ?? 0) + data.clicks;
        totals['conversions'] = (totals['conversions'] ?? 0) + data.conversions;
        totals['cost'] = (totals['cost'] ?? 0) + data.cost;
        totals['revenue'] = (totals['revenue'] ?? 0) + data.revenue;
      }

      // Calculate derived metrics
      if (analytics.isNotEmpty) {
        final lastData = analytics.first;
        totals['ctr'] = lastData.ctr;
        totals['conversion_rate'] = lastData.conversionRate;
        totals['cpc'] = lastData.cpc;
        totals['cpa'] = lastData.cpa;
        totals['roi'] = lastData.roi;
        totals['roas'] = lastData.roas;
      }

      return totals;
    } catch (e) {
      throw DatabaseException('Failed to get metrics by ad id: $e');
    }
  }

  @override
  Future<Map<String, double>> getMetricsByPeriod(String period) async {
    try {
      final analytics = await getAnalyticsByPeriod(period);
      final totals = <String, double>{
        'impressions': 0,
        'clicks': 0,
        'conversions': 0,
        'cost': 0,
        'revenue': 0,
      };

      for (final data in analytics) {
        totals['impressions'] = (totals['impressions'] ?? 0) + data.impressions;
        totals['clicks'] = (totals['clicks'] ?? 0) + data.clicks;
        totals['conversions'] = (totals['conversions'] ?? 0) + data.conversions;
        totals['cost'] = (totals['cost'] ?? 0) + data.cost;
        totals['revenue'] = (totals['revenue'] ?? 0) + data.revenue;
      }

      return totals;
    } catch (e) {
      throw DatabaseException('Failed to get metrics by period: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPerformanceTrends(
      String adId, int days) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));
      final analytics = await getAnalyticsByDateRange(startDate, endDate);
      
      final adAnalytics = analytics.where((data) => data.adId == adId).toList();
      adAnalytics.sort((a, b) => a.date.compareTo(b.date));

      return adAnalytics.map((data) => data.toMap()).toList();
    } catch (e) {
      throw DatabaseException('Failed to get performance trends: $e');
    }
  }

  @override
  Future<Map<String, double>> getROIAnalysis() async {
    try {
      final allAnalytics = await getAllAnalytics();
      final roiData = <String, double>{};

      // Group by ad ID and calculate ROI for each
      final adGroups = <String, List<AnalyticsData>>{};
      for (final data in allAnalytics) {
        adGroups.putIfAbsent(data.adId, () => []).add(data);
      }

      for (final entry in adGroups.entries) {
        final adId = entry.key;
        final dataList = entry.value;
        
        final totalCost = dataList.fold(0.0, (sum, data) => sum + data.cost);
        final totalRevenue = dataList.fold(0.0, (sum, data) => sum + data.revenue);
        
        final roi = totalCost > 0 ? ((totalRevenue - totalCost) / totalCost) * 100 : 0.0;
        roiData[adId] = roi.toDouble();
      }

      return roiData;
    } catch (e) {
      throw DatabaseException('Failed to get ROI analysis: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getTopPerformingAds({int limit = 10}) async {
    try {
      final roiData = await getROIAnalysis();
      final sortedAds = roiData.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final topAds = <Map<String, dynamic>>[];
      for (final entry in sortedAds.take(limit)) {
        final adId = entry.key;
        final roi = entry.value;
        final metrics = await getMetricsByAdId(adId);
        
        topAds.add({
          'adId': adId,
          'roi': roi,
          'metrics': metrics,
        });
      }

      return topAds;
    } catch (e) {
      throw DatabaseException('Failed to get top performing ads: $e');
    }
  }

  void _notifyAnalyticsChanged() {
    getAllAnalytics().then((analytics) {
      if (!_analyticsController.isClosed) {
        _analyticsController.add(analytics);
      }
    });
  }

  void dispose() {
    _analyticsController.close();
  }
}
