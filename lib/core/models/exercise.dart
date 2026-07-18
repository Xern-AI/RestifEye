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
  neckTilt,
  chestOpen,
  torsoTwist,
  forwardFold,
  calfRaise,
  armCircles,
  squat,
  lunge,
  marchInPlace,
  jumpingJacks,
}

/// How much the exercise asks of the user — and of the room they are in.
///
/// This exists because "stand up and do ten squats" is excellent advice at
/// home and impossible in an open-plan office or a coffee shop. Without a
/// ceiling, the heavier exercises would simply train users to dismiss the
/// overlay, which costs far more than the exercise was worth.
enum ExerciseIntensity {
  /// Seated, invisible to anyone watching.
  soft,

  /// Standing or stretching. Noticeable, but nothing anyone would remark on.
  medium,

  /// Raises the heart rate. Needs space and a certain lack of self
  /// consciousness.
  heavy;

  /// Whether this fits within a [ceiling] the user has chosen. Relies on
  /// declaration order, so the values must stay ordered least to most
  /// demanding.
  bool allowedBy(ExerciseIntensity ceiling) => index <= ceiling.index;
}

class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.steps,
    required this.tier,
    required this.art,
    this.intensity = ExerciseIntensity.soft,
  });

  final String id;
  final String name;
  final List<String> steps;

  /// Which break tier this exercise fits.
  final BreakKind tier;
  final ExerciseArt art;
  final ExerciseIntensity intensity;
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
    intensity: ExerciseIntensity.medium,
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
    intensity: ExerciseIntensity.medium,
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
    intensity: ExerciseIntensity.medium,
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
  // ---- long: added soft options -------------------------------------
  Exercise(
    id: 'neck_side_stretch',
    name: 'Neck side stretch',
    steps: [
      'Sit tall and drop one ear toward that shoulder',
      'Rest a hand on your head for gentle weight — do not pull',
      'Hold 15 seconds, then switch sides',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.neckTilt,
  ),
  Exercise(
    id: 'chest_opener',
    name: 'Chest opener',
    steps: [
      'Clasp your hands behind your back',
      'Straighten your arms and lift them slightly',
      'Open your chest and breathe; hold 15 seconds',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.chestOpen,
  ),
  Exercise(
    id: 'seated_twist',
    name: 'Seated twist',
    steps: [
      'Sit tall, feet flat on the floor',
      'Turn your torso to one side, hand on the chair back',
      'Hold 15 seconds, unwind slowly, switch sides',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.torsoTwist,
  ),
  // ---- long: medium ---------------------------------------------------
  Exercise(
    id: 'forward_fold',
    name: 'Standing forward fold',
    steps: [
      'Stand with feet hip-width apart',
      'Hinge at the hips and let your upper body hang',
      'Keep a soft bend in the knees; hold 20 seconds',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.forwardFold,
    intensity: ExerciseIntensity.medium,
  ),
  Exercise(
    id: 'calf_raises',
    name: 'Calf raises',
    steps: [
      'Stand tall, hand on the desk for balance',
      'Rise onto the balls of your feet',
      'Lower slowly; repeat 15 times',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.calfRaise,
    intensity: ExerciseIntensity.medium,
  ),
  Exercise(
    id: 'arm_circles',
    name: 'Arm circles',
    steps: [
      'Stand and stretch both arms out to the sides',
      'Draw small circles forward for 15 seconds',
      'Reverse direction for another 15',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.armCircles,
    intensity: ExerciseIntensity.medium,
  ),
  Exercise(
    id: 'stairs_trip',
    name: 'Take the stairs',
    steps: [
      'Leave the room and find a staircase',
      'Walk up and down one flight at an easy pace',
      'Come back with a glass of water',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.walk,
    intensity: ExerciseIntensity.medium,
  ),
  // ---- long: heavy ----------------------------------------------------
  Exercise(
    id: 'bodyweight_squats',
    name: 'Bodyweight squats',
    steps: [
      'Stand with feet shoulder-width apart',
      'Sit back and down, keeping your chest up',
      'Drive through your heels to stand; repeat 12 times',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.squat,
    intensity: ExerciseIntensity.heavy,
  ),
  Exercise(
    id: 'alternating_lunges',
    name: 'Alternating lunges',
    steps: [
      'Step forward and lower your back knee toward the floor',
      'Push back to standing',
      'Alternate legs, 8 each side',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.lunge,
    intensity: ExerciseIntensity.heavy,
  ),
  Exercise(
    id: 'high_knees',
    name: 'March on the spot',
    steps: [
      'Stand tall and drive one knee up to hip height',
      'Alternate at a brisk pace, swinging your arms',
      'Keep going for 30 seconds',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.marchInPlace,
    intensity: ExerciseIntensity.heavy,
  ),
  Exercise(
    id: 'jumping_jacks',
    name: 'Jumping jacks',
    steps: [
      'Stand with feet together, arms at your sides',
      'Jump your feet wide as your arms sweep overhead',
      'Jump back together; repeat for 30 seconds',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.jumpingJacks,
    intensity: ExerciseIntensity.heavy,
  ),
];
