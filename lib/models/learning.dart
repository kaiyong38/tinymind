import 'dart:math' as math;

import 'package:flutter/material.dart';

enum AnswerVisual {
  text,
  colorSwatch,
  shape,
  letterPicture,
  numberDots,
  picture,
  colorPair,
  shapeCorners,
  shapeSides,
}

enum PlayType {
  lookListen,
  findSame,
  sayName,
  realWorld,
  concept,
}

enum CueShapeStyle {
  solid,
  silhouette,
  dashed,
}

enum ShapeKind {
  circle,
  square,
  triangle,
  star,
}

sealed class QuizCue {
  const QuizCue();

  String get identityKey;
}

final class EmojiCue extends QuizCue {
  const EmojiCue(this.emoji);

  final String emoji;

  @override
  String get identityKey => 'emoji:$emoji';
}

final class LetterCue extends QuizCue {
  const LetterCue(this.text);

  final String text;

  @override
  String get identityKey => 'letter:$text';
}

final class ShapeCue extends QuizCue {
  const ShapeCue(
    this.shape, {
    this.color = const Color(0xFF3A86FF),
    this.style = CueShapeStyle.solid,
    this.numberSides = false,
    this.colorSides = false,
    this.markCorners = false,
  });

  final ShapeKind shape;
  final Color color;
  final CueShapeStyle style;
  final bool numberSides;
  final bool colorSides;
  final bool markCorners;

  @override
  String get identityKey => 'shape:${style.name}:${shape.name}';
}

final class ShapeRowCue extends QuizCue {
  const ShapeRowCue({
    required this.shapes,
    required this.differentIndex,
    required this.color,
    this.differentColor,
  });

  final List<ShapeKind> shapes;
  final int differentIndex;
  final Color color;

  /// Colour of the odd shape. When null it uses the same colour as the rest.
  final Color? differentColor;

  @override
  String get identityKey =>
      'row:${shapes.map((shape) => shape.name).join(',')}:$differentIndex:${color.toARGB32()}:${differentColor?.toARGB32()}';
}

final class NumberCue extends QuizCue {
  const NumberCue(this.value);

  final int value;

  @override
  String get identityKey => 'number:$value';
}

enum ItemCountArrangement {
  ordered,
  scattered,
}

final class ItemCountCue extends QuizCue {
  const ItemCountCue({
    required this.emoji,
    required this.count,
    this.arrangement = ItemCountArrangement.ordered,
    this.rows = 0,
    this.removedCount = 0,
    this.showResult = false,
  });

  final String emoji;
  final int count;
  final ItemCountArrangement arrangement;
  final int rows;
  final int removedCount;
  final bool showResult;

  @override
  String get identityKey =>
      'item-count:$emoji:$count:${arrangement.name}:$rows:$removedCount:$showResult';

  List<Rect> itemRectsFor(Size size) {
    const scatteredCenters = [
      Offset(0.14, 0.28),
      Offset(0.38, 0.20),
      Offset(0.62, 0.32),
      Offset(0.86, 0.24),
      Offset(0.24, 0.68),
      Offset(0.50, 0.78),
      Offset(0.76, 0.64),
      Offset(0.88, 0.82),
    ];
    final rowCount = rows > 0
        ? rows
        : arrangement == ItemCountArrangement.scattered
            ? 2
            : count > 5
                ? (count / 5).ceil()
                : 1;
    final columns =
        rows > 0 ? (count / rowCount).ceil() : math.min(5, count);
    final itemSize = arrangement == ItemCountArrangement.scattered
        ? math.max(
            28.0,
            math.min(46.0, math.min(size.width / 10, size.height / 5)),
          )
        : math.max(
            28.0,
            math.min(64.0, math.min(size.width / (columns + 1), size.height / (rowCount + 1))),
          );
    return List.generate(count, (index) {
      final center = arrangement == ItemCountArrangement.scattered
          ? Offset(
              scatteredCenters[index].dx * size.width,
              scatteredCenters[index].dy * size.height,
            )
          : Offset(
              size.width * ((index % columns) + 1) / (columns + 1),
              size.height * ((index ~/ columns) + 1) / (rowCount + 1),
            );
      return Rect.fromCenter(
        center: center,
        width: itemSize,
        height: itemSize,
      );
    });
  }
}

final class EquationPictureCue extends QuizCue {
  const EquationPictureCue({
    required this.emoji,
    required this.firstCount,
    required this.secondCount,
  });

  final String emoji;
  final int firstCount;
  final int secondCount;

  @override
  String get identityKey =>
      'equation-picture:$emoji:$firstCount+$secondCount';
}

enum TenFrameMode {
  addition,
  subtraction,
  makeTen,
  teenNumber,
}

final class TenFrameCue extends QuizCue {
  const TenFrameCue({
    required this.mode,
    required this.firstCount,
    this.secondCount = 0,
  });

  final TenFrameMode mode;
  final int firstCount;
  final int secondCount;

  /// Red dots drawn. For [TenFrameMode.teenNumber] this is the full first frame.
  int get filledDots => switch (mode) {
        TenFrameMode.teenNumber => 10,
        _ => firstCount,
      };

  /// Grey "?" dots drawn. For [TenFrameMode.teenNumber] they sit in the
  /// second frame; otherwise they follow the red dots in the single frame.
  int get questionDots => switch (mode) {
        TenFrameMode.addition => math.min(secondCount, 10 - firstCount),
        TenFrameMode.subtraction => 0,
        TenFrameMode.makeTen => 10 - firstCount,
        TenFrameMode.teenNumber => math.min(secondCount, 10),
      };

  @override
  String get identityKey =>
      'ten-frame:${mode.name}:$firstCount:$secondCount';
}

final class NightSkyCue extends QuizCue {
  const NightSkyCue({this.showMoon = true});

  final bool showMoon;

  @override
  String get identityKey => 'scene:night-sky:moon=$showMoon';
}

final class RollingSlopeCue extends QuizCue {
  const RollingSlopeCue();

  @override
  String get identityKey => 'rolling-slope';
}

final class ColorWordCue extends QuizCue {
  const ColorWordCue(this.name);

  final String name;

  @override
  String get identityKey => 'color-word:${name.toLowerCase()}';
}

final class ColorSwatchCue extends QuizCue {
  const ColorSwatchCue(this.name, this.color);

  final String name;
  final Color color;

  @override
  String get identityKey => 'color-swatch:${name.toLowerCase()}';
}

final class ColorMixCue extends QuizCue {
  const ColorMixCue({
    required this.firstName,
    required this.first,
    required this.secondName,
    required this.second,
  });

  final String firstName;
  final Color first;
  final String secondName;
  final Color second;

  @override
  String get identityKey =>
      'color-mix:${firstName.toLowerCase()}+${secondName.toLowerCase()}';
}

final class RainbowCue extends QuizCue {
  const RainbowCue({required this.bands, required this.missingIndex});

  final List<Color> bands;
  final int missingIndex;

  @override
  String get identityKey => 'rainbow:$missingIndex';
}

class QuizOption {
  const QuizOption(this.label,
      {this.color, this.color2, this.emoji, this.count});

  final String label;
  final Color? color;
  final Color? color2;
  final String? emoji;
  final int? count;

  String identityKeyFor(AnswerVisual visual) {
    if (emoji != null) return 'emoji:$emoji';
    if (visual == AnswerVisual.shape) return 'shape:solid:$label';
    if (visual == AnswerVisual.shapeCorners) return 'shape:corners:$label';
    if (visual == AnswerVisual.shapeSides) return 'shape:sides:$label';
    return 'label:${label.toLowerCase()}';
  }
}

class QuizQuestion {
  const QuizQuestion({
    required this.prompt,
    required this.options,
    required this.answerIndex,
    this.visual = AnswerVisual.text,
    this.teach,
    this.spokenText,
    this.teachOption,
    this.hint,
    this.playType,
    this.cue,
  });

  final String prompt;
  final List<QuizOption> options;
  final int answerIndex;
  final AnswerVisual visual;
  final String? teach;
  final String? spokenText;
  final QuizOption? teachOption;
  final String? hint;
  final PlayType? playType;
  final QuizCue? cue;
}

class LearningModule {
  const LearningModule({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.illustrationAsset,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String? illustrationAsset;
}

const learningModules = [
  LearningModule(
    id: 'letters',
    title: 'Letter Land',
    subtitle: 'Explore letters and sounds',
    icon: Icons.abc,
    color: Color(0xFFA78BFA),
    illustrationAsset: 'assets/illustrations/letters_buddy.svg',
  ),
  LearningModule(
    id: 'numbers',
    title: 'Math Town',
    subtitle: 'Count, add and take away',
    icon: Icons.pin,
    color: Color(0xFFFF8FAB),
    illustrationAsset: 'assets/illustrations/numbers_buddy.svg',
  ),
  LearningModule(
    id: 'shapes',
    title: 'Shape Safari',
    subtitle: 'Spot shapes all around you',
    icon: Icons.category,
    color: Color(0xFF4ECDC4),
    illustrationAsset: 'assets/illustrations/shapes_buddy.svg',
  ),
  LearningModule(
    id: 'colors',
    title: 'Color Garden',
    subtitle: 'Mix and match bright colors',
    icon: Icons.palette,
    color: Color(0xFFFFC857),
    illustrationAsset: 'assets/illustrations/colors_buddy.svg',
  ),
];

class UserProgress {
  UserProgress({
    this.points = 0,
    this.todayQuestions = 0,
    this.totalQuestions = 0,
    this.correctAnswers = 0,
    Map<String, int>? completedByModule,
    this.avatar = '🧒',
    this.childName = 'Mia',
    this.childAge = 4,
    Map<String, int>? moduleAnswered,
    Map<String, int>? moduleCorrect,
    Map<String, List<int>>? dailyStats,
    Map<String, int>? activityStars,
  })  : completedByModule = completedByModule ?? {},
        moduleAnswered = moduleAnswered ?? {},
        moduleCorrect = moduleCorrect ?? {},
        dailyStats = dailyStats ?? {},
        activityStars = activityStars ?? {};

  int points;
  int todayQuestions;
  int totalQuestions;
  int correctAnswers;
  String avatar;
  String childName;
  int childAge;

  final Map<String, int> completedByModule;
  final Map<String, int> moduleAnswered;
  final Map<String, int> moduleCorrect;
  final Map<String, List<int>> dailyStats;
  final Map<String, int> activityStars;

  int get daysLearned => dailyStats.length;

  int get streak {
    final today = DateTime.now();
    final todayKey = _dateKey(today);
    var date = dailyStats.containsKey(todayKey)
        ? DateTime(today.year, today.month, today.day)
        : DateTime(today.year, today.month, today.day)
            .subtract(const Duration(days: 1));
    var consecutiveDays = 0;
    while (dailyStats.containsKey(_dateKey(date))) {
      consecutiveDays++;
      date = date.subtract(const Duration(days: 1));
    }
    return consecutiveDays;
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'points': points,
        'daysLearned': daysLearned,
        'streak': streak,
        'todayQuestions': todayQuestions,
        'totalQuestions': totalQuestions,
        'correctAnswers': correctAnswers,
        'completedByModule': completedByModule,
        'avatar': avatar,
        'childName': childName,
        'childAge': childAge,
        'moduleAnswered': moduleAnswered,
        'moduleCorrect': moduleCorrect,
        'dailyStats': dailyStats,
        'activityStars': activityStars,
      };

  factory UserProgress.fromJson(Map<String, dynamic> json) => UserProgress(
        points: json['points'] as int? ?? 0,
          todayQuestions: json['todayQuestions'] as int? ?? 0,
        totalQuestions: json['totalQuestions'] as int? ?? 0,
        correctAnswers: json['correctAnswers'] as int? ?? 0,
        completedByModule:
            Map<String, int>.from(json['completedByModule'] as Map? ?? {}),
        avatar: json['avatar'] as String? ?? '🧒',
        childName: json['childName'] as String? ?? 'Mia',
        childAge: json['childAge'] as int? ?? 4,
        moduleAnswered:
            Map<String, int>.from(json['moduleAnswered'] as Map? ?? {}),
        moduleCorrect:
            Map<String, int>.from(json['moduleCorrect'] as Map? ?? {}),
        dailyStats: {
          for (final entry in (json['dailyStats'] as Map? ?? {}).entries)
            entry.key as String: [
              for (final value in entry.value as List) (value as num).toInt(),
            ],
        },
        activityStars: {
          for (final entry in (json['activityStars'] as Map? ?? {}).entries)
            entry.key as String: (entry.value as num).toInt(),
        },
      );
}
