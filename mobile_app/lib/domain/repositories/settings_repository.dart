import '../entities/app_settings.dart';

abstract class SettingsRepository {
  Stream<AppSettings> watchSettings();
  Future<AppSettings> getSettings();
  Future<void> saveSettings(AppSettings settings);
  Future<String?> uploadLogo(String localPath);
}
