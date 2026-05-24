// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppSettingsImpl _$$AppSettingsImplFromJson(Map<String, dynamic> json) =>
    _$AppSettingsImpl(
      storeName: json['storeName'] as String? ?? 'Cửa Hàng Vật Liệu Xây Dựng',
      storeAddress: json['storeAddress'] as String? ?? '',
      storePhone: json['storePhone'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? '',
      logoLocalPath: json['logoLocalPath'] as String? ?? '',
    );

Map<String, dynamic> _$$AppSettingsImplToJson(_$AppSettingsImpl instance) =>
    <String, dynamic>{
      'storeName': instance.storeName,
      'storeAddress': instance.storeAddress,
      'storePhone': instance.storePhone,
      'logoUrl': instance.logoUrl,
      'logoLocalPath': instance.logoLocalPath,
    };
