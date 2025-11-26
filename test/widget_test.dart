import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:chmrsystem/main.dart';
import 'package:chmrsystem/firebase_options.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App builds and shows MaterialApp', (WidgetTester tester) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify that the root MaterialApp is present (routes and theming wired).
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
