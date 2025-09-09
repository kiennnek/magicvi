// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AnalyticsDataModelAdapter extends TypeAdapter<AnalyticsDataModel> {
  @override
  final int typeId = 2;

  @override
  AnalyticsDataModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AnalyticsDataModel(
      id: fields[0] as String,
      adId: fields[1] as String,
      metrics: (fields[2] as Map).cast<String, double>(),
      date: fields[3] as DateTime,
      period: fields[4] as String,
      impressions: fields[5] as double,
      clicks: fields[6] as double,
      conversions: fields[7] as double,
      cost: fields[8] as double,
      revenue: fields[9] as double,
    );
  }

  @override
  void write(BinaryWriter writer, AnalyticsDataModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.adId)
      ..writeByte(2)
      ..write(obj.metrics)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.period)
      ..writeByte(5)
      ..write(obj.impressions)
      ..writeByte(6)
      ..write(obj.clicks)
      ..writeByte(7)
      ..write(obj.conversions)
      ..writeByte(8)
      ..write(obj.cost)
      ..writeByte(9)
      ..write(obj.revenue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsDataModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnalyticsDataModel _$AnalyticsDataModelFromJson(Map<String, dynamic> json) =>
    AnalyticsDataModel(
      id: json['id'] as String,
      adId: json['adId'] as String,
      metrics: (json['metrics'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      date: DateTime.parse(json['date'] as String),
      period: json['period'] as String,
      impressions: (json['impressions'] as num).toDouble(),
      clicks: (json['clicks'] as num).toDouble(),
      conversions: (json['conversions'] as num).toDouble(),
      cost: (json['cost'] as num).toDouble(),
      revenue: (json['revenue'] as num).toDouble(),
    );

Map<String, dynamic> _$AnalyticsDataModelToJson(AnalyticsDataModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'adId': instance.adId,
      'metrics': instance.metrics,
      'date': instance.date.toIso8601String(),
      'period': instance.period,
      'impressions': instance.impressions,
      'clicks': instance.clicks,
      'conversions': instance.conversions,
      'cost': instance.cost,
      'revenue': instance.revenue,
    };
