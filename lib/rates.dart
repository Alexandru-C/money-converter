const currencies = ['RON', 'EUR', 'RSD'];

/// BNR (RON) and NBS (RSD) reference rates published for this date.
const ratesDate = '2026-10-22';

/// Units of each currency per 1 EUR.
const perEur = {'EUR': 1.0, 'RON': 5.3485, 'RSD': 117.451};

double convert(double amount, String from, String to) =>
    amount / perEur[from]! * perEur[to]!;
