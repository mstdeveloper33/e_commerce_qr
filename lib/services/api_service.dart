import 'package:dio/dio.dart';
import '../models/barcode_result.dart';
import '../models/api_settings.dart';

class ApiService {
  late Dio _dio;
  ApiSettings? _settings;

  ApiService() {
    _dio = Dio();
    _setupDio();
  }

  void _setupDio() {
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    _dio.options.sendTimeout = const Duration(seconds: 10);
  }

  void updateSettings(ApiSettings settings) {
    _settings = settings;
    // Custom headers ekle
    settings.headers.forEach((key, value) {
      _dio.options.headers[key] = value;
    });
  }

  Future<bool> sendBarcodeResult(BarcodeResult result) async {
    if (_settings == null || _settings!.apiUrl.isEmpty) {
      throw Exception('API URL ayarlanmamış');
    }

    try {
      final response = await _dio.post(
        _settings!.apiUrl,
        data: result.toJson(),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      throw Exception('API isteği başarısız: ${e.message}');
    } catch (e) {
      throw Exception('Beklenmeyen hata: $e');
    }
  }

  Future<bool> testConnection() async {
    if (_settings == null || _settings!.apiUrl.isEmpty) {
      return false;
    }

    try {
      final response = await _dio.get(_settings!.apiUrl);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
} 