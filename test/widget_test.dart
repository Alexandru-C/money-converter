import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_converter/main.dart';
import 'package:money_converter/rates.dart';

void main() {
  test('converts via EUR cross rate', () {
    expect(convert(1, 'EUR', 'RON'), 5.3485);
    expect(convert(5.3485, 'RON', 'EUR'), closeTo(1, 1e-12));
    expect(convert(5.3485, 'RON', 'RSD'), closeTo(117.451, 1e-9));
  });

  testWidgets('shows converted amounts', (tester) async {
    await tester.pumpWidget(const MoneyConverterApp());
    // Default: 100 RON
    expect(find.text('18.70 EUR'), findsOneWidget);
    expect(find.text('2,195.96 RSD'), findsOneWidget);

    await tester.tap(find.text('EUR'));
    await tester.pumpAndSettle();
    expect(find.text('534.85 RON'), findsOneWidget);
    expect(find.text('11,745.10 RSD'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '2,5');
    await tester.pump();
    expect(find.text('13.37 RON'), findsOneWidget);
  });
}
