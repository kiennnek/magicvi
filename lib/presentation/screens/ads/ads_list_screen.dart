import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/advertisement.dart';
import '../../providers/advertisement_provider.dart';

class AdsListScreen extends StatefulWidget {
  const AdsListScreen({Key? key}) : super(key: key);

  @override
  State<AdsListScreen> createState() => _AdsListScreenState();
}

class _AdsListScreenState extends State<AdsListScreen> {
  String _searchQuery = '';
  String _sortBy = 'title';
  bool _sortAscending = true;
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Campaigns', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade200),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterMenu(context),
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortMenu(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search campaigns...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Filter chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Active', 'active'),
                const SizedBox(width: 8),
                _buildFilterChip('Paused', 'paused'),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: Consumer<AdvertisementProvider>(
              builder: (context, adProvider, child) {
                final ads = _getFilteredAndSortedAds(adProvider.advertisements);

                if (adProvider.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading campaigns...'),
                      ],
                    ),
                  );
                }

                if (ads.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                            ? 'No campaigns found matching "$_searchQuery"'
                            : 'No campaigns yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                            ? 'Try adjusting your search or filters'
                            : 'Create your first campaign to get started',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: ads.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final ad = ads[index];
                    return _buildCampaignCard(context, ad, adProvider);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => setState(() => _filterStatus = value),
      backgroundColor: Colors.grey.shade100,
      selectedColor: Colors.blue.shade50,
      checkmarkColor: Colors.blue.shade700,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue.shade700 : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildCampaignCard(BuildContext context, Advertisement ad, AdvertisementProvider adProvider) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50.withAlpha(50),
            ],
          ),
          border: Border(
            left: BorderSide(
              width: 4,
              color: ad.isActive ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Campaign icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: _getTypeGradient(ad.type),
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        ad.type.displayName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Title and status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ad.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              ad.isActive ? Icons.play_circle_filled : Icons.pause_circle_filled,
                              size: 16,
                              color: ad.isActive ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ad.isActive ? 'Active' : 'Paused',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: ad.isActive ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Quick actions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: ad.isActive,
                        onChanged: (v) => _toggleStatus(adProvider, ad.id, v),
                        activeColor: const Color(0xFF10B981),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: Color(0xFF6B7280)),
                        onSelected: (value) => _handleMenuAction(context, value, ad, adProvider),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 20),
                                SizedBox(width: 12),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                Icon(Icons.copy, size: 20),
                                SizedBox(width: 12),
                                Text('Duplicate'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 20, color: Colors.red),
                                SizedBox(width: 12),
                                Text('Delete', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Campaign details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TYPE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ad.type.displayName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BUDGET',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '\$${_formatBudget(ad.budget)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AUDIENCE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            ad.targetAudience,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Metrics section
              if (_hasMetrics(ad)) ...[
                const SizedBox(height: 16),
                Text(
                  'PERFORMANCE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _buildMetricChips(ad),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getTypeGradient(AdType type) {
    switch (type) {
      case AdType.google:
        return [const Color(0xFF4285F4), const Color(0xFF1A73E8)];
      case AdType.facebook:
        return [const Color(0xFF1877F2), const Color(0xFF0B5EE5)];
      case AdType.instagram:
        return [const Color(0xFFE4405F), const Color(0xFFC13584)];
      case AdType.tiktok:
        return [const Color(0xFF000000), const Color(0xFF333333)];
      case AdType.youtube:
        return [const Color(0xFFFF0000), const Color(0xFFCC0000)];
      default:
        return [const Color(0xFF6366F1), const Color(0xFF4F46E5)];
    }
  }

  bool _hasMetrics(Advertisement ad) {
    return ad.metrics.isNotEmpty &&
           (ad.metrics['ctr'] != null ||
            ad.metrics['conversion_rate'] != null ||
            ad.metrics['roi'] != null ||
            ad.metrics['roas'] != null);
  }

  List<Widget> _buildMetricChips(Advertisement ad) {
    final chips = <Widget>[];

    if (ad.metrics['ctr'] != null) {
      chips.add(_buildMetricChip(
        'CTR ${ad.metrics['ctr']}%',
        const Color(0xFF3B82F6),
        Icons.ads_click,
      ));
    }

    if (ad.metrics['conversion_rate'] != null) {
      chips.add(_buildMetricChip(
        'Conv ${ad.metrics['conversion_rate']}%',
        const Color(0xFFF59E0B),
        Icons.transform,
      ));
    }

    if (ad.metrics['roi'] != null) {
      final roi = ad.metrics['roi'] as double;
      chips.add(_buildMetricChip(
        'ROI ${roi.toStringAsFixed(1)}%',
        roi > 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
        Icons.trending_up,
      ));
    }

    if (ad.metrics['roas'] != null) {
      chips.add(_buildMetricChip(
        'ROAS ${ad.metrics['roas']}',
        const Color(0xFF8B5CF6),
        Icons.pie_chart,
      ));
    }

    return chips;
  }

  Widget _buildMetricChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatBudget(double budget) {
    if (budget >= 1000000) {
      return '${(budget / 1000000).toStringAsFixed(1)}M';
    } else if (budget >= 1000) {
      return '${(budget / 1000).toStringAsFixed(1)}K';
    } else {
      return budget.toStringAsFixed(0);
    }
  }

  List<Advertisement> _getFilteredAndSortedAds(List<Advertisement> ads) {
    // Filter by search query
    var filteredAds = ads.where((ad) {
      if (_searchQuery.isEmpty) return true;
      return ad.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             ad.type.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             ad.targetAudience.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Filter by status
    if (_filterStatus == 'active') {
      filteredAds = filteredAds.where((ad) => ad.isActive).toList();
    } else if (_filterStatus == 'paused') {
      filteredAds = filteredAds.where((ad) => !ad.isActive).toList();
    }

    // Sort
    filteredAds.sort((a, b) {
      int result = 0;
      switch (_sortBy) {
        case 'title':
          result = a.title.compareTo(b.title);
          break;
        case 'budget':
          result = a.budget.compareTo(b.budget);
          break;
        case 'created':
          result = a.createdAt.compareTo(b.createdAt);
          break;
        case 'status':
          result = a.isActive.toString().compareTo(b.isActive.toString());
          break;
      }
      return _sortAscending ? result : -result;
    });

    return filteredAds;
  }

  void _showFilterMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Filter by Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('All Campaigns'),
              leading: Radio<String>(
                value: 'all',
                groupValue: _filterStatus,
                onChanged: (value) {
                  setState(() => _filterStatus = value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Active Only'),
              leading: Radio<String>(
                value: 'active',
                groupValue: _filterStatus,
                onChanged: (value) {
                  setState(() => _filterStatus = value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Paused Only'),
              leading: Radio<String>(
                value: 'paused',
                groupValue: _filterStatus,
                onChanged: (value) {
                  setState(() => _filterStatus = value!);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSortMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sort by', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Campaign Name'),
              leading: Radio<String>(
                value: 'title',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Budget'),
              leading: Radio<String>(
                value: 'budget',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Created Date'),
              leading: Radio<String>(
                value: 'created',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Status'),
              leading: Radio<String>(
                value: 'status',
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() => _sortAscending = true);
                      Navigator.pop(context);
                    },
                    child: Text(_sortAscending ? '✓ Ascending' : 'Ascending'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      setState(() => _sortAscending = false);
                      Navigator.pop(context);
                    },
                    child: Text(!_sortAscending ? '✓ Descending' : 'Descending'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStatus(AdvertisementProvider adProvider, String id, bool isActive) async {
    try {
      await adProvider.toggleAdvertisementStatus(id, isActive);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Campaign ${isActive ? 'activated' : 'paused'} successfully'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleMenuAction(BuildContext context, String action, Advertisement ad, AdvertisementProvider adProvider) {
    switch (action) {
      case 'edit':
        _showEditDialog(context, ad, adProvider);
        break;
      case 'duplicate':
        _duplicateCampaign(ad, adProvider);
        break;
      case 'delete':
        _showDeleteDialog(context, ad, adProvider);
        break;
    }
  }

  Future<void> _duplicateCampaign(Advertisement ad, AdvertisementProvider adProvider) async {
    try {
      await adProvider.createAdvertisement(
        adType: ad.type,
        budget: ad.budget,
        targetAudience: ad.targetAudience,
        title: '${ad.title} (Copy)',
        description: ad.description,
        metrics: Map.from(ad.metrics),
        isActive: false,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Campaign duplicated successfully'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error duplicating campaign: $e'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showDeleteDialog(BuildContext context, Advertisement ad, AdvertisementProvider adProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Campaign'),
        content: Text('Are you sure you want to delete "${ad.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await adProvider.deleteAdvertisement(ad.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Campaign deleted successfully'),
                      backgroundColor: Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting campaign: $e'),
                      backgroundColor: const Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showEditDialog(BuildContext context, Advertisement ad, AdvertisementProvider adProvider) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditCampaignDialog(ad: ad, adProvider: adProvider),
    );
    return result == true;
  }

  // ...existing code...
}

class EditCampaignDialog extends StatefulWidget {
  final Advertisement ad;
  final AdvertisementProvider adProvider;
  const EditCampaignDialog({Key? key, required this.ad, required this.adProvider}) : super(key: key);

  @override
  State<EditCampaignDialog> createState() => _EditCampaignDialogState();
}

class _EditCampaignDialogState extends State<EditCampaignDialog> {
  late TextEditingController titleCtrl;
  late TextEditingController descCtrl;
  late TextEditingController budgetCtrl;
  late TextEditingController targetCtrl;
  late TextEditingController impressionsCtrl;
  late TextEditingController clicksCtrl;
  late TextEditingController conversionsCtrl;
  late TextEditingController costCtrl;
  late TextEditingController revenueCtrl;
  late TextEditingController ctrCtrl;
  late TextEditingController convRateCtrl;
  late TextEditingController roiCtrl;
  late TextEditingController roasCtrl;

  late AdType selectedType;
  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final ad = widget.ad;
    titleCtrl = TextEditingController(text: ad.title);
    descCtrl = TextEditingController(text: ad.description);
    budgetCtrl = TextEditingController(text: ad.budget.toString());
    targetCtrl = TextEditingController(text: ad.targetAudience);
    impressionsCtrl = TextEditingController(text: ad.metrics['impressions']?.toString() ?? '');
    clicksCtrl = TextEditingController(text: ad.metrics['clicks']?.toString() ?? '');
    conversionsCtrl = TextEditingController(text: ad.metrics['conversions']?.toString() ?? '');
    costCtrl = TextEditingController(text: ad.metrics['cost']?.toString() ?? '');
    revenueCtrl = TextEditingController(text: ad.metrics['revenue']?.toString() ?? '');
    ctrCtrl = TextEditingController(text: ad.metrics['ctr']?.toString() ?? '');
    convRateCtrl = TextEditingController(text: ad.metrics['conversion_rate']?.toString() ?? '');
    roiCtrl = TextEditingController(text: ad.metrics['roi']?.toString() ?? '');
    roasCtrl = TextEditingController(text: ad.metrics['roas']?.toString() ?? '');
    selectedType = ad.type;
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    budgetCtrl.dispose();
    targetCtrl.dispose();
    impressionsCtrl.dispose();
    clicksCtrl.dispose();
    conversionsCtrl.dispose();
    costCtrl.dispose();
    revenueCtrl.dispose();
    ctrCtrl.dispose();
    convRateCtrl.dispose();
    roiCtrl.dispose();
    roasCtrl.dispose();
    super.dispose();
  }

  List<Color> _getTypeGradient(AdType type) {
    switch (type) {
      case AdType.google:
        return [const Color(0xFF4285F4), const Color(0xFF1A73E8)];
      case AdType.facebook:
        return [const Color(0xFF1877F2), const Color(0xFF0B5EE5)];
      case AdType.instagram:
        return [const Color(0xFFE4405F), const Color(0xFFC13584)];
      case AdType.tiktok:
        return [const Color(0xFF000000), const Color(0xFF333333)];
      case AdType.youtube:
        return [const Color(0xFFFF0000), const Color(0xFFCC0000)];
      default:
        return [const Color(0xFF6366F1), const Color(0xFF4F46E5)];
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withAlpha(20),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF3B82F6), size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon, color: color, size: 20),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getTypeGradient(selectedType),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        selectedType.displayName.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Edit Campaign',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ad.title,
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader('Basic Information', Icons.info_outline),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<AdType>(
                        value: selectedType,
                        items: AdType.values.map((t) => DropdownMenuItem(
                          value: t,
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: _getTypeGradient(t)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    t.displayName.substring(0, 1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(t.displayName),
                            ],
                          ),
                        )).toList(),
                        onChanged: (type) => setState(() => selectedType = type!),
                        decoration: const InputDecoration(
                          labelText: 'Campaign Type',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Campaign Title',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: budgetCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Budget (USD)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Budget is required';
                                final val = double.tryParse(v.replaceAll(',', ''));
                                if (val == null || val < 0) return 'Enter valid budget';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: targetCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Target Audience',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.people),
                              ),
                              validator: (v) => (v == null || v.trim().isEmpty) ? 'Target audience is required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      _buildSectionHeader('Performance Metrics', Icons.analytics),
                      const SizedBox(height: 8),
                      Text(
                        'Update your campaign metrics for better comparison and analysis',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildMetricField(controller: impressionsCtrl, label: 'Impressions', icon: Icons.remove_red_eye, color: const Color(0xFF3B82F6))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildMetricField(controller: clicksCtrl, label: 'Clicks', icon: Icons.mouse, color: const Color(0xFF10B981))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildMetricField(controller: conversionsCtrl, label: 'Conversions', icon: Icons.check_circle, color: const Color(0xFFF59E0B))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildMetricField(controller: costCtrl, label: 'Cost (USD)', icon: Icons.money_off, color: const Color(0xFFEF4444))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildMetricField(controller: revenueCtrl, label: 'Revenue (USD)', icon: Icons.sell, color: const Color(0xFF10B981))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildMetricField(controller: ctrCtrl, label: 'CTR (%)', icon: Icons.ads_click, color: const Color(0xFF3B82F6))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildMetricField(controller: convRateCtrl, label: 'Conv Rate (%)', icon: Icons.transform, color: const Color(0xFFF59E0B))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildMetricField(controller: roiCtrl, label: 'ROI (%)', icon: Icons.trending_up, color: const Color(0xFF10B981))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildMetricField(controller: roasCtrl, label: 'ROAS', icon: Icons.pie_chart, color: const Color(0xFF8B5CF6))),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Leave fields empty to auto-calculate based on other metrics (CTR, Conversion Rate, ROI, ROAS)',
                                style: TextStyle(color: Colors.blue.shade700, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final impressions = double.tryParse(impressionsCtrl.text.replaceAll(',', '')) ?? 0;
                        final clicks = double.tryParse(clicksCtrl.text.replaceAll(',', '')) ?? 0;
                        final conversions = double.tryParse(conversionsCtrl.text.replaceAll(',', '')) ?? 0;
                        final cost = double.tryParse(costCtrl.text.replaceAll(',', '')) ?? 0;
                        final revenue = double.tryParse(revenueCtrl.text.replaceAll(',', '')) ?? 0;
                        final ctr = impressions > 0 && ctrCtrl.text.isEmpty ? (clicks / impressions) * 100 : (double.tryParse(ctrCtrl.text) ?? 0);
                        final conversionRate = clicks > 0 && convRateCtrl.text.isEmpty ? (conversions / clicks) * 100 : (double.tryParse(convRateCtrl.text) ?? 0);
                        final roi = cost > 0 && roiCtrl.text.isEmpty ? ((revenue - cost) / cost) * 100 : (double.tryParse(roiCtrl.text) ?? 0);
                        final roas = cost > 0 && roasCtrl.text.isEmpty ? revenue / cost : (double.tryParse(roasCtrl.text) ?? 0);
                        final Map<String, dynamic> metrics = {};
                        if (impressions > 0) metrics['impressions'] = impressions;
                        if (clicks > 0) metrics['clicks'] = clicks;
                        if (conversions > 0) metrics['conversions'] = conversions;
                        if (cost > 0) metrics['cost'] = cost;
                        if (revenue > 0) metrics['revenue'] = revenue;
                        metrics['ctr'] = double.parse(ctr.toStringAsFixed(2));
                        metrics['conversion_rate'] = double.parse(conversionRate.toStringAsFixed(2));
                        metrics['roi'] = double.parse(roi.toStringAsFixed(2));
                        metrics['roas'] = double.parse(roas.toStringAsFixed(2));
                        final updated = widget.ad.copyWith(
                          title: titleCtrl.text.trim(),
                          description: descCtrl.text.trim(),
                          budget: double.tryParse(budgetCtrl.text.replaceAll(',', '')) ?? widget.ad.budget,
                          targetAudience: targetCtrl.text.trim(),
                          type: selectedType,
                          metrics: metrics,
                          updatedAt: DateTime.now(),
                        );
                        try {
                          await widget.adProvider.updateAdvertisement(updated);
                          if (mounted) {
                            Navigator.pop(context, true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Campaign updated successfully'),
                                backgroundColor: Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error updating campaign: $e'),
                                backgroundColor: const Color(0xFFEF4444),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
