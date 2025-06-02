import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';

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

  // 사용자 정보 저장
  Future<void> saveUserInfo({
    required String userId,
    required String userName,
  }) async {
    print('💾 SecureStorage: 사용자 정보 저장 시작');
    print('   ▶ userId: $userId');
    print('   ▶ userName: $userName');
    
    await Future.wait([
      _storage.write(key: _userIdKey, value: userId),
      _storage.write(key: _userNameKey, value: userName),
    ]);
    
    print('✅ SecureStorage: 사용자 정보 저장 완료');
  }

  // AccessToken 읽기
  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  // RefreshToken 읽기
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // UserId 읽기
  Future<String?> getUserId() async {
    final userId = await _storage.read(key: _userIdKey);
    print('📖 SecureStorage: userId 읽기 - $userId');
    return userId;
  }

  // UserName 읽기
  Future<String?> getUserName() async {
    final userName = await _storage.read(key: _userNameKey);
    print('📖 SecureStorage: userName 읽기 - $userName');
    return userName;
  }

  // 토큰 삭제
  Future<void> deleteTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }

  // 사용자 정보 삭제
  Future<void> deleteUserInfo() async {
    await Future.wait([
      _storage.delete(key: _userIdKey),
      _storage.delete(key: _userNameKey),
    ]);
  }

  // 모든 데이터 삭제
  Future<void> deleteAll() async {
    await Future.wait([
      deleteTokens(),
      deleteUserInfo(),
    ]);
  }

  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
  }
  
  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: _refreshTokenKey);
  }
}
