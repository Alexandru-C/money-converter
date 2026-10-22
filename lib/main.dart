import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'rates.dart';

void main() => runApp(const MoneyConverterApp());

class MoneyConverterApp extends StatelessWidget {
  const MoneyConverterApp({super.key, this.service});

  final RatesService? service;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Money Converter',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: ConverterPage(service: service ?? RatesService()),
    );
  }
}

const _flags = {'RON': '🇷🇴', 'EUR': '🇪🇺', 'RSD': '🇷🇸'};

class ConverterPage extends StatefulWidget {
  const ConverterPage({super.key, required this.service});

  final RatesService service;

  @override
  State<ConverterPage> createState() => _ConverterPageState();
}

class _ConverterPageState extends State<ConverterPage> {
  final _amount = TextEditingController(text: '100');
  String _from = 'RON';
  Rates? _rates;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _amount.addListener(() => setState(() {}));
    _refresh();
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rates = await widget.service.load();
      if (mounted) setState(() => _rates = rates);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double? get _parsedAmount =>
      double.tryParse(_amount.text.replaceAll(',', '.').replaceAll(' ', ''));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rates = _rates;
    final amount = _parsedAmount;
    final fmt = NumberFormat('#,##0.00', 'en_US');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Money Converter'),
        actions: [
          IconButton(
            tooltip: 'Refresh rates',
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<String>(
              segments: [
                for (final c in currencies)
                  ButtonSegment(value: c, label: Text('${_flags[c]} $c')),
              ],
              selected: {_from},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _from = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
            if (_loading && rates == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (rates == null)
              Card(
                color: theme.colorScheme.errorContainer,
                child: ListTile(
                  leading: const Icon(Icons.error_outline),
                  title: const Text('No exchange rates available'),
                  subtitle: Text(_error ?? ''),
                  trailing: TextButton(
                    onPressed: _refresh,
                    child: const Text('Retry'),
                  ),
                ),
              )
            else ...[
              for (final to in currencies.where((c) => c != _from))
                Card(
                  child: ListTile(
                    leading: Text(_flags[to]!,
                        style: const TextStyle(fontSize: 28)),
                    title: Text(
                      amount == null
                          ? '—'
                          : '${fmt.format(rates.convert(amount, _from, to))} $to',
                      style: theme.textTheme.titleLarge,
                    ),
                    subtitle: Text(
                      '1 $_from = ${_rateText(rates.convert(1, _from, to))} $to',
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Rates for ${rates.date} · ${rates.source}'
                '${rates.fromCache ? '\nOffline: showing last saved rates' : ''}',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _rateText(double r) =>
      r >= 1 ? r.toStringAsFixed(4) : r.toStringAsPrecision(4);
}
