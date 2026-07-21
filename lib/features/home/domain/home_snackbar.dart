import 'package:flutter/material.dart';
import 'package:osetrovich/core/l10n/app_strings.dart';

void showLoyaltyCardCopiedSnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text(AppStrings.homeLoyaltyCardCopied)),
  );
}
