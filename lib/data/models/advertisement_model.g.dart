// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'advertisement_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AdvertisementModelAdapter extends TypeAdapter<AdvertisementModel> {
  @override
  final int typeId = 1;

  @override
  AdvertisementModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AdvertisementModel(
      id: fields[0] as String,
      type: fields[1] as AdTypeModel,
      title: fields[2] as String,
      description: fields[3] as String,
      budget: fields[4] as double,
      targetAudience: fields[5] as String,
      metrics: (fields[6] as Map).cast<String, dynamic>(),
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime?,
      isActive: fields[9] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AdvertisementModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.budget)
      ..writeByte(5)
      ..write(obj.targetAudience)
      ..writeByte(6)
      ..write(obj.metrics)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.isActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdvertisementModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AdTypeModelAdapter extends TypeAdapter<AdTypeModel> {
  @override
  final int typeId = 3;

  @override
  AdTypeModel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AdTypeModel.socialMedia;
      case 1:
        return AdTypeModel.google;
      case 2:
        return AdTypeModel.facebook;
      case 3:
        return AdTypeModel.instagram;
      case 4:
        return AdTypeModel.tiktok;
      case 5:
        return AdTypeModel.youtube;
      case 6:
        return AdTypeModel.other;
      default:
        return AdTypeModel.socialMedia;
    }
  }

  @override
  void write(BinaryWriter writer, AdTypeModel obj) {
    switch (obj) {
      case AdTypeModel.socialMedia:
        writer.writeByte(0);
        break;
      case AdTypeModel.google:
        writer.writeByte(1);
        break;
      case AdTypeModel.facebook:
        writer.writeByte(2);
        break;
      case AdTypeModel.instagram:
        writer.writeByte(3);
        break;
      case AdTypeModel.tiktok:
        writer.writeByte(4);
        break;
      case AdTypeModel.youtube:
        writer.writeByte(5);
        break;
      case AdTypeModel.other:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdTypeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdvertisementModel _$AdvertisementModelFromJson(Map<String, dynamic> json) =>
    AdvertisementModel(
      id: json['id'] as String,
      type: $enumDecode(_$AdTypeModelEnumMap, json['type']),
      title: json['title'] as String,
      description: json['description'] as String,
      budget: (json['budget'] as num).toDouble(),
      targetAudience: json['targetAudience'] as String,
      metrics: json['metrics'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );

Map<String, dynamic> _$AdvertisementModelToJson(AdvertisementModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$AdTypeModelEnumMap[instance.type]!,
      'title': instance.title,
      'description': instance.description,
      'budget': instance.budget,
      'targetAudience': instance.targetAudience,
      'metrics': instance.metrics,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'isActive': instance.isActive,
    };

const _$AdTypeModelEnumMap = {
  AdTypeModel.socialMedia: 'socialMedia',
  AdTypeModel.google: 'google',
  AdTypeModel.facebook: 'facebook',
  AdTypeModel.instagram: 'instagram',
  AdTypeModel.tiktok: 'tiktok',
  AdTypeModel.youtube: 'youtube',
  AdTypeModel.other: 'other',
};
