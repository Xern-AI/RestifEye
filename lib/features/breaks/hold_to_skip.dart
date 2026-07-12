import 'package:flutter/material.dart';

/// The emergency escape: hold for [holdFor] to confirm. Deliberate friction —
/// a slip of the mouse must not skip a break, but a real emergency can.
class HoldToSkip extends StatefulWidget {
  const HoldToSkip({
    super.key,
    required this.onConfirmed,
    this.holdFor = const Duration(seconds: 3),
    this.label = 'Hold to skip',
  });

  final VoidCallback onConfirmed;
  final Duration holdFor;
  final String label;

  @override
  State<HoldToSkip> createState() => _HoldToSkipState();
}

class _HoldToSkipState extends State<HoldToSkip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: widget.holdFor,
  );

  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _progress.addListener(() {
      if (_progress.value >= 1.0 && !_confirmed) {
        _confirmed = true;
        widget.onConfirmed();
        _progress.reset();
        _confirmed = false;
      }
    });
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label:
          '${widget.label} — press and hold for '
          '${widget.holdFor.inSeconds} seconds',
      child: GestureDetector(
        // Opaque: the ring/icon children don't claim hit tests themselves.
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _progress.forward(),
        onTapUp: (_) => _progress.reverse(),
        onTapCancel: () => _progress.reverse(),
        child: AnimatedBuilder(
          animation: _progress,
          builder: (context, _) => Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  value: _progress.value,
                  strokeWidth: 3,
                  color: scheme.error,
                  backgroundColor: scheme.outlineVariant,
                ),
              ),
              Icon(Icons.close, size: 20, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
