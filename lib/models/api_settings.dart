class ApiSettings {
  final String apiUrl;
  final Map<String, String> headers;

  ApiSettings({
    required this.apiUrl,
    this.headers = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'apiUrl': apiUrl,
      'headers': headers,
    };
  }

  factory ApiSettings.fromJson(Map<String, dynamic> json) {
    return ApiSettings(
      apiUrl: json['apiUrl'] ?? '',
      headers: Map<String, String>.from(json['headers'] ?? {}),
    );
  }

  ApiSettings copyWith({
    String? apiUrl,
    Map<String, String>? headers,
  }) {
    return ApiSettings(
      apiUrl: apiUrl ?? this.apiUrl,
      headers: headers ?? this.headers,
    );
  }
} 