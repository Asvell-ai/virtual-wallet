import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hamyon/core/widgets/pin_confirmation_sheet.dart';

void main() {
  testWidgets('PIN tasdiqlash qisqa ekranda overflow bermaydi', (tester) async {
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: PinConfirmationSheet(
          title: 'To‘lovni tasdiqlang',
          subtitle: '4 xonali PIN-kodni kiriting',
          pinLength: 0,
          submitting: false,
          onDigit: (_) async => false,
          onBackspace: () {},
        ),
      ),
    );

    expect(find.text('To‘lovni tasdiqlang'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
