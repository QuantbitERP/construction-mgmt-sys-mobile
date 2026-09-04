class AppConfig {
  /// App name shown in UI.
  static const String appName = 'ConstructionMS';

  /// App version shown in UI.
  static const String appVersion = '1.0.0';

  /// Android/iOS package identifier.
  static const String packageName = 'com.constructionms.app';

  /// Home screen layout mode. Allowed values: 'list' or 'folder'.
  static const String homeScreenLayout = 'list';

  /// Frappe server base URL configured by the user.
  static String baseUrl = '';

  /// OAuth client ID from Frappe OAuth Client settings
  static String oauthClientId = '';

  /// OAuth client secret from Frappe OAuth Client settings
  static String oauthClientSecret = '';
}
