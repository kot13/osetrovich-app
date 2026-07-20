import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/api_error_mapper.dart';
import 'package:osetrovich/core/network/api_exception.dart';

void main() {
  group('mapToApiException', () {
    test('maps DioException 401 to UNAUTHORIZED with Russian message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/profile/me'),
        response: Response(
          requestOptions: RequestOptions(path: '/profile/me'),
          statusCode: 401,
          data: {'code': 'unauthorized', 'message': 'Требуется авторизация'},
        ),
        type: DioExceptionType.badResponse,
      );

      final mapped = mapToApiException(error);

      expect(mapped.code, 'UNAUTHORIZED');
      expect(mapped.message, 'Требуется авторизация');
      expect(mapped.message, isNot(contains('DioException')));
    });

    test('maps DioException badResponse without body to requestFailed', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/profile/me'),
        response: Response(
          requestOptions: RequestOptions(path: '/profile/me'),
          statusCode: 500,
        ),
        type: DioExceptionType.badResponse,
      );

      final mapped = mapToApiException(error);

      expect(mapped.code, 'HTTP_500');
      expect(mapped.message, AppStrings.requestFailed);
      expect(mapped.message, isNot(contains('bad response')));
    });

    test('maps connection timeout to NETWORK_ERROR', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/profile/me'),
        type: DioExceptionType.connectionTimeout,
      );

      final mapped = mapToApiException(error);

      expect(mapped.code, 'NETWORK_ERROR');
      expect(mapped.message, AppStrings.networkError);
    });

    test('passes through ApiException', () {
      final original = ApiException(
        code: 'NOT_FOUND',
        message: 'Товар не найден',
      );

      expect(mapToApiException(original), same(original));
    });
  });

  group('userFacingErrorMessage', () {
    test('returns ApiException message for DioException badResponse', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/profile/me'),
        response: Response(
          requestOptions: RequestOptions(path: '/profile/me'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );

      final message = userFacingErrorMessage(error);

      expect(message, AppStrings.sessionExpired);
      expect(message, isNot(contains('DioException')));
      expect(message, isNot(contains('bad response')));
    });
  });
}
