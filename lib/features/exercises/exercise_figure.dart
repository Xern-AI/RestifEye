import 'package:flutter/material.dart';

import '../../core/models/exercise.dart';
import 'body_art.dart';
import 'eye_art.dart';

/// Theme-aware looping illustration for an exercise.
class ExerciseFigure extends StatefulWidget {
  const ExerciseFigure({super.key, required this.art, this.size = 220});

  final ExerciseArt art;
  final double size;

  @override
  State<ExerciseFigure> createState() => _ExerciseFigureState();
}

class _ExerciseFigureState extends State<ExerciseFigure>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final painter = switch (widget.art) {
            ExerciseArt.eyesFarNear => EyeArtPainter(
              t: t,
              mode: EyeMode.farNear,
              scheme: scheme,
            ),
            ExerciseArt.eyesPalming => EyeArtPainter(
              t: t,
              mode: EyeMode.palming,
              scheme: scheme,
            ),
            ExerciseArt.eyesFigureEight => EyeArtPainter(
              t: t,
              mode: EyeMode.figureEight,
              scheme: scheme,
            ),
            ExerciseArt.eyesBlink => EyeArtPainter(
              t: t,
              mode: EyeMode.blink,
              scheme: scheme,
            ),
            ExerciseArt.headRoll => BodyArtPainter(
              t: t,
              mode: BodyMode.headRoll,
              scheme: scheme,
            ),
            ExerciseArt.chinTuck => BodyArtPainter(
              t: t,
              mode: BodyMode.chinTuck,
              scheme: scheme,
            ),
            ExerciseArt.shoulders => BodyArtPainter(
              t: t,
              mode: BodyMode.shoulders,
              scheme: scheme,
            ),
            ExerciseArt.wrists => BodyArtPainter(
              t: t,
              mode: BodyMode.wrists,
              scheme: scheme,
            ),
            ExerciseArt.posture => BodyArtPainter(
              t: t,
              mode: BodyMode.posture,
              scheme: scheme,
            ),
            ExerciseArt.sideStretch => BodyArtPainter(
              t: t,
              mode: BodyMode.sideStretch,
              scheme: scheme,
            ),
            ExerciseArt.walk => BodyArtPainter(
              t: t,
              mode: BodyMode.walk,
              scheme: scheme,
            ),
            ExerciseArt.breathe => BodyArtPainter(
              t: t,
              mode: BodyMode.breathe,
              scheme: scheme,
            ),
          };
          return CustomPaint(size: Size.square(widget.size), painter: painter);
        },
      ),
    );
  }
}
