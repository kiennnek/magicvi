import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/advertisement_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart' hide EmptyStateWidget;
import '../../widgets/common/empty_state_widget.dart';
import 'widgets/chart_widget.dart';
import 'widgets/metrics_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ad Analytics'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<AnalyticsProvider>(
            builder: (context, provider, child) {
              return PopupMenuButton<String>(
                onSelected: (value) async {
                  switch (value) {
                    case 'refresh':
                      await provider.refreshDashboard();
                      break;
                    case 'generate':
                      await _showGenerateDataDialog(context, provider);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'refresh',
                    child: Row(
                      children: [
                        Icon(Icons.refresh),
                        SizedBox(width: 8),
                        Text('Refresh'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'generate',
                    child: Row(
                      children: [
                        Icon(Icons.add_chart),
                        SizedBox(width: 8),
                        Text('Generate sample data'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Charts', icon: Icon(Icons.show_chart)),
            Tab(text: 'Compare', icon: Icon(Icons.compare_arrows)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildChartsTab(),
          _buildComparisonTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer2<AnalyticsProvider, AdvertisementProvider>(
      builder: (context, provider, adProvider, child) {
        if (provider.isLoading && provider.dashboardData == null) {
          return const Center(child: LoadingWidget(message: 'Loading data...'));
        }
        if (provider.errorMessage != null && provider.dashboardData == null) {
          return Center(
            child: CustomErrorWidget(
              message: provider.errorMessage!,
              onRetry: () => provider.refreshDashboard(),
            ),
          );
        }

        final metrics = provider.selectedTotals;
        final hasData = metrics.isNotEmpty;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ad Selector
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: provider.selectedAdId,
                      decoration: const InputDecoration(
                        labelText: 'Select campaign',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All campaigns')),
                        ...adProvider.advertisements.map((ad) => DropdownMenuItem(
                              value: ad.id,
                              child: Text(ad.title, overflow: TextOverflow.ellipsis),
                            )),
                      ],
                      onChanged: (val) => provider.setSelectedAdId(val),
                    ),
                  ),
                  if (provider.selectedAdId != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Clear selection',
                      onPressed: () => provider.setSelectedAdId(null),
                      icon: const Icon(Icons.clear),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              if (!hasData)
                const EmptyStateWidget(
                  message: 'No analytics data for current selection.',
                  icon: Icons.analytics,
                )
              else ...[
                Text('Key Metrics', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    MetricsCard(title: 'Impressions', value: _formatNumber(metrics['impressions'] ?? 0), icon: Icons.visibility, color: Colors.blue),
                    MetricsCard(title: 'Clicks', value: _formatNumber(metrics['clicks'] ?? 0), icon: Icons.mouse, color: Colors.green),
                    MetricsCard(title: 'Conversions', value: _formatNumber(metrics['conversions'] ?? 0), icon: Icons.trending_up, color: Colors.orange),
                    MetricsCard(title: 'Cost', value: '\$${_formatNumber(metrics['cost'] ?? 0)}', icon: Icons.attach_money, color: Colors.red),
                    MetricsCard(title: 'Revenue', value: '\$${_formatNumber(metrics['revenue'] ?? 0)}', icon: Icons.payments, color: Colors.teal),
                    MetricsCard(title: 'ROAS', value: (metrics['roas'] ?? 0).toStringAsFixed(2), icon: Icons.pie_chart, color: Colors.indigo),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Performance', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    MetricsCard(title: 'CTR', value: '${(metrics['ctr'] ?? 0).toStringAsFixed(2)}%', icon: Icons.ads_click, color: Colors.purple),
                    MetricsCard(title: 'Conversion Rate', value: '${(metrics['conversion_rate'] ?? 0).toStringAsFixed(2)}%', icon: Icons.transform, color: Colors.deepOrange),
                    MetricsCard(title: 'CPC', value: '\$${(metrics['cpc'] ?? 0).toStringAsFixed(2)}', icon: Icons.payment, color: Colors.brown),
                    MetricsCard(
                      title: 'ROI',
                      value: '${(metrics['roi'] ?? 0).toStringAsFixed(1)}%',
                      icon: Icons.trending_up,
                      color: (metrics['roi'] ?? 0) >= 0 ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartsTab() {
    return Consumer2<AnalyticsProvider, AdvertisementProvider>(
      builder: (context, provider, adProvider, child) {
        if (provider.isLoading) {
          return const Center(child: LoadingWidget(message: 'Loading charts...'));
        }
        if (provider.errorMessage != null) {
          return Center(
            child: CustomErrorWidget(
              message: provider.errorMessage!,
              onRetry: () => provider.refreshAnalytics(),
            ),
          );
        }
        if (provider.chartData.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: Icon(
                      Icons.show_chart,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No chart data',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Generate sample data or select a campaign to view charts',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showGenerateDataDialog(context, provider),
                    icon: const Icon(Icons.add_chart),
                    label: const Text('Generate sample data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.grey.shade50,
                Colors.white,
              ],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with controls
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analytics Charts',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Monitor ad performance in real time',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Control row
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          // Period selector
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.schedule, size: 18, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Text(
                                  'Period:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                DropdownButton<String>(
                                  value: provider.selectedPeriod,
                                  underline: const SizedBox(),
                                  onChanged: (value) {
                                    if (value != null) provider.setSelectedPeriod(value);
                                  },
                                  items: const [
                                    DropdownMenuItem(value: 'daily', child: Text('Daily')),
                                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Campaign selector
                          Container(
                            width: 300,
                            child: DropdownButtonFormField<String>(
                              value: provider.selectedAdId,
                              decoration: InputDecoration(
                                labelText: 'Select Campaign',
                                prefixIcon: Icon(Icons.campaign, size: 18),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('All campaigns'),
                                ),
                                ...adProvider.advertisements.map((ad) => DropdownMenuItem(
                                      value: ad.id,
                                      child: Text(ad.title, overflow: TextOverflow.ellipsis),
                                    )),
                              ],
                              onChanged: (v) => provider.setSelectedAdId(v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Line Chart
                ChartWidget(
                  title: 'Performance Over Time',
                  subtitle: 'Impressions & clicks trend',
                  chartType: ChartType.line,
                  data: provider.chartData,
                  height: 320,
                  legendItems: ['Impressions', 'Clicks'],
                ),

                const SizedBox(height: 24),

                // Bar Chart
                ChartWidget(
                  title: 'Revenue & Cost',
                  subtitle: 'Financial performance trend',
                  chartType: ChartType.bar,
                  data: provider.chartData,
                  height: 320,
                ),

                const SizedBox(height: 24),

                // Pie Chart
                if (provider.selectedTotals.isNotEmpty) ...[
                  Row(
                    children: [
                      // Pie chart
                      Expanded(
                        child: ChartWidget(
                          title: 'Budget Allocation',
                          subtitle: 'Cost vs revenue distribution',
                          chartType: ChartType.pie,
                          data: [
                            {
                              'name': 'Cost',
                              'value': provider.selectedTotals['cost'] ?? 0,
                              'color': const Color(0xFFEF4444),
                            },
                            {
                              'name': 'Revenue',
                              'value': provider.selectedTotals['revenue'] ?? 0,
                              'color': const Color(0xFF10B981),
                            },
                          ],
                          height: 280,
                        ),
                      ),

                      // Summary metrics

                    ],
                  ),
                  Row(
                    children: [
                      // Pie chart

                      // Summary metrics
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Performance Summary',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 20),

                              _buildSummaryMetric(
                                'CTR',
                                '${(provider.selectedTotals['ctr'] ?? 0).toStringAsFixed(2)}%',
                                Icons.ads_click,
                                const Color(0xFF3B82F6),
                              ),
                              const SizedBox(height: 16),

                              _buildSummaryMetric(
                                'ROAS',
                                (provider.selectedTotals['roas'] ?? 0).toStringAsFixed(2),
                                Icons.pie_chart,
                                const Color(0xFF8B5CF6),
                              ),
                              const SizedBox(height: 16),

                              _buildSummaryMetric(
                                'ROI',
                                '${(provider.selectedTotals['roi'] ?? 0).toStringAsFixed(1)}%',
                                Icons.trending_up,
                                (provider.selectedTotals['roi'] ?? 0) >= 0
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                              const SizedBox(height: 16),

                              _buildSummaryMetric(
                                'Conversion Rate',
                                '${(provider.selectedTotals['conversion_rate'] ?? 0).toStringAsFixed(2)}%',
                                Icons.transform,
                                const Color(0xFFF59E0B),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryMetric(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonTab() {
    return Consumer2<AnalyticsProvider, AdvertisementProvider>(
      builder: (context, provider, adProvider, child) {
        final analysis = provider.performanceAnalysis;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Performance Comparison',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
             Card(
              child: Padding(
                 padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                     if (analysis == null) ...[
                        Text(
                          'Select at least 2 campaigns to compare performance.',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                       ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                         onPressed: () => _showCompareAdsDialog(context, provider, adProvider),
                         child: const Text('Select Campaigns to Compare'),
                        ),
                      ] else ...[
                       // Display comparison results
                        Text(
                          'Results',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text('Timestamp: ${analysis['timestamp'] ?? ''}'),
                        const SizedBox(height: 8),
                        if (analysis['performanceScores'] != null)
                          _buildScoresSection(context, analysis),
                        const SizedBox(height: 12),
                        if (analysis['comparison'] != null)
                          _buildComparisonTable(context, analysis['comparison']),
                       const SizedBox(height: 12),
                       Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => provider.clearAnalysis(),
                              child: const Text('Clear Results'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _showCompareAdsDialog(context, provider, adProvider),
                              child: const Text('Compare Again'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
           ],
          ),
        );
     },
    );
   }
   Widget _buildScoresSection(BuildContext context, Map<String, dynamic> analysis) {
    final Map<String, dynamic> scores = Map<String, dynamic>.from(analysis['performanceScores'] ?? {});
    final winner = analysis['winner'];

    return Column(
     crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ranking',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          children: scores.entries.map((e) {
            final isWinner = winner != null && e.key == winner;
            return Chip(
              label: Text('${e.key}: ${e.value.toStringAsFixed(2)}'),
              backgroundColor: isWinner ? Colors.green.withOpacity(0.12) : null,
              avatar: isWinner ? const Icon(Icons.emoji_events, color: Colors.amber) : null,
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        if (winner != null)
          Text('Winner: $winner', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildComparisonTable(BuildContext context, Map<String, dynamic> comparison) {
    // comparison: { adId: {metric: value, ...}, ... }
    final adIds = comparison.keys.toList();
   final allMetrics = <String>{};
    for (final m in comparison.values) {
      if (m is Map) allMetrics.addAll(m.keys.map((k) => k.toString()));
    }

    final metricsList = allMetrics.toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          const DataColumn(label: Text('Metric')),
         ...adIds.map((id) => DataColumn(label: Text(id))).toList(),
       ],
        rows: metricsList.map((metric) {
          return DataRow(
            cells: [
              DataCell(Text(metric)),
             ...adIds.map((id) {
                final value = comparison[id] is Map ? (comparison[id][metric] ?? '-') : '-';
                return DataCell(Text(value is double ? value.toStringAsFixed(2) : value.toString()));
              }).toList(),
            ],
          );
        }).toList(),
      ),     );
  }

  Future<bool> _showCompareAdsDialog(BuildContext context, AnalyticsProvider analyticsProvider, AdvertisementProvider adProvider) async {
    final ads = adProvider.advertisements;
    final Map<String, bool> selected = {for (var ad in ads) ad.id: false};

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Select Campaigns'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: ads.map((ad) {
                  return CheckboxListTile(
                    value: selected[ad.id],
                    title: Text(ad.title),
                    subtitle: Text('${ad.type} • ${ad.targetAudience}'),
                    onChanged: (v) => setState(() => selected[ad.id] = v ?? false),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final chosen = selected.entries.where((e) => e.value).map((e) => e.key).toList();
                  if (chosen.length < 2) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select at least 2 campaigns')));
                    return;
                  }

                  Navigator.of(context).pop(true);
                  await analyticsProvider.compareAds(chosen);
                },
                child: const Text('Compare'),
              ),
           ],
          );
        },
      ),
    );

   return result == true;
  }

   Future<void> _showGenerateDataDialog(BuildContext context, AnalyticsProvider provider) async {
     final result = await showDialog<Map<String, dynamic>>(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('Generate Sample Data'),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             const Text('Generate sample data for analysis?'),
             const SizedBox(height: 16),
             Row(
               children: [
                 const Text('Days:'),
                 const SizedBox(width: 8),
                 Expanded(
                   child: DropdownButton<int>(
                     value: 30,
                     isExpanded: true,
                     items: const [
                       DropdownMenuItem(value: 7, child: Text('7 days')),
                       DropdownMenuItem(value: 30, child: Text('30 days')),
                       DropdownMenuItem(value: 90, child: Text('90 days')),
                     ],
                     onChanged: (value) {},
                   ),
                 ),
               ],
             ),
           ],
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.of(context).pop(),
             child: const Text('Cancel'),
           ),
           ElevatedButton(
             onPressed: () => Navigator.of(context).pop({'days': 30}),
             child: const Text('Generate'),
           ),
         ],
       ),
     );

     if (result != null) {
       await provider.generateSampleData(
         adId: 'sample_ad_${DateTime.now().millisecondsSinceEpoch}',
         days: result['days'] ?? 30,
       );
     }
   }

   String _formatNumber(double number) {
     if (number >= 1000000) {
       return '${(number / 1000000).toStringAsFixed(1)}M';
     } else if (number >= 1000) {
       return '${(number / 1000).toStringAsFixed(1)}K';
     } else {
       return number.toStringAsFixed(0);
     }
   }
 }
