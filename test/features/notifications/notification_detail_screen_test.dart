import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:osetrovich/core/network/mock_api_client.dart';
import 'package:osetrovich/core/network/providers.dart';
import 'package:osetrovich/core/theme/app_theme.dart';
import 'package:osetrovich/features/notifications/presentation/notification_detail_screen.dart';

void main() {
  testWidgets('detail screen shows title body and time', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiClientProvider.overrideWithValue(MockApiClient())],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const NotificationDetailScreen(notificationId: 'n1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Скидка на икру'), findsOneWidget);
    expect(
      find.text('До конца недели скидка 15% на красную икру.'),
      findsOneWidget,
    );
    expect(find.textContaining('2026'), findsOneWidget);
  });
}
