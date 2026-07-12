import 'break_kind.dart';

/// Which animated illustration an exercise uses. Several exercises share
/// a primitive with different parameters — see ExerciseFigure.
enum ExerciseArt {
  eyesFarNear,
  eyesPalming,
  eyesFigureEight,
  eyesBlink,
  headRoll,
  chinTuck,
  shoulders,
  wrists,
  posture,
  sideStretch,
  walk,
  breathe,
}

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.steps,
    required this.tier,
    required this.art,
  });

  final String id;
  final String name;
  final List<String> steps;

  /// Which break tier this exercise fits.
  final BreakKind tier;
  final ExerciseArt art;
}

/// The built-in deck. IDs are stable — they appear in the exercise log
/// and in the opt-out list, so never reuse or rename one.
const exerciseDeck = <Exercise>[
  // ---- micro (eye) exercises ------------------------------------------
  Exercise(
    id: 'eyes_20_20_20',
    name: 'Look far away',
    steps: [
      'Look at something at least 6 meters away',
      'Keep your gaze relaxed until the timer ends',
      'Blink normally',
    ],
    tier: BreakKind.micro,
    art: ExerciseArt.eyesFarNear,
  ),
  Exercise(
    id: 'eyes_palming',
    name: 'Palming',
    steps: [
      'Rub your palms together until warm',
      'Cup them gently over your closed eyes',
      'Breathe slowly in the darkness',
    ],
    tier: BreakKind.micro,
    art: ExerciseArt.eyesPalming,
  ),
  Exercise(
    id: 'eyes_figure8',
    name: 'Figure eight',
    steps: [
      'Pick a point about 3 meters away',
      'Trace a slow sideways 8 with your eyes',
      'Switch direction halfway through',
    ],
    tier: BreakKind.micro,
    art: ExerciseArt.eyesFigureEight,
  ),
  Exercise(
    id: 'eyes_blink',
    name: 'Blink burst',
    steps: [
      'Blink quickly ten times',
      'Close your eyes and rest for a few seconds',
      'Repeat once more',
    ],
    tier: BreakKind.micro,
    art: ExerciseArt.eyesBlink,
  ),
  // ---- long (movement) exercises --------------------------------------
  Exercise(
    id: 'neck_rolls',
    name: 'Neck rolls',
    steps: [
      'Drop your chin toward your chest',
      'Roll your head slowly in a half circle',
      'Reverse direction; keep shoulders relaxed',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.headRoll,
  ),
  Exercise(
    id: 'chin_tucks',
    name: 'Chin tucks',
    steps: [
      'Sit tall, look straight ahead',
      'Draw your chin straight back (make a double chin)',
      'Hold 3 seconds, release, repeat',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.chinTuck,
  ),
  Exercise(
    id: 'shoulder_shrugs',
    name: 'Shoulder shrugs',
    steps: [
      'Raise both shoulders toward your ears',
      'Hold 3 seconds, then drop them fully',
      'Repeat slowly',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.shoulders,
  ),
  Exercise(
    id: 'wrist_stretch',
    name: 'Wrist & finger stretch',
    steps: [
      'Extend one arm, palm up',
      'Gently pull the fingers back with the other hand',
      'Hold 10 seconds, switch hands, then shake them out',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.wrists,
  ),
  Exercise(
    id: 'posture_reset',
    name: 'Posture reset',
    steps: [
      'Stand up, feet hip-width apart',
      'Roll shoulders back and down',
      'Imagine a string pulling the top of your head up',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.posture,
  ),
  Exercise(
    id: 'side_stretch',
    name: 'Side stretch',
    steps: [
      'Stand and raise one arm overhead',
      'Lean gently to the opposite side',
      'Hold, breathe, switch sides',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.sideStretch,
  ),
  Exercise(
    id: 'walk_around',
    name: 'Stand & walk',
    steps: [
      'Stand up and walk away from your desk',
      'Get water or look out a window',
      'Keep moving until the timer ends',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.walk,
  ),
  Exercise(
    id: 'deep_breathing',
    name: 'Deep breathing',
    steps: [
      'Breathe in through your nose for 4 counts',
      'Hold for 4 counts',
      'Breathe out slowly for 6 counts; repeat',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.breathe,
  ),
];
