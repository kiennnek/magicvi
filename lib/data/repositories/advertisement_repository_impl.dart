import 'dart:async';

import '../../domain/entities/advertisement.dart';
import '../../domain/repositories/advertisement_repository.dart';
import '../datasources/local/hive_database.dart';
import '../models/advertisement_model.dart';
import '../../core/errors/exceptions.dart';

class AdvertisementRepositoryImpl implements AdvertisementRepository {
  final StreamController<List<Advertisement>> _advertisementsController = 
      StreamController<List<Advertisement>>.broadcast();

  @override
  Future<List<Advertisement>> getAllAdvertisements() async {
    try {
      final models = HiveDatabase.getAllAdvertisements();
      return models.map((model) => model.toEntity()).toList();
    } catch (e) {
      throw DatabaseException('Failed to get all advertisements: $e');
    }
  }

  @override
  Future<void> saveAdvertisement(Advertisement advertisement) async {
    try {
      final model = AdvertisementModel.fromEntity(advertisement);
      await HiveDatabase.saveAdvertisement(model);
      _notifyAdvertisementsChanged();
    } catch (e) {
      throw DatabaseException('Failed to save advertisement: $e');
    }
  }

  @override
  Future<void> deleteAdvertisement(String id) async {
    try {
      await HiveDatabase.deleteAdvertisement(id);
      _notifyAdvertisementsChanged();
    } catch (e) {
      throw DatabaseException('Failed to delete advertisement: $e');
    }
  }

  @override
  Future<void> updateAdvertisement(Advertisement advertisement) async {
    try {
      final model = AdvertisementModel.fromEntity(advertisement);
      await HiveDatabase.saveAdvertisement(model);
      _notifyAdvertisementsChanged();
    } catch (e) {
      throw DatabaseException('Failed to update advertisement: $e');
    }
  }

  @override
  Future<Advertisement?> getAdvertisementById(String id) async {
    try {
      final model = HiveDatabase.advertisementsBox.get(id);
      return model?.toEntity();
    } catch (e) {
      throw DatabaseException('Failed to get advertisement by id: $e');
    }
  }

  @override
  Future<List<Advertisement>> getAdvertisementsByType(AdType type) async {
    try {
      final allAds = await getAllAdvertisements();
      return allAds.where((ad) => ad.type == type).toList();
    } catch (e) {
      throw DatabaseException('Failed to get advertisements by type: $e');
    }
  }

  @override
  Future<List<Advertisement>> getActiveAdvertisements() async {
    try {
      final allAds = await getAllAdvertisements();
      return allAds.where((ad) => ad.isActive).toList();
    } catch (e) {
      throw DatabaseException('Failed to get active advertisements: $e');
    }
  }

  @override
  Future<void> toggleAdvertisementStatus(String id, bool isActive) async {
    try {
      final model = HiveDatabase.advertisementsBox.get(id);
      if (model != null) {
        final updatedModel = model.copyWith(
          isActive: isActive,
          updatedAt: DateTime.now(),
        );
        await HiveDatabase.saveAdvertisement(updatedModel);
        _notifyAdvertisementsChanged();
      }
    } catch (e) {
      throw DatabaseException('Failed to toggle advertisement status: $e');
    }
  }

  @override
  Stream<List<Advertisement>> watchAdvertisements() {
    // Initial load
    getAllAdvertisements().then((advertisements) {
      if (!_advertisementsController.isClosed) {
        _advertisementsController.add(advertisements);
      }
    });
    
    return _advertisementsController.stream;
  }

  @override
  Future<double> getTotalBudget() async {
    try {
      final allAds = await getAllAdvertisements();
      return allAds
          .where((ad) => ad.isActive)
          .fold<double>(0.0, (double sum, Advertisement ad) => sum + ad.budget);
    } catch (e) {
      throw DatabaseException('Failed to get total budget: $e');
    }
  }

  @override
  Future<Map<AdType, int>> getAdvertisementCountByType() async {
    try {
      final allAds = await getAllAdvertisements();
      final countMap = <AdType, int>{};
      
      for (final type in AdType.values) {
        countMap[type] = allAds.where((ad) => ad.type == type).length;
      }
      
      return countMap;
    } catch (e) {
      throw DatabaseException('Failed to get advertisement count by type: $e');
    }
  }

  void _notifyAdvertisementsChanged() {
    getAllAdvertisements().then((advertisements) {
      if (!_advertisementsController.isClosed) {
        _advertisementsController.add(advertisements);
      }
    });
  }

  void dispose() {
    _advertisementsController.close();
  }
}
