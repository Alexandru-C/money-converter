import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart';

const currencies = ['RON', 'EUR', 'RSD'];

/// BNR and NBS reference rates published for 2026-10-22.
final fixedRates = Rates(
  perEur: {'EUR': 1, 'RON': 5.3485, 'RSD': 117.451},
  date: '2026-10-22',
  source: 'BNR (RON) · NBS (RSD), fixed',
);

/// Exchange rates expressed as "units of currency per 1 EUR".
class Rates {
  Rates({
    required this.perEur,
    required this.date,
    required this.source,
    this.fromCache = false,
  });

  final Map<String, double> perEur;
  final String date;
  final String source;
  final bool fromCache;

  double convert(double amount, String from, String to) =>
      amount / perEur[from]! * perEur[to]!;

  Map<String, dynamic> toJson() =>
      {'perEur': perEur, 'date': date, 'source': source};

  factory Rates.fromJson(Map<String, dynamic> j, {bool fromCache = false}) =>
      Rates(
        perEur: (j['perEur'] as Map)
            .map((k, v) => MapEntry(k as String, (v as num).toDouble())),
        date: j['date'] as String,
        source: j['source'] as String,
        fromCache: fromCache,
      );
}

class RatesService {
  RatesService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _cacheKey = 'rates_v1';
  static const _timeout = Duration(seconds: 10);

  /// Official central-bank rates first (BNR for RON, NBS for RSD), then a
  /// commercial aggregator, then the last successfully fetched rates.
  Future<Rates> load() async {
    // BNR's XML sends no CORS header, so browsers can't fetch it. The web
    // build uses rates fixed at build time instead.
    if (kIsWeb) return fixedRates;
    Rates? rates;
    try {
      rates = await _fetchOfficial();
    } catch (_) {
      try {
        rates = await _fetchFallback();
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    if (rates != null) {
      await prefs.setString(_cacheKey, jsonEncode(rates.toJson()));
      return rates;
    }
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      return Rates.fromJson(jsonDecode(cached), fromCache: true);
    }
    throw Exception('Could not fetch exchange rates and none are cached.');
  }

  Future<Rates> _fetchOfficial() async {
    final results = await Future.wait([_fetchBnrEur(), _fetchNbsEur()]);
    final (ronPerEur, bnrDate) = results[0];
    final (rsdPerEur, nbsDate) = results[1];
    return Rates(
      perEur: {'EUR': 1, 'RON': ronPerEur, 'RSD': rsdPerEur},
      date: bnrDate == nbsDate ? bnrDate : 'BNR $bnrDate · NBS $nbsDate',
      source: 'BNR (RON) · NBS (RSD)',
    );
  }

  /// National Bank of Romania daily reference rates: RON per 1 EUR.
  Future<(double, String)> _fetchBnrEur() async {
    final res = await _client
        .get(Uri.parse('https://curs.bnr.ro/nbrfxrates.xml'))
        .timeout(_timeout);
    if (res.statusCode != 200) throw Exception('BNR HTTP ${res.statusCode}');
    final doc = XmlDocument.parse(res.body);
    final cube = doc.findAllElements('Cube').first;
    final eur = cube
        .findElements('Rate')
        .firstWhere((e) => e.getAttribute('currency') == 'EUR');
    final multiplier = int.parse(eur.getAttribute('multiplier') ?? '1');
    return (double.parse(eur.innerText) / multiplier, cube.getAttribute('date')!);
  }

  /// National Bank of Serbia official middle rate (via kurs.resenje.org):
  /// RSD per 1 EUR.
  Future<(double, String)> _fetchNbsEur() async {
    final res = await _client
        .get(Uri.parse('https://kurs.resenje.org/api/v1/currencies/eur/rates/today'))
        .timeout(_timeout);
    if (res.statusCode != 200) throw Exception('NBS HTTP ${res.statusCode}');
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final middle = (j['exchange_middle'] as num).toDouble();
    final parity = (j['parity'] as num).toDouble();
    return (middle / parity, j['date'] as String);
  }

  Future<Rates> _fetchFallback() async {
    final res = await _client
        .get(Uri.parse('https://open.er-api.com/v6/latest/EUR'))
        .timeout(_timeout);
    if (res.statusCode != 200) throw Exception('ER-API HTTP ${res.statusCode}');
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final r = j['rates'] as Map<String, dynamic>;
    final updated = DateTime.fromMillisecondsSinceEpoch(
        (j['time_last_update_unix'] as int) * 1000,
        isUtc: true);
    return Rates(
      perEur: {
        'EUR': 1,
        'RON': (r['RON'] as num).toDouble(),
        'RSD': (r['RSD'] as num).toDouble(),
      },
      date: updated.toIso8601String().substring(0, 10),
      source: 'ExchangeRate-API (fallback)',
    );
  }
}
