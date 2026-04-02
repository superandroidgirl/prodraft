import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pro_draft/main.dart';

void main() {
  testWidgets('ProDraft app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProDraftApp());
    await tester.pumpAndSettle();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
