import 'package:flutter_test/flutter_test.dart';
import 'package:cms/core/services/base_url_storage.dart';

void main() {
  group('BaseUrlStorage URL normalization & validation', () {
    test('normalizeUrl prepends https:// if scheme is missing', () {
      expect(
        BaseUrlStorage.normalizeUrl('my-site.frappe.cloud'),
        'https://my-site.frappe.cloud',
      );
    });

    test('normalizeUrl trims whitespace and trailing slashes', () {
      expect(
        BaseUrlStorage.normalizeUrl('  https://my-site.frappe.cloud///  '),
        'https://my-site.frappe.cloud',
      );
    });

    test('normalizeUrl retains http:// scheme when provided', () {
      expect(
        BaseUrlStorage.normalizeUrl('http://192.168.1.100:8000/'),
        'http://192.168.1.100:8000',
      );
    });

    test('isValidUrl returns true for valid URLs', () {
      expect(BaseUrlStorage.isValidUrl('https://demo.frappe.cloud'), isTrue);
      expect(BaseUrlStorage.isValidUrl('demo.frappe.cloud'), isTrue);
      expect(BaseUrlStorage.isValidUrl('http://localhost:8000'), isTrue);
    });

    test('isValidUrl returns false for empty or invalid inputs', () {
      expect(BaseUrlStorage.isValidUrl(''), isFalse);
      expect(BaseUrlStorage.isValidUrl('   '), isFalse);
      expect(BaseUrlStorage.isValidUrl('://invalid'), isFalse);
    });
  });
}
