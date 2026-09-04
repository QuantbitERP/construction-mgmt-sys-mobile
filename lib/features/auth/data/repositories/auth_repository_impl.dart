import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/services/base_url_storage.dart';
import '../../../../core/di/injection_container.dart';

import 'package:frappe_mobile_sdk/frappe_mobile_sdk.dart';

class AuthRepositoryImpl implements AuthRepository {
  final BaseUrlStorage baseUrlStorage;
  final SharedPreferences sharedPreferences;
  User? _currentUser;

  static const String _userKey = 'cached_user_id';
  static const String _usernameKey = 'cached_username';

  AuthRepositoryImpl(this.baseUrlStorage, this.sharedPreferences);

  FrappeSDK get _sdk => sl<FrappeSDK>();

  @override
  Future<Either<Failure, User>> login(
    String url,
    String username,
    String password,
  ) async {
    try {
      final normalizedUrl = BaseUrlStorage.normalizeUrl(url);
      if (!BaseUrlStorage.isValidUrl(normalizedUrl)) {
        return Left(AuthFailure('Please enter a valid Server URL.'));
      }

      await reconfigureFrappeSdk(normalizedUrl);

      final response = await _sdk.auth.login(username, password);

      if (response.isNotEmpty) {
        final userId = response['full_name'] ?? response['message'] ?? username;
        _currentUser = User(id: userId, username: username);

        // Persist user info
        await sharedPreferences.setString(_userKey, userId);
        await sharedPreferences.setString(_usernameKey, username);

        return Right(_currentUser!);
      } else {
        return Left(
          AuthFailure('Invalid Email ID or Password.'),
        );
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.toLowerCase().contains('not allowed to use mobile app')) {
        return Left(AuthFailure('please set user permission to use this mobile app'));
      }
      if (errorStr.contains('Invalid login credentials') ||
          errorStr.contains('ValidationError') ||
          errorStr.contains('Unable to login')) {
        return Left(AuthFailure('Invalid Email ID or Password.'));
      }
      return Left(AuthFailure('Error: $errorStr'));
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _sdk.auth.logout();
    } catch (_) {
      // Ignore API errors during logout to guarantee local user state is cleared
    }
    await sharedPreferences.remove(_userKey);
    await sharedPreferences.remove(_usernameKey);
    _currentUser = null;
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    if (_currentUser != null) {
      return Right(_currentUser!);
    }

    final savedUrl = await baseUrlStorage.getBaseUrl();
    if (savedUrl == null || savedUrl.isEmpty) {
      return Left(AuthFailure('No user logged in.'));
    }

    final userId = sharedPreferences.getString(_userKey);
    final username = sharedPreferences.getString(_usernameKey);

    if (userId != null && username != null && _sdk.isAuthenticated) {
      _currentUser = User(id: userId, username: username);
      return Right(_currentUser!);
    }

    return Left(AuthFailure('No user logged in.'));
  }
}
