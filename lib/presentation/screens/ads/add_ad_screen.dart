import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/entities/advertisement.dart';
import '../../providers/advertisement_provider.dart';

class AddAdScreen extends StatefulWidget {
  const AddAdScreen({Key? key}) : super(key: key);

  @override
  State<AddAdScreen> createState() => _AddAdScreenState();
}

class _AddAdScreenState extends State<AddAdScreen> {
  final _formKey = GlobalKey<FormState>();
  AdType _selectedType = AdType.socialMedia;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _targetAudienceController = TextEditingController();
  bool _isActive = false;

  // Advanced metric controllers
  final TextEditingController _impressionsController = TextEditingController();
  final TextEditingController _clicksController = TextEditingController();
  final TextEditingController _conversionsController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _revenueController = TextEditingController();
  final TextEditingController _ctrController = TextEditingController(); // percentage
  final TextEditingController _conversionRateController = TextEditingController(); // percentage
  final TextEditingController _roiController = TextEditingController(); // percentage
  final TextEditingController _roasController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _targetAudienceController.dispose();
    _impressionsController.dispose();
    _clicksController.dispose();
    _conversionsController.dispose();
    _costController.dispose();
    _revenueController.dispose();
    _ctrController.dispose();
    _conversionRateController.dispose();
    _roiController.dispose();
    _roasController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final adProvider = context.read<AdvertisementProvider>();

    final double budget = double.tryParse(_budgetController.text.replaceAll(',', '')) ?? 0.0;

    // Parse advanced metrics
    final double impressions = double.tryParse(_impressionsController.text.replaceAll(',', '')) ?? 0.0;
    final double clicks = double.tryParse(_clicksController.text.replaceAll(',', '')) ?? 0.0;
    final double conversions = double.tryParse(_conversionsController.text.replaceAll(',', '')) ?? 0.0;
    final double cost = double.tryParse(_costController.text.replaceAll(',', '')) ?? 0.0;
    final double revenue = double.tryParse(_revenueController.text.replaceAll(',', '')) ?? 0.0;

    // Derived metrics (if user provided explicit values, prefer them)
    final double ctr = _ctrController.text.trim().isNotEmpty
        ? (double.tryParse(_ctrController.text.replaceAll(',', '')) ?? 0.0)
        : (impressions > 0 ? (clicks / impressions) * 100 : 0.0);

    final double conversionRate = _conversionRateController.text.trim().isNotEmpty
        ? (double.tryParse(_conversionRateController.text.replaceAll(',', '')) ?? 0.0)
        : (clicks > 0 ? (conversions / clicks) * 100 : 0.0);

    final double roi = _roiController.text.trim().isNotEmpty
        ? (double.tryParse(_roiController.text.replaceAll(',', '')) ?? 0.0)
        : (cost > 0 ? ((revenue - cost) / cost) * 100 : 0.0);

    final double roas = _roasController.text.trim().isNotEmpty
        ? (double.tryParse(_roasController.text.replaceAll(',', '')) ?? 0.0)
        : (cost > 0 ? (revenue / cost) : 0.0);

    final Map<String, dynamic> metrics = {
      if (impressions > 0) 'impressions': impressions,
      if (clicks > 0) 'clicks': clicks,
      if (conversions > 0) 'conversions': conversions,
      if (cost > 0) 'cost': cost,
      if (revenue > 0) 'revenue': revenue,
      'ctr': double.parse(ctr.toStringAsFixed(2)),
      'conversion_rate': double.parse(conversionRate.toStringAsFixed(2)),
      'roi': double.parse(roi.toStringAsFixed(2)),
      'roas': double.parse(roas.toStringAsFixed(2)),
    };

    try {
      await adProvider.createAdvertisement(
        adType: _selectedType,
        budget: budget,
        targetAudience: _targetAudienceController.text.trim(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        isActive: _isActive,
        metrics: metrics,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad added successfully'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding ad: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Advertisement'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Basic info card
              Card(
                margin: EdgeInsets.zero,
                elevation: 1,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.campaign, size: 18),
                          const SizedBox(width: 8),
                          Text('Basic Information', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<AdType>(
                        initialValue: _selectedType,
                        items: AdType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
                        onChanged: (v) { if (v != null) setState(() => _selectedType = v); },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Ad Type',
                          prefixIcon: Icon(Icons.category),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description (optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.notes),
                        ),
                        maxLines: 3,
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _budgetController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Budget (USD)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                          helperText: 'Enter total campaign budget',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Please enter a budget';
                          final value = double.tryParse(v.replaceAll(',', ''));
                          if (value == null || value < 0) return 'Invalid budget';
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _targetAudienceController,
                        decoration: const InputDecoration(
                          labelText: 'Target Audience',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.people),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a target audience' : null,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Advanced metrics card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  title: Row(
                    children: [
                      const Icon(Icons.analytics, size: 18),
                      const SizedBox(width: 8),
                      Text('Advanced Metrics', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildNumberField(controller: _impressionsController, label: 'Impressions', icon: Icons.remove_red_eye),
                        _buildNumberField(controller: _clicksController, label: 'Clicks', icon: Icons.mouse),
                        _buildNumberField(controller: _conversionsController, label: 'Conversions', icon: Icons.check_circle),
                        _buildNumberField(controller: _costController, label: 'Cost (USD)', icon: Icons.money_off),
                        _buildNumberField(controller: _revenueController, label: 'Revenue (USD)', icon: Icons.sell),
                        _buildNumberField(controller: _ctrController, label: 'CTR (%)', icon: Icons.percent),
                        _buildNumberField(controller: _conversionRateController, label: 'Conversion Rate (%)', icon: Icons.show_chart),
                        _buildNumberField(controller: _roiController, label: 'ROI (%)', icon: Icons.trending_up),
                        _buildNumberField(controller: _roasController, label: 'ROAS', icon: Icons.pie_chart),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text('You can leave existing values blank for the system to auto-calculate.', style: Theme.of(context).textTheme.bodySmall),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.toggle_on, size: 20),
                      SizedBox(width: 8),
                      Text('Activate now'),
                    ],
                  ),
                  Switch(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Consumer<AdvertisementProvider>(
                builder: (context, adProvider, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: adProvider.isLoading ? null : _submit,
                      icon: adProvider.isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.add),
                      label: Text(adProvider.isLoading ? 'Saving...' : 'Add Advertisement', style: const TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // helper builder for compact number input fields used in the advanced section
  Widget _buildNumberField({required TextEditingController controller, required String label, IconData? icon}) {
    return SizedBox(
      width: 160,
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: icon != null ? Icon(icon) : null,
          isDense: true,
        ),
      ),
    );
  }
}
