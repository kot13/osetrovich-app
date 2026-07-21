import 'package:flutter/material.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';
import 'package:osetrovich/core/network/api_exception.dart';

String orderRatingErrorMessage(ApiException exception) {
  final code = exception.code.toLowerCase();
  return switch (code) {
    'rating_period_expired' => AppStrings.ratingPeriodExpired,
    'rating_already_set' => AppStrings.ratingAlreadySet,
    'not_found' || 'http_404' => AppStrings.ratingUnavailable,
    'network_error' => AppStrings.networkError,
    'invalid_request' => AppStrings.ratingUnavailable,
    _ =>
      exception.message.isNotEmpty
          ? exception.message
          : AppStrings.ratingSubmitFailed,
  };
}

bool shouldRefreshOrderAfterRatingError(ApiException exception) {
  final code = exception.code.toLowerCase();
  return code == 'rating_already_set' ||
      code == 'rating_period_expired' ||
      code == 'not_found' ||
      code == 'http_404';
}

void showRatingThankYouSnackBar(BuildContext context) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text(AppStrings.ratingThankYou)));
}
