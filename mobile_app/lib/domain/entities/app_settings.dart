import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings.freezed.dart';
part 'app_settings.g.dart';

@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default('Cửa hàng VLXD Hoàng Hạnh') String storeName,
    @Default('Phố Xuân - Phường Đông Hoa Lư - Tỉnh Ninh Bình') String storeAddress,
    @Default('0914140566-0941709111') String storePhone,
    @Default('') String logoUrl,
    @Default('') String logoLocalPath,
    @Default(4.0) double truckVolume,
    DateTime? lastBackupTime,
    @Default(0) int lastBackupSizeBytes,
    @Default('') String lastBackupStatus,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) => _$AppSettingsFromJson(json);
}
