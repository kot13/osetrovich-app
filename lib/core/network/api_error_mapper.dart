import 'package:dio/dio.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/api_exception.dart';

ApiException mapToApiException(Object error) {
  if (error is ApiException) {
    return error;
  }
  if (error is DioException) {
    return _mapDioException(error);
  }
  return ApiException(code: 'UNKNOWN', message: AppStrings.requestFailed);
}

String userFacingErrorMessage(Object error) {
  return mapToApiException(error).message;
}

ApiException _mapDioException(DioException error) {
  final response = error.response;
  final statusCode = response?.statusCode;
  final bodyMessage = _messageFromBody(response?.data);

  if (error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.sendTimeout ||
      error.type == DioExceptionType.receiveTimeout ||
      error.type == DioExceptionType.connectionError) {
    return ApiException(code: 'NETWORK_ERROR', message: AppStrings.networkError);
  }

  if (statusCode == 401) {
    return ApiException(
      code: 'UNAUTHORIZED',
      message: bodyMessage ?? AppStrings.sessionExpired,
    );
  }

  if (bodyMessage != null && bodyMessage.isNotEmpty) {
    final code = _codeFromBody(response?.data) ?? 'HTTP_$statusCode';
    return ApiException(code: code, message: bodyMessage);
  }

  if (statusCode != null) {
    return ApiException(
      code: 'HTTP_$statusCode',
      message: AppStrings.requestFailed,
    );
  }

  return ApiException(code: 'NETWORK_ERROR', message: AppStrings.networkError);
}

String? _messageFromBody(Object? data) {
  if (data is Map<String, dynamic>) {
    final message = data['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }
  }
  return null;
}

String? _codeFromBody(Object? data) {
  if (data is Map<String, dynamic>) {
    final code = data['code'];
    if (code is String && code.isNotEmpty) {
      return code;
    }
  }
  return null;
}
