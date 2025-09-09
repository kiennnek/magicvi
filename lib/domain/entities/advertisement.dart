import 'package:equatable/equatable.dart';

enum AdType {
  socialMedia,
  google,
  facebook,
  instagram,
  tiktok,
  youtube,
  other,
}

extension AdTypeExtension on AdType {
  String get displayName {
    switch (this) {
      case AdType.socialMedia:
        return 'Social Media';
      case AdType.google:
        return 'Google Ads';
      case AdType.facebook:
        return 'Facebook Ads';
      case AdType.instagram:
        return 'Instagram Ads';
      case AdType.tiktok:
        return 'TikTok Ads';
      case AdType.youtube:
        return 'YouTube Ads';
      case AdType.other:
        return 'Other';
    }
  }

  String get value {
    return toString().split('.').last;
  }

  static AdType fromString(String value) {
    return AdType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => AdType.other,
    );
  }
}

class Advertisement extends Equatable {
  final String id;
  final AdType type;
  final String title;
  final String description;
  final double budget;
  final String targetAudience;
  final Map<String, dynamic> metrics;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  const Advertisement({
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

  Advertisement copyWith({
    String? id,
    AdType? type,
    String? title,
    String? description,
    double? budget,
    String? targetAudience,
    Map<String, dynamic>? metrics,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Advertisement(
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
  List<Object?> get props => [
        id,
        type,
        title,
        description,
        budget,
        targetAudience,
        metrics,
        createdAt,
        updatedAt,
        isActive,
      ];
}

