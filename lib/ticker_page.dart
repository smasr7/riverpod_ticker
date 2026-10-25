import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/tick.dart';
import 'providers/ticker_providers.dart';
import 'widgets/tick_row.dart';

class TickerPage extends ConsumerWidget {
  const TickerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticks = ref.watch(tickerProvider);

    Future<void> refresh() async {
      await ref.refresh(tickerProvider.future);
    }

    void retry() => ref.invalidate(tickerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live ticker'),
        actions: [
          IconButton(
            tooltip: 'Simulate feed failure',
            icon: const Icon(Icons.wifi_off),
            onPressed: () => ref.read(failAfterProvider.notifier).set(5),
          ),
          IconButton(
            tooltip: 'Restore feed',
            icon: const Icon(Icons.wifi),
            onPressed: () => ref.read(failAfterProvider.notifier).set(null),
          ),
        ],
      ),
      body: switch (ticks) {
        AsyncError(:final error, :final value?) => Column(
          children: [
            MaterialBanner(
              content: Text('Feed error: $error — showing last prices'),
              actions: [
                TextButton(onPressed: retry, child: const Text('Retry')),
              ],
            ),
            Expanded(child: Opacity(opacity: 0.5, child: _TickList(value))),
          ],
        ),
        AsyncError(:final error) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Could not load ticker\n$error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: retry, child: const Text('Retry')),
            ],
          ),
        ),
        AsyncValue(:final value?, isLoading: true) => Column(
          children: [
            const LinearProgressIndicator(),
            Expanded(child: _TickList(value)),
          ],
        ),
        AsyncData(value: []) => const Center(
          child: Text('No symbols subscribed'),
        ),
        AsyncData(value: [final only]) => Center(child: TickRow(only)),
        AsyncData(:final value) => _TickList(value, onRefresh: refresh),
        AsyncLoading() => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _TickList extends StatelessWidget {
  const _TickList(this.ticks, {this.onRefresh});

  final List<Tick> ticks;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final list = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        for (final tick in ticks) TickRow(tick, key: ValueKey(tick.symbol)),
      ],
    );

    final onRefresh = this.onRefresh;
    if (onRefresh == null) return list;
    return RefreshIndicator(onRefresh: onRefresh, child: list);
  }
}
