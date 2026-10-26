// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/licensing/entitlement.dart';
import '../../platform/interfaces/licence_store.dart';
import '../../services/licence_service.dart';
import '../../services/providers.dart';

/// The trial's state on the dashboard: one quiet line while it runs, a clear
/// card once it has ended. Nothing at all once a plan is owned, on Linux or
/// on a test build.
class PlanBanner extends ConsumerWidget {
  const PlanBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(entitlementProvider).value;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return switch (entitlement) {
      Trial(:final daysLeft) => Padding(
        padding: const EdgeInsets.only(bottom: AppTokens.spaceMd),
        child: Card(
          color: scheme.surfaceContainerHigh,
          child: ListTile(
            leading: Icon(
              Icons.hourglass_bottom_outlined,
              color: scheme.primary,
            ),
            title: Text(
              daysLeft == 1
                  ? 'Free trial: last day'
                  : 'Free trial: $daysLeft days left',
            ),
            subtitle: const Text(
              'Choose Yearly or Lifetime whenever you like.',
            ),
            trailing: FilledButton.tonal(
              onPressed: () => showPlanSheet(context),
              child: const Text('Choose a plan'),
            ),
          ),
        ),
      ),
      TrialEnded() => Padding(
        padding: const EdgeInsets.only(bottom: AppTokens.spaceMd),
        child: Card(
          color: scheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spaceMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your free trial has ended', style: text.titleMedium),
                const SizedBox(height: AppTokens.spaceXs),
                const Text(
                  'Breaks are paused. Your history is all still here. '
                  'Choose a plan to bring your breaks back.',
                ),
                const SizedBox(height: AppTokens.spaceMd),
                FilledButton(
                  onPressed: () => showPlanSheet(context),
                  child: const Text('Choose a plan'),
                ),
              ],
            ),
          ),
        ),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

/// The plan row in Settings → About. Shown only on the Store build.
class PlanSettingsTile extends ConsumerWidget {
  const PlanSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(entitlementProvider).value;
    final (status, action) = switch (entitlement) {
      Trial(:final daysLeft) => (
        'Free trial, $daysLeft ${daysLeft == 1 ? 'day' : 'days'} left',
        'Choose a plan',
      ),
      TrialEnded() => ('Free trial ended', 'Choose a plan'),
      Owned(plan: Plan.yearly) => (
        'Yearly. Manage or cancel at account.microsoft.com',
        null,
      ),
      Owned(plan: Plan.lifetime) => ('Lifetime. Thank you!', null),
      _ => (null, null),
    };
    if (status == null) return const SizedBox.shrink();
    return ListTile(
      leading: const Icon(Icons.workspace_premium_outlined),
      title: const Text('Plan'),
      subtitle: Text(status),
      trailing: action == null
          ? null
          : FilledButton.tonal(
              onPressed: () => showPlanSheet(context),
              child: Text(action),
            ),
    );
  }
}

Future<void> showPlanSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => const PlanSheet(),
);

/// Yearly and Lifetime with the Store's own prices, in the buyer's currency.
class PlanSheet extends ConsumerStatefulWidget {
  const PlanSheet({super.key});

  @override
  ConsumerState<PlanSheet> createState() => _PlanSheetState();
}

class _PlanSheetState extends ConsumerState<PlanSheet> {
  late Future<List<StoreOffer>> _offers;
  Plan? _buying;
  bool _restoring = false;

  LicenceService get _service => ref.read(licenceServiceProvider)!;

  @override
  void initState() {
    super.initState();
    _offers = _service.offers();
  }

  void _say(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _buy(Plan plan) async {
    setState(() => _buying = plan);
    final outcome = await _service.buy(plan);
    if (!mounted) return;
    setState(() => _buying = null);
    switch (outcome) {
      case PurchaseOutcome.purchased:
        Navigator.of(context).pop();
        _say('Thank you! RestifEye is unlocked.');
      case PurchaseOutcome.alreadyOwned:
        Navigator.of(context).pop();
        _say('You already own this plan.');
      case PurchaseOutcome.cancelled:
        break;
      case PurchaseOutcome.failed:
        _say('The Store could not finish the purchase. Please try again.');
    }
  }

  Future<void> _restore() async {
    setState(() => _restoring = true);
    final result = await _service.refresh();
    if (!mounted) return;
    setState(() => _restoring = false);
    if (result is Owned) {
      Navigator.of(context).pop();
      _say('Your plan is restored.');
    } else {
      _say('No plan found for the Microsoft account signed in to the Store.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTokens.spaceLg,
          0,
          AppTokens.spaceLg,
          AppTokens.spaceLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choose a plan', style: text.headlineSmall),
            const SizedBox(height: AppTokens.spaceXs),
            const Text('Everything in RestifEye, on this PC.'),
            const SizedBox(height: AppTokens.spaceLg),
            FutureBuilder<List<StoreOffer>>(
              future: _offers,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(AppTokens.spaceLg),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final offers = snapshot.data ?? const [];
                if (offers.isEmpty) {
                  return _StoreUnavailable(
                    onRetry: () => setState(() => _offers = _service.offers()),
                  );
                }
                return Wrap(
                  spacing: AppTokens.spaceMd,
                  runSpacing: AppTokens.spaceMd,
                  children: [
                    for (final offer in offers)
                      _OfferCard(
                        offer: offer,
                        reserveSaleLine: offers.any((o) => o.fullPrice != null),
                        busy: _buying == offer.plan,
                        enabled: _buying == null,
                        onBuy: () => _buy(offer.plan),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppTokens.spaceMd),
            Text(
              'Payment, renewal and cancelling are handled by the Microsoft '
              'Store.',
              style: text.bodySmall,
            ),
            const SizedBox(height: AppTokens.spaceSm),
            TextButton(
              onPressed: _restoring || _buying != null ? null : _restore,
              child: Text(_restoring ? 'Checking…' : 'Restore purchase'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.reserveSaleLine,
    required this.busy,
    required this.enabled,
    required this.onBuy,
  });

  final StoreOffer offer;

  /// Keeps the cards' buttons level when only one of them shows a sale.
  final bool reserveSaleLine;
  final bool busy;
  final bool enabled;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final lifetime = offer.plan == Plan.lifetime;
    final label = lifetime ? 'Buy Lifetime' : 'Buy Yearly';
    final button = busy
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Text(label);

    return SizedBox(
      width: 240,
      child: Card(
        color: lifetime ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lifetime ? 'Lifetime' : 'Yearly', style: text.titleMedium),
              const SizedBox(height: AppTokens.spaceSm),
              if (offer.fullPrice != null || reserveSaleLine)
                Text(
                  offer.fullPrice ?? ' ',
                  style: text.bodyMedium?.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              Text(offer.price, style: text.headlineMedium),
              Text(
                lifetime
                    ? 'Pay once, yours to keep'
                    : 'Per year, renews automatically',
                style: text.bodySmall,
              ),
              const SizedBox(height: AppTokens.spaceMd),
              SizedBox(
                width: double.infinity,
                child: lifetime
                    ? FilledButton(
                        onPressed: enabled ? onBuy : null,
                        child: button,
                      )
                    : FilledButton.tonal(
                        onPressed: enabled ? onBuy : null,
                        child: button,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StoreUnavailable extends StatelessWidget {
  const _StoreUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'The Microsoft Store did not answer. Check your internet connection '
        'and that you are signed in to the Store, then try again.',
      ),
      const SizedBox(height: AppTokens.spaceSm),
      OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
    ],
  );
}
