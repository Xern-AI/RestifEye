// Copyright 2026 Xernai. All rights reserved.
// Use of this source code is governed by the PolyForm Shield 1.0.0
// license that can be found in the LICENSE file.

import 'break_kind.dart';

/// Which animated illustration an exercise uses. Several exercises share
/// a primitive with different parameters — see ExerciseFigure.
enum ExerciseArt {
  eyesFarNear,
  eyesPalming,
  eyesFigureEight,
  eyesBlink,
  eyesRoll,
  eyesScan,
  eyesDiagonal,
  eyesZoom,
  eyesSqueeze,
  eyesMassage,
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
  ankleCircles,
  bladeSqueeze,
  legExtension,
  neckPress,
  wallAngels,
  doorwayStretch,
  quadStretch,
  hamstringStretch,
  deskPushUp,
  balance,
  hipCircles,
  heelToeWalk,
  wallSit,
  buttKicks,
  shadowBox,
  jumpRope,
  plank,
  pushUp,
  mountainClimber,
  catCow,
  gluteBridge,
  superman,
  hipFlexor,
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

  /// Anything you would do at home in your own room: raises the heart rate,
  /// or puts you on the floor. Needs space, a mat's worth of clear ground
  /// and a certain lack of self consciousness.
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
  Exercise(
    id: 'eyes_rolls',
    name: 'Eye rolls',
    steps: [
      'Keep your head still and look up',
      'Roll your eyes slowly in a full circle',
      'Five circles one way, then five the other',
    ],
    tier: BreakKind.micro,
    art: ExerciseArt.eyesRoll,
  ),
  Exercise(
    id: 'eyes_scan',
    name: 'Up-down, side-to-side',
    steps: [
      'Without moving your head, look up, then down',
      'Then far left, then far right',
      'Five slow rounds; let your gaze reach the edges',
    ],
    tier: BreakKind.micro,
    art: ExerciseArt.eyesScan,
  ),
  Exercise(
    id: 'eyes_diagonal',
    name: 'Diagonal sweeps',
    steps: [
      'Look up-left, then down-right',
      'Then up-right, then down-left',
      'Head still; five slow rounds',
    ],
    tier: BreakKind.micro,
    art: ExerciseArt.eyesDiagonal,
  ),
  Exercise(
    id: 'eyes_zoom',
    name: 'Thumb zoom',
    steps: [
      'Hold a thumb up at arm\'s length',
      'Focus on it, then on something far behind it',
      'Switch back and forth ten times',
    ],
    tier: BreakKind.micro,
    art: ExerciseArt.eyesZoom,
  ),
  Exercise(
    id: 'eyes_squeeze',
    name: 'Squeeze and open',
    steps: [
      'Shut your eyes tight for three seconds',
      'Open them wide and lift your brows',
      'Repeat five times',
    ],
    tier: BreakKind.micro,
    art: ExerciseArt.eyesSqueeze,
  ),
  Exercise(
    id: 'eyes_temple_massage',
    name: 'Temple massage',
    steps: [
      'Close your eyes and rest your fingertips on your temples',
      'Circle gently, ten times each way',
      'Finish along the brow bone and under the eyes',
    ],
    tier: BreakKind.micro,
    art: ExerciseArt.eyesMassage,
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
      'Rest a hand on your head for gentle weight, do not pull',
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
  // ---- long: more seated options --------------------------------------
  Exercise(
    id: 'ankle_circles',
    name: 'Ankle circles',
    steps: [
      'Sit tall and lift one foot off the floor',
      'Circle the ankle ten times each way',
      'Swap feet and repeat',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.ankleCircles,
  ),
  Exercise(
    id: 'shoulder_blade_squeeze',
    name: 'Shoulder blade squeeze',
    steps: [
      'Sit or stand tall, elbows bent at your sides',
      'Draw your shoulder blades together, chest open',
      'Hold 5 seconds, release; repeat 10 times',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.bladeSqueeze,
  ),
  Exercise(
    id: 'seated_leg_extension',
    name: 'Seated leg extensions',
    steps: [
      'Sit back in the chair, feet flat',
      'Straighten one leg out until it is level',
      'Hold 3 seconds, lower slowly; 10 each side',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.legExtension,
  ),
  Exercise(
    id: 'neck_isometrics',
    name: 'Neck press',
    steps: [
      'Rest a palm flat on your forehead',
      'Press your head gently into it without moving',
      'Hold 10 seconds; repeat at each side and the back',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.neckPress,
  ),
  // ---- long: more standing options ------------------------------------
  Exercise(
    id: 'wall_angels',
    name: 'Wall angels',
    steps: [
      'Stand with your back and arms flat against a wall',
      'Slide your arms up overhead, keeping contact',
      'Slide back down; repeat 10 times',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.wallAngels,
    intensity: ExerciseIntensity.medium,
  ),
  Exercise(
    id: 'doorway_stretch',
    name: 'Doorway chest stretch',
    steps: [
      'Stand in a doorway, forearms on the frame',
      'Step gently forward until you feel the chest open',
      'Hold 20 seconds, breathing slowly',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.doorwayStretch,
    intensity: ExerciseIntensity.medium,
  ),
  Exercise(
    id: 'quad_stretch',
    name: 'Standing quad stretch',
    steps: [
      'Hold the desk for balance and bend one knee back',
      'Catch the ankle and draw the heel toward you',
      'Hold 20 seconds, then switch legs',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.quadStretch,
    intensity: ExerciseIntensity.medium,
  ),
  Exercise(
    id: 'hamstring_stretch',
    name: 'Hamstring stretch',
    steps: [
      'Put one heel forward with the leg straight',
      'Hinge at the hips and reach toward that foot',
      'Hold 20 seconds, then switch legs',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.hamstringStretch,
    intensity: ExerciseIntensity.medium,
  ),
  Exercise(
    id: 'desk_push_ups',
    name: 'Desk push-ups',
    steps: [
      'Hands on the desk edge, feet back, body straight',
      'Lower your chest to the desk, elbows tucked',
      'Push back up; repeat 12 times',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.deskPushUp,
    intensity: ExerciseIntensity.medium,
  ),
  Exercise(
    id: 'single_leg_balance',
    name: 'Single-leg balance',
    steps: [
      'Stand on one leg, arms out to the sides',
      'Hold 30 seconds without touching down',
      'Switch legs; close your eyes to make it harder',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.balance,
    intensity: ExerciseIntensity.medium,
  ),
  Exercise(
    id: 'hip_circles',
    name: 'Hip circles',
    steps: [
      'Stand with hands on your hips, feet shoulder-width',
      'Circle your hips slowly, ten times each way',
      'Keep your shoulders still and your knees soft',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.hipCircles,
    intensity: ExerciseIntensity.medium,
  ),
  Exercise(
    id: 'heel_toe_walk',
    name: 'Heel-to-toe walk',
    steps: [
      'Walk a straight line, heel touching toe each step',
      'Arms out to the sides, eyes ahead',
      'Twenty steps out and twenty back',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.heelToeWalk,
    intensity: ExerciseIntensity.medium,
  ),
  // ---- long: at home, anything goes -----------------------------------
  Exercise(
    id: 'plank_hold',
    name: 'Plank',
    steps: [
      'Forearms on the floor, elbows under your shoulders',
      'Straight line from head to heels, hips level',
      'Hold 30 seconds, breathing steadily',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.plank,
    intensity: ExerciseIntensity.heavy,
  ),
  Exercise(
    id: 'push_ups',
    name: 'Push-ups',
    steps: [
      'Hands under your shoulders, body in one line',
      'Lower until your elbows reach 90 degrees',
      'Press back up; 10 reps, knees down if needed',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.pushUp,
    intensity: ExerciseIntensity.heavy,
  ),
  Exercise(
    id: 'wall_sit',
    name: 'Wall sit',
    steps: [
      'Slide down a wall until your thighs are level',
      'Knees over ankles, back flat against the wall',
      'Hold 30 seconds',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.wallSit,
    intensity: ExerciseIntensity.heavy,
  ),
  Exercise(
    id: 'glute_bridge',
    name: 'Glute bridge',
    steps: [
      'Lie on your back, knees bent, feet flat',
      'Drive through your heels and lift your hips',
      'Squeeze at the top, lower slowly; 15 reps',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.gluteBridge,
    intensity: ExerciseIntensity.heavy,
  ),
  Exercise(
    id: 'cat_cow',
    name: 'Cat-cow',
    steps: [
      'On hands and knees, wrists under shoulders',
      'Round your back and tuck your chin',
      'Then drop your belly and lift your gaze; 10 slow rounds',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.catCow,
    intensity: ExerciseIntensity.heavy,
  ),
  Exercise(
    id: 'mountain_climbers',
    name: 'Mountain climbers',
    steps: [
      'Start in a push-up position, hips level',
      'Drive one knee toward your chest, then the other',
      'Keep a steady rhythm for 30 seconds',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.mountainClimber,
    intensity: ExerciseIntensity.heavy,
  ),
  Exercise(
    id: 'superman_hold',
    name: 'Superman',
    steps: [
      'Lie face down, arms stretched out in front',
      'Lift your arms, chest and legs off the floor',
      'Hold 5 seconds, lower; repeat 10 times',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.superman,
    intensity: ExerciseIntensity.heavy,
  ),
  Exercise(
    id: 'hip_flexor_lunge',
    name: 'Kneeling hip stretch',
    steps: [
      'Kneel on one knee with the other foot forward',
      'Press your hips gently forward, chest tall',
      'Hold 20 seconds, then switch sides',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.hipFlexor,
    intensity: ExerciseIntensity.heavy,
  ),
  Exercise(
    id: 'butt_kicks',
    name: 'Heel kicks',
    steps: [
      'Jog on the spot, kicking your heels toward your seat',
      'Keep your knees pointing down and your chest tall',
      'Thirty seconds at a brisk pace',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.buttKicks,
    intensity: ExerciseIntensity.heavy,
  ),
  Exercise(
    id: 'shadow_boxing',
    name: 'Shadow boxing',
    steps: [
      'Hands up by your chin, one foot slightly forward',
      'Punch alternately, turning through your hips',
      'Keep moving for 30 seconds',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.shadowBox,
    intensity: ExerciseIntensity.heavy,
  ),
  Exercise(
    id: 'invisible_jump_rope',
    name: 'Invisible skipping',
    steps: [
      'Hop lightly on the balls of your feet',
      'Turn your wrists as if a rope were going round',
      'Thirty seconds; land softly',
    ],
    tier: BreakKind.long,
    art: ExerciseArt.jumpRope,
    intensity: ExerciseIntensity.heavy,
  ),
];
