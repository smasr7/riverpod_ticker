import 'dart:async';
import 'dart:math';

import '../models/tick.dart';

class FeedException implements Exception {
  const FeedException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TickFeed {
  TickFeed({this.symbols = const ['BTC', 'ETH', 'SOL'], this.failAfter});

  final List<String> symbols;
  final int? failAfter;

  final _rng = Random();
  final _prices = <String, double>{};

  Stream<List<Tick>> watch() async* {
    var count = 0;
    await Future<void>.delayed(const Duration(milliseconds: 800));

    while (true) {
      if (failAfter != null && count >= failAfter!) {
        throw const FeedException('Feed disconnected');
      }
      yield [for (final symbol in symbols) _next(symbol)];
      count++;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  Tick _next(String symbol) {
    final previous = _prices[symbol] ?? 100 + _rng.nextDouble() * 900;
    final change = (_rng.nextDouble() - 0.5) * 4;
    final price = (previous + change).clamp(1, double.infinity).toDouble();
    _prices[symbol] = price;
    return Tick(
      symbol: symbol,
      price: price,
      change: change,
      at: DateTime.now(),
    );
  }
}
