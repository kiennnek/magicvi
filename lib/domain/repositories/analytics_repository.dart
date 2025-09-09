import '../entities/analytics_data.dart';

abstract class AnalyticsRepository {
  Future<List<AnalyticsData>> getAllAnalytics();
  Future<void> saveAnalyticsData(AnalyticsData data);
  Future<void> deleteAnalyticsData(String id);
  Future<void> updateAnalyticsData(AnalyticsData data);
  Future<AnalyticsData?> getAnalyticsById(String id);
  Future<List<AnalyticsData>> getAnalyticsByAdId(String adId);
  Future<List<AnalyticsData>> getAnalyticsByPeriod(String period);
  Future<List<AnalyticsData>> getAnalyticsByDateRange(DateTime start, DateTime end);
  Stream<List<AnalyticsData>> watchAnalytics();
  
  // Aggregated analytics methods
  Future<Map<String, double>> getTotalMetrics();
  Future<Map<String, double>> getMetricsByAdId(String adId);
  Future<Map<String, double>> getMetricsByPeriod(String period);
  Future<List<Map<String, dynamic>>> getPerformanceTrends(String adId, int days);
  Future<Map<String, double>> getROIAnalysis();
  Future<List<Map<String, dynamic>>> getTopPerformingAds({int limit = 10});
}

