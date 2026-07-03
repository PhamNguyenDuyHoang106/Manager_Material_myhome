// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppSettingsImpl _$$AppSettingsImplFromJson(Map<String, dynamic> json) =>
    _$AppSettingsImpl(
      storeName: json['storeName'] as String? ?? 'Cửa hàng VLXD Hoàng Hạnh',
      storeAddress: json['storeAddress'] as String? ??
          'Phố Xuân - Phường Đông Hoa Lư - Tỉnh Ninh Bình',
      storePhone: json['storePhone'] as String? ?? '0914140566-0941709111',
      logoUrl: json['logoUrl'] as String? ?? '',
      logoLocalPath: json['logoLocalPath'] as String? ?? '',
      truckVolume: (json['truckVolume'] as num?)?.toDouble() ?? 4.0,
      lastBackupTime: json['lastBackupTime'] == null
          ? null
          : DateTime.parse(json['lastBackupTime'] as String),
      lastBackupSizeBytes: (json['lastBackupSizeBytes'] as num?)?.toInt() ?? 0,
      lastBackupStatus: json['lastBackupStatus'] as String? ?? '',
    );

Map<String, dynamic> _$$AppSettingsImplToJson(_$AppSettingsImpl instance) =>
    <String, dynamic>{
      'storeName': instance.storeName,
      'storeAddress': instance.storeAddress,
      'storePhone': instance.storePhone,
      'logoUrl': instance.logoUrl,
      'logoLocalPath': instance.logoLocalPath,
      'truckVolume': instance.truckVolume,
      'lastBackupTime': instance.lastBackupTime?.toIso8601String(),
      'lastBackupSizeBytes': instance.lastBackupSizeBytes,
      'lastBackupStatus': instance.lastBackupStatus,
    };
