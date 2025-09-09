import 'package:hive_flutter/hive_flutter.dart';
import '../../models/chat_message_model.dart';
import '../../models/advertisement_model.dart';
import '../../models/analytics_model.dart';

class HiveDatabase {
  static const String chatMessagesBoxName = 'chat_messages';
  static const String advertisementsBoxName = 'advertisements';
  static const String analyticsBoxName = 'analytics';
  static const String settingsBoxName = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ChatMessageModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AdvertisementModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AnalyticsDataModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(AdTypeModelAdapter());
    }

    // Open boxes
    await openBoxes();
  }

  static Future<void> openBoxes() async {
    await Future.wait([
      Hive.openBox<ChatMessageModel>(chatMessagesBoxName),
      Hive.openBox<AdvertisementModel>(advertisementsBoxName),
      Hive.openBox<AnalyticsDataModel>(analyticsBoxName),
      Hive.openBox(settingsBoxName),
    ]);
  }

  static Box<ChatMessageModel> get chatMessagesBox =>
      Hive.box<ChatMessageModel>(chatMessagesBoxName);

  static Box<AdvertisementModel> get advertisementsBox =>
      Hive.box<AdvertisementModel>(advertisementsBoxName);

  static Box<AnalyticsDataModel> get analyticsBox =>
      Hive.box<AnalyticsDataModel>(analyticsBoxName);

  static Box get settingsBox => Hive.box(settingsBoxName);

  static Future<void> clearAllData() async {
    await Future.wait([
      chatMessagesBox.clear(),
      advertisementsBox.clear(),
      analyticsBox.clear(),
      settingsBox.clear(),
    ]);
  }

  static Future<void> close() async {
    await Hive.close();
  }

  // Utility methods for common operations
  static Future<void> saveChatMessage(ChatMessageModel message) async {
    await chatMessagesBox.put(message.id, message);
  }

  static Future<void> saveAdvertisement(AdvertisementModel ad) async {
    await advertisementsBox.put(ad.id, ad);
  }

  static Future<void> saveAnalyticsData(AnalyticsDataModel analytics) async {
    await analyticsBox.put(analytics.id, analytics);
  }

  static List<ChatMessageModel> getAllChatMessages() {
    return chatMessagesBox.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  static List<AdvertisementModel> getAllAdvertisements() {
    return advertisementsBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static List<AnalyticsDataModel> getAllAnalytics() {
    return analyticsBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<AnalyticsDataModel> getAnalyticsByAdId(String adId) {
    return analyticsBox.values
        .where((analytics) => analytics.adId == adId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> deleteChatMessage(String id) async {
    await chatMessagesBox.delete(id);
  }

  static Future<void> deleteAdvertisement(String id) async {
    await advertisementsBox.delete(id);
  }

  static Future<void> deleteAnalyticsData(String id) async {
    await analyticsBox.delete(id);
  }

  // Settings methods
  static Future<void> saveSetting(String key, dynamic value) async {
    await settingsBox.put(key, value);
  }

  static T? getSetting<T>(String key, {T? defaultValue}) {
    return settingsBox.get(key, defaultValue: defaultValue) as T?;
  }

  static Future<void> deleteSetting(String key) async {
    await settingsBox.delete(key);
  }
}
