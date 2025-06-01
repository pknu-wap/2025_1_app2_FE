import 'package:app2_client/constants/api_constants.dart';
import 'package:app2_client/services/auth_service.dart';
import 'package:dio/dio.dart';
import '../services/secure_storage_service.dart';

class TokenInterceptor extends Interceptor {
  final SecureStorageService _storage = SecureStorageService();
  final Dio _refreshDio = Dio(); // 순환 방지용

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

    // 403 & access token 만료만 처리
    if (res?.statusCode == 403 && res?.data != null && data != "") {
      final code = data['code'];
      if (code != "TOKEN-403-1") {
        return handler.next(err);
      }

      final refreshToken = await _storage.getRefreshToken();

      try {
        final refreshResp = await _refreshDio.post(
          '${ApiConstants.baseUrl}${ApiConstants.reissueEndPoint}',
          data: {'refreshToken': refreshToken},
        );

        // 토큰 저장
        final newAccessToken = refreshResp.data['accessToken'];
        final newRefreshToken = refreshResp.data['refreshToken'];
        await _storage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );

        // 원래 요청 새 토큰으로 재시도
        final opts = err.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newAccessToken';

        final retryResp = await Dio().fetch(opts);
        return handler.resolve(retryResp);

      } on DioException catch (e) {
        // 리프레시 토큰 만료
        final status = e.response?.statusCode;
        if (status == 403) {
          print("리프레시 토큰 만료 또는 유효하지 않음");
          AuthService().logout();
          return handler.reject(err);
        }
        print('전송 오류: $e');
        return handler.reject(err);
      } catch (e) {
        print('전송 오류: $e');
        return handler.reject(err);
      }
    }
    return handler.next(err);
  }
}