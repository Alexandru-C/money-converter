import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_converter/main.dart';
import 'package:money_converter/rates.dart';

class _FakeService extends RatesService {
  @override
  Future<Rates> load() async => Rates(
        perEur: {'EUR': 1, 'RON': 5, 'RSD': 100},
        date: '2026-10-22',
        source: 'test',
      );
}

void main() {
  test('converts via EUR cross rate', () {
    final r = Rates(
        perEur: {'EUR': 1, 'RON': 5, 'RSD': 100}, date: '', source: '');
    expect(r.convert(10, 'EUR', 'RON'), 50);
    expect(r.convert(50, 'RON', 'EUR'), 10);
    expect(r.convert(5, 'RON', 'RSD'), 100);
  });

  testWidgets('shows converted amounts', (tester) async {
    await tester.pumpWidget(MoneyConverterApp(service: _FakeService()));
    await tester.pumpAndSettle();
    // Default: 100 RON
    expect(find.text('20.00 EUR'), findsOneWidget);
    expect(find.text('2,000.00 RSD'), findsOneWidget);

    await tester.tap(find.text('🇪🇺 EUR'));
    await tester.pumpAndSettle();
    expect(find.text('500.00 RON'), findsOneWidget);
    expect(find.text('10,000.00 RSD'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '2,5');
    await tester.pump();
    expect(find.text('12.50 RON'), findsOneWidget);
  });
}
