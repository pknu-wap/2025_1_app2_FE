import 'package:app2_client/constants/api_constants.dart';
import 'package:dio/dio.dart';
import '../services/secure_storage_service.dart';

class TokenInterceptor extends Interceptor {
  final SecureStorageService _storage = SecureStorageService();
  final Dio _refreshDio = Dio(); // 순환 방지용 별도 인스턴스

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final accessToken = await _storage.getAccessToken();
    if (accessToken != null) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final res = err.response;
    final data = res?.data;

    // 403 & access token 만료
    if (res != null && res.statusCode == 403 && data is Map<String, dynamic>) {
      final code = data['code'];

      if (code != "TOKEN-403-2") {
        return handler.next(err);
      }

      try {
        final refreshToken = await _storage.getRefreshToken();
        // 토큰 재발급 요청
        final refreshResp = await _refreshDio.post(
          '${ApiConstants.baseUrl}${ApiConstants.reissueEndPoint}',
          data: {'refreshToken': refreshToken},
        );

        if (refreshResp.statusCode == 403 &&
            refreshResp.data is Map<String, dynamic> &&
            refreshResp.data['code'] == "TOKEN-403-3") {
          //리프레시 토큰도 만료
          await _storage.deleteTokens();
          return handler.reject(err);
        }

        // 새 토큰 저장
        final newAccessToken = refreshResp.data['accessToken'];
        final newRefreshToken = refreshResp.data['refreshToken'];
        await _storage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        // 원래 요청에 새 토큰으로 재시도
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccessToken';

        final retryResp = await Dio().fetch(opts);
        return handler.resolve(retryResp);
      } catch (e) {
        //재발행 중 오류
        await _storage.deleteTokens();
        return handler.reject(err);
      }
    }
    return handler.next(err);
  }
}