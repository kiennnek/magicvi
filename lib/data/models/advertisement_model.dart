import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/advertisement.dart';

part 'advertisement_model.g.dart';

@HiveType(typeId: 3)
enum AdTypeModel {
  @HiveField(0)
  socialMedia,
  @HiveField(1)
  google,
  @HiveField(2)
  facebook,
  @HiveField(3)
  instagram,
  @HiveField(4)
  tiktok,
  @HiveField(5)
  youtube,
  @HiveField(6)
  other,
}

extension AdTypeModelExtension on AdTypeModel {
  AdType toEntity() {
    switch (this) {
      case AdTypeModel.socialMedia:
        return AdType.socialMedia;
      case AdTypeModel.google:
        return AdType.google;
      case AdTypeModel.facebook:
        return AdType.facebook;
      case AdTypeModel.instagram:
        return AdType.instagram;
      case AdTypeModel.tiktok:
        return AdType.tiktok;
      case AdTypeModel.youtube:
        return AdType.youtube;
      case AdTypeModel.other:
        return AdType.other;
    }
  }

  static AdTypeModel fromEntity(AdType entity) {
    switch (entity) {
      case AdType.socialMedia:
        return AdTypeModel.socialMedia;
      case AdType.google:
        return AdTypeModel.google;
      case AdType.facebook:
        return AdTypeModel.facebook;
      case AdType.instagram:
        return AdTypeModel.instagram;
      case AdType.tiktok:
        return AdTypeModel.tiktok;
      case AdType.youtube:
        return AdTypeModel.youtube;
      case AdType.other:
        return AdTypeModel.other;
    }
  }
}

@HiveType(typeId: 1)
@JsonSerializable()
class AdvertisementModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final AdTypeModel type;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final double budget;

  @HiveField(5)
  final String targetAudience;

  @HiveField(6)
  final Map<String, dynamic> metrics;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime? updatedAt;

  @HiveField(9)
  final bool isActive;

  AdvertisementModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.budget,
    required this.targetAudience,
    required this.metrics,
    required this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  // Convert from Entity to Model
  factory AdvertisementModel.fromEntity(Advertisement entity) {
    return AdvertisementModel(
      id: entity.id,
      type: AdTypeModelExtension.fromEntity(entity.type),
      title: entity.title,
      description: entity.description,
      budget: entity.budget,
      targetAudience: entity.targetAudience,
      metrics: entity.metrics,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      isActive: entity.isActive,
    );
  }

  // Convert from Model to Entity
  Advertisement toEntity() {
    return Advertisement(
      id: id,
      type: type.toEntity(),
      title: title,
      description: description,
      budget: budget,
      targetAudience: targetAudience,
      metrics: metrics,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isActive: isActive,
    );
  }

  // JSON serialization
  factory AdvertisementModel.fromJson(Map<String, dynamic> json) =>
      _$AdvertisementModelFromJson(json);

  Map<String, dynamic> toJson() => _$AdvertisementModelToJson(this);

  AdvertisementModel copyWith({
    String? id,
    AdTypeModel? type,
    String? title,
    String? description,
    double? budget,
    String? targetAudience,
    Map<String, dynamic>? metrics,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return AdvertisementModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      budget: budget ?? this.budget,
      targetAudience: targetAudience ?? this.targetAudience,
      metrics: metrics ?? this.metrics,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'AdvertisementModel(id: $id, type: $type, title: $title, budget: $budget, isActive: $isActive)';
  }
}

