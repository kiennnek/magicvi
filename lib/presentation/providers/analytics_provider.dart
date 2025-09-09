import 'package:flutter/foundation.dart';
import '../../domain/entities/analytics_data.dart';
import '../../domain/usecases/generate_analytics_usecase.dart';
import '../../core/errors/exceptions.dart';

enum AnalyticsState {
  idle,
  loading,
  generating,
  analyzing,
  error,
}

class AnalyticsProvider extends ChangeNotifier {
  final GenerateAnalyticsUseCase _generateAnalyticsUseCase;

  AnalyticsProvider(this._generateAnalyticsUseCase) {
    _init();
  }

  Future<void> _init() async {
    _setState(AnalyticsState.loading);
    await Future.wait([
      _loadAnalyticsData(),
      _loadDashboardData(),
    ]);
    _setState(AnalyticsState.idle);
  }

  // State
  AnalyticsState _state = AnalyticsState.idle;
  List<AnalyticsData> _analyticsData = [];
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _performanceAnalysis;
  List<Map<String, dynamic>> _performanceTrends = [];
  String? _errorMessage;
  String? _selectedAdId;
  String _selectedPeriod = 'daily';

  // Getters
  AnalyticsState get state => _state;
  List<AnalyticsData> get analyticsData => List.unmodifiable(_analyticsData);
  Map<String, dynamic>? get dashboardData => _dashboardData;
  Map<String, dynamic>? get performanceAnalysis => _performanceAnalysis;
  List<Map<String, dynamic>> get performanceTrends => List.unmodifiable(_performanceTrends);
  String? get errorMessage => _errorMessage;
  String? get selectedAdId => _selectedAdId;
  String get selectedPeriod => _selectedPeriod;
  bool get isLoading => _state == AnalyticsState.loading;
  bool get isGenerating => _state == AnalyticsState.generating;
  bool get isAnalyzing => _state == AnalyticsState.analyzing;

  // Chart data getters
  List<Map<String, dynamic>> get chartData {
    if (_analyticsData.isEmpty) return [];

    // Filter by period first
    final periodFiltered = _analyticsData.where((d) => d.period == _selectedPeriod).toList();
    if (periodFiltered.isEmpty) return [];

    List<AnalyticsData> working;

    if (_selectedAdId != null) {
      // Data for single ad
      working = periodFiltered.where((d) => d.adId == _selectedAdId).toList();
      working.sort((a, b) => a.date.compareTo(b.date));

      if (working.isEmpty) return [];

      // Fill missing days only when daily
      if (_selectedPeriod == 'daily') {
        final filled = <AnalyticsData>[];
        DateTime cursor = DateTime(working.first.date.year, working.first.date.month, working.first.date.day);
        final last = DateTime(working.last.date.year, working.last.date.month, working.last.date.day);
        int i = 0;
        while (!cursor.isAfter(last)) {
          if (i < working.length) {
            final current = working[i];
            final currentDay = DateTime(current.date.year, current.date.month, current.date.day);
            if (currentDay.isAtSameMomentAs(cursor)) {
              filled.add(current);
              i++;
            } else {
              filled.add(_emptyDataPoint(_selectedAdId!, cursor));
            }
          } else {
            filled.add(_emptyDataPoint(_selectedAdId!, cursor));
          }
          cursor = cursor.add(const Duration(days: 1));
        }
        working = filled;
      }
    } else {
      // Aggregate across all ads (sum by date) when no ad selected
      final Map<String, AnalyticsData> grouped = {};
      for (final d in periodFiltered) {
        final keyDate = DateTime(d.date.year, d.date.month, d.date.day);
        final key = keyDate.toIso8601String();
        if (!grouped.containsKey(key)) {
          grouped[key] = AnalyticsData(
            id: 'agg_$key',
            adId: 'ALL',
            metrics: const {},
            date: keyDate,
            period: d.period,
            impressions: d.impressions,
            clicks: d.clicks,
            conversions: d.conversions,
            cost: d.cost,
            revenue: d.revenue,
          );
        } else {
          final prev = grouped[key]!;
          grouped[key] = prev.copyWith(
            impressions: prev.impressions + d.impressions,
            clicks: prev.clicks + d.clicks,
            conversions: prev.conversions + d.conversions,
            cost: prev.cost + d.cost,
            revenue: prev.revenue + d.revenue,
          );
        }
      }
      working = grouped.values.toList()..sort((a, b) => a.date.compareTo(b.date));

      // Optionally fill daily gaps for aggregated view
      if (_selectedPeriod == 'daily' && working.isNotEmpty) {
        final filled = <AnalyticsData>[];
        DateTime cursor = DateTime(working.first.date.year, working.first.date.month, working.first.date.day);
        final last = DateTime(working.last.date.year, working.last.date.month, working.last.date.day);
        int i = 0;
        while (!cursor.isAfter(last)) {
          if (i < working.length) {
            final current = working[i];
            final currentDay = DateTime(current.date.year, current.date.month, current.date.day);
            if (currentDay.isAtSameMomentAs(cursor)) {
              filled.add(current);
              i++;
            } else {
              filled.add(_emptyDataPoint('ALL', cursor));
            }
          } else {
            filled.add(_emptyDataPoint('ALL', cursor));
          }
          cursor = cursor.add(const Duration(days: 1));
        }
        working = filled;
      }
    }

    return working.map((d) => {
      'date': d.date.millisecondsSinceEpoch,
      'impressions': d.impressions,
      'clicks': d.clicks,
      'conversions': d.conversions,
      'cost': d.cost,
      'revenue': d.revenue,
      'ctr': d.ctr,
      'roi': d.roi,
      'roas': d.roas,
    }).toList();
  }

  AnalyticsData _emptyDataPoint(String adId, DateTime date) {
    return AnalyticsData(
      id: 'gap_${adId}_${date.toIso8601String()}',
      adId: adId,
      metrics: const {},
      date: date,
      period: 'daily',
      impressions: 0,
      clicks: 0,
      conversions: 0,
      cost: 0,
      revenue: 0,
    );
  }



  Map<String, double> get totalMetrics {
    if (_dashboardData == null) return {};
    return Map<String, double>.from(_dashboardData!['totalMetrics'] ?? {});
  }

  Map<String, double> get selectedTotals {
    if (_selectedAdId == null) return totalMetrics;
    final filtered = _analyticsData.where((d) => d.adId == _selectedAdId && d.period == _selectedPeriod).toList();
    if (filtered.isEmpty) return {};
    double impressions = 0, clicks = 0, conversions = 0, cost = 0, revenue = 0;
    for (final d in filtered) {
      impressions += d.impressions;
      clicks += d.clicks;
      conversions += d.conversions;
      cost += d.cost;
      revenue += d.revenue;
    }
    final ctr = impressions > 0 ? (clicks / impressions) * 100 : 0;
    final conversionRate = clicks > 0 ? (conversions / clicks) * 100 : 0;
    final cpc = clicks > 0 ? cost / clicks : 0;
    final roi = cost > 0 ? ((revenue - cost) / cost) * 100 : 0;
    final roas = cost > 0 ? revenue / cost : 0;

    return {
      'impressions': impressions,
      'clicks': clicks,
      'conversions': conversions,
      'cost': cost,
      'revenue': revenue,
      'ctr': ctr.toDouble(),
      'conversion_rate': conversionRate.toDouble(),
      'cpc': cpc.toDouble(),
      'roi': roi.toDouble(),
      'roas': roas.toDouble(),
    };
  }

  // Methods
  void setSelectedAdId(String? adId) {
    _selectedAdId = adId;
    if (adId != null) {
      _loadPerformanceTrends(adId);
    }
    notifyListeners();
  }

  void setSelectedPeriod(String period) {
    _selectedPeriod = period;
    _loadPeriodAnalysis();
    notifyListeners();
  }

  Future<void> generateSampleData({
    required String adId,
    int days = 30,
  }) async {
    try {
      _setState(AnalyticsState.generating);
      _clearError();

      await _generateAnalyticsUseCase.generateMultipleDaysData(
        adId: adId,
        days: days,
        period: _selectedPeriod,
      );

      await _loadAnalyticsData();
      await _loadDashboardData();
      _setState(AnalyticsState.idle);
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setState(AnalyticsState.error);
    }
  }

  Future<void> analyzePerformance(String adId) async {
    try {
      _setState(AnalyticsState.analyzing);
      _clearError();

      final analysis = await _generateAnalyticsUseCase.analyzePerformance(
        adId: adId,
        days: 30,
      );

      _performanceAnalysis = analysis;
      _setState(AnalyticsState.idle);
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setState(AnalyticsState.error);
    }
  }

  Future<void> compareAds(List<String> adIds) async {
    try {
      _setState(AnalyticsState.analyzing);
      _clearError();

      final comparison = await _generateAnalyticsUseCase.compareAds(
        adIds: adIds,
        days: 30,
      );

      _performanceAnalysis = comparison;
      _setState(AnalyticsState.idle);
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setState(AnalyticsState.error);
    }
  }

  Future<void> refreshDashboard() async {
    await Future.wait([
      _loadDashboardData(),
      _loadAnalyticsData(),
    ]);
  }

  Future<void> refreshAnalytics() async {
    await _loadAnalyticsData();
  }

  List<AnalyticsData> getAnalyticsByAdId(String adId) {
    return _analyticsData.where((data) => data.adId == adId).toList();
  }

  List<AnalyticsData> getAnalyticsByPeriod(String period) {
    return _analyticsData.where((data) => data.period == period).toList();
  }

  List<AnalyticsData> getAnalyticsByDateRange(DateTime start, DateTime end) {
    return _analyticsData.where((data) =>
        data.date.isAfter(start.subtract(Duration(days: 1))) &&
        data.date.isBefore(end.add(Duration(days: 1)))).toList();
  }

  void clearAnalysis() {
    _performanceAnalysis = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  // Private methods
  Future<void> _loadAnalyticsData() async {
    try {
      final data = await _generateAnalyticsUseCase.getAllAnalytics();
      _analyticsData = data;
      notifyListeners();
    } catch (e) {
      _setError(_getErrorMessage(e));
    }
  }

  Future<void> _loadDashboardData() async {
    try {
      final data = await _generateAnalyticsUseCase.getDashboardData();
      _dashboardData = data;
      notifyListeners();
    } catch (e) {
      _setError(_getErrorMessage(e));
    }
  }

  Future<void> _loadPerformanceTrends(String adId) async {
    try {
      final trends = await _generateAnalyticsUseCase.getPerformanceTrends(
        adId: adId,
        days: 30,
      );
      _performanceTrends = trends;
      notifyListeners();
    } catch (e) {
      _setError(_getErrorMessage(e));
    }
  }

  Future<void> _loadPeriodAnalysis() async {
    try {
      _setState(AnalyticsState.loading);
      final analysis = await _generateAnalyticsUseCase.getPeriodAnalysis(
        period: _selectedPeriod,
        limit: 30,
      );
      
      if (analysis['data'] != null) {
        // Convert analysis data back to AnalyticsData objects if needed
        _performanceAnalysis = analysis;
      }
      
      _setState(AnalyticsState.idle);
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setState(AnalyticsState.error);
    }
  }

  void _setState(AnalyticsState newState) {
    _state = newState;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is NetworkException) {
      return 'No internet connection. Please check your connection and try again.';
    } else if (error is ApiException) {
      return 'Server error: ${error.message}';
    } else if (error is DatabaseException) {
      return 'Database error: ${error.message}';
    } else if (error is ValidationException) {
      return 'Invalid data: ${error.message}';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
