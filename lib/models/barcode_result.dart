class BarcodeResult {
  final String code;
  final String format;
  final DateTime timestamp;
  final bool isSuccess;
  final String? errorMessage;

  BarcodeResult({
    required this.code,
    required this.format,
    required this.timestamp,
    this.isSuccess = true,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'format': format,
      'timestamp': timestamp.toIso8601String(),
      'isSuccess': isSuccess,
      'errorMessage': errorMessage,
    };
  }

  factory BarcodeResult.fromJson(Map<String, dynamic> json) {
    return BarcodeResult(
      code: json['code'] ?? '',
      format: json['format'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      isSuccess: json['isSuccess'] ?? true,
      errorMessage: json['errorMessage'],
    );
  }
} 