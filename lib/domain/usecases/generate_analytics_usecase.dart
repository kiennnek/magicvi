import 'dart:math';
import '../entities/analytics_data.dart';
import '../repositories/analytics_repository.dart';
import '../../data/datasources/remote/gemini_api_service.dart';
import '../../core/errors/exceptions.dart';
import 'package:uuid/uuid.dart';

class GenerateAnalyticsUseCase {
  final AnalyticsRepository _analyticsRepository;
  final GeminiApiService _geminiApiService;
  final Uuid _uuid = const Uuid();
  final Random _random = Random();

  GenerateAnalyticsUseCase(this._analyticsRepository, this._geminiApiService);

  Future<AnalyticsData> generateSampleData({
    required String adId,
    DateTime? date,
    String period = 'daily',
  }) async {
    try {
      final analyticsData = AnalyticsData(
        id: _uuid.v4(),
        adId: adId,
        date: date ?? DateTime.now(),
        period: period,
        impressions: _generateRandomDouble(1000, 10000),
        clicks: _generateRandomDouble(50, 500),
        conversions: _generateRandomDouble(5, 50),
        cost: _generateRandomDouble(100, 1000),
        revenue: _generateRandomDouble(200, 2000),
        metrics: {
          'bounce_rate': _generateRandomDouble(20, 80),
          'session_duration': _generateRandomDouble(30, 300),
          'page_views': _generateRandomDouble(1, 10),
        },
      );

      await _analyticsRepository.saveAnalyticsData(analyticsData);
      return analyticsData;
    } catch (e) {
      throw DatabaseException('Failed to generate sample analytics data: $e');
    }
  }

  Future<List<AnalyticsData>> generateMultipleDaysData({
    required String adId,
    required int days,
    String period = 'daily',
  }) async {
    try {
      final dataList = <AnalyticsData>[];
      final endDate = DateTime.now();

      for (int i = 0; i < days; i++) {
        final date = endDate.subtract(Duration(days: i));
        final data = await generateSampleData(
          adId: adId,
          date: date,
          period: period,
        );
        dataList.add(data);
      }

      return dataList.reversed.toList(); // Return in chronological order
    } catch (e) {
      throw DatabaseException('Failed to generate multiple days data: $e');
    }
  }

  Future<Map<String, dynamic>> analyzePerformance({
    required String adId,
    int days = 30,
  }) async {
    try {
      final analytics = await _analyticsRepository.getAnalyticsByAdId(adId);
      
      if (analytics.isEmpty) {
        throw ValidationException('No analytics data found for ad ID: $adId');
      }

      final metrics = await _analyticsRepository.getMetricsByAdId(adId);
      
      // Prepare ad data for analysis
      final adData = {
        'id': adId,
        'type': 'General', // You might want to get this from actual ad data
        'campaign': 'Campaign_$adId',
        'status': 'active',
        'created_date': analytics.last.date.toIso8601String(),
        'data_points': analytics.length,
      };

      // Prepare metrics data for analysis
      final metricsData = Map<String, dynamic>.from(metrics);

      // Get AI analysis
      final aiAnalysis = await _geminiApiService.analyzeAdPerformance(
        adData: adData,
        metricsData: metricsData,
      );

      return {
        'adId': adId,
        'metrics': metrics,
        'aiAnalysis': aiAnalysis,
        'dataPoints': analytics.length,
        'dateRange': {
          'start': analytics.last.date.toIso8601String(),
          'end': analytics.first.date.toIso8601String(),
        },
        'trends': await _calculateTrends(analytics),
      };
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ApiException('Failed to analyze performance: $e');
    }
  }

  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final totalMetrics = await _analyticsRepository.getTotalMetrics();
      final roiAnalysis = await _analyticsRepository.getROIAnalysis();
      final topPerformingAds = await _analyticsRepository.getTopPerformingAds();

      return {
        'totalMetrics': totalMetrics,
        'roiAnalysis': roiAnalysis,
        'topPerformingAds': topPerformingAds,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw DatabaseException('Failed to get dashboard data: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getPerformanceTrends({
    required String adId,
    int days = 30,
  }) async {
    try {
      return await _analyticsRepository.getPerformanceTrends(adId, days);
    } catch (e) {
      throw DatabaseException('Failed to get performance trends: $e');
    }
  }

  Future<Map<String, dynamic>> compareAds({
    required List<String> adIds,
    int days = 30,
  }) async {
    try {
      final comparison = <String, Map<String, double>>{};
      
      for (final adId in adIds) {
        final metrics = await _analyticsRepository.getMetricsByAdId(adId);
        comparison[adId] = metrics;
      }

      // Calculate relative performance
      final performanceScores = <String, double>{};
      for (final entry in comparison.entries) {
        final metrics = entry.value;
        final score = _calculatePerformanceScore(metrics);
        performanceScores[entry.key] = score;
      }

      return {
        'comparison': comparison,
        'performanceScores': performanceScores,
        'winner': performanceScores.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw DatabaseException('Failed to compare ads: $e');
    }
  }

  Future<Map<String, dynamic>> getPeriodAnalysis({
    required String period, // 'daily', 'weekly', 'monthly'
    int limit = 30,
  }) async {
    try {
      final analytics = await _analyticsRepository.getAnalyticsByPeriod(period);
      analytics.sort((a, b) => b.date.compareTo(a.date));
      
      final limitedData = analytics.take(limit).toList();
      final metrics = await _analyticsRepository.getMetricsByPeriod(period);

      return {
        'period': period,
        'data': limitedData.map((data) => data.toMap()).toList(),
        'aggregatedMetrics': metrics,
        'dataPoints': limitedData.length,
        'trends': await _calculateTrends(limitedData),
      };
    } catch (e) {
      throw DatabaseException('Failed to get period analysis: $e');
    }
  }

  Future<void> deleteAnalyticsData(String id) async {
    try {
      await _analyticsRepository.deleteAnalyticsData(id);
    } catch (e) {
      throw DatabaseException('Failed to delete analytics data: $e');
    }
  }

  Future<List<AnalyticsData>> getAllAnalytics() async {
    try {
      return await _analyticsRepository.getAllAnalytics();
    } catch (e) {
      throw DatabaseException('Failed to get all analytics: $e');
    }
  }

  // Helper methods
  double _generateRandomDouble(double min, double max) {
    return min + _random.nextDouble() * (max - min);
  }

  Future<Map<String, dynamic>> _calculateTrends(List<AnalyticsData> data) async {
    if (data.length < 2) {
      return {'trend': 'insufficient_data'};
    }

    final sortedData = List<AnalyticsData>.from(data)
      ..sort((a, b) => a.date.compareTo(b.date));

    final first = sortedData.first;
    final last = sortedData.last;

    final trends = <String, dynamic>{};

    // Calculate percentage changes
    trends['impressions_change'] = _calculatePercentageChange(
      first.impressions, last.impressions);
    trends['clicks_change'] = _calculatePercentageChange(
      first.clicks, last.clicks);
    trends['conversions_change'] = _calculatePercentageChange(
      first.conversions, last.conversions);
    trends['cost_change'] = _calculatePercentageChange(
      first.cost, last.cost);
    trends['revenue_change'] = _calculatePercentageChange(
      first.revenue, last.revenue);
    trends['roi_change'] = _calculatePercentageChange(
      first.roi, last.roi);

    // Overall trend direction
    final positiveChanges = [
      trends['impressions_change'],
      trends['clicks_change'],
      trends['conversions_change'],
      trends['revenue_change'],
      trends['roi_change'],
    ].where((change) => change > 0).length;

    trends['overall_trend'] = positiveChanges >= 3 ? 'improving' : 
                             positiveChanges <= 1 ? 'declining' : 'stable';

    return trends;
  }

  double _calculatePercentageChange(double oldValue, double newValue) {
    if (oldValue == 0) return newValue > 0 ? 100 : 0;
    return ((newValue - oldValue) / oldValue) * 100;
  }

  double _calculatePerformanceScore(Map<String, double> metrics) {
    // Weighted performance score calculation
    final weights = {
      'roi': 0.3,
      'roas': 0.2,
      'conversion_rate': 0.2,
      'ctr': 0.15,
      'revenue': 0.1,
      'impressions': 0.05,
    };

    double score = 0;
    double totalWeight = 0;

    for (final entry in weights.entries) {
      final metric = metrics[entry.key];
      if (metric != null) {
        score += metric * entry.value;
        totalWeight += entry.value;
      }
    }

    return totalWeight > 0 ? score / totalWeight : 0;
  }
}
