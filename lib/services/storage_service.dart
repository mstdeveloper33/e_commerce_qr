import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_settings.dart';
import '../models/barcode_result.dart';

class StorageService {
  static const String _apiSettingsKey = 'api_settings';
  static const String _lastScannedKey = 'last_scanned_barcode';
  static const String _scanHistoryKey = 'scan_history';

  // API ayarlarını kaydet
  Future<void> saveApiSettings(ApiSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiSettingsKey, jsonEncode(settings.toJson()));
  }

  // API ayarlarını yükle
  Future<ApiSettings?> loadApiSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_apiSettingsKey);
    
    if (settingsJson != null) {
      try {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        return ApiSettings.fromJson(settingsMap);
      } catch (e) {
        print('API ayarları yüklenirken hata: $e');
        return null;
      }
    }
    return null;
  }

  // Son taranan barkodu kaydet
  Future<void> saveLastScannedBarcode(String barcode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastScannedKey, barcode);
  }

  // Son taranan barkodu yükle
  Future<String?> loadLastScannedBarcode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastScannedKey);
  }

  // Tarama geçmişini kaydet
  Future<void> saveScanHistory(List<BarcodeResult> history) async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = history.map((result) => result.toJson()).toList();
    await prefs.setString(_scanHistoryKey, jsonEncode(historyJson));
  }

  // Tarama geçmişini yükle
  Future<List<BarcodeResult>> loadScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_scanHistoryKey);
    
    if (historyJson != null) {
      try {
        final historyList = jsonDecode(historyJson) as List<dynamic>;
        return historyList
            .map((json) => BarcodeResult.fromJson(json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('Tarama geçmişi yüklenirken hata: $e');
        return [];
      }
    }
    return [];
  }

  // Tarama geçmişini temizle
  Future<void> clearScanHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scanHistoryKey);
  }

  // Tüm verileri temizle
  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
} 