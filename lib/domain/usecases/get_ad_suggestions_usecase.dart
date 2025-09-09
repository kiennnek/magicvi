import '../entities/advertisement.dart';
import '../repositories/advertisement_repository.dart';
import '../../data/datasources/remote/gemini_api_service.dart';
import '../../core/errors/exceptions.dart';
import 'package:uuid/uuid.dart';

class GetAdSuggestionsUseCase {
  final AdvertisementRepository _advertisementRepository;
  final GeminiApiService _geminiApiService;
  final Uuid _uuid = const Uuid();

  GetAdSuggestionsUseCase(this._advertisementRepository, this._geminiApiService);

  Future<Map<String, dynamic>> execute({
    required AdType adType,
    required double budget,
    required String targetAudience,
    String? industry,
    String? objective,
  }) async {
    try {
      final suggestions = await _geminiApiService.getAdSuggestions(
        adType: adType.displayName,
        budget: budget,
        targetAudience: targetAudience,
        industry: industry,
      );

      return {
        'suggestions': suggestions,
        'adType': adType,
        'budget': budget,
        'targetAudience': targetAudience,
        'industry': industry,
        'objective': objective,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ApiException('Failed to get ad suggestions: $e');
    }
  }

  Future<Advertisement> createAdvertisementFromSuggestion({
    required Map<String, dynamic> suggestion,
    required AdType adType,
    required double budget,
    required String targetAudience,
    String? title,
    String? description,
  }) async {
    try {
      final advertisement = Advertisement(
        id: _uuid.v4(),
        type: adType,
        title: title ?? 'New ${adType.displayName} Campaign',
        description: description ?? 'Campaign created from AI suggestions',
        budget: budget,
        targetAudience: targetAudience,
        metrics: {
          'suggested_at': DateTime.now().toIso8601String(),
          'ai_generated': true,
        },
        createdAt: DateTime.now(),
        isActive: false, // Start as inactive until user activates
      );

      await _advertisementRepository.saveAdvertisement(advertisement);
      return advertisement;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw DatabaseException('Failed to create advertisement from suggestion: $e');
    }
  }

  /// Create an advertisement manually with basic fields.
  Future<Advertisement> createAdvertisement({
    required AdType adType,
    required double budget,
    required String targetAudience,
    required String title,
    String? description,
    Map<String, dynamic>? metrics,
    bool isActive = false,
  }) async {
    try {
      final advertisement = Advertisement(
        id: _uuid.v4(),
        type: adType,
        title: title,
        description: description ?? '',
        budget: budget,
        targetAudience: targetAudience,
        metrics: metrics ?? {},
        createdAt: DateTime.now(),
        isActive: isActive,
      );

      await _advertisementRepository.saveAdvertisement(advertisement);
      return advertisement;
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Failed to create advertisement: $e');
    }
  }

  Future<List<Advertisement>> getAllAdvertisements() async {
    try {
      return await _advertisementRepository.getAllAdvertisements();
    } catch (e) {
      throw DatabaseException('Failed to get all advertisements: $e');
    }
  }

  Future<List<Advertisement>> getAdvertisementsByType(AdType type) async {
    try {
      return await _advertisementRepository.getAdvertisementsByType(type);
    } catch (e) {
      throw DatabaseException('Failed to get advertisements by type: $e');
    }
  }

  Future<List<Advertisement>> getActiveAdvertisements() async {
    try {
      return await _advertisementRepository.getActiveAdvertisements();
    } catch (e) {
      throw DatabaseException('Failed to get active advertisements: $e');
    }
  }

  Future<void> toggleAdvertisementStatus(String id, bool isActive) async {
    try {
      await _advertisementRepository.toggleAdvertisementStatus(id, isActive);
    } catch (e) {
      throw DatabaseException('Failed to toggle advertisement status: $e');
    }
  }

  Future<void> updateAdvertisement(Advertisement advertisement) async {
    try {
      final updatedAd = advertisement.copyWith(
        updatedAt: DateTime.now(),
      );
      await _advertisementRepository.updateAdvertisement(updatedAd);
    } catch (e) {
      throw DatabaseException('Failed to update advertisement: $e');
    }
  }

  Future<void> deleteAdvertisement(String id) async {
    try {
      await _advertisementRepository.deleteAdvertisement(id);
    } catch (e) {
      throw DatabaseException('Failed to delete advertisement: $e');
    }
  }

  Future<double> getTotalBudget() async {
    try {
      return await _advertisementRepository.getTotalBudget();
    } catch (e) {
      throw DatabaseException('Failed to get total budget: $e');
    }
  }

  Future<Map<AdType, int>> getAdvertisementCountByType() async {
    try {
      return await _advertisementRepository.getAdvertisementCountByType();
    } catch (e) {
      throw DatabaseException('Failed to get advertisement count by type: $e');
    }
  }

  Future<Map<String, dynamic>> getAdTypeRecommendations({
    required String industry,
    required double budget,
    required String objective,
  }) async {
    try {
      final prompt = '''
Dựa trên thông tin sau, hãy đề xuất loại quảng cáo phù hợp nhất:
- Ngành: $industry
- Ngân sách: \$${budget.toStringAsFixed(2)}
- Mục tiêu: $objective

Hãy xếp hạng các loại quảng cáo sau theo độ phù hợp:
1. Google Ads
2. Facebook Ads
3. Instagram Ads
4. TikTok Ads
5. YouTube Ads
6. Social Media Ads (general)

Đưa ra lý do cho từng lựa chọn và phân bổ ngân sách đề xuất.
''';

      final response = await _geminiApiService.generateContent(prompt: prompt);
      
      return {
        'recommendations': response,
        'industry': industry,
        'budget': budget,
        'objective': objective,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw ApiException('Failed to get ad type recommendations: $e');
    }
  }
}
