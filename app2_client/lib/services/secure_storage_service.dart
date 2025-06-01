import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  // 토큰 저장
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  // AccessToken 읽기
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  // RefreshToken 읽기
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // 토큰 삭제
  Future<void> deleteTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }

  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }
  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }
}
