// GENERATED CONTENT — TinyMind learning library (70 short activities).
//
// Each tile in the library is ONE fixed short activity: an optional "teach"
// card on its first question, then exactly 3 questions in a fixed order.
// Stars are earned from how many questions the child gets right on the first
// try (see [starsForScore]); every activity can be replayed at any time.
//
// Reuses [QuizQuestion], [QuizOption], [AnswerVisual], and [QuizCue] from
// learning.dart. Left-card cues are rendered independently from answer tiles.
import 'package:flutter/material.dart';

import 'learning.dart';

const _red = Color(0xFFE84855);
const _blue = Color(0xFF3A86FF);
const _yellow = Color(0xFFFFC857);
const _green = Color(0xFF2ECC71);
const _orange = Color(0xFFFF8C42);
const _purple = Color(0xFFA78BFA);
const _pink = Color(0xFFFF8FAB);
const _brown = Color(0xFF8D6748);
const _shapeRed = Color(0xFFE84855);

/// A heading that groups several activities in the library grid.
class LearningSection {
  const LearningSection({required this.title, required this.emoji});
  final String title;
  final String emoji;
}

/// One library tile: a short, fixed activity of exactly 3 questions.
class Activity {
  const Activity({
    required this.id,
    required this.sectionIndex,
    required this.title,
    required this.emoji,
    required this.questions,
    this.minAge = 3,
  });

  /// Stable id, e.g. 'letters_a', 'numbers_07'. Used as the key in saved
  /// progress, so never renumber or reuse an id.
  final String id;
  final int sectionIndex;
  final String title;
  final String emoji;
  final List<QuizQuestion> questions;
  final int minAge;
}

/// Everything one learning world (LearningModule.id) shows in its library.
class WorldCatalog {
  const WorldCatalog({
    required this.sections,
    required this.olderStartSection,
    required this.youngMaxSection,
    required this.activities,
  });

  final List<LearningSection> sections;

  /// Section where children aged 5-6 are first recommended to start
  /// (3-4 year olds always start at section 0).
  final int olderStartSection;

  /// Last section recommended to children aged 4 and under, inclusive.
  final int youngMaxSection;
  final List<Activity> activities;

  List<Activity> inSection(int index) =>
      activities.where((a) => a.sectionIndex == index).toList();
}

/// Stars for one finished activity, from the number of questions answered
/// correctly on the first try: 90%+ = 3 stars, 60%+ = 2 stars, otherwise
/// 1 star for finishing. With 3 questions that means 3/3 -> 3, 2/3 -> 2,
/// 0-1 -> 1.
int starsForScore(int correct, int total) {
  if (total <= 0) return 1;
  final ratio = correct / total;
  if (ratio >= 0.9) return 3;
  if (ratio >= 0.6) return 2;
  return 1;
}

/// Looks an activity up by id across all worlds (null if unknown).
Activity? activityById(String id) {
  for (final catalog in worldCatalogs.values) {
    for (final activity in catalog.activities) {
      if (activity.id == id) return activity;
    }
  }
  return null;
}

/// The rule-based "try this next" suggestion for a world (this is the
/// adaptive part): start from the section that suits the child's age, and
/// suggest the first activity that does not yet have 2+ stars — an unplayed
/// one, or a 1-star one worth replaying. Falls back to the earliest such
/// activity in the age-appropriate range, then to the first without 3 stars
/// in that range, then null.
/// [bestStars] maps activity id -> best stars earned so far (missing = 0).
String? recommendedActivityId({
  required String worldId,
  required int age,
  required Map<String, int> bestStars,
}) {
  final catalog = worldCatalogs[worldId];
  if (catalog == null) return null;
  final start = age >= 5 ? catalog.olderStartSection : 0;
  final candidates = catalog.activities.where(
    (activity) =>
        age >= activity.minAge &&
        (age > 4 || activity.sectionIndex <= catalog.youngMaxSection),
  );
  int stars(Activity a) => bestStars[a.id] ?? 0;
  for (final a in candidates) {
    if (a.sectionIndex >= start && stars(a) < 2) return a.id;
  }
  for (final a in candidates) {
    if (stars(a) < 2) return a.id;
  }
  for (final a in candidates) {
    if (stars(a) < 3) return a.id;
  }
  return null;
}

const worldCatalogs = <String, WorldCatalog>{

  // ===== Letter Land (26 activities) =====
  'letters': WorldCatalog(
    olderStartSection: 0,
    youngMaxSection: 2,
    sections: [
      LearningSection(title: 'A to I', emoji: '🍎'),
      LearningSection(title: 'J to R', emoji: '🦁'),
      LearningSection(title: 'S to Z', emoji: '☀️'),
    ],
    activities: [
    Activity(
      id: 'letters_a',
      sectionIndex: 0,
      title: 'A',
      emoji: '🍎',
      questions: [
        QuizQuestion(
          prompt: 'Tap the letter that matches 🍎',
          visual: AnswerVisual.letterPicture,
          teach: '"A" is for Apple! 🍎 Say it with me: Aaa!',
          spokenText: 'A is for apple. Say it with me: ah.',
          teachOption: QuizOption('A', emoji: '🍎'),
          hint: 'Say "apple" slowly. Listen for the very first sound: Aaa!',
          options: [QuizOption('A', emoji: '🍎'), QuizOption('E', emoji: '🐘'), QuizOption('L', emoji: '🦁')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: 'Find the letter A',
          visual: AnswerVisual.text,
          hint: 'This letter is called "ay". Look at its shape and try again!',
          options: [QuizOption('F'), QuizOption('A'), QuizOption('N')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: 'Which picture starts with the letter A?',
          visual: AnswerVisual.picture,
          hint: 'Say each picture slowly. Which one starts with "Aaa"?',
          options: [QuizOption('Hat', emoji: '🎩'), QuizOption('Pizza', emoji: '🍕'), QuizOption('Apple', emoji: '🍎')],
          answerIndex: 2,
        ),
      ],
    ),
    Activity(
      id: 'letters_b',
      sectionIndex: 0,
      title: 'B',
      emoji: '⚽',
      questions: [
        QuizQuestion(
          prompt: 'Tap the letter that matches ⚽',
          visual: AnswerVisual.letterPicture,
          teach: '"B" is for Ball! ⚽ Say it with me: Buh!',
          spokenText: 'B is for ball. Say it with me: buh.',
          teachOption: QuizOption('B', emoji: '⚽'),
          hint: 'Say "ball" slowly. Listen for the very first sound: Buh!',
          options: [QuizOption('F', emoji: '🐟'), QuizOption('B', emoji: '⚽'), QuizOption('M', emoji: '🌙')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: 'Find the letter B',
          visual: AnswerVisual.text,
          hint: 'This letter is called "bee". Look at its shape and try again!',
          options: [QuizOption('G'), QuizOption('O'), QuizOption('B')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: 'Which picture starts with the letter B?',
          visual: AnswerVisual.picture,
          hint: 'Say each picture slowly. Which one starts with "Buh"?',
          options: [QuizOption('Ball', emoji: '⚽'), QuizOption('Ice cream', emoji: '🍦'), QuizOption('Queen', emoji: '👸')],
          answerIndex: 0,
        ),
      ],
    ),
    Activity(
      id: 'letters_c',
      sectionIndex: 0,
      title: 'C',
      emoji: '🐱',
      questions: [
        QuizQuestion(
          prompt: 'Tap the letter that matches 🐱',
          visual: AnswerVisual.letterPicture,
          teach: '"C" is for Cat! 🐱 Say it with me: Cuh!',
          spokenText: 'C is for cat. Say it with me: kuh.',
          teachOption: QuizOption('C', emoji: '🐱'),
          hint: 'Say "cat" slowly. Listen for the very first sound: Cuh!',
          options: [QuizOption('G', emoji: '🍇'), QuizOption('N', emoji: '👃'), QuizOption('C', emoji: '🐱')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: 'Find the letter C',
          visual: AnswerVisual.text,
          hint: 'This letter is called "see". Look at its shape and try again!',
          options: [QuizOption('C'), QuizOption('H'), QuizOption('P')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: 'Which picture starts with the letter C?',
          visual: AnswerVisual.picture,
          hint: 'Say each picture slowly. Which one starts with "Cuh"?',
          options: [QuizOption('Jeans', emoji: '👖'), QuizOption('Cat', emoji: '🐱'), QuizOption('Rainbow', emoji: '🌈')],
          answerIndex: 1,
        ),
      ],
    ),
    Activity(
      id: 'letters_d',
      sectionIndex: 0,
      title: 'D',
      emoji: '🐶',
      questions: [
        QuizQuestion(
          prompt: 'Tap the letter that matches 🐶',
          visual: AnswerVisual.letterPicture,
          teach: '"D" is for Dog! 🐶 Say it with me: Duh!',
          spokenText: 'D is for dog. Say it with me: duh.',
          teachOption: QuizOption('D', emoji: '🐶'),
          hint: 'Say "dog" slowly. Listen for the very first sound: Duh!',
          options: [QuizOption('D', emoji: '🐶'), QuizOption('H', emoji: '🎩'), QuizOption('O', emoji: '🍊')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: 'Find the letter D',
          visual: AnswerVisual.text,
          hint: 'This letter is called "dee". Look at its shape and try again!',
          options: [QuizOption('I'), QuizOption('D'), QuizOption('Q')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: 'Which picture starts with the letter D?',
          visual: AnswerVisual.picture,
          hint: 'Say each picture slowly. Which one starts with "Duh"?',
          options: [QuizOption('Key', emoji: '🔑'), QuizOption('Sun', emoji: '☀️'), QuizOption('Dog', emoji: '🐶')],
          answerIndex: 2,
        ),
      ],
    ),
    Activity(
      id: 'letters_e',
      sectionIndex: 0,
      title: 'E',
      emoji: '🐘',
      questions: [
        QuizQuestion(
          prompt: 'Tap the letter that matches 🐘',
          visual: AnswerVisual.letterPicture,
          teach: '"E" is for Elephant! 🐘 Say it with me: Eh!',
          spokenText: 'E is for elephant. Say it with me: eh.',
          teachOption: QuizOption('E', emoji: '🐘'),
          hint: 'Say "elephant" slowly. Listen for the very first sound: Eh!',
          options: [QuizOption('I', emoji: '🍦'), QuizOption('E', emoji: '🐘'), QuizOption('P', emoji: '🍕')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: 'Find the letter E',
          visual: AnswerVisual.text,
          hint: 'This letter is called "ee". Look at its shape and try again!',
          options: [QuizOption('J'), QuizOption('R'), QuizOption('E')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: 'Which picture starts with the letter E?',
          visual: AnswerVisual.picture,
          hint: 'Say each picture slowly. Which one starts with "Eh"?',
          options: [QuizOption('Elephant', emoji: '🐘'), QuizOption('Lion', emoji: '🦁'), QuizOption('Tree', emoji: '🌳')],
          answerIndex: 0,
        ),
      ],
    ),
    Activity(
      id: 'letters_f',
      sectionIndex: 0,
      title: 'F',
      emoji: '🐟',
      questions: [
        QuizQuestion(
          prompt: 'Tap the letter that matches 🐟',
          visual: AnswerVisual.letterPicture,
          teach: '"F" is for Fish! 🐟 Say it with me: Fff!',
          spokenText: 'F is for fish. Say it with me: fuh.',
          teachOption: QuizOption('F', emoji: '🐟'),
          hint: 'Say "fish" slowly. Listen for the very first sound: Fff!',
          options: [QuizOption('J', emoji: '👖'), QuizOption('Q', emoji: '👸'), QuizOption('F', emoji: '🐟')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: 'Find the letter F',
          visual: AnswerVisual.text,
          hint: 'This letter is called "eff". Look at its shape and try again!',
          options: [QuizOption('F'), QuizOption('K'), QuizOption('S')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: 'Which picture starts with the letter F?',
          visual: AnswerVisual.picture,
          hint: 'Say each picture slowly. Which one starts with "Fff"?',
          options: [QuizOption('Moon', emoji: '🌙'), QuizOption('Fish', emoji: '🐟'), QuizOption('Umbrella', emoji: '☂️')],
          answerIndex: 1,
        ),
      ],
    ),
    Activity(
      id: 'letters_g',
      sectionIndex: 0,
      title: 'G',
      emoji: '🍇',
      questions: [
        QuizQuestion(
          prompt: 'Tap the letter that matches 🍇',
          visual: AnswerVisual.letterPicture,
          teach: '"G" is for Grapes! 🍇 Say it with me: Guh!',
          spokenText: 'G is for grapes. Say it with me: guh.',
          teachOption: QuizOption('G', emoji: '🍇'),
          hint: 'Say "grapes" slowly. Listen for the very first sound: Guh!',
          options: [QuizOption('G', emoji: '🍇'), QuizOption('K', emoji: '🔑'), QuizOption('R', emoji: '🌈')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: 'Find the letter G',
          visual: AnswerVisual.text,
          hint: 'This letter is called "gee". Look at its shape and try again!',
          options: [QuizOption('L'), QuizOption('G'), QuizOption('T')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: 'Which picture starts with the letter G?',
          visual: AnswerVisual.picture,
          hint: 'Say each picture slowly. Which one starts with "Guh"?',
          options: [QuizOption('Nose', emoji: '👃'), QuizOption('Violin', emoji: '🎻'), QuizOption('Grapes', emoji: '🍇')],
          answerIndex: 2,
        ),
      ],
    ),
    Activity(
      id: 'letters_h',
      sectionIndex: 0,
      title: 'H',
      emoji: '🎩',
      questions: [
        QuizQuestion(
          prompt: 'Tap the letter that matches 🎩',
          visual: AnswerVisual.letterPicture,
          teach: '"H" is for Hat! 🎩 Say it with me: Huh!',
          spokenText: 'H is for hat. Say it with me: huh.',
          teachOption: QuizOption('H', emoji: '🎩'),
          hint: 'Say "hat" slowly. Listen for the very first sound: Huh!',
          options: [QuizOption('L', emoji: '🦁'), QuizOption('H', emoji: '🎩'), QuizOption('S', emoji: '☀️')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: 'Find the letter H',
          visual: AnswerVisual.text,
          hint: 'This letter is called "aitch". Look at its shape and try again!',
          options: [QuizOption('M'), QuizOption('U'), QuizOption('H')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: 'Which picture starts with the letter H?',
          visual: AnswerVisual.picture,
          hint: 'Say each picture slowly. Which one starts with "Huh"?',
          options: [QuizOption('Hat', emoji: '🎩'), QuizOption('Orange', emoji: '🍊'), QuizOption('Whale', emoji: '🐳')],
          answerIndex: 0,
        ),
      ],
    ),
    Activity(
      id: 'letters_i',
      sectionIndex: 0,
      title: 'I',
      emoji: '🍦',
      questions: [
        QuizQuestion(
          prompt: 'Tap the letter that matches 🍦',
          visual: AnswerVisual.letterPicture,
          teach: '"I" is for Ice cream! 🍦 Say it with me: Ih!',
          spokenText: 'I is for ice cream. Say it with me: ih.',
          teachOption: QuizOption('I', emoji: '🍦'),
          hint: 'Say "ice cream" slowly. Listen for the very first sound: Ih!',
          options: [QuizOption('M', emoji: '🌙'), QuizOption('T', emoji: '🌳'), QuizOption('I', emoji: '🍦')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: 'Find the letter I',
          visual: AnswerVisual.text,
          hint: 'This letter is called "eye". Look at its shape and try again!',
          options: [QuizOption('I'), QuizOption('N'), QuizOption('V')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: 'Which picture starts with the letter I?',
          visual: AnswerVisual.picture,
          hint: 'Say each picture slowly. Which one starts with "Ih"?',
          options: [QuizOption('Pizza', emoji: '🍕'), QuizOption('Ice cream', emoji: '🍦'), QuizOption('Yarn', emoji: '🧶')],
          answerIndex: 1,
        ),
      ],
    ),
    Activity(
      id: 'letters_j',
      sectionIndex: 1,
      title: 'J',
      emoji: '👖',
      questions: [
        QuizQuestion(
          prompt: 'Tap the letter that matches 👖',
          visual: AnswerVisual.letterPicture,
          teach: '"J" is for Jeans! 👖 Say it with me: Juh!',
          spokenText: 'J is for jeans. Say it with me: juh.',
          teachOption: QuizOption('J', emoji: '👖'),
          hint: 'Say "jeans" slowly. Listen for the very first sound: Juh!',
          options: [QuizOption('J', emoji: '👖'), QuizOption('N', emoji: '👃'), QuizOption('U', emoji: '☂️')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: 'Find the small letter j',
          visual: AnswerVisual.text,
          hint: 'Look for the small letter "j". It is called "jay".',
          options: [QuizOption('o'), QuizOption('j'), QuizOption('w')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: 'Which picture starts with the letter J?',
          visual: AnswerVisual.picture,
          hint: 'Say each picture slowly. Which one starts with "Juh"?',
          options: [QuizOption('Queen', emoji: '👸'), QuizOption('Yarn', emoji: '🧶'), QuizOption('Jeans', emoji: '👖')],
          answerIndex: 2,
        ),
      ],
    ),
    Activity(
      id: 'letters_k',
      sectionIndex: 1,
      title: 'K',
      emoji: '🔑',
      questions: [
        QuizQuestion(
          prompt: 'Tap the letter that matches 🔑',
          visual: AnswerVisual.letterPicture,
          teach: '"K" is for Key! 🔑 Say it with me: Kuh!',
          spokenText: 'K is for key. Say it with me: kuh.',
          teachOption: QuizOption('K', emoji: '🔑'),
          hint: 'Say "key" slowly. Listen for the very first sound: Kuh!',
          options: [QuizOption('O', emoji: '🍊'), QuizOption('K', emoji: '🔑'), QuizOption('V', emoji: '🎻')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: 'Find the small letter k',
          visual: AnswerVisual.text,
          hint: 'Look for the small letter "k". It is called "kay".',
          options: [QuizOption('p'), QuizOption('x'), QuizOption('k')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: 'Which picture starts with the letter K?',
          visual: AnswerVisual.picture,
          hint: 'Say each picture slowly. Which one starts with "Kuh"?',
          options: [QuizOption('Key', emoji: '🔑'), QuizOption('Rainbow', emoji: '🌈'), QuizOption('Zebra', emoji: '🦓')],
          answerIndex: 0,
        ),
      ],
    ),
    Activity(
      id: 'letters_l',
      sectionIndex: 1,
      title: 'L',
      emoji: '🦁',
      questions: [
        QuizQuestion(
          prompt: 'Tap the letter that matches 🦁',
          visual: AnswerVisual.letterPicture,
          teach: '"L" is for Lion! 🦁 Say it with me: Lll!',
          spokenText: 'L is for lion. Say it with me: luh.',
          teachOption: QuizOption('L', emoji: '🦁'),
          hint: 'Say "lion" slowly. Listen for the very first sound: Lll!',
          options: [QuizOption('P', emoji: '🍕'), QuizOption('W', emoji: '🐳'), QuizOption('L', emoji: '🦁')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: 'Find the small letter l',
          visual: AnswerVisual.text,
          hint: 'Look for the small letter "l". It is called "ell".',
          options: [QuizOption('l'), QuizOption('q'), QuizOption('y')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: 'Which picture starts with the letter L?',
          visual: AnswerVisual.picture,
          hint: 'Say each picture slowly. Which one starts with "Lll"?',
          options: [QuizOption('Sun', emoji: '☀️'), QuizOption('Lion', emoji: '🦁'), QuizOption('Apple', emoji: '🍎')],
          answerIndex: 1,
        ),
      ],
    ),
    Activity(
      id: 'letters_m',
      sectionIndex: 1,
      title: 'M',
      emoji: '🌙',
      questions: [
        QuizQuestion(
          prompt: 'Tap the letter that matches 🌙',
          visual: AnswerVisual.letterPicture,
          teach: '"M" is for Moon! 🌙 Say it with me: Mmm!',
          spokenText: 'M is for moon. Say it with me: muh.',
          teachOption: QuizOption('M', emoji: '🌙'),
          hint: 'Say "moon" slowly. Listen for the very first sound: Mmm!',
          options: [QuizOption('M', emoji: '🌙'), QuizOption('Q', emoji: '👸'), QuizOption('Y', emoji: '🧶')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: 'Find the small letter m',
          visual: AnswerVisual.text,
          hint: 'Look for the small letter "m". It is called "em".',
          options: [QuizOption('r'), QuizOption('m'), QuizOption('z')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: 'Which picture starts with the letter M?',
          visual: AnswerVisual.picture,
          hint: 'Say each picture slowly. Which one starts with "Mmm"?',
          options: [QuizOption('Tree', emoji: '🌳'), QuizOption('Ball', emoji: '⚽'), QuizOption('Moon', emoji: '🌙')],
          answerIndex: 2,
        ),
      ],
    ),
    Activity(
      id: 'letters_n',
      sectionIndex: 1,
      title: 'N',
      emoji: '👃',
      questions: [
        QuizQuestion(
          prompt: 'Tap the letter that matches 👃',
          visual: AnswerVisual.letterPicture,
          teach: '"N" is for Nose! 👃 Say it with me: Nnn!',
          spokenText: 'N is for nose. Say it with me: nuh.',
          teachOption: QuizOption('N', emoji: '👃'),
          hint: 'Say "nose" slowly. Listen for the very first sound: Nnn!',
          options: [QuizOption('R', emoji: '🌈'), QuizOption('N', emoji: '👃'), QuizOption('Y', emoji: '🧶')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: 'Find the small letter n',
          visual: AnswerVisual.text,
          hint: 'Look for the small letter "n". It is called "en".',
          options: [QuizOption('s'), QuizOption('a'), QuizOption('n')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: 'Which picture starts with the letter N?',
          visual: AnswerVisual.picture,
          hint: 'Say each picture slowly. Which one starts with "Nnn"?',
          options: [QuizOption('Nose', emoji: '👃'), QuizOption('Umbrella', emoji: '☂️'), QuizOption('Cat', emoji: '🐱')],
          answerIndex: 0,
        ),
      ],
    ),
    Activity(
      id: 'letters_o',
      sectionIndex: 1,
      title: 'O',
      emoji: '🍊',
      questions: [
        QuizQuestion(
          prompt: 'Tap the letter that matches 🍊',
          visual: AnswerVisual.letterPicture,
          teach: '"O" is for Orange! 🍊 Say it with me: Ah!',
          spokenText: 'O is for orange. Say it with me: ah.',
          teachOption: QuizOption('O', emoji: '🍊'),
          hint: 'Say "orange" slowly. Listen for the very first sound: Ah!',
          options: [QuizOption('S', emoji: '☀️'), QuizOption('Z', emoji: '🦓'), QuizOption('O', emoji: '🍊')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: 'Find the small letter o',
          visual: AnswerVisual.text,
          hint: 'Look for the small letter "o". It is called "oh".',
          options: [QuizOption('o'), QuizOption('t'), QuizOption('b')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: 'Which picture starts with the letter O?',
          visual: AnswerVisual.picture,
          hint: 'Say each picture slowly. Which one starts with "Ah"?',
          options: [QuizOption('Violin', emoji: '🎻'), QuizOption('Orange', emoji: '🍊'), QuizOption('Dog', emoji: '🐶')],
          answerIndex: 1,
        ),
      ],
    ),
    Activity(
      id: 'letters_p',
      sectionIndex: 1,
      title: 'P',
      emoji: '🍕',
      questions: [
        QuizQuestion(
          prompt: 'Tap the letter that matches 🍕',
          visual: AnswerVisual.letterPicture,
          teach: '"P" is for Pizza! 🍕 Say it with me: Puh!',
          spokenText: 'P is for pizza. Say it with me: puh.',
          teachOption: QuizOption('P', emoji: '🍕'),
          hint: 'Say "pizza" slowly. Listen for the very first sound: Puh!',
          options: [QuizOption('P', emoji: '🍕'), QuizOption('T', emoji: '🌳'), QuizOption('A', emoji: '🍎')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: 'Find the small letter p',
          visual: AnswerVisual.text,
          hint: 'Look for the small letter "p". It is called "pee".',
          options: [QuizOption('u'), QuizOption('p'), QuizOption('c')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: 'Which picture starts with the letter P?',
          visual: AnswerVisual.picture,
          hint: 'Say each picture slowly. Which one starts with "Puh"?',
          options: [QuizOption('Whale', emoji: '🐳'), QuizOption('Elephant', emoji: '🐘'), QuizOption('Pizza', emoji: '🍕')],
          answerIndex: 2,
        ),
      ],
    ),
    Activity(
      id: 'letters_q',
      sectionIndex: 1,
      title: 'Q',
      emoji: '👸',
      questions: [
        QuizQuestion(
          prompt: 'Tap the letter that matches 👸',
          visual: AnswerVisual.letterPicture,
          teach: '"Q" is for Queen! 👸 Say it with me: Kwuh!',
          spokenText: 'Q is for queen. Say it with me: kwuh.',
          teachOption: QuizOption('Q', emoji: '👸'),
          hint: 'Say "queen" slowly. Listen for the very first sound: Kwuh!',
          options: [QuizOption('U', emoji: '☂️'), QuizOption('Q', emoji: '👸'), QuizOption('B', emoji: '⚽')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: 'Find the small letter q',
          visual: AnswerVisual.text,
          hint: 'Look for the small letter "q". It is called "cue".',
          options: [QuizOption('v'), QuizOption('e'), QuizOption('q')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: 'Which picture starts with the letter Q?',
          visual: AnswerVisual.picture,
          hint: 'Say each picture slowly. Which one starts with "Kwuh"?',
          options: [QuizOption('Queen', emoji: '👸'), QuizOption('Yarn', emoji: '🧶'), QuizOption('Fish', emoji: '🐟')],
          answerIndex: 0,
        ),
      ],
    ),
    Activity(
      id: 'letters_r',
      sectionIndex: 1,
      title: 'R',
      emoji: '🌈',
      questions: [
        QuizQuestion(
          prompt: 'Tap the letter that matches 🌈',
          visual: AnswerVisual.letterPicture,
          teach: '"R" is for Rainbow! 🌈 Say it with me: Rrr!',
          spokenText: 'R is for rainbow. Say it with me: ruh.',
          teachOption: QuizOption('R', emoji: '🌈'),
          hint: 'Say "rainbow" slowly. Listen for the very first sound: Rrr!',
          options: [QuizOption('V', emoji: '🎻'), QuizOption('C', emoji: '🐱'), QuizOption('R', emoji: '🌈')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: 'Find the small letter r',
          visual: AnswerVisual.text,
          hint: 'Look for the small letter "r". It is called "are".',
          options: [QuizOption('r'), QuizOption('w'), QuizOption('e')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: 'Which picture starts with the letter R?',
          visual: AnswerVisual.picture,
          hint: 'Say each picture slowly. Which one starts with "Rrr"?',
          options: [QuizOption('Yarn', emoji: '🧶'), QuizOption('Rainbow', emoji: '🌈'), QuizOption('Grapes', emoji: '🍇')],
          answerIndex: 1,
        ),
      ],
    ),
    Activity(
      id: 'letters_s',
      sectionIndex: 2,
      title: 'S',
      emoji: '☀️',
      questions: [
        QuizQuestion(
          prompt: 'Tap the letter that matches ☀️',
          visual: AnswerVisual.letterPicture,
          teach: '"S" is for Sun! ☀️ Say it with me: Sss!',
          spokenText: 'S is for sun. Say it with me: suh.',
          teachOption: QuizOption('S', emoji: '☀️'),
          hint: 'Say "sun" slowly. Listen for the very first sound: Sss!',
          options: [QuizOption('S', emoji: '☀️'), QuizOption('W', emoji: '🐳'), QuizOption('D', emoji: '🐶')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: 'Tap the small letter for S',
          visual: AnswerVisual.text,
          hint: 'The big "S" has a small partner. Which small letter is it?',
          options: [QuizOption('x'), QuizOption('s'), QuizOption('f')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: 'Which picture starts with the letter S?',
          visual: AnswerVisual.picture,
          hint: 'Say each picture slowly. Which one starts with "Sss"?',
          options: [QuizOption('Zebra', emoji: '🦓'), QuizOption('Hat', emoji: '🎩'), QuizOption('Sun', emoji: '☀️')],
          answerIndex: 2,
        ),
      ],
    ),
    Activity(
      id: 'letters_t',
      sectionIndex: 2,
      title: 'T',
      emoji: '🌳',
      questions: [
        QuizQuestion(
          prompt: 'Tap the letter that matches 🌳',
          visual: AnswerVisual.letterPicture,
          teach: '"T" is for Tree! 🌳 Say it with me: Tuh!',
          spokenText: 'T is for tree. Say it with me: tuh.',
          teachOption: QuizOption('T', emoji: '🌳'),
          hint: 'Say "tree" slowly. Listen for the very first sound: Tuh!',
          options: [QuizOption('Y', emoji: '🧶'), QuizOption('T', emoji: '🌳'), QuizOption('E', emoji: '🐘')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: 'Tap the small letter for T',
          visual: AnswerVisual.text,
          hint: 'The big "T" has a small partner. Which small letter is it?',
          options: [QuizOption('y'), QuizOption('g'), QuizOption('t')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: 'Which picture starts with the letter T?',
          visual: AnswerVisual.picture,
          hint: 'Say each picture slowly. Which one starts with "Tuh"?',
          options: [QuizOption('Tree', emoji: '🌳'), QuizOption('Apple', emoji: '🍎'), QuizOption('Ice cream', emoji: '🍦')],
          answerIndex: 0,
        ),
      ],
    ),
    Activity(
      id: 'letters_u',
      sectionIndex: 2,
      title: 'U',
      emoji: '☂️',
      questions: [
        QuizQuestion(
          prompt: 'Tap the letter that matches ☂️',
          visual: AnswerVisual.letterPicture,
          teach: '"U" is for Umbrella! ☂️ Say it with me: Uh!',
          spokenText: 'U is for umbrella. Say it with me: uh.',
          teachOption: QuizOption('U', emoji: '☂️'),
          hint: 'Say "umbrella" slowly. Listen for the very first sound: Uh!',
          options: [QuizOption('Y', emoji: '🧶'), QuizOption('F', emoji: '🐟'), QuizOption('U', emoji: '☂️')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: 'Tap the small letter for U',
          visual: AnswerVisual.text,
          hint: 'The big "U" has a small partner. Which small letter is it?',
          options: [QuizOption('u'), QuizOption('z'), QuizOption('h')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: 'Which picture starts with the letter U?',
          visual: AnswerVisual.picture,
          hint: 'Say each picture slowly. Which one starts with "Uh"?',
          options: [QuizOption('Ball', emoji: '⚽'), QuizOption('Umbrella', emoji: '☂️'), QuizOption('Jeans', emoji: '👖')],
          answerIndex: 1,
        ),
      ],
    ),
    Activity(
      id: 'letters_v',
      sectionIndex: 2,
      title: 'V',
      emoji: '🎻',
      questions: [
        QuizQuestion(
          prompt: 'Tap the letter that matches 🎻',
          visual: AnswerVisual.letterPicture,
          teach: '"V" is for Violin! 🎻 Say it with me: Vvv!',
          spokenText: 'V is for violin. Say it with me: vuh.',
          teachOption: QuizOption('V', emoji: '🎻'),
          hint: 'Say "violin" slowly. Listen for the very first sound: Vvv!',
          options: [QuizOption('V', emoji: '🎻'), QuizOption('Z', emoji: '🦓'), QuizOption('G', emoji: '🍇')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: 'Tap the small letter for V',
          visual: AnswerVisual.text,
          hint: 'The big "V" has a small partner. Which small letter is it?',
          options: [QuizOption('a'), QuizOption('v'), QuizOption('i')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: 'Which picture starts with the letter V?',
          visual: AnswerVisual.picture,
          hint: 'Say each picture slowly. Which one starts with "Vvv"?',
          options: [QuizOption('Cat', emoji: '🐱'), QuizOption('Key', emoji: '🔑'), QuizOption('Violin', emoji: '🎻')],
          answerIndex: 2,
        ),
      ],
    ),
    Activity(
      id: 'letters_w',
      sectionIndex: 2,
      title: 'W',
      emoji: '🐳',
      questions: [
        QuizQuestion(
          prompt: 'Tap the letter that matches 🐳',
          visual: AnswerVisual.letterPicture,
          teach: '"W" is for Whale! 🐳 Say it with me: Wuh!',
          spokenText: 'W is for whale. Say it with me: wuh.',
          teachOption: QuizOption('W', emoji: '🐳'),
          hint: 'Say "whale" slowly. Listen for the very first sound: Wuh!',
          options: [QuizOption('A', emoji: '🍎'), QuizOption('W', emoji: '🐳'), QuizOption('H', emoji: '🎩')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: 'Tap the small letter for W',
          visual: AnswerVisual.text,
          hint: 'The big "W" has a small partner. Which small letter is it?',
          options: [QuizOption('b'), QuizOption('j'), QuizOption('w')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: 'Which picture starts with the letter W?',
          visual: AnswerVisual.picture,
          hint: 'Say each picture slowly. Which one starts with "Wuh"?',
          options: [QuizOption('Whale', emoji: '🐳'), QuizOption('Dog', emoji: '🐶'), QuizOption('Lion', emoji: '🦁')],
          answerIndex: 0,
        ),
      ],
    ),
    Activity(
      id: 'letters_x',
      sectionIndex: 2,
      title: 'X',
      emoji: '🦊',
      questions: [
        QuizQuestion(
          prompt: 'Which letter makes the sound at the end of fox?',
          visual: AnswerVisual.text,
          teach: '"X" says "ks" at the end of fox 🦊 and box 📦! Say it with me: ks!',
          spokenText: 'X says ks at the end of fox and box. Say it with me: ks.',
          teachOption: QuizOption('X'),
          hint: 'Say "fox" slowly: fo-ks. Listen to the very last sound!',
          options: [QuizOption('F'), QuizOption('O'), QuizOption('X')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: 'Tap the small letter for X',
          visual: AnswerVisual.text,
          hint: 'The big "X" has a small partner. Which small letter is it?',
          options: [QuizOption('x'), QuizOption('c'), QuizOption('k')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: 'Which picture ends with the letter X?',
          visual: AnswerVisual.picture,
          hint: 'Say each word slowly and listen to the very last sound.',
          options: [QuizOption('Apple', emoji: '🍎'), QuizOption('Fox', emoji: '🦊'), QuizOption('Cat', emoji: '🐱')],
          answerIndex: 1,
        ),
      ],
    ),
    Activity(
      id: 'letters_y',
      sectionIndex: 2,
      title: 'Y',
      emoji: '🧶',
      questions: [
        QuizQuestion(
          prompt: 'Tap the letter that matches 🧶',
          visual: AnswerVisual.letterPicture,
          teach: '"Y" is for Yarn! 🧶 Say it with me: Yuh!',
          spokenText: 'Y is for yarn. Say it with me: yuh.',
          teachOption: QuizOption('Y', emoji: '🧶'),
          hint: 'Say "yarn" slowly. Listen for the very first sound: Yuh!',
          options: [QuizOption('Y', emoji: '🧶'), QuizOption('C', emoji: '🐱'), QuizOption('J', emoji: '👖')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: 'Tap the small letter for Y',
          visual: AnswerVisual.text,
          hint: 'The big "Y" has a small partner. Which small letter is it?',
          options: [QuizOption('d'), QuizOption('y'), QuizOption('l')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: 'Which picture starts with the letter Y?',
          visual: AnswerVisual.picture,
          hint: 'Say each picture slowly. Which one starts with "Yuh"?',
          options: [QuizOption('Fish', emoji: '🐟'), QuizOption('Nose', emoji: '👃'), QuizOption('Yarn', emoji: '🧶')],
          answerIndex: 2,
        ),
      ],
    ),
    Activity(
      id: 'letters_z',
      sectionIndex: 2,
      title: 'Z',
      emoji: '🦓',
      questions: [
        QuizQuestion(
          prompt: 'Tap the letter that matches 🦓',
          visual: AnswerVisual.letterPicture,
          teach: '"Z" is for Zebra! 🦓 Say it with me: Zzz!',
          spokenText: 'Z is for zebra. Say it with me: zuh.',
          teachOption: QuizOption('Z', emoji: '🦓'),
          hint: 'Say "zebra" slowly. Listen for the very first sound: Zzz!',
          options: [QuizOption('D', emoji: '🐶'), QuizOption('Z', emoji: '🦓'), QuizOption('K', emoji: '🔑')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: 'Tap the small letter for Z',
          visual: AnswerVisual.text,
          hint: 'The big "Z" has a small partner. Which small letter is it?',
          options: [QuizOption('e'), QuizOption('m'), QuizOption('z')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: 'Which picture starts with the letter Z?',
          visual: AnswerVisual.picture,
          hint: 'Say each picture slowly. Which one starts with "Zzz"?',
          options: [QuizOption('Zebra', emoji: '🦓'), QuizOption('Grapes', emoji: '🍇'), QuizOption('Orange', emoji: '🍊')],
          answerIndex: 0,
        ),
      ],
    ),
    ],
  ),
  // ===== Math Town (20 activities) =====
  'numbers': WorldCatalog(
    olderStartSection: 2,
    youngMaxSection: 2,
    sections: [
      LearningSection(title: 'Counting to 5', emoji: '🔢'),
      LearningSection(title: 'Counting to 10', emoji: '🔟'),
      LearningSection(title: 'Adding and taking away to 5', emoji: '➕'),
      LearningSection(title: 'Adding and taking away to 10', emoji: '➖'),
    ],
    activities: [
    Activity(
      id: 'numbers_01',
      sectionIndex: 0,
      title: 'Count balloons',
      emoji: '🎈',
      questions: [
        QuizQuestion(
          prompt: '🎈\nHow many balloons?',
          visual: AnswerVisual.text,
          teach: 'Let\'s count balloons! 1! 🎈',
          teachOption: QuizOption('1'),
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('1'), QuizOption('2'), QuizOption('3')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: '🎈🎈\nHow many balloons?',
          visual: AnswerVisual.text,
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('3'), QuizOption('2'), QuizOption('1')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: '🎈🎈🎈\nHow many balloons?',
          visual: AnswerVisual.text,
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('4'), QuizOption('2'), QuizOption('3')],
          answerIndex: 2,
        ),
      ],
    ),
    Activity(
      id: 'numbers_02',
      sectionIndex: 0,
      title: 'Count apples',
      emoji: '🍎',
      questions: [
        QuizQuestion(
          prompt: '🍎🍎\nHow many apples?',
          visual: AnswerVisual.text,
          teach: 'Let\'s count apples! 1... 2! 🍎🍎',
          teachOption: QuizOption('2'),
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('3'), QuizOption('2'), QuizOption('1')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: '🍎🍎🍎🍎\nHow many apples?',
          visual: AnswerVisual.text,
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('5'), QuizOption('3'), QuizOption('4')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: '🍎🍎🍎\nHow many apples?',
          visual: AnswerVisual.text,
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('3'), QuizOption('4'), QuizOption('2')],
          answerIndex: 0,
        ),
      ],
    ),
    Activity(
      id: 'numbers_03',
      sectionIndex: 0,
      title: 'Count stars',
      emoji: '⭐',
      questions: [
        QuizQuestion(
          prompt: '⭐⭐⭐\nHow many stars?',
          visual: AnswerVisual.text,
          teach: 'Let\'s count stars! 1... 2... 3! ⭐⭐⭐',
          teachOption: QuizOption('3'),
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('4'), QuizOption('2'), QuizOption('3')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: '⭐⭐⭐⭐⭐\nHow many stars?',
          visual: AnswerVisual.text,
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('5'), QuizOption('4'), QuizOption('3')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: '⭐⭐⭐⭐\nHow many stars?',
          visual: AnswerVisual.text,
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('5'), QuizOption('4'), QuizOption('3')],
          answerIndex: 1,
        ),
      ],
    ),
    Activity(
      id: 'numbers_04',
      sectionIndex: 0,
      title: 'Count ducks',
      emoji: '🦆',
      questions: [
        QuizQuestion(
          prompt: '🦆🦆🦆🦆\nHow many ducks?',
          visual: AnswerVisual.text,
          teach: 'Let\'s count ducks! 1... 2... 3... 4! 🦆🦆🦆🦆',
          teachOption: QuizOption('4'),
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('4'), QuizOption('5'), QuizOption('3')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: '🦆🦆\nHow many ducks?',
          visual: AnswerVisual.text,
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('3'), QuizOption('2'), QuizOption('1')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: '🦆🦆🦆🦆🦆\nHow many ducks?',
          visual: AnswerVisual.text,
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('4'), QuizOption('3'), QuizOption('5')],
          answerIndex: 2,
        ),
      ],
    ),
    Activity(
      id: 'numbers_05',
      sectionIndex: 0,
      title: 'Count cars',
      emoji: '🚗',
      questions: [
        QuizQuestion(
          prompt: '🚗🚗🚗🚗🚗\nHow many cars?',
          visual: AnswerVisual.text,
          teach: 'Let\'s count cars! 1... 2... 3... 4... 5! 🚗🚗🚗🚗🚗',
          teachOption: QuizOption('5'),
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('4'), QuizOption('5'), QuizOption('3')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: '🚗🚗🚗\nHow many cars?',
          visual: AnswerVisual.text,
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('4'), QuizOption('2'), QuizOption('3')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: '🚗🚗🚗🚗\nHow many cars?',
          visual: AnswerVisual.text,
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('4'), QuizOption('5'), QuizOption('3')],
          answerIndex: 0,
        ),
      ],
    ),
    Activity(
      id: 'numbers_06',
      sectionIndex: 1,
      title: 'Count flowers',
      emoji: '🌸',
      questions: [
        QuizQuestion(
          prompt: '🌸🌸🌸🌸🌸\n🌸\nHow many flowers?',
          visual: AnswerVisual.text,
          teach: 'Let\'s count flowers! 1... 2... 3... 4... 5... 6! 🌸🌸🌸🌸🌸',
          teachOption: QuizOption('6'),
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('7'), QuizOption('5'), QuizOption('6')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: '🌸🌸🌸🌸🌸\n🌸🌸\nHow many flowers?',
          visual: AnswerVisual.text,
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('7'), QuizOption('8'), QuizOption('6')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: '🌸🌸🌸🌸🌸\n🌸🌸🌸\nHow many flowers?',
          visual: AnswerVisual.text,
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('9'), QuizOption('8'), QuizOption('7')],
          answerIndex: 1,
        ),
      ],
    ),
    Activity(
      id: 'numbers_07',
      sectionIndex: 1,
      title: 'Count fish',
      emoji: '🐟',
      questions: [
        QuizQuestion(
          prompt: '🐟🐟🐟🐟🐟\n🐟🐟\nHow many fish?',
          visual: AnswerVisual.text,
          teach: 'Let\'s count fish! 1... 2... 3... 4... 5... 6... 7! 🐟🐟🐟🐟🐟',
          teachOption: QuizOption('7'),
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('7'), QuizOption('8'), QuizOption('6')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: '🐟🐟🐟🐟🐟\n🐟🐟🐟🐟\nHow many fish?',
          visual: AnswerVisual.text,
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('10'), QuizOption('9'), QuizOption('8')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: '🐟🐟🐟🐟🐟\n🐟\nHow many fish?',
          visual: AnswerVisual.text,
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('7'), QuizOption('5'), QuizOption('6')],
          answerIndex: 2,
        ),
      ],
    ),
    Activity(
      id: 'numbers_08',
      sectionIndex: 1,
      title: 'Count cookies',
      emoji: '🍪',
      questions: [
        QuizQuestion(
          prompt: '🍪🍪🍪🍪🍪\n🍪🍪🍪\nHow many cookies?',
          visual: AnswerVisual.text,
          teach: 'Let\'s count cookies! 1... 2... 3... 4... 5... 6... 7... 8! 🍪🍪🍪🍪🍪',
          teachOption: QuizOption('8'),
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('9'), QuizOption('8'), QuizOption('7')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: '🍪🍪🍪🍪🍪\n🍪\nHow many cookies?',
          visual: AnswerVisual.text,
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('7'), QuizOption('5'), QuizOption('6')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: '🍪🍪🍪🍪🍪\n🍪🍪🍪🍪🍪\nHow many cookies?',
          visual: AnswerVisual.text,
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('10'), QuizOption('9'), QuizOption('8')],
          answerIndex: 0,
        ),
      ],
    ),
    Activity(
      id: 'numbers_09',
      sectionIndex: 1,
      title: 'Count ladybugs',
      emoji: '🐞',
      questions: [
        QuizQuestion(
          prompt: '🐞🐞🐞🐞🐞\n🐞🐞🐞🐞\nHow many ladybugs?',
          visual: AnswerVisual.text,
          teach: 'Let\'s count ladybugs! 1... 2... 3... 4... 5... 6... 7... 8... 9! 🐞🐞🐞🐞🐞',
          teachOption: QuizOption('9'),
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('10'), QuizOption('8'), QuizOption('9')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: '🐞🐞🐞🐞🐞\n🐞🐞🐞🐞🐞\nHow many ladybugs?',
          visual: AnswerVisual.text,
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('10'), QuizOption('9'), QuizOption('8')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: '🐞🐞🐞🐞🐞\n🐞🐞\nHow many ladybugs?',
          visual: AnswerVisual.text,
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('8'), QuizOption('7'), QuizOption('6')],
          answerIndex: 1,
        ),
      ],
    ),
    Activity(
      id: 'numbers_10',
      sectionIndex: 1,
      title: 'Count teddy bears',
      emoji: '🧸',
      questions: [
        QuizQuestion(
          prompt: '🧸🧸🧸🧸🧸\n🧸🧸🧸🧸🧸\nHow many teddy bears?',
          visual: AnswerVisual.text,
          teach: 'Let\'s count teddy bears! 1... 2... 3... 4... 5... 6... 7... 8... 9... 10! 🧸🧸🧸🧸🧸',
          teachOption: QuizOption('10'),
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('10'), QuizOption('9'), QuizOption('8')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: '🧸🧸🧸🧸🧸\n🧸🧸🧸\nHow many teddy bears?',
          visual: AnswerVisual.text,
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('9'), QuizOption('8'), QuizOption('7')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: '🧸🧸🧸🧸🧸\n🧸🧸🧸🧸\nHow many teddy bears?',
          visual: AnswerVisual.text,
          hint: 'Point to each one and count out loud: 1, 2, 3...',
          options: [QuizOption('10'), QuizOption('8'), QuizOption('9')],
          answerIndex: 2,
        ),
      ],
    ),
    Activity(
      id: 'numbers_11',
      sectionIndex: 2,
      title: 'Add 1',
      emoji: '➕',
      questions: [
        QuizQuestion(
          prompt: '🍎 + 🍎\n1 + 1 = ?',
          visual: AnswerVisual.text,
          teach: 'Adding means putting groups together. 1 apple and 1 more apple makes 2! ➕',
          teachOption: QuizOption('2'),
          hint: 'Put both groups together, then count them all.',
          options: [QuizOption('3'), QuizOption('2'), QuizOption('1')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: '🍎🍎 + 🍎\n2 + 1 = ?',
          visual: AnswerVisual.text,
          hint: 'Put both groups together, then count them all.',
          options: [QuizOption('4'), QuizOption('2'), QuizOption('3')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: '🍎🍎🍎 + 🍎\n3 + 1 = ?',
          visual: AnswerVisual.text,
          hint: 'Put both groups together, then count them all.',
          options: [QuizOption('4'), QuizOption('5'), QuizOption('3')],
          answerIndex: 0,
        ),
      ],
    ),
    Activity(
      id: 'numbers_12',
      sectionIndex: 2,
      title: 'Add 2',
      emoji: '➕',
      questions: [
        QuizQuestion(
          prompt: '🐥 + 🐥🐥\n1 + 2 = ?',
          visual: AnswerVisual.text,
          teach: 'Let\'s add 2 more! 1 chick and 2 more chicks make 3. ➕',
          teachOption: QuizOption('3'),
          hint: 'Put both groups together, then count them all.',
          options: [QuizOption('4'), QuizOption('2'), QuizOption('3')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: '🐥🐥 + 🐥🐥\n2 + 2 = ?',
          visual: AnswerVisual.text,
          hint: 'Put both groups together, then count them all.',
          options: [QuizOption('4'), QuizOption('5'), QuizOption('3')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: '🐥🐥🐥 + 🐥🐥\n3 + 2 = ?',
          visual: AnswerVisual.text,
          hint: 'Put both groups together, then count them all.',
          options: [QuizOption('6'), QuizOption('5'), QuizOption('4')],
          answerIndex: 1,
        ),
      ],
    ),
    Activity(
      id: 'numbers_13',
      sectionIndex: 2,
      title: 'Add to 5',
      emoji: '➕',
      questions: [
        QuizQuestion(
          prompt: '🌟🌟 + 🌟🌟🌟\n2 + 3 = ?',
          visual: AnswerVisual.text,
          teach: 'Let\'s add up to 5! 2 stars and 3 more stars make 5. ➕',
          teachOption: QuizOption('5'),
          hint: 'Put both groups together, then count them all.',
          options: [QuizOption('5'), QuizOption('6'), QuizOption('4')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: '🌟🌟🌟🌟 + 🌟\n4 + 1 = ?',
          visual: AnswerVisual.text,
          hint: 'Put both groups together, then count them all.',
          options: [QuizOption('6'), QuizOption('5'), QuizOption('4')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: '🌟 + 🌟🌟🌟\n1 + 3 = ?',
          visual: AnswerVisual.text,
          hint: 'Put both groups together, then count them all.',
          options: [QuizOption('5'), QuizOption('3'), QuizOption('4')],
          answerIndex: 2,
        ),
      ],
    ),
    Activity(
      id: 'numbers_14',
      sectionIndex: 2,
      title: 'Take away 1',
      emoji: '➖',
      questions: [
        QuizQuestion(
          prompt: '🍪🍪🍪\n3 − 1 = ?',
          visual: AnswerVisual.text,
          teach: 'Taking away means fewer! 3 cookies, take away 1, leaves 2. ➖',
          teachOption: QuizOption('2'),
          hint: 'Take some away, then count what is left.',
          options: [QuizOption('3'), QuizOption('2'), QuizOption('1')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: '🍪🍪🍪🍪\n4 − 1 = ?',
          visual: AnswerVisual.text,
          hint: 'Take some away, then count what is left.',
          options: [QuizOption('4'), QuizOption('2'), QuizOption('3')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: '🍪🍪🍪🍪🍪\n5 − 1 = ?',
          visual: AnswerVisual.text,
          hint: 'Take some away, then count what is left.',
          options: [QuizOption('4'), QuizOption('5'), QuizOption('3')],
          answerIndex: 0,
        ),
      ],
    ),
    Activity(
      id: 'numbers_15',
      sectionIndex: 2,
      title: 'Take away to 5',
      emoji: '➖',
      questions: [
        QuizQuestion(
          prompt: '🎈🎈🎈🎈🎈\n5 − 2 = ?',
          visual: AnswerVisual.text,
          teach: 'Let\'s take away more! 5 balloons, take away 2, leaves 3. ➖',
          teachOption: QuizOption('3'),
          hint: 'Take some away, then count what is left.',
          options: [QuizOption('4'), QuizOption('2'), QuizOption('3')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: '🎈🎈🎈🎈\n4 − 3 = ?',
          visual: AnswerVisual.text,
          hint: 'Take some away, then count what is left.',
          options: [QuizOption('1'), QuizOption('2'), QuizOption('3')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: '🎈🎈🎈🎈🎈\n5 − 3 = ?',
          visual: AnswerVisual.text,
          hint: 'Take some away, then count what is left.',
          options: [QuizOption('3'), QuizOption('2'), QuizOption('1')],
          answerIndex: 1,
        ),
      ],
    ),
    Activity(
      id: 'numbers_16',
      sectionIndex: 3,
      title: 'Doubles',
      emoji: '👯',
      questions: [
        QuizQuestion(
          prompt: '3 + 3 = ?',
          visual: AnswerVisual.text,
          teach: 'Doubles are the same number twice! 3 and 3 make 6.',
          teachOption: QuizOption('6'),
          hint: 'Doubles use the same number twice. Count on from the first one.',
          options: [QuizOption('6'), QuizOption('7'), QuizOption('5')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: '4 + 4 = ?',
          visual: AnswerVisual.text,
          hint: 'Doubles use the same number twice. Count on from the first one.',
          options: [QuizOption('9'), QuizOption('8'), QuizOption('7')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: '5 + 5 = ?',
          visual: AnswerVisual.text,
          hint: 'Doubles use the same number twice. Count on from the first one.',
          options: [QuizOption('9'), QuizOption('8'), QuizOption('10')],
          answerIndex: 2,
        ),
      ],
    ),
    Activity(
      id: 'numbers_17',
      sectionIndex: 3,
      title: 'Add to 10',
      emoji: '➕',
      questions: [
        QuizQuestion(
          prompt: '4 + 3 = ?',
          visual: AnswerVisual.text,
          teach: 'Let\'s add bigger numbers! 4 and 3 make 7.',
          teachOption: QuizOption('7'),
          hint: 'Count them all together, starting from the biggest number.',
          options: [QuizOption('8'), QuizOption('7'), QuizOption('6')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: '6 + 2 = ?',
          visual: AnswerVisual.text,
          hint: 'Count them all together, starting from the biggest number.',
          options: [QuizOption('9'), QuizOption('7'), QuizOption('8')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: '5 + 4 = ?',
          visual: AnswerVisual.text,
          hint: 'Count them all together, starting from the biggest number.',
          options: [QuizOption('9'), QuizOption('10'), QuizOption('8')],
          answerIndex: 0,
        ),
      ],
    ),
    Activity(
      id: 'numbers_18',
      sectionIndex: 3,
      title: 'Take away to 10',
      emoji: '➖',
      questions: [
        QuizQuestion(
          prompt: '8 − 3 = ?',
          visual: AnswerVisual.text,
          teach: 'Let\'s take away from bigger numbers! 8 take away 3 leaves 5.',
          teachOption: QuizOption('5'),
          hint: 'Start at the big number and count backwards.',
          options: [QuizOption('6'), QuizOption('4'), QuizOption('5')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: '9 − 5 = ?',
          visual: AnswerVisual.text,
          hint: 'Start at the big number and count backwards.',
          options: [QuizOption('4'), QuizOption('5'), QuizOption('3')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: '10 − 4 = ?',
          visual: AnswerVisual.text,
          hint: 'Start at the big number and count backwards.',
          options: [QuizOption('7'), QuizOption('6'), QuizOption('5')],
          answerIndex: 1,
        ),
      ],
    ),
    Activity(
      id: 'numbers_19',
      sectionIndex: 3,
      title: 'Make 10',
      emoji: '🔟',
      minAge: 5,
      questions: [
        QuizQuestion(
          prompt: '7 + ? = 10',
          visual: AnswerVisual.text,
          teach: 'Let\'s make 10! 7 and 3 more make 10.',
          teachOption: QuizOption('3'),
          hint: 'How many more to get to 10? Count up from 7.',
          options: [QuizOption('3'), QuizOption('4'), QuizOption('2')],
          answerIndex: 0,
        ),
        QuizQuestion(
          prompt: '6 + ? = 10',
          visual: AnswerVisual.text,
          hint: 'How many more to get to 10? Count up from 6.',
          options: [QuizOption('5'), QuizOption('4'), QuizOption('3')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: '8 + ? = 10',
          visual: AnswerVisual.text,
          hint: 'How many more to get to 10? Count up from 8.',
          options: [QuizOption('3'), QuizOption('1'), QuizOption('2')],
          answerIndex: 2,
        ),
      ],
    ),
    Activity(
      id: 'numbers_20',
      sectionIndex: 3,
      title: 'Teen numbers',
      emoji: '🔢',
      questions: [
        QuizQuestion(
          prompt: '10 + 3 = ?',
          visual: AnswerVisual.text,
          teach: 'Teen numbers start with 10! 10 and 3 more make 13.',
          teachOption: QuizOption('13'),
          hint: '10 and 3 more makes 13.',
          options: [QuizOption('14'), QuizOption('13'), QuizOption('12')],
          answerIndex: 1,
        ),
        QuizQuestion(
          prompt: '10 + 5 = ?',
          visual: AnswerVisual.text,
          hint: '10 and 5 more makes 15.',
          options: [QuizOption('16'), QuizOption('14'), QuizOption('15')],
          answerIndex: 2,
        ),
        QuizQuestion(
          prompt: '10 + 8 = ?',
          visual: AnswerVisual.text,
          hint: '10 and 8 more makes 18.',
          options: [QuizOption('18'), QuizOption('19'), QuizOption('17')],
          answerIndex: 0,
        ),
      ],
    ),
    ],
  ),
  // ===== Shape Safari (12 activities) =====
  'shapes': WorldCatalog(
    olderStartSection: 1,
    youngMaxSection: 1,
    sections: [
      LearningSection(title: 'Meet the shapes', emoji: '🔺'),
      LearningSection(title: 'Shapes around us', emoji: '🌍'),
      LearningSection(title: 'Shape challenges', emoji: '🧩'),
    ],
    activities: [
      Activity(
        id: 'shapes_01',
        sectionIndex: 0,
        title: 'Circle',
        emoji: '⚪',
        questions: [
          QuizQuestion(
            prompt: 'Circle',
            playType: PlayType.lookListen,
            cue: ShapeCue(ShapeKind.circle, color: _blue),
            visual: AnswerVisual.shape,
            teach: 'A circle is round.',
            spokenText: 'This is a circle. It is round like a wheel.',
            teachOption: QuizOption('circle', color: _blue),
            hint: 'Look for the round one.',
            options: [
              QuizOption('circle', color: _blue),
              QuizOption('square', color: _orange),
              QuizOption('triangle', color: _green)
            ],
            answerIndex: 0,
          ),
          QuizQuestion(
            prompt: 'Match shape',
            playType: PlayType.findSame,
            cue: ShapeCue(
              ShapeKind.circle,
              style: CueShapeStyle.silhouette,
            ),
            visual: AnswerVisual.shape,
            spokenText: 'Find the shape that matches this circle.',
            hint: 'Match the dark circle.',
            options: [
              QuizOption('square', color: _orange),
              QuizOption('circle', color: _blue),
              QuizOption('triangle', color: _green)
            ],
            answerIndex: 1,
          ),
          QuizQuestion(
            prompt: 'Which looks round?',
            playType: PlayType.realWorld,
            cue: ShapeCue(ShapeKind.circle, color: _blue),
            visual: AnswerVisual.picture,
            spokenText: 'Which object is round like this circle?',
            hint: 'Look for the round object.',
            options: [
              QuizOption('Gift', emoji: '🎁'),
              QuizOption('Tent', emoji: '⛺'),
              QuizOption('Ball', emoji: '⚽')
            ],
            answerIndex: 2,
          ),
        ],
      ),
      Activity(
        id: 'shapes_02',
        sectionIndex: 0,
        title: 'Square',
        emoji: '⬛',
        questions: [
          QuizQuestion(
            prompt: 'Square',
            playType: PlayType.lookListen,
            cue: ShapeCue(ShapeKind.square, color: _orange),
            visual: AnswerVisual.shape,
            teach: 'A square has four equal sides.',
            spokenText: 'This is a square. It has four equal sides.',
            teachOption: QuizOption('square', color: _orange),
            hint: 'Find four equal sides.',
            options: [
              QuizOption('triangle', color: _green),
              QuizOption('square', color: _orange),
              QuizOption('circle', color: _blue)
            ],
            answerIndex: 1,
          ),
          QuizQuestion(
            prompt: 'Match shape',
            playType: PlayType.findSame,
            cue: ShapeCue(
              ShapeKind.square,
              style: CueShapeStyle.silhouette,
            ),
            visual: AnswerVisual.shape,
            spokenText: 'Find the shape that matches this square.',
            hint: 'Match the dark square.',
            options: [
              QuizOption('circle', color: _blue),
              QuizOption('triangle', color: _green),
              QuizOption('square', color: _orange)
            ],
            answerIndex: 2,
          ),
          QuizQuestion(
            prompt: 'Which looks square?',
            playType: PlayType.realWorld,
            cue: ShapeCue(ShapeKind.square, color: _orange),
            visual: AnswerVisual.picture,
            spokenText: 'Which object looks like this square?',
            hint: 'Look for four corners.',
            options: [
              QuizOption('Gift', emoji: '🎁'),
              QuizOption('Cookie', emoji: '🍪'),
              QuizOption('Pizza slice', emoji: '🍕')
            ],
            answerIndex: 0,
          ),
        ],
      ),
      Activity(
        id: 'shapes_03',
        sectionIndex: 0,
        title: 'Triangle',
        emoji: '🔺',
        questions: [
          QuizQuestion(
            prompt: 'Triangle',
            playType: PlayType.lookListen,
            cue: ShapeCue(ShapeKind.triangle, color: _green),
            visual: AnswerVisual.shape,
            teach: 'A triangle has three sides.',
            spokenText: 'This is a triangle. It has three sides.',
            teachOption: QuizOption('triangle', color: _green),
            hint: 'Look for three pointy corners.',
            options: [
              QuizOption('star', color: _yellow),
              QuizOption('circle', color: _blue),
              QuizOption('triangle', color: _green)
            ],
            answerIndex: 2,
          ),
          QuizQuestion(
            prompt: 'Match shape',
            playType: PlayType.findSame,
            cue: ShapeCue(
              ShapeKind.triangle,
              style: CueShapeStyle.silhouette,
            ),
            visual: AnswerVisual.shape,
            spokenText: 'Find the shape that matches this triangle.',
            hint: 'Match the dark triangle.',
            options: [
              QuizOption('triangle', color: _green),
              QuizOption('square', color: _orange),
              QuizOption('circle', color: _blue)
            ],
            answerIndex: 0,
          ),
          QuizQuestion(
            prompt: 'Which looks pointy?',
            playType: PlayType.realWorld,
            cue: ShapeCue(ShapeKind.triangle, color: _green),
            visual: AnswerVisual.picture,
            spokenText: 'Which object is pointy like this shape?',
            hint: 'Find the pointy object.',
            options: [
              QuizOption('Cookie', emoji: '🍪'),
              QuizOption('Pizza slice', emoji: '🍕'),
              QuizOption('Gift', emoji: '🎁')
            ],
            answerIndex: 1,
          ),
        ],
      ),
      Activity(
        id: 'shapes_04',
        sectionIndex: 0,
        title: 'Star',
        emoji: '⭐',
        questions: [
          QuizQuestion(
            prompt: 'Star',
            playType: PlayType.lookListen,
            cue: ShapeCue(ShapeKind.star, color: _yellow),
            visual: AnswerVisual.shape,
            teach: 'Stars twinkle in the sky.',
            spokenText: 'This is a star. It twinkles in the sky.',
            teachOption: QuizOption('star', color: _yellow),
            hint: 'Look for the pointy tips.',
            options: [
              QuizOption('star', color: _yellow),
              QuizOption('circle', color: _blue),
              QuizOption('square', color: _orange)
            ],
            answerIndex: 0,
          ),
          QuizQuestion(
            prompt: 'Match shape',
            playType: PlayType.findSame,
            cue: ShapeCue(
              ShapeKind.star,
              color: _shapeRed,
              style: CueShapeStyle.silhouette,
            ),
            visual: AnswerVisual.shape,
            spokenText: 'Find the shape that matches this star.',
            hint: 'Match the dark star.',
            options: [
              QuizOption('triangle', color: _green),
              QuizOption('star', color: _yellow),
              QuizOption('circle', color: _blue)
            ],
            answerIndex: 1,
          ),
          QuizQuestion(
            prompt: 'Twinkles?',
            playType: PlayType.realWorld,
            cue: EmojiCue('✨'),
            visual: AnswerVisual.picture,
            spokenText: 'Which one twinkles in the night sky?',
            hint: 'Find what twinkles at night.',
            options: [
              QuizOption('Moon', emoji: '🌕'),
              QuizOption('Cloud', emoji: '☁️'),
              QuizOption('Star', emoji: '⭐')
            ],
            answerIndex: 2,
          ),
        ],
      ),
      Activity(
        id: 'shapes_05',
        sectionIndex: 1,
        title: 'Round things',
        emoji: '🌕',
        questions: [
          QuizQuestion(
            prompt: 'Which is round?',
            playType: PlayType.lookListen,
            cue: ShapeCue(ShapeKind.circle, color: _blue),
            visual: AnswerVisual.picture,
            teach: 'A ball is round.',
            spokenText: 'This ball is round like a circle.',
            hint: 'Find the round object.',
            options: [
              QuizOption('Gift', emoji: '🎁'),
              QuizOption('Ball', emoji: '⚽'),
              QuizOption('Pizza slice', emoji: '🍕')
            ],
            answerIndex: 1,
          ),
          QuizQuestion(
            prompt: 'Find round!',
            playType: PlayType.concept,
            cue: ShapeCue(
              ShapeKind.circle,
              style: CueShapeStyle.silhouette,
            ),
            visual: AnswerVisual.picture,
            spokenText: 'Which object is round like this circle?',
            hint: 'Find the round object.',
            options: [
              QuizOption('Tent', emoji: '⛺'),
              QuizOption('Box', emoji: '📦'),
              QuizOption('Cookie', emoji: '🍪')
            ],
            answerIndex: 2,
          ),
          QuizQuestion(
            prompt: 'Round one?',
            playType: PlayType.realWorld,
            cue: ShapeCue(
              ShapeKind.circle,
              style: CueShapeStyle.dashed,
            ),
            visual: AnswerVisual.picture,
            spokenText: 'Which object is round like this outline?',
            hint: 'Choose the round object.',
            options: [
              QuizOption('Gift', emoji: '🎁'),
              QuizOption('Tent', emoji: '⛺'),
              QuizOption('Orange', emoji: '🍊')
            ],
            answerIndex: 2,
          ),
        ],
      ),
      Activity(
        id: 'shapes_06',
        sectionIndex: 1,
        title: 'Square things',
        emoji: '📦',
        questions: [
          QuizQuestion(
            prompt: 'Which is square?',
            playType: PlayType.lookListen,
            cue: ShapeCue(ShapeKind.square, color: _orange),
            visual: AnswerVisual.picture,
            teach: 'Boxes have square sides.',
            spokenText: 'Which object has a square shape?',
            hint: 'Look for four square sides.',
            options: [
              QuizOption('Ball', emoji: '⚽'),
              QuizOption('Pizza slice', emoji: '🍕'),
              QuizOption('Gift', emoji: '🎁')
            ],
            answerIndex: 2,
          ),
          QuizQuestion(
            prompt: 'Looks like this?',
            playType: PlayType.findSame,
            cue: ShapeCue(
              ShapeKind.square,
              style: CueShapeStyle.silhouette,
            ),
            visual: AnswerVisual.picture,
            spokenText: 'Which object matches this square shape?',
            hint: 'Find the matching object.',
            options: [
              QuizOption('Box', emoji: '📦'),
              QuizOption('Orange', emoji: '🍊'),
              QuizOption('Moon', emoji: '🌕')
            ],
            answerIndex: 0,
          ),
          QuizQuestion(
            prompt: 'Frame shape?',
            playType: PlayType.sayName,
            cue: EmojiCue('🖼️'),
            visual: AnswerVisual.shape,
            spokenText: 'Which shape looks like this picture frame?',
            hint: 'Choose the matching shape.',
            options: [
              QuizOption('circle', color: _blue),
              QuizOption('square', color: _orange),
              QuizOption('triangle', color: _green)
            ],
            answerIndex: 1,
          ),
        ],
      ),
      Activity(
        id: 'shapes_07',
        sectionIndex: 1,
        title: 'Pointy things',
        emoji: '⛺',
        questions: [
          QuizQuestion(
            prompt: 'Which is pointy?',
            playType: PlayType.lookListen,
            cue: ShapeCue(ShapeKind.triangle, color: _green),
            visual: AnswerVisual.picture,
            teach: 'Some things are pointy.',
            spokenText: 'Which object has a pointy shape?',
            hint: 'Find the pointy object.',
            options: [
              QuizOption('Pizza slice', emoji: '🍕'),
              QuizOption('Ball', emoji: '⚽'),
              QuizOption('Cookie', emoji: '🍪')
            ],
            answerIndex: 0,
          ),
          QuizQuestion(
            prompt: 'Looks like this?',
            playType: PlayType.findSame,
            cue: ShapeCue(
              ShapeKind.triangle,
              style: CueShapeStyle.silhouette,
            ),
            visual: AnswerVisual.picture,
            spokenText: 'Which object matches this pointy shape?',
            hint: 'Find the matching object.',
            options: [
              QuizOption('Orange', emoji: '🍊'),
              QuizOption('Tent', emoji: '⛺'),
              QuizOption('Moon', emoji: '🌕')
            ],
            answerIndex: 1,
          ),
          QuizQuestion(
            prompt: 'Which shape fits?',
            playType: PlayType.sayName,
            cue: EmojiCue('⛰️'),
            visual: AnswerVisual.shape,
            spokenText: 'Which shape has this pointy outline?',
            hint: 'Choose the matching shape.',
            options: [
              QuizOption('circle', color: _blue),
              QuizOption('square', color: _orange),
              QuizOption('triangle', color: _green)
            ],
            answerIndex: 2,
          ),
        ],
      ),
      Activity(
        id: 'shapes_08',
        sectionIndex: 1,
        title: 'Twinkly things',
        emoji: '🌟',
        questions: [
          QuizQuestion(
            prompt: 'Find the star',
            playType: PlayType.lookListen,
            cue: ShapeCue(ShapeKind.star, color: _yellow),
            visual: AnswerVisual.shape,
            teach: 'Stars twinkle at night.',
            spokenText: 'A star has pointy tips all around.',
            teachOption: QuizOption('star', color: _yellow),
            hint: 'Look for the pointy tips.',
            options: [
              QuizOption('circle', color: _blue),
              QuizOption('star', color: _yellow),
              QuizOption('square', color: _orange)
            ],
            answerIndex: 1,
          ),
          QuizQuestion(
            prompt: 'Match star',
            playType: PlayType.findSame,
            cue: ShapeCue(
              ShapeKind.star,
              style: CueShapeStyle.silhouette,
            ),
            visual: AnswerVisual.picture,
            spokenText: 'Find the picture that matches this star silhouette.',
            hint: 'Find the matching picture.',
            options: [
              QuizOption('Cookie', emoji: '🍪'),
              QuizOption('Box', emoji: '📦'),
              QuizOption('Glowing star', emoji: '🌟')
            ],
            answerIndex: 2,
          ),
          QuizQuestion(
            prompt: 'Night sky?',
            playType: PlayType.realWorld,
            cue: NightSkyCue(),
            visual: AnswerVisual.picture,
            spokenText: 'Which picture belongs in this night sky?',
            hint: 'Choose a night-sky picture.',
            options: [
              QuizOption('Star', emoji: '⭐'),
              QuizOption('Pizza slice', emoji: '🍕'),
              QuizOption('Gift', emoji: '🎁')
            ],
            answerIndex: 0,
          ),
        ],
      ),
      Activity(
        id: 'shapes_09',
        sectionIndex: 2,
        title: 'Count the sides',
        emoji: '✋',
        minAge: 5,
        questions: [
          QuizQuestion(
            prompt: 'How many sides?',
            playType: PlayType.lookListen,
            cue: ShapeCue(
              ShapeKind.triangle,
              color: _green,
              numberSides: true,
            ),
            visual: AnswerVisual.text,
            teach: 'A triangle has three sides.',
            spokenText: 'How many sides does a triangle have?',
            teachOption: QuizOption('3'),
            hint: 'Count each marked side.',
            options: [QuizOption('2'), QuizOption('4'), QuizOption('3')],
            answerIndex: 2,
          ),
          QuizQuestion(
            prompt: 'How many sides?',
            playType: PlayType.concept,
            cue: ShapeCue(
              ShapeKind.square,
              colorSides: true,
            ),
            visual: AnswerVisual.text,
            spokenText: 'How many sides does a square have?',
            hint: 'Count each colored side.',
            options: [QuizOption('4'), QuizOption('3'), QuizOption('5')],
            answerIndex: 0,
          ),
          QuizQuestion(
            prompt: 'How many corners?',
            playType: PlayType.sayName,
            cue: ShapeCue(ShapeKind.square, markCorners: true),
            visual: AnswerVisual.text,
            spokenText: 'How many corners does a square have?',
            hint: 'Count each marked corner.',
            options: [QuizOption('3'), QuizOption('5'), QuizOption('4')],
            answerIndex: 2,
          ),
        ],
      ),
      Activity(
        id: 'shapes_10',
        sectionIndex: 2,
        title: 'Odd one out',
        emoji: '🧐',
        minAge: 5,
        questions: [
          QuizQuestion(
            prompt: 'Odd one out?',
            playType: PlayType.concept,
            cue: ShapeRowCue(
              shapes: [ShapeKind.triangle, ShapeKind.circle, ShapeKind.circle],
              differentIndex: 0,
              color: _blue,
            ),
            visual: AnswerVisual.shape,
            teach: 'Find the shape that is different.',
            spokenText: 'Which shape is different in this row?',
            hint: 'Two match. One is different.',
            options: [
              QuizOption('triangle', color: _green),
              QuizOption('circle', color: _blue),
              QuizOption('square', color: _orange)
            ],
            answerIndex: 0,
          ),
          QuizQuestion(
            prompt: 'Odd one out?',
            playType: PlayType.concept,
            cue: ShapeRowCue(
              shapes: [ShapeKind.square, ShapeKind.triangle, ShapeKind.square],
              differentIndex: 1,
              color: _blue,
            ),
            visual: AnswerVisual.shape,
            spokenText: 'Which shape is different in this row?',
            hint: 'Two match. One is different.',
            options: [
              QuizOption('square', color: _orange),
              QuizOption('triangle', color: _green),
              QuizOption('circle', color: _blue)
            ],
            answerIndex: 1,
          ),
          QuizQuestion(
            prompt: 'Odd one out?',
            playType: PlayType.concept,
            cue: ShapeRowCue(
              shapes: [
                ShapeKind.triangle,
                ShapeKind.triangle,
                ShapeKind.circle
              ],
              differentIndex: 2,
              color: _blue,
            ),
            visual: AnswerVisual.shape,
            spokenText: 'Which shape is different in this row?',
            hint: 'Two match. One is different.',
            options: [
              QuizOption('triangle', color: _green),
              QuizOption('square', color: _orange),
              QuizOption('circle', color: _blue)
            ],
            answerIndex: 2,
          ),
        ],
      ),
      Activity(
        id: 'shapes_11',
        sectionIndex: 2,
        title: 'Same shape',
        emoji: '👀',
        questions: [
          QuizQuestion(
            prompt: 'Match triangle',
            playType: PlayType.findSame,
            cue: ShapeCue(ShapeKind.triangle, color: _shapeRed),
            visual: AnswerVisual.shape,
            teach: 'Let\'s match shapes.',
            spokenText: 'Find the triangle that matches the target.',
            hint: 'Look at the shape at the top. Which one looks just like it?',
            options: [
              QuizOption('circle', color: _blue),
              QuizOption('triangle', color: _green),
              QuizOption('square', color: _orange)
            ],
            answerIndex: 1,
          ),
          QuizQuestion(
            prompt: 'Match circle',
            playType: PlayType.findSame,
            cue: ShapeCue(ShapeKind.circle, color: _shapeRed),
            visual: AnswerVisual.shape,
            spokenText: 'Find the circle that matches the target.',
            hint: 'Look at the shape at the top. Which one looks just like it?',
            options: [
              QuizOption('square', color: _orange),
              QuizOption('triangle', color: _green),
              QuizOption('circle', color: _blue)
            ],
            answerIndex: 2,
          ),
          QuizQuestion(
            prompt: 'Match square',
            playType: PlayType.findSame,
            cue: ShapeCue(ShapeKind.square, color: _shapeRed),
            visual: AnswerVisual.shape,
            spokenText: 'Find the square that matches the target.',
            hint: 'Look at the shape at the top. Which one looks just like it?',
            options: [
              QuizOption('square', color: _orange),
              QuizOption('circle', color: _blue),
              QuizOption('triangle', color: _green)
            ],
            answerIndex: 0,
          ),
        ],
      ),
      Activity(
        id: 'shapes_12',
        sectionIndex: 2,
        title: 'Shape mix-up',
        emoji: '🧩',
        minAge: 5,
        questions: [
          QuizQuestion(
            prompt: '4 corners?',
            playType: PlayType.lookListen,
            cue: CornerMarksCue(4),
            visual: AnswerVisual.shape,
            teach: 'Let\'s explore shapes.',
            spokenText: 'Which shape has four corners?',
            hint: 'Count the four corners.',
            options: [
              QuizOption('circle', color: _blue),
              QuizOption('triangle', color: _green),
              QuizOption('square', color: _orange)
            ],
            answerIndex: 2,
          ),
          QuizQuestion(
            prompt: 'Rolls best?',
            playType: PlayType.concept,
            cue: RollingSlopeCue(),
            visual: AnswerVisual.shape,
            spokenText: 'Which shape rolls smoothly down a slope?',
            hint: 'Look for the smooth shape.',
            options: [
              QuizOption('circle', color: _blue),
              QuizOption('square', color: _orange),
              QuizOption('triangle', color: _green)
            ],
            answerIndex: 0,
          ),
          QuizQuestion(
            prompt: '3 sides?',
            playType: PlayType.sayName,
            cue: EdgeMarksCue(3),
            visual: AnswerVisual.shape,
            spokenText: 'Which shape has three sides?',
            hint: 'Count the three edge marks.',
            options: [
              QuizOption('square', color: _orange),
              QuizOption('triangle', color: _green),
              QuizOption('circle', color: _blue)
            ],
            answerIndex: 1,
          ),
        ],
      ),
    ],
  ),
  // ===== Color Garden (12 activities) =====
  'colors': WorldCatalog(
    olderStartSection: 1,
    youngMaxSection: 1,
    sections: [
      LearningSection(title: 'Meet the colors', emoji: '🎨'),
      LearningSection(title: 'More colors', emoji: '🌈'),
      LearningSection(title: 'Mix and match', emoji: '🖌️'),
    ],
    activities: [
      Activity(
        id: 'colors_01',
        sectionIndex: 0,
        title: 'Red',
        emoji: '🔴',
        questions: [
          QuizQuestion(
            prompt: 'Tap the color',
            playType: PlayType.lookListen,
            cue: ColorWordCue('Red'),
            visual: AnswerVisual.colorSwatch,
            teach: 'This is red! 🔴 Say it with me.',
            spokenText: 'This is red. Say it with me: red! Now tap the color red.',
            teachOption: QuizOption('Red', color: _red),
            hint: 'Look for red.',
            options: [QuizOption('Red', color: _red), QuizOption('Blue', color: _blue), QuizOption('Orange', color: _orange)],
            answerIndex: 0,
          ),
          QuizQuestion(
            prompt: 'Which is red?',
            playType: PlayType.realWorld,
            cue: ColorSwatchCue('Red', _red),
            visual: AnswerVisual.picture,
            spokenText: 'Which picture is red?',
            hint: 'Find something red.',
            options: [QuizOption('Wave', emoji: '🌊'), QuizOption('Apple', emoji: '🍎'), QuizOption('Carrot', emoji: '🥕')],
            answerIndex: 1,
          ),
          QuizQuestion(
            prompt: 'What color?',
            playType: PlayType.realWorld,
            cue: EmojiCue('🍓'),
            visual: AnswerVisual.colorSwatch,
            spokenText: 'What color is a strawberry?',
            hint: 'Picture a strawberry.',
            options: [QuizOption('Yellow', color: _yellow), QuizOption('Pink', color: _pink), QuizOption('Red', color: _red)],
            answerIndex: 2,
          ),
        ],
      ),
      Activity(
        id: 'colors_02',
        sectionIndex: 0,
        title: 'Blue',
        emoji: '🔵',
        questions: [
          QuizQuestion(
            prompt: 'Tap the color',
            playType: PlayType.lookListen,
            cue: ColorWordCue('Blue'),
            visual: AnswerVisual.colorSwatch,
            teach: 'This is blue! 🔵 Say it with me.',
            spokenText: 'This is blue. Say it with me: blue! Now tap the color blue.',
            teachOption: QuizOption('Blue', color: _blue),
            hint: 'Look for blue.',
            options: [QuizOption('Yellow', color: _yellow), QuizOption('Blue', color: _blue), QuizOption('Purple', color: _purple)],
            answerIndex: 1,
          ),
          QuizQuestion(
            prompt: 'Which is blue?',
            playType: PlayType.realWorld,
            cue: ColorSwatchCue('Blue', _blue),
            visual: AnswerVisual.picture,
            spokenText: 'Which picture is blue?',
            hint: 'Find something blue.',
            options: [QuizOption('Banana', emoji: '🍌'), QuizOption('Apple', emoji: '🍎'), QuizOption('Water drop', emoji: '💧')],
            answerIndex: 2,
          ),
          QuizQuestion(
            prompt: 'What color?',
            playType: PlayType.realWorld,
            cue: EmojiCue('🐳'),
            visual: AnswerVisual.colorSwatch,
            spokenText: 'What color is a whale?',
            hint: 'Picture a whale.',
            options: [QuizOption('Blue', color: _blue), QuizOption('Green', color: _green), QuizOption('Brown', color: _brown)],
            answerIndex: 0,
          ),
        ],
      ),
      Activity(
        id: 'colors_03',
        sectionIndex: 0,
        title: 'Yellow',
        emoji: '🟡',
        questions: [
          QuizQuestion(
            prompt: 'Tap the color',
            playType: PlayType.lookListen,
            cue: ColorWordCue('Yellow'),
            visual: AnswerVisual.colorSwatch,
            teach: 'This is yellow! 🟡 Say it with me.',
            spokenText: 'This is yellow. Say it with me: yellow! Now tap the color yellow.',
            teachOption: QuizOption('Yellow', color: _yellow),
            hint: 'Look for yellow.',
            options: [QuizOption('Green', color: _green), QuizOption('Pink', color: _pink), QuizOption('Yellow', color: _yellow)],
            answerIndex: 2,
          ),
          QuizQuestion(
            prompt: 'Which is yellow?',
            playType: PlayType.realWorld,
            cue: ColorSwatchCue('Yellow', _yellow),
            visual: AnswerVisual.picture,
            spokenText: 'Which picture is yellow?',
            hint: 'Find something yellow.',
            options: [QuizOption('Chick', emoji: '🐥'), QuizOption('Frog', emoji: '🐸'), QuizOption('Pig', emoji: '🐷')],
            answerIndex: 0,
          ),
          QuizQuestion(
            prompt: 'What color?',
            playType: PlayType.realWorld,
            cue: EmojiCue('🍌'),
            visual: AnswerVisual.colorSwatch,
            spokenText: 'What color is a banana?',
            hint: 'Picture a banana.',
            options: [QuizOption('Orange', color: _orange), QuizOption('Yellow', color: _yellow), QuizOption('Red', color: _red)],
            answerIndex: 1,
          ),
        ],
      ),
      Activity(
        id: 'colors_04',
        sectionIndex: 0,
        title: 'Green',
        emoji: '🟢',
        questions: [
          QuizQuestion(
            prompt: 'Tap the color',
            playType: PlayType.lookListen,
            cue: ColorWordCue('Green'),
            visual: AnswerVisual.colorSwatch,
            teach: 'This is green! 🟢 Say it with me.',
            spokenText: 'This is green. Say it with me: green! Now tap the color green.',
            teachOption: QuizOption('Green', color: _green),
            hint: 'Look for green.',
            options: [QuizOption('Green', color: _green), QuizOption('Orange', color: _orange), QuizOption('Brown', color: _brown)],
            answerIndex: 0,
          ),
          QuizQuestion(
            prompt: 'Which is green?',
            playType: PlayType.realWorld,
            cue: ColorSwatchCue('Green', _green),
            visual: AnswerVisual.picture,
            spokenText: 'Which picture is green?',
            hint: 'Find something green.',
            options: [QuizOption('Orange', emoji: '🍊'), QuizOption('Frog', emoji: '🐸'), QuizOption('Chocolate', emoji: '🍫')],
            answerIndex: 1,
          ),
          QuizQuestion(
            prompt: 'What color?',
            playType: PlayType.realWorld,
            cue: EmojiCue('🌿'),
            visual: AnswerVisual.colorSwatch,
            spokenText: 'What color is the grass?',
            hint: 'Picture the grass.',
            options: [QuizOption('Purple', color: _purple), QuizOption('Blue', color: _blue), QuizOption('Green', color: _green)],
            answerIndex: 2,
          ),
        ],
      ),
      Activity(
        id: 'colors_05',
        sectionIndex: 1,
        title: 'Orange',
        emoji: '🟠',
        questions: [
          QuizQuestion(
            prompt: 'Tap the color',
            playType: PlayType.lookListen,
            cue: ColorWordCue('Orange'),
            visual: AnswerVisual.colorSwatch,
            teach: 'This is orange! 🟠 Say it with me.',
            spokenText: 'This is orange. Say it with me: orange! Now tap the color orange.',
            teachOption: QuizOption('Orange', color: _orange),
            hint: 'Look for orange.',
            options: [QuizOption('Red', color: _red), QuizOption('Orange', color: _orange), QuizOption('Green', color: _green)],
            answerIndex: 1,
          ),
          QuizQuestion(
            prompt: 'Which is orange?',
            playType: PlayType.realWorld,
            cue: ColorSwatchCue('Orange', _orange),
            visual: AnswerVisual.picture,
            spokenText: 'Which picture is orange?',
            hint: 'Find something orange.',
            options: [QuizOption('Apple', emoji: '🍎'), QuizOption('Tree', emoji: '🌳'), QuizOption('Fox', emoji: '🦊')],
            answerIndex: 2,
          ),
          QuizQuestion(
            prompt: 'What color?',
            playType: PlayType.realWorld,
            cue: EmojiCue('🥕'),
            visual: AnswerVisual.colorSwatch,
            spokenText: 'What color is a carrot?',
            hint: 'Picture a carrot.',
            options: [QuizOption('Orange', color: _orange), QuizOption('Blue', color: _blue), QuizOption('Pink', color: _pink)],
            answerIndex: 0,
          ),
        ],
      ),
      Activity(
        id: 'colors_06',
        sectionIndex: 1,
        title: 'Purple',
        emoji: '🟣',
        questions: [
          QuizQuestion(
            prompt: 'Tap the color',
            playType: PlayType.lookListen,
            cue: ColorWordCue('Purple'),
            visual: AnswerVisual.colorSwatch,
            teach: 'This is purple! 🟣 Say it with me.',
            spokenText: 'This is purple. Say it with me: purple! Now tap the color purple.',
            teachOption: QuizOption('Purple', color: _purple),
            hint: 'Look for purple.',
            options: [QuizOption('Blue', color: _blue), QuizOption('Orange', color: _orange), QuizOption('Purple', color: _purple)],
            answerIndex: 2,
          ),
          QuizQuestion(
            prompt: 'Which is purple?',
            playType: PlayType.realWorld,
            cue: ColorSwatchCue('Purple', _purple),
            visual: AnswerVisual.picture,
            spokenText: 'Which picture is purple?',
            hint: 'Find something purple.',
            options: [QuizOption('Crystal ball', emoji: '🔮'), QuizOption('Wave', emoji: '🌊'), QuizOption('Carrot', emoji: '🥕')],
            answerIndex: 0,
          ),
          QuizQuestion(
            prompt: 'What color?',
            playType: PlayType.realWorld,
            cue: EmojiCue('🍇'),
            visual: AnswerVisual.colorSwatch,
            spokenText: 'What color are grapes?',
            hint: 'Picture grapes.',
            options: [QuizOption('Yellow', color: _yellow), QuizOption('Purple', color: _purple), QuizOption('Brown', color: _brown)],
            answerIndex: 1,
          ),
        ],
      ),
      Activity(
        id: 'colors_07',
        sectionIndex: 1,
        title: 'Pink',
        emoji: '🌸',
        questions: [
          QuizQuestion(
            prompt: 'Tap the color',
            playType: PlayType.lookListen,
            cue: ColorWordCue('Pink'),
            visual: AnswerVisual.colorSwatch,
            teach: 'This is pink! 🌸 Say it with me.',
            spokenText: 'This is pink. Say it with me: pink! Now tap the color pink.',
            teachOption: QuizOption('Pink', color: _pink),
            hint: 'Look for pink.',
            options: [QuizOption('Pink', color: _pink), QuizOption('Yellow', color: _yellow), QuizOption('Purple', color: _purple)],
            answerIndex: 0,
          ),
          QuizQuestion(
            prompt: 'Which is pink?',
            playType: PlayType.realWorld,
            cue: ColorSwatchCue('Pink', _pink),
            visual: AnswerVisual.picture,
            spokenText: 'Which picture is pink?',
            hint: 'Find something pink.',
            options: [QuizOption('Banana', emoji: '🍌'), QuizOption('Ribbon', emoji: '🎀'), QuizOption('Frog', emoji: '🐸')],
            answerIndex: 1,
          ),
          QuizQuestion(
            prompt: 'What color?',
            playType: PlayType.realWorld,
            cue: EmojiCue('🐷'),
            visual: AnswerVisual.colorSwatch,
            spokenText: 'What color is a pig?',
            hint: 'Picture a pig.',
            options: [QuizOption('Green', color: _green), QuizOption('Red', color: _red), QuizOption('Pink', color: _pink)],
            answerIndex: 2,
          ),
        ],
      ),
      Activity(
        id: 'colors_08',
        sectionIndex: 1,
        title: 'Brown',
        emoji: '🟤',
        questions: [
          QuizQuestion(
            prompt: 'Tap the color',
            playType: PlayType.lookListen,
            cue: ColorWordCue('Brown'),
            visual: AnswerVisual.colorSwatch,
            teach: 'This is brown! 🟤 Say it with me.',
            spokenText: 'This is brown. Say it with me: brown! Now tap the color brown.',
            teachOption: QuizOption('Brown', color: _brown),
            hint: 'Look for brown.',
            options: [QuizOption('Green', color: _green), QuizOption('Brown', color: _brown), QuizOption('Pink', color: _pink)],
            answerIndex: 1,
          ),
          QuizQuestion(
            prompt: 'Which is brown?',
            playType: PlayType.realWorld,
            cue: ColorSwatchCue('Brown', _brown),
            visual: AnswerVisual.picture,
            spokenText: 'Which picture is brown?',
            hint: 'Find something brown.',
            options: [QuizOption('Frog', emoji: '🐸'), QuizOption('Pig', emoji: '🐷'), QuizOption('Bear', emoji: '🐻')],
            answerIndex: 2,
          ),
          QuizQuestion(
            prompt: 'What color?',
            playType: PlayType.realWorld,
            cue: EmojiCue('🧸'),
            visual: AnswerVisual.colorSwatch,
            spokenText: 'What color is a teddy bear?',
            hint: 'Picture a teddy bear.',
            options: [QuizOption('Brown', color: _brown), QuizOption('Orange', color: _orange), QuizOption('Blue', color: _blue)],
            answerIndex: 0,
          ),
        ],
      ),
      Activity(
        id: 'colors_09',
        sectionIndex: 2,
        title: 'Red + Yellow',
        emoji: '🟠',
        minAge: 5,
        questions: [
          QuizQuestion(
            prompt: 'What color?',
            playType: PlayType.lookListen,
            cue: ColorMixCue(firstName: 'Red', first: _red, secondName: 'Yellow', second: _yellow),
            visual: AnswerVisual.colorSwatch,
            teach: 'Red and yellow make orange! 🎨',
            spokenText: 'What color do red and yellow make?',
            teachOption: QuizOption('Orange', color: _orange),
            hint: 'Imagine mixing the paints.',
            options: [QuizOption('Green', color: _green), QuizOption('Purple', color: _purple), QuizOption('Orange', color: _orange)],
            answerIndex: 2,
          ),
          QuizQuestion(
            prompt: 'Make orange?',
            playType: PlayType.concept,
            cue: ColorSwatchCue('Orange', _orange),
            visual: AnswerVisual.picture,
            spokenText: 'Which two colors make orange?',
            hint: 'Think of mixing paint.',
            options: [QuizOption('Red + Yellow', emoji: '🔴🟡'), QuizOption('Blue + Yellow', emoji: '🔵🟡'), QuizOption('Red + Blue', emoji: '🔴🔵')],
            answerIndex: 0,
          ),
          QuizQuestion(
            prompt: 'What color?',
            playType: PlayType.realWorld,
            cue: EmojiCue('🎃'),
            visual: AnswerVisual.colorSwatch,
            spokenText: 'What color is a pumpkin?',
            hint: 'Picture a pumpkin.',
            options: [QuizOption('Blue', color: _blue), QuizOption('Orange', color: _orange), QuizOption('Pink', color: _pink)],
            answerIndex: 1,
          ),
        ],
      ),
      Activity(
        id: 'colors_10',
        sectionIndex: 2,
        title: 'Blue + Yellow',
        emoji: '🟢',
        minAge: 5,
        questions: [
          QuizQuestion(
            prompt: 'What color?',
            playType: PlayType.lookListen,
            cue: ColorMixCue(firstName: 'Blue', first: _blue, secondName: 'Yellow', second: _yellow),
            visual: AnswerVisual.colorSwatch,
            teach: 'Blue and yellow make green! 🎨',
            spokenText: 'What color do blue and yellow make?',
            teachOption: QuizOption('Green', color: _green),
            hint: 'Imagine mixing the paints.',
            options: [QuizOption('Green', color: _green), QuizOption('Orange', color: _orange), QuizOption('Pink', color: _pink)],
            answerIndex: 0,
          ),
          QuizQuestion(
            prompt: 'Make green?',
            playType: PlayType.concept,
            cue: ColorSwatchCue('Green', _green),
            visual: AnswerVisual.picture,
            spokenText: 'Which two colors make green?',
            hint: 'Think of mixing paint.',
            options: [QuizOption('Red + Yellow', emoji: '🔴🟡'), QuizOption('Blue + Yellow', emoji: '🔵🟡'), QuizOption('Red + Blue', emoji: '🔴🔵')],
            answerIndex: 1,
          ),
          QuizQuestion(
            prompt: 'What color?',
            playType: PlayType.realWorld,
            cue: EmojiCue('🐢'),
            visual: AnswerVisual.colorSwatch,
            spokenText: 'What color is a turtle?',
            hint: 'Picture a turtle.',
            options: [QuizOption('Purple', color: _purple), QuizOption('Red', color: _red), QuizOption('Green', color: _green)],
            answerIndex: 2,
          ),
        ],
      ),
      Activity(
        id: 'colors_11',
        sectionIndex: 2,
        title: 'Red + Blue',
        emoji: '🟣',
        minAge: 5,
        questions: [
          QuizQuestion(
            prompt: 'What color?',
            playType: PlayType.lookListen,
            cue: ColorMixCue(firstName: 'Red', first: _red, secondName: 'Blue', second: _blue),
            visual: AnswerVisual.colorSwatch,
            teach: 'Red and blue make purple! 🎨',
            spokenText: 'What color do red and blue make?',
            teachOption: QuizOption('Purple', color: _purple),
            hint: 'Imagine mixing the paints.',
            options: [QuizOption('Green', color: _green), QuizOption('Purple', color: _purple), QuizOption('Brown', color: _brown)],
            answerIndex: 1,
          ),
          QuizQuestion(
            prompt: 'Make purple?',
            playType: PlayType.concept,
            cue: ColorSwatchCue('Purple', _purple),
            visual: AnswerVisual.picture,
            spokenText: 'Which two colors make purple?',
            hint: 'Think of mixing paint.',
            options: [QuizOption('Blue + Yellow', emoji: '🔵🟡'), QuizOption('Red + Yellow', emoji: '🔴🟡'), QuizOption('Red + Blue', emoji: '🔴🔵')],
            answerIndex: 2,
          ),
          QuizQuestion(
            prompt: 'What color?',
            playType: PlayType.realWorld,
            cue: EmojiCue('💜'),
            visual: AnswerVisual.colorSwatch,
            spokenText: 'What color is the heart?',
            hint: 'Picture the heart.',
            options: [QuizOption('Purple', color: _purple), QuizOption('Yellow', color: _yellow), QuizOption('Orange', color: _orange)],
            answerIndex: 0,
          ),
        ],
      ),
      Activity(
        id: 'colors_12',
        sectionIndex: 2,
        title: 'Rainbow',
        emoji: '🌈',
        minAge: 5,
        questions: [
          QuizQuestion(
            prompt: 'First color?',
            playType: PlayType.lookListen,
            cue: RainbowCue(bands: [_red, _orange, _yellow, _green, _blue, _purple], missingIndex: 0),
            visual: AnswerVisual.colorSwatch,
            teach: 'Red is at the top of the rainbow! 🌈',
            spokenText: 'Which color is first in the rainbow?',
            teachOption: QuizOption('Red', color: _red),
            hint: 'Look at the top band.',
            options: [QuizOption('Green', color: _green), QuizOption('Blue', color: _blue), QuizOption('Red', color: _red)],
            answerIndex: 2,
          ),
          QuizQuestion(
            prompt: 'What is next?',
            playType: PlayType.concept,
            cue: RainbowCue(bands: [_red, _orange, _yellow, _green, _blue, _purple], missingIndex: 3),
            visual: AnswerVisual.colorSwatch,
            spokenText: 'Which color comes after yellow?',
            hint: 'Follow the colors in order.',
            options: [QuizOption('Blue', color: _blue), QuizOption('Green', color: _green), QuizOption('Red', color: _red)],
            answerIndex: 1,
          ),
          QuizQuestion(
            prompt: 'What is missing?',
            playType: PlayType.concept,
            cue: RainbowCue(bands: [_red, _orange, _yellow, _green, _blue, _purple], missingIndex: 1),
            visual: AnswerVisual.colorSwatch,
            spokenText: 'Which color is between red and yellow?',
            hint: 'Mix red and yellow paint.',
            options: [QuizOption('Green', color: _green), QuizOption('Orange', color: _orange), QuizOption('Purple', color: _purple)],
            answerIndex: 1,
          ),
        ],
      ),
    ],
  ),
};
