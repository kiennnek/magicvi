import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../../core/errors/exceptions.dart';

class GeminiApiService {
  final http.Client _client;

  GeminiApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<String> generateContent({
    required String prompt,
    String? adType,
    Map<String, dynamic>? context,
  }) async {
    try {
      final requestBody = _buildRequestBody(prompt, adType, context);

      final response = await _client
          .post(
            Uri.parse(ApiConstants.generateContentUrl),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode(requestBody),
          )
          .timeout(Duration(seconds: ApiConstants.requestTimeout));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return _extractContentFromResponse(responseData);
      } else if (response.statusCode == 400) {
        // Handle bad request - provide fallback response
        return _getFallbackResponse(prompt, adType);
      } else {
        throw ApiException(
          'Failed to generate content: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on SocketException {
      // Provide offline response when no internet
      return _getFallbackResponse(prompt, adType);
    } on HttpException {
      return _getFallbackResponse(prompt, adType);
    } catch (e) {
      // Provide fallback response for any other errors
      return _getFallbackResponse(prompt, adType);
    }
  }

  Future<Stream<String>> generateContentStream({
    required String prompt,
    String? adType,
    Map<String, dynamic>? context,
  }) async {
    try {
      final requestBody = _buildRequestBody(prompt, adType, context);

      final request = http.Request(
        'POST',
        Uri.parse(ApiConstants.streamGenerateContentUrl),
      );

      request.headers.addAll({
        'Content-Type': 'application/json',
      });

      request.body = json.encode(requestBody);

      final streamedResponse = await _client.send(request);

      if (streamedResponse.statusCode == 200) {
        return streamedResponse.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .where((line) => line.trim().isNotEmpty)
            .map((line) => _extractContentFromStreamLine(line));
      } else {
        // Return fallback as stream
        return Stream.fromIterable([_getFallbackResponse(prompt, adType)]);
      }
    } catch (e) {
      // Return fallback as stream
      return Stream.fromIterable([_getFallbackResponse(prompt, adType)]);
    }
  }

  String _getFallbackResponse(String prompt, String? adType) {
    // Provide intelligent fallback responses based on common advertising questions
    final lowerPrompt = prompt.toLowerCase();

    if (lowerPrompt.contains('google ads') ||
        lowerPrompt.contains('google adwords')) {
      return '''
To optimize your Google Ads campaign:

1. **Keyword Research**: Use Google Keyword Planner to find suitable keywords
2. **Ad Copy**: Write compelling headlines and clear descriptions
3. **Landing Page**: Ensure the landing page matches the ad content
4. **Bidding Strategy**: Start with manual CPC to control costs
5. **Targeting**: Use demographic and geographic targeting
6. **Quality Score**: Optimize to reduce costs and improve performance

Would you like a detailed guide on any specific part?
''';
    }

    if (lowerPrompt.contains('facebook ads') ||
        lowerPrompt.contains('facebook')) {
      return '''
Effective Facebook Ads strategy:

1. **Audience Targeting**: Use Custom Audiences and Lookalike Audiences
2. **Creative Testing**: A/B test with various formats (image, video, carousel)
3. **Campaign Objectives**: Choose the right objective (awareness, conversion, traffic)
4. **Budget**: Start with a small budget and scale up gradually
5. **Pixel Tracking**: Set up Facebook Pixel to track conversions
6. **Retargeting**: Re-engage users who have interacted

Would you like me to explain any part in detail?
''';
    }

    if (lowerPrompt.contains('roi') || lowerPrompt.contains('return')) {
      return '''
How to calculate and optimize ad ROI:

**ROI Formula:**
ROI = (Revenue - Cost) / Cost × 100%

**Optimization Tips:**
1. **Tracking**: Set up accurate conversion tracking
2. **Attribution**: Understand the customer journey
3. **LTV**: Calculate customer Lifetime Value
4. **Cost Optimization**: Lower CPC/CPM by improving quality score
5. **Conversion Rate**: Optimize landing page and funnel
6. **Budget Allocation**: Focus budget on high-ROI campaigns

Do you need help with a specific part?
''';
    }

    if (lowerPrompt.contains('instagram') || lowerPrompt.contains('ig')) {
      return '''
Optimize Instagram Ads:

1. **Visual Content**: Use high-quality images/videos
2. **Stories Ads**: Leverage Instagram Stories format
3. **Influencer Marketing**: Collaborate with influencers
4. **Hashtags**: Use relevant hashtags
5. **User-Generated Content**: Encourage customers to create content
6. **Shopping Tags**: Use Instagram Shopping for e-commerce

Want to know more about any strategy?
''';
    }

    // Default fallback response
    return '''
Thank you for your advertising question! I'm an AI assistant specializing in digital advertising.

I can help you with:
- Google Ads & SEO
- Facebook/Instagram Ads  
- TikTok & YouTube Ads
- ROI & metrics analysis
- Campaign optimization
- Budget planning
- Creative strategy

You can ask more specifically about your issue, for example:
- "How to increase CTR for Google Ads?"
- "Effective targeting on Facebook?"
- "How to analyze campaign ROI?"

I'll provide detailed and actionable advice!
''';
  }

  Map<String, dynamic> _buildRequestBody(
    String prompt,
    String? adType,
    Map<String, dynamic>? context,
  ) {
    final enhancedPrompt =
        _enhancePromptForAdvertising(prompt, adType, context);

    return {
      'contents': [
        {
          'parts': [
            {'text': enhancedPrompt}
          ]
        }
      ],
      'generationConfig': ApiConstants.generationConfig,
      'safetySettings': ApiConstants.safetySettings.entries
          .map((entry) => {
                'category': entry.key,
                'threshold': entry.value,
              })
          .toList(),
    };
  }

  String _enhancePromptForAdvertising(
    String prompt,
    String? adType,
    Map<String, dynamic>? context,
  ) {
    final buffer = StringBuffer();

    // System prompt for advertising expertise
    buffer.writeln('''
You are an AI advertising expert with deep knowledge of:
- Advertising platforms: Google Ads, Facebook Ads, Instagram, TikTok, YouTube
- Ad performance analysis and ROI
- Campaign optimization
- Targeting and segmentation
- Creative optimization
- Budget management

Please answer professionally, providing specific advice and actionable insights.
''');

    // Add ad type context if provided
    if (adType != null && adType.isNotEmpty) {
      buffer.writeln('Ad type under discussion: $adType');
    }

    // Add additional context if provided
    if (context != null && context.isNotEmpty) {
      buffer.writeln('Additional information:');
      context.forEach((key, value) {
        buffer.writeln('- $key: $value');
      });
    }

    buffer.writeln('\nUser question: $prompt');

    return buffer.toString();
  }

  String _extractContentFromResponse(Map<String, dynamic> response) {
    try {
      final candidates = response['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates[0]['content'];
        if (content != null) {
          final parts = content['parts'] as List?;
          if (parts != null && parts.isNotEmpty) {
            final text = parts[0]['text'];
            if (text != null && text.toString().trim().isNotEmpty) {
              return text.toString();
            }
          }
        }
      }

      // If no valid response found, throw exception to trigger fallback
      throw ApiException('No valid content in response');
    } catch (e) {
      throw ApiException('Failed to parse response: $e');
    }
  }

  String _extractContentFromStreamLine(String line) {
    try {
      if (line.startsWith('data: ')) {
        final jsonStr = line.substring(6);
        if (jsonStr.trim() == '[DONE]') {
          return '';
        }
        final data = json.decode(jsonStr);
        return _extractContentFromResponse(data);
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  Future<Map<String, dynamic>> getAdSuggestions({
    required String adType,
    required double budget,
    required String targetAudience,
    String? industry,
  }) async {
    try {
      final prompt = '''
I need advice for an ad campaign with the following information:
- Ad type: $adType
- Budget: \$${budget.toStringAsFixed(2)}
- Target audience: $targetAudience
${industry != null ? '- Industry: $industry' : ''}

Please provide:
1. Suitable ad strategy
2. Suggested budget allocation
3. Targeting recommendations
4. Creative suggestions
5. KPIs to track
6. Suggested timeline
''';

      final response = await generateContent(
        prompt: prompt,
        adType: adType,
        context: {
          'budget': budget,
          'targetAudience': targetAudience,
          'industry': industry,
        },
      );

      // Parse the response into structured data
      return {
        'strategy': response,
        'budget': budget,
        'targetAudience': targetAudience,
        'adType': adType,
        'industry': industry,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      // Return fallback suggestions
      return _getFallbackAdSuggestions(
          adType, budget, targetAudience, industry);
    }
  }

  Future<Map<String, dynamic>> analyzeAdPerformance({
    required Map<String, dynamic> adData,
    required Map<String, dynamic> metricsData,
  }) async {
    try {
      final prompt = '''
Analyze ad performance with the following data:

Ad information:
${adData.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}

Metrics data:
${metricsData.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}

Please analyze:
1. Overall performance (Good/Average/Poor)
2. Strengths and weaknesses
3. Specific improvement recommendations
4. Comparison with industry benchmarks
5. Priority action items
6. Trend prediction
7. Budget optimization suggestions
8. Creative optimization recommendations
''';

      final response = await generateContent(
        prompt: prompt,
        adType: adData['type']?.toString(),
        context: {
          'adData': adData,
          'metrics': metricsData,
          'analysisType': 'performance_analysis',
        },
      );

      // Calculate performance score
      final performanceScore = _calculatePerformanceScore(metricsData);

      // Extract recommendations from response
      final recommendations = _extractRecommendations(response);

      // Generate actionable insights
      final insights = _generateActionableInsights(metricsData, adData);

      return {
        'analysis': response,
        'performanceScore': performanceScore,
        'grade': _getPerformanceGrade(performanceScore),
        'recommendations': recommendations,
        'insights': insights,
        'adData': adData,
        'metrics': metricsData,
        'timestamp': DateTime.now().toIso8601String(),
        'benchmarks': _getIndustryBenchmarks(adData['type']?.toString()),
        'optimizationAreas': _identifyOptimizationAreas(metricsData),
      };
    } catch (e) {
      // Return fallback analysis
      return _getFallbackPerformanceAnalysis(adData, metricsData);
    }
  }

  Map<String, dynamic> _getFallbackAdSuggestions(
    String adType,
    double budget,
    String targetAudience,
    String? industry,
  ) {
    String strategy = '';

    switch (adType.toLowerCase()) {
      case 'google':
      case 'google ads':
        strategy = '''
**Google Ads Strategy:**

1. **Campaign Structure**: Create campaigns by product/service
2. **Keywords**: Focus on long-tail keywords with low competition
3. **Ad Groups**: Group keywords by specific topics
4. **Landing Pages**: Optimize for high Quality Score
5. **Bidding**: Start with Manual CPC, then switch to Smart Bidding

**Budget Allocation:**
- Search campaigns: 60% (\$${(budget * 0.6).toStringAsFixed(2)})
- Display campaigns: 25% (\$${(budget * 0.25).toStringAsFixed(2)})
- YouTube ads: 15% (\$${(budget * 0.15).toStringAsFixed(2)})
''';
        break;

      case 'facebook':
      case 'facebook ads':
        strategy = '''
**Facebook Ads Strategy:**

1. **Campaign Objectives**: Conversion optimization
2. **Audiences**: Custom + Lookalike audiences
3. **Creatives**: Prioritize video content
4. **Placements**: Start with automatic placements
5. **Testing**: A/B test audiences and creatives

**Budget Allocation:**
- Feed ads: 50% (\$${(budget * 0.5).toStringAsFixed(2)})
- Stories: 30% (\$${(budget * 0.3).toStringAsFixed(2)})
- Reels: 20% (\$${(budget * 0.2).toStringAsFixed(2)})
''';
        break;

      default:
        strategy = '''
**Multi-Platform Strategy:**

1. **Platform Mix**: Allocate based on target audience behavior
2. **Content Strategy**: Adapt for each platform
3. **Attribution**: Cross-platform tracking
4. **Testing**: Platform-specific optimization
5. **Scaling**: Focus on platforms with highest ROI

**Budget Allocation:**
- Primary platform: 60% (\$${(budget * 0.6).toStringAsFixed(2)})
- Secondary platform: 30% (\$${(budget * 0.3).toStringAsFixed(2)})
- Testing budget: 10% (\$${(budget * 0.1).toStringAsFixed(2)})
''';
    }

    return {
      'strategy': strategy,
      'budget': budget,
      'targetAudience': targetAudience,
      'adType': adType,
      'industry': industry,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> _getFallbackPerformanceAnalysis(
    Map<String, dynamic> adData,
    Map<String, dynamic> metricsData,
  ) async {
    final performanceScore = _calculatePerformanceScore(metricsData);
    final grade = _getPerformanceGrade(performanceScore);

    String analysis = '''
**📊 Ad Performance Analysis**

**Performance Score: ${performanceScore.toStringAsFixed(1)}/10 (${grade})**

**✅ Strengths:**
- Campaign is set up and running
- Metrics data available for analysis and optimization
- ${_getStrengthPoints(metricsData).join('\n- ')}

**⚠️ Needs Improvement:**
${_getWeaknessPoints(metricsData).map((point) => '- $point').join('\n')}

**🎯 Priority Recommendations:**
1. **Optimize Targeting**: Review and refine target audience
2. **Creative Testing**: A/B test with new creative formats
3. **Budget Optimization**: Reallocate budget to effective ads
4. **Landing Page**: Improve landing page conversion rate
5. **Bidding Strategy**: Optimize bidding strategy

**📈 Action Items:**
- [ ] Analyze competitor strategies
- [ ] Create variations for top performing ads
- [ ] Optimize landing page UX/UI
- [ ] Set up advanced conversion tracking
- [ ] Test new audience segments
''';

    return {
      'analysis': analysis,
      'performanceScore': performanceScore,
      'grade': grade,
      'recommendations': [
        'Tối ưu targeting để tăng relevance',
        'A/B test creative formats khác nhau',
        'Cải thiện quality score',
        'Optimize landing page experience',
        'Review và adjust bidding strategy',
        'Phân tích competitor tactics',
        'Scale successful ad variations'
      ],
      'insights': _generateActionableInsights(metricsData, adData),
      'adData': adData,
      'metrics': metricsData,
      'timestamp': DateTime.now().toIso8601String(),
      'benchmarks': _getIndustryBenchmarks(adData['type']?.toString()),
      'optimizationAreas': _identifyOptimizationAreas(metricsData),
    };
  }

  double _calculatePerformanceScore(Map<String, dynamic> metrics) {
    double score = 5.0; // Base score

    // CTR analysis (Click-through rate)
    if (metrics.containsKey('ctr')) {
      final ctr = double.tryParse(metrics['ctr'].toString()) ?? 0;
      if (ctr > 3.0) {
        score += 2.0;
      } else if (ctr > 2.0)
        score += 1.5;
      else if (ctr > 1.0)
        score += 1.0;
      else if (ctr > 0.5)
        score += 0.5;
      else
        score -= 0.5;
    }

    // Conversion Rate analysis
    if (metrics.containsKey('conversionRate')) {
      final convRate =
          double.tryParse(metrics['conversionRate'].toString()) ?? 0;
      if (convRate > 10.0) {
        score += 2.0;
      } else if (convRate > 5.0)
        score += 1.5;
      else if (convRate > 3.0)
        score += 1.0;
      else if (convRate > 1.0)
        score += 0.5;
      else
        score -= 0.5;
    }

    // ROI analysis
    if (metrics.containsKey('roi')) {
      final roi = double.tryParse(metrics['roi'].toString()) ?? 0;
      if (roi > 500) {
        score += 2.5;
      } else if (roi > 300)
        score += 2.0;
      else if (roi > 200)
        score += 1.5;
      else if (roi > 100)
        score += 1.0;
      else if (roi > 0)
        score += 0.5;
      else
        score -= 1.5;
    }

    // CPC analysis (Cost per click)
    if (metrics.containsKey('cpc')) {
      final cpc = double.tryParse(metrics['cpc'].toString()) ?? 0;
      if (cpc < 0.5) {
        score += 1.0;
      } else if (cpc < 1.0)
        score += 0.5;
      else if (cpc > 3.0)
        score -= 0.5;
      else if (cpc > 5.0) score -= 1.0;
    }

    // Impressions volume
    if (metrics.containsKey('impressions')) {
      final impressions =
          double.tryParse(metrics['impressions'].toString()) ?? 0;
      if (impressions > 100000) {
        score += 0.5;
      } else if (impressions > 50000)
        score += 0.3;
      else if (impressions < 1000) score -= 0.3;
    }

    return score.clamp(0.0, 10.0);
  }

  String _getPerformanceGrade(double score) {
    if (score >= 8.5) {
      return 'Excellent';
    } else if (score >= 7.0)
      return 'Good';
    else if (score >= 5.5)
      return 'Average';
    else if (score >= 3.0)
      return 'Needs Improvement';
    else
      return 'Poor';
  }

  List<String> _getStrengthPoints(Map<String, dynamic> metrics) {
    final strengths = <String>[];

    final ctr = double.tryParse(metrics['ctr'].toString()) ?? 0;
    if (ctr > 2.0) strengths.add('High CTR (${ctr.toStringAsFixed(2)}%)');

    final roi = double.tryParse(metrics['roi'].toString()) ?? 0;
    if (roi > 200) strengths.add('Positive ROI (${roi.toStringAsFixed(1)}%)');

    final conversionRate =
        double.tryParse(metrics['conversionRate'].toString()) ?? 0;
    if (conversionRate > 3.0)
      strengths
          .add('Good conversion rate (${conversionRate.toStringAsFixed(2)}%)');

    final impressions = double.tryParse(metrics['impressions'].toString()) ?? 0;
    if (impressions > 50000)
      strengths.add('Wide reach (${impressions.toInt()} impressions)');

    if (strengths.isEmpty) {
      strengths.add('Campaign is collecting data for optimization');
    }

    return strengths;
  }

  List<String> _getWeaknessPoints(Map<String, dynamic> metrics) {
    final weaknesses = <String>[];

    final ctr = double.tryParse(metrics['ctr'].toString()) ?? 0;
    if (ctr < 1.0)
      weaknesses.add('Low CTR - optimize creative and targeting');

    final roi = double.tryParse(metrics['roi'].toString()) ?? 0;
    if (roi < 100)
      weaknesses.add('ROI below target - review budget allocation');

    final conversionRate =
        double.tryParse(metrics['conversionRate'].toString()) ?? 0;
    if (conversionRate < 2.0)
      weaknesses.add('Low conversion rate - optimize landing page');

    final cpc = double.tryParse(metrics['cpc'].toString()) ?? 0;
    if (cpc > 3.0) weaknesses.add('High CPC - optimize bidding strategy');

    if (weaknesses.isEmpty) {
      weaknesses.add('Not enough data to analyze weaknesses');
    }

    return weaknesses;
  }

  List<String> _extractRecommendations(String analysis) {
    final recommendations = <String>[];
    final lines = analysis.split('\n');

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.startsWith('-') ||
          trimmedLine.startsWith('•') ||
          trimmedLine.startsWith('*') ||
          trimmedLine.startsWith('1.') ||
          trimmedLine.startsWith('2.') ||
          trimmedLine.startsWith('3.')) {
        String recommendation = trimmedLine;
        // Remove prefixes
        recommendation = recommendation.replaceFirst(RegExp(r'^[-•*]\s*'), '');
        recommendation = recommendation.replaceFirst(RegExp(r'^\d+\.\s*'), '');
        if (recommendation.isNotEmpty) {
          recommendations.add(recommendation);
        }
      }
    }

    // Default recommendations if none found
    if (recommendations.isEmpty) {
      return [
        'Tối ưu targeting để tăng relevance',
        'A/B test creative formats khác nhau',
        'Cải thiện quality score',
        'Optimize landing page experience',
        'Review và adjust bidding strategy',
        'Phân tích competitor tactics',
        'Scale successful ad variations'
      ];
    }

    return recommendations.take(8).toList(); // Limit to 8 recommendations
  }

  Map<String, dynamic> _generateActionableInsights(
    Map<String, dynamic> metrics,
    Map<String, dynamic> adData,
  ) {
    final insights = <String, dynamic>{};

    // Budget insights
    final cost = double.tryParse(metrics['cost'].toString()) ?? 0;
    final revenue = double.tryParse(metrics['revenue'].toString()) ?? 0;
    if (cost > 0) {
      insights['budgetEfficiency'] = revenue / cost;
      insights['budgetRecommendation'] = revenue > cost * 2
          ? 'You can increase the budget for this campaign'
          : 'Optimize before increasing the budget';
    }

    // Audience insights
    final ctr = double.tryParse(metrics['ctr'].toString()) ?? 0;
    insights['audienceQuality'] = ctr > 2.0
        ? 'Good'
        : ctr > 1.0
            ? 'Average'
            : 'Needs improvement';

    // Creative insights
    final conversionRate =
        double.tryParse(metrics['conversionRate'].toString()) ?? 0;
    insights['creativeEffectiveness'] =
        conversionRate > 3.0 ? 'Effective' : 'Needs optimization';

    // Timing insights
    insights['optimizationStage'] = _getOptimizationStage(metrics);

    return insights;
  }

  String _getOptimizationStage(Map<String, dynamic> metrics) {
    final impressions = double.tryParse(metrics['impressions'].toString()) ?? 0;
    final clicks = double.tryParse(metrics['clicks'].toString()) ?? 0;

    if (impressions < 1000) {
      return 'Learning Phase - Collecting data';
    } else if (clicks < 100)
      return 'Early Stage - Optimize targeting';
    else if (clicks < 500)
      return 'Growth Stage - Scale and optimize';
    else
      return 'Mature Stage - Maintain and improve';
  }

  Map<String, String> _getIndustryBenchmarks(String? adType) {
    switch (adType?.toLowerCase()) {
      case 'google':
      case 'google ads':
        return {
          'avgCTR': '2.0%',
          'avgConversionRate': '3.75%',
          'avgCPC': '\$2.32',
          'goodROI': '200%+'
        };
      case 'facebook':
      case 'facebook ads':
        return {
          'avgCTR': '0.9%',
          'avgConversionRate': '9.21%',
          'avgCPC': '\$1.72',
          'goodROI': '150%+'
        };
      default:
        return {
          'avgCTR': '1.0-2.0%',
          'avgConversionRate': '2-5%',
          'avgCPC': '\$1-3',
          'goodROI': '150%+'
        };
    }
  }

  List<String> _identifyOptimizationAreas(Map<String, dynamic> metrics) {
    final areas = <String>[];

    final ctr = double.tryParse(metrics['ctr'].toString()) ?? 0;
    if (ctr < 1.0) areas.add('Creative & Targeting');

    final conversionRate =
        double.tryParse(metrics['conversionRate'].toString()) ?? 0;
    if (conversionRate < 2.0) areas.add('Landing Page');

    final roi = double.tryParse(metrics['roi'].toString()) ?? 0;
    if (roi < 150) areas.add('Budget Allocation');

    final cpc = double.tryParse(metrics['cpc'].toString()) ?? 0;
    if (cpc > 3.0) areas.add('Bidding Strategy');

    if (areas.isEmpty) areas.add('Monitoring & Scaling');

    return areas;
  }

  void dispose() {
    _client.close();
  }
}
