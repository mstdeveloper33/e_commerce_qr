import 'package:flutter/material.dart';
import 'dart:async';
import '../models/barcode_result.dart';
import '../models/api_settings.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class BarcodeProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  bool _isScanning = false;
  bool _isLoading = false;
  String _lastScannedBarcode = '';
  String _lastError = '';
  ApiSettings? _apiSettings;
  List<BarcodeResult> _scanHistory = [];
  
  // Performans optimizasyonu için
  Timer? _debounceTimer;
  final Set<String> _recentlyScanned = {};
  static const Duration _debounceDelay = Duration(milliseconds: 800);
  static const Duration _recentlyScannedTimeout = Duration(milliseconds: 2000);

  // Getters
  bool get isScanning => _isScanning;
  bool get isLoading => _isLoading;
  String get lastScannedBarcode => _lastScannedBarcode;
  String get lastError => _lastError;
  ApiSettings? get apiSettings => _apiSettings;
  List<BarcodeResult> get scanHistory => _scanHistory;

  // Constructor - ayarları yükle
  BarcodeProvider() {
    _loadSettings();
  }

  // Ayarları ve geçmişi yükle
  Future<void> _loadSettings() async {
    // API ayarlarını yükle
    _apiSettings = await _storageService.loadApiSettings();
    if (_apiSettings != null) {
      _apiService.updateSettings(_apiSettings!);
    }
    
    // Tarama geçmişini yükle
    _scanHistory = await _storageService.loadScanHistory();
    print('📚 Geçmiş yüklendi: ${_scanHistory.length} kayıt');
    
    // Son taranan barkodu yükle
    _lastScannedBarcode = await _storageService.loadLastScannedBarcode() ?? '';
    
    notifyListeners();
  }

  // API ayarlarını güncelle
  Future<void> updateApiSettings(ApiSettings settings) async {
    _apiSettings = settings;
    _apiService.updateSettings(settings);
    await _storageService.saveApiSettings(settings);
    notifyListeners();
  }

  // Barkod tarama durumunu güncelle
  void setScanning(bool scanning) {
    _isScanning = scanning;
    notifyListeners();
  }

  // Barkod tara ve API'ye gönder (basitleştirilmiş)
  Future<void> scanAndSendBarcode(String code, String format) async {
    // Aynı barkod son 2 saniyede taranmışsa tekrar işleme
    if (_recentlyScanned.contains(code) || _isScanning || _isLoading) {
      return;
    }

    // Tarama durumunu aktif et
    _isScanning = true;
    notifyListeners();

    // Debounce timer'ı iptal et
    _debounceTimer?.cancel();

    // Yeni debounce timer başlat
    _debounceTimer = Timer(_debounceDelay, () async {
      await _processBarcode(code, format, 0, 0.0);
    });
  }

  // Stok ve fiyat bilgisi ile barkod tara ve API'ye gönder
  Future<void> scanAndSendBarcodeWithDetails(String code, String format, int stok, double fiyat) async {
    // Aynı barkod son 2 saniyede taranmışsa tekrar işleme
    if (_recentlyScanned.contains(code) || _isScanning || _isLoading) {
      return;
    }

    // Tarama durumunu aktif et
    _isScanning = true;
    notifyListeners();

    // Debounce timer'ı iptal et
    _debounceTimer?.cancel();

    // Direkt olarak işle (dialog'dan geldiği için debounce gerek yok)
    await _processBarcode(code, format, stok, fiyat);
  }

  // Barkod işleme (debounce sonrası)
  Future<void> _processBarcode(String code, String format, [int stok = 0, double fiyat = 0.0]) async {
    if (_recentlyScanned.contains(code)) {
      return;
    }
    
    // Kodu hemen koruma altına al - 2 saniye boyunca aynı kod işlenmeyecek
    _recentlyScanned.add(code);

    _isLoading = true;
    _lastError = '';
    notifyListeners();

    try {
      // Barkodun geçerli olup olmadığını kontrol et (ör: boş veya format hatalı)
      if (code.isEmpty || format.isEmpty) {
        final failResult = BarcodeResult(
          code: code,
          format: format,
          timestamp: DateTime.now(),
          isSuccess: false,
          errorMessage: 'Geçersiz barkod veya format',
          stok: stok,
          fiyat: fiyat,
        );
        _scanHistory.insert(0, failResult);
        _lastError = 'Geçersiz barkod veya format';
        return;
      }

      final result = BarcodeResult(
        code: code,
        format: format,
        timestamp: DateTime.now(),
        isSuccess: true,
        stok: stok,
        fiyat: fiyat,
      );
      if (_apiSettings == null || _apiSettings!.apiUrl.isEmpty) {
        _lastScannedBarcode = code;
        
        // Aynı barkod zaten varsa güncelle, yoksa ekle
        final existingIndex = _scanHistory.indexWhere((item) => item.code == code);
        if (existingIndex != -1) {
          // Varolan barkodu güncelle ve en üste taşı
          _scanHistory.removeAt(existingIndex);
        }
        _scanHistory.insert(0, result);
        
        await _storageService.saveLastScannedBarcode(code);
        if (_scanHistory.length > 50) {
          _scanHistory = _scanHistory.take(50).toList();
        }
        // Geçmişi kaydet
        await _storageService.saveScanHistory(_scanHistory);
        _lastError = 'Test modu: Barkod kaydedildi (API URL ayarlanmamış)';
      } else {
        print('🌐 API modu: Barkod API\'ye gönderiliyor');
        final success = await _apiService.sendBarcodeResult(result);
        if (success) {
          _lastScannedBarcode = code;
          
          // Aynı barkod zaten varsa güncelle, yoksa ekle
          final existingIndex = _scanHistory.indexWhere((item) => item.code == code);
          if (existingIndex != -1) {
            // Varolan barkodu güncelle ve en üste taşı
            _scanHistory.removeAt(existingIndex);
            print('🔄 API modu: Varolan barkod güncellendi: $code');
          }
          _scanHistory.insert(0, result);
          
          await _storageService.saveLastScannedBarcode(code);
          if (_scanHistory.length > 50) {
            _scanHistory = _scanHistory.take(50).toList();
          }
          // Geçmişi kaydet
          await _storageService.saveScanHistory(_scanHistory);
          print('✅ API modu: Barkod başarıyla gönderildi. Geçmiş sayısı: ${_scanHistory.length}');
        } else {
          final failResult = BarcodeResult(
            code: code,
            format: format,
            timestamp: DateTime.now(),
            isSuccess: false,
            errorMessage: 'API\'ye gönderilemedi',
            stok: stok,
            fiyat: fiyat,
          );
          
          // Aynı barkod zaten varsa güncelle, yoksa ekle
          final existingIndex = _scanHistory.indexWhere((item) => item.code == code);
          if (existingIndex != -1) {
            // Varolan barkodu güncelle ve en üste taşı
            _scanHistory.removeAt(existingIndex);
            print('🔄 API modu: Varolan başarısız barkod güncellendi: $code');
          }
          _scanHistory.insert(0, failResult);
          
          // Geçmişi kaydet
          await _storageService.saveScanHistory(_scanHistory);
          _lastError = 'Barkod API\'ye gönderilemedi.';
          print('❌ API modu: Barkod gönderilemedi');
        }
      }
    } catch (e) {
      final failResult = BarcodeResult(
        code: code,
        format: format,
        timestamp: DateTime.now(),
        isSuccess: false,
        errorMessage: e.toString(),
        stok: stok,
        fiyat: fiyat,
      );
      
      // Aynı barkod zaten varsa güncelle, yoksa ekle
      final existingIndex = _scanHistory.indexWhere((item) => item.code == code);
      if (existingIndex != -1) {
        // Varolan barkodu güncelle ve en üste taşı
        _scanHistory.removeAt(existingIndex);
        print('🔄 Hata durumu: Varolan barkod güncellendi: $code');
      }
      _scanHistory.insert(0, failResult);
      
      // Geçmişi kaydet
      await _storageService.saveScanHistory(_scanHistory);
      _lastError = 'Hata: $e';
      print('💥 Barkod işleme hatası: $e');
          } finally {
      _isLoading = false;
      _resetScanningState();
      
      // 3 saniye sonra aynı barkod tekrar işlenebilir
      Timer(_recentlyScannedTimeout, () {
        _recentlyScanned.remove(code);
        print('🔓 Kod koruması kaldırıldı: $code');
      });
      
      print('🔄 Tarama durumu sıfırlandı');
    }
  }

  // Tarama durumunu sıfırla
  void _resetScanningState() {
    // Hemen tarama durumunu sıfırla
    _isScanning = false;
    _isLoading = false;
    _debounceTimer?.cancel();
    notifyListeners();
    
    // Kısa süre sonra tarama durumunu kontrol et
    Timer(const Duration(milliseconds: 500), () {
      if (!_isScanning && !_isLoading) {
        print('✅ Tarama durumu tamamen sıfırlandı - Yeni tarama için hazır');
      }
    });
  }

  // Manuel olarak tarama durumunu sıfırla
  void resetScanningState() {
    _isScanning = false;
    _isLoading = false;
    _debounceTimer?.cancel();
    notifyListeners();
  }

  // API bağlantısını test et
  Future<bool> testApiConnection() async {
    if (_apiSettings == null || _apiSettings!.apiUrl.isEmpty) {
      return false;
    }

    try {
      return await _apiService.testConnection();
    } catch (e) {
      return false;
    }
  }

  // Geçici ayarlarla API bağlantısını test et
  Future<bool> testApiConnectionWithSettings(ApiSettings settings) async {
    if (settings.apiUrl.isEmpty) {
      return false;
    }

    try {
      final tempApiService = ApiService();
      tempApiService.updateSettings(settings);
      return await tempApiService.testConnection();
    } catch (e) {
      return false;
    }
  }

  // Hata mesajını temizle
  void clearError() {
    _lastError = '';
    notifyListeners();
  }
  
  // Tarama geçmişini temizle
  Future<void> clearScanHistory() async {
    _scanHistory = [];
    await _storageService.clearScanHistory();
    print('🗑️ Tarama geçmişi temizlendi');
    notifyListeners();
  }

  // Son taranan barkodları temizle
  void clearRecentlyScanned() {
    _recentlyScanned.clear();
  }

  // Debug: Geçmiş durumunu yazdır
  void debugPrintHistory() {
    // Debug çıktısını azalt
    print('📋 Geçmiş durumu: ${_scanHistory.length} kayıt');
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
} 