import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluebubbles/app/components/custom/custom_cupertino_alert_dialog.dart';

void main() {
  testWidgets('CupertinoDialogAction responds to taps', (WidgetTester tester) async {
    bool pressed = false;
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoAlertDialog(
          actions: [
            CupertinoDialogAction(
              onPressed: () => pressed = true,
              child: const Text('Tap me'),
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Tap me'));
    await tester.pumpAndSettle();
    expect(pressed, isTrue);
  });

  testWidgets('Action text wraps in accessibility mode', (WidgetTester tester) async {
    const String longText = 'This is a very long button label that should wrap when text is scaled.';
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaleFactor: 2.0),
        child: CupertinoApp(
          home: CupertinoAlertDialog(
            actions: [
              CupertinoDialogAction(
                onPressed: () {},
                child: const Text(longText),
              ),
            ],
          ),
        ),
      ),
    );

    final Size size = tester.getSize(find.text(longText));
    final RichText richText = tester.widget<RichText>(
      find.descendant(of: find.text(longText), matching: find.byType(RichText)),
    );
    final double fontSize = richText.text.style!.fontSize!;
    expect(size.height, greaterThan(fontSize * 1.5));
  });

  testWidgets('Single-word action text wraps instead of ellipsizing', (WidgetTester tester) async {
    const String longWord = 'SupercalifragilisticexpialidociousSupercalifragilisticexpialidocious';
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoAlertDialog(
          actions: [
            CupertinoDialogAction(
              onPressed: () {},
              child: const Text(longWord),
            ),
          ],
        ),
      ),
    );

    final Size size = tester.getSize(find.text(longWord));
    final RichText richText = tester.widget<RichText>(
      find.descendant(of: find.text(longWord), matching: find.byType(RichText)),
    );
    final double fontSize = richText.text.style!.fontSize!;
    expect(size.height, greaterThan(fontSize * 1.5));
  });
}
