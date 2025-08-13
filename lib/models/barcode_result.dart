class BarcodeResult {
  final String code;
  final String format;
  final DateTime timestamp;
  final bool isSuccess;
  final String? errorMessage;
  final int stok;
  final double fiyat;

  BarcodeResult({
    required this.code,
    required this.format,
    required this.timestamp,
    this.isSuccess = true,
    this.errorMessage,
    this.stok = 0,
    this.fiyat = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'format': format,
      'timestamp': timestamp.toIso8601String(),
      'isSuccess': isSuccess,
      'errorMessage': errorMessage,
      'stok': stok,
      'fiyat': fiyat,
    };
  }

  factory BarcodeResult.fromJson(Map<String, dynamic> json) {
    return BarcodeResult(
      code: json['code'] ?? '',
      format: json['format'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      isSuccess: json['isSuccess'] ?? true,
      errorMessage: json['errorMessage'],
      stok: json['stok'] ?? 0,
      fiyat: (json['fiyat'] ?? 0.0).toDouble(),
    );
  }
} 