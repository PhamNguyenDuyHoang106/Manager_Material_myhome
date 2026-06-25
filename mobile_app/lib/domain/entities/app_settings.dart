import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default('Cửa Hàng Vật Liệu Xây Dựng') String storeName,
    @Default('') String storeAddress,
    @Default('') String storePhone,
    @Default('') String logoUrl,
    @Default('') String logoLocalPath,
    @Default(4.0) double truckVolume,
    DateTime? lastBackupTime,
    @Default(0) int lastBackupSizeBytes,
    @Default('') String lastBackupStatus,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) => _$AppSettingsFromJson(json);
}
