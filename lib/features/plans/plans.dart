// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/licensing/entitlement.dart';
import '../../platform/interfaces/licence_store.dart';
import '../../services/providers.dart';

/// The app's price as the Store shows it, in the buyer's currency; null
/// while unknown or when the Store does not answer.
final storeOfferProvider = FutureProvider<StoreOffer?>((ref) async {
  final service = ref.watch(licenceServiceProvider);
  return service?.offer();
});

/// The trial's state on the dashboard: one quiet line while it runs, a clear
/// card once it has ended. Nothing at all once bought, on Linux or on a test
/// build.
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
            subtitle: const _PriceLine(),
            trailing: const BuyButton(tonal: true),
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
                  'Buy RestifEye to bring your breaks back.',
                ),
                const SizedBox(height: AppTokens.spaceXs),
                const _PriceLine(),
                const SizedBox(height: AppTokens.spaceMd),
                const BuyButton(),
              ],
            ),
          ),
        ),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

/// The licence row in Settings → About. Shown only on the Store build.
class PlanSettingsTile extends ConsumerWidget {
  const PlanSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement = ref.watch(entitlementProvider).value;
    final (title, status, canBuy) = switch (entitlement) {
      Trial(:final daysLeft) => (
        'Free trial',
        '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left',
        true,
      ),
      TrialEnded() => ('Free trial', 'Ended', true),
      Owned() => ('Full version', 'Bought. Thank you!', false),
      _ => (null, null, false),
    };
    if (title == null) return const SizedBox.shrink();
    return ListTile(
      leading: const Icon(Icons.workspace_premium_outlined),
      title: Text(title),
      subtitle: Text(status!),
      trailing: canBuy ? const BuyButton(tonal: true) : null,
    );
  }
}

/// "Pay once: $19.99", with the usual price crossed out during a sale.
class _PriceLine extends ConsumerWidget {
  const _PriceLine();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offer = ref.watch(storeOfferProvider).value;
    final text = Theme.of(context).textTheme;
    if (offer == null || offer.price.isEmpty) {
      return const Text('Pay once, yours to keep.');
    }
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Pay once: '),
          if (offer.fullPrice != null) ...[
            TextSpan(
              text: offer.fullPrice,
              style: const TextStyle(decoration: TextDecoration.lineThrough),
            ),
            const TextSpan(text: ' '),
          ],
          TextSpan(
            text: offer.price,
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Opens the Microsoft Store's own purchase window for the full app.
class BuyButton extends ConsumerStatefulWidget {
  const BuyButton({super.key, this.tonal = false});

  final bool tonal;

  @override
  ConsumerState<BuyButton> createState() => _BuyButtonState();
}

class _BuyButtonState extends ConsumerState<BuyButton> {
  bool _buying = false;

  void _say(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Future<void> _buy() async {
    final service = ref.read(licenceServiceProvider);
    if (service == null) return;
    setState(() => _buying = true);
    final outcome = await service.buy();
    if (!mounted) return;
    setState(() => _buying = false);
    switch (outcome) {
      case PurchaseOutcome.purchased:
        _say('Thank you! RestifEye is yours to keep.');
      case PurchaseOutcome.alreadyOwned:
        _say('You already own RestifEye.');
      case PurchaseOutcome.cancelled:
        break;
      case PurchaseOutcome.failed:
        _say(
          'The Microsoft Store could not finish the purchase. Check that you '
          'are online and signed in to the Store, then try again.',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _buying
        ? const SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Text('Buy');
    final onPressed = _buying ? null : _buy;
    return widget.tonal
        ? FilledButton.tonal(onPressed: onPressed, child: child)
        : FilledButton(onPressed: onPressed, child: child);
  }
}
