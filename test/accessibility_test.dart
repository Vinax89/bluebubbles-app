import 'package:bluebubbles/app/components/circle_progress_bar.dart';
import 'package:bluebubbles/app/layouts/conversation_view/widgets/text_field/send_button.dart';
import 'package:bluebubbles/services/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    setupServices();
    await ss.init(headless: true);
  });

  testWidgets('SendButton has semantics and focus order', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SendButton(
          onLongPress: () {},
          sendMessage: () {},
        ),
      ),
    ));
    final semantics = tester.getSemantics(find.byType(SendButton));
    expect(semantics.label, 'Send message');
    expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
    expect((semantics.sortKey as OrdinalSortKey).order, 3.0);
    handle.dispose();
  });

  testWidgets('CircleProgressBar reports progress semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: CircleProgressBar(
        backgroundColor: Color(0x00000000),
        foregroundColor: Color(0xFF0000FF),
        value: 0.5,
      ),
    ));
    final semantics = tester.getSemantics(find.byType(CircleProgressBar));
    expect(semantics.label, 'Progress 50%');
    handle.dispose();
  });
}
