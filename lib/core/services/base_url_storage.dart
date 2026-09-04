import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BaseUrlStorage {
  static const String _baseUrlKey = 'frappe_server_base_url';
  final FlutterSecureStorage _storage;

  BaseUrlStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Normalizes a given URL by trimming whitespace, ensuring https/http prefix,
  /// and stripping trailing slashes.
  static String normalizeUrl(String rawUrl) {
    String url = rawUrl.trim();
    if (url.isEmpty) return '';

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }

    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    return url;
  }

  /// Validates whether the given URL is well-formed.
  static bool isValidUrl(String rawUrl) {
    final normalized = normalizeUrl(rawUrl);
    if (normalized.isEmpty) return false;
    final uri = Uri.tryParse(normalized);
    return uri != null && uri.hasScheme && uri.hasAuthority && uri.host.isNotEmpty;
  }

  /// Retrieves the saved base URL, or null if none is saved.
  Future<String?> getBaseUrl() async {
    try {
      final url = await _storage.read(key: _baseUrlKey);
      if (url != null && url.trim().isNotEmpty) {
        return normalizeUrl(url);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Normalizes and saves the base URL securely.
  Future<void> saveBaseUrl(String url) async {
    final normalized = normalizeUrl(url);
    await _storage.write(key: _baseUrlKey, value: normalized);
  }

  /// Clears the saved base URL.
  Future<void> clearBaseUrl() async {
    await _storage.delete(key: _baseUrlKey);
  }
}
