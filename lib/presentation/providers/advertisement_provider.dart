import 'package:flutter/foundation.dart';
import '../../domain/entities/advertisement.dart';
import '../../domain/usecases/get_ad_suggestions_usecase.dart';
import '../../core/errors/exceptions.dart';

enum AdvertisementState {
  idle,
  loading,
  loadingSuggestions,
  error,
}

class AdvertisementProvider extends ChangeNotifier {
  final GetAdSuggestionsUseCase _getAdSuggestionsUseCase;

  AdvertisementProvider(this._getAdSuggestionsUseCase) {
    _loadAdvertisements();
  }

  // State
  AdvertisementState _state = AdvertisementState.idle;
  List<Advertisement> _advertisements = [];
  Map<String, dynamic>? _currentSuggestions;
  String? _errorMessage;
  AdType? _selectedAdType;
  double _totalBudget = 0.0;
  Map<AdType, int> _adCountByType = {};

  // Getters
  AdvertisementState get state => _state;
  List<Advertisement> get advertisements => List.unmodifiable(_advertisements);
  List<Advertisement> get activeAdvertisements => 
      _advertisements.where((ad) => ad.isActive).toList();
  Map<String, dynamic>? get currentSuggestions => _currentSuggestions;
  String? get errorMessage => _errorMessage;
  AdType? get selectedAdType => _selectedAdType;
  double get totalBudget => _totalBudget;
  Map<AdType, int> get adCountByType => Map.unmodifiable(_adCountByType);
  bool get isLoading => _state == AdvertisementState.loading;
  bool get isLoadingSuggestions => _state == AdvertisementState.loadingSuggestions;

  // Methods
  void setSelectedAdType(AdType? adType) {
    _selectedAdType = adType;
    notifyListeners();
  }

  Future<void> getAdSuggestions({
    required AdType adType,
    required double budget,
    required String targetAudience,
    String? industry,
    String? objective,
  }) async {
    try {
      _setState(AdvertisementState.loadingSuggestions);
      _clearError();

      final suggestions = await _getAdSuggestionsUseCase.execute(
        adType: adType,
        budget: budget,
        targetAudience: targetAudience,
        industry: industry,
        objective: objective,
      );

      _currentSuggestions = suggestions;
      _setState(AdvertisementState.idle);
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setState(AdvertisementState.error);
    }
  }

  Future<void> createAdvertisementFromSuggestion({
    required AdType adType,
    required double budget,
    required String targetAudience,
    String? title,
    String? description,
  }) async {
    try {
      _setState(AdvertisementState.loading);
      _clearError();

      if (_currentSuggestions == null) {
        throw ValidationException('No suggestions available');
      }

      await _getAdSuggestionsUseCase.createAdvertisementFromSuggestion(
        suggestion: _currentSuggestions!,
        adType: adType,
        budget: budget,
        targetAudience: targetAudience,
        title: title,
        description: description,
      );

      await _loadAdvertisements();
      _setState(AdvertisementState.idle);
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setState(AdvertisementState.error);
    }
  }

  Future<void> createAdvertisement({
    required AdType adType,
    required double budget,
    required String targetAudience,
    required String title,
    String? description,
    Map<String, dynamic>? metrics,
    bool isActive = false,
  }) async {
    try {
      _setState(AdvertisementState.loading);
      _clearError();

      await _getAdSuggestionsUseCase.createAdvertisement(
        adType: adType,
        budget: budget,
        targetAudience: targetAudience,
        title: title,
        description: description,
        metrics: metrics,
        isActive: isActive,
      );

      await _loadAdvertisements();
      _setState(AdvertisementState.idle);
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setState(AdvertisementState.error);
    }
  }

  Future<void> toggleAdvertisementStatus(String id, bool isActive) async {
    try {
      await _getAdSuggestionsUseCase.toggleAdvertisementStatus(id, isActive);
      await _loadAdvertisements();
    } catch (e) {
      _setError(_getErrorMessage(e));
    }
  }

  Future<void> updateAdvertisement(Advertisement advertisement) async {
    try {
      _setState(AdvertisementState.loading);
      await _getAdSuggestionsUseCase.updateAdvertisement(advertisement);
      await _loadAdvertisements();
      _setState(AdvertisementState.idle);
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setState(AdvertisementState.error);
    }
  }

  Future<void> deleteAdvertisement(String id) async {
    try {
      await _getAdSuggestionsUseCase.deleteAdvertisement(id);
      await _loadAdvertisements();
    } catch (e) {
      _setError(_getErrorMessage(e));
    }
  }

  Future<void> getAdTypeRecommendations({
    required String industry,
    required double budget,
    required String objective,
  }) async {
    try {
      _setState(AdvertisementState.loadingSuggestions);
      _clearError();

      final recommendations = await _getAdSuggestionsUseCase.getAdTypeRecommendations(
        industry: industry,
        budget: budget,
        objective: objective,
      );

      _currentSuggestions = recommendations;
      _setState(AdvertisementState.idle);
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setState(AdvertisementState.error);
    }
  }

  List<Advertisement> getAdvertisementsByType(AdType type) {
    return _advertisements.where((ad) => ad.type == type).toList();
  }

  Advertisement? getAdvertisementById(String id) {
    try {
      return _advertisements.firstWhere((ad) => ad.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> refreshAdvertisements() async {
    await _loadAdvertisements();
  }

  void clearSuggestions() {
    _currentSuggestions = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  // Private methods
  Future<void> _loadAdvertisements() async {
    try {
      final advertisements = await _getAdSuggestionsUseCase.getAllAdvertisements();
      _advertisements = advertisements;
      
      // Update derived data
      _totalBudget = await _getAdSuggestionsUseCase.getTotalBudget();
      _adCountByType = await _getAdSuggestionsUseCase.getAdvertisementCountByType();
      
      notifyListeners();
    } catch (e) {
      _setError(_getErrorMessage(e));
    }
  }

  void _setState(AdvertisementState newState) {
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
