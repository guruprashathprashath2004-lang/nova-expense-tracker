import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova/core/glass/theme_toggle_button.dart';
import 'package:nova/core/theme.dart';
import 'package:nova/providers/theme_provider.dart';

void main() {
  testWidgets('theme toggle updates the application theme immediately',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ref.watch(themeModeProvider),
            home: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    Text(Theme.of(context).brightness.name),
                    const ThemeToggleButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('light'), findsOneWidget);
    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pumpAndSettle();
    expect(find.text('dark'), findsOneWidget);
    expect(find.byTooltip('Switch to light mode'), findsOneWidget);
  });
}
