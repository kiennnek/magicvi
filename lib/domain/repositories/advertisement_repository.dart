import '../entities/advertisement.dart';

abstract class AdvertisementRepository {
  Future<List<Advertisement>> getAllAdvertisements();
  Future<void> saveAdvertisement(Advertisement advertisement);
  Future<void> deleteAdvertisement(String id);
  Future<void> updateAdvertisement(Advertisement advertisement);
  Future<Advertisement?> getAdvertisementById(String id);
  Future<List<Advertisement>> getAdvertisementsByType(AdType type);
  Future<List<Advertisement>> getActiveAdvertisements();
  Future<void> toggleAdvertisementStatus(String id, bool isActive);
  Stream<List<Advertisement>> watchAdvertisements();
  Future<double> getTotalBudget();
  Future<Map<AdType, int>> getAdvertisementCountByType();
}

