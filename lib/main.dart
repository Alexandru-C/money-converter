import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'flags.dart';
import 'rates.dart';

void main() => runApp(const MoneyConverterApp());

class MoneyConverterApp extends StatelessWidget {
  const MoneyConverterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Converter',
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
        fontFamily: 'AppRoboto',
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'AppRoboto',
      ),
      home: const ConverterPage(),
    );
  }
}

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key});

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final _amount = TextEditingController(text: '100');
  String _from = 'RON';

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double? get _parsedAmount =>
      double.tryParse(_amount.text.replaceAll(',', '.').replaceAll(' ', ''));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = _parsedAmount;
    final fmt = NumberFormat('#,##0.00', 'en_US');

    return Scaffold(
      appBar: AppBar(title: const Text('Money Converter')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<String>(
            segments: [
              for (final c in currencies)
                ButtonSegment(
                  value: c,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Flag(c, height: 14), const SizedBox(width: 8), Text(c)],
                  ),
                ),
            ],
            selected: {_from},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _from = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            style: theme.textTheme.headlineMedium,
            decoration: InputDecoration(
              labelText: 'Amount',
              suffixText: _from,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          for (final to in currencies.where((c) => c != _from))
            Card(
              child: ListTile(
                leading: Flag(to),
                title: Text(
                  amount == null
                      ? '—'
                      : '${fmt.format(convert(amount, _from, to))} $to',
                  style: theme.textTheme.titleLarge,
                ),
                subtitle: Text(
                  '1 $_from = ${_rateText(convert(1, _from, to))} $to',
                ),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            'Rates for $ratesDate · BNR (RON) · NBS (RSD)',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _rateText(double r) =>
      r >= 1 ? r.toStringAsFixed(4) : r.toStringAsPrecision(4);
}
