import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/activities.dart';
import '../models/learning.dart';
import '../services/firestore_service.dart';

/// The parent's "everything about this learner" screen, opened by tapping a
/// child on the Learning dashboard: accuracy, a per-world breakdown, the
/// last seven days of activity and a plain-language suggestion.
class ChildDetailPage extends StatelessWidget {
  ChildDetailPage({
    required this.parentUid,
    required this.childId,
    required this.summary,
    FirestoreService? firestore,
    super.key,
  }) : firestore = firestore ?? FirestoreService();

  final String parentUid;
  final String childId;

  /// The lightweight profile already shown on the dashboard card — used
  /// while (or if) the full saved progress can't be loaded.
  final Map<String, dynamic> summary;
  final FirestoreService firestore;

  UserProgress _fallback() => UserProgress(
        points: (summary['points'] as num?)?.toInt() ?? 0,
        totalQuestions: (summary['totalQuestions'] as num?)?.toInt() ?? 0,
        correctAnswers: (summary['correctAnswers'] as num?)?.toInt() ?? 0,
        avatar: summary['avatar'] as String? ?? '🧒',
        childName: summary['name'] as String? ?? 'Little Learner',
        childAge: (summary['age'] as num?)?.toInt() ?? 4,
        completedByModule: {
          for (final e
              in ((summary['completedByModule'] as Map?) ?? {}).entries)
            e.key as String: (e.value as num).toInt(),
        },
        activityStars: {
          for (final e in ((summary['activityStars'] as Map?) ?? {}).entries)
            e.key as String: (e.value as num).toInt(),
        },
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${summary['name'] ?? 'Learner'}'s progress"),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: firestore.loadProgress(parentUid, childId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          UserProgress progress;
          try {
            final data = snapshot.data;
            progress = data == null ? _fallback() : UserProgress.fromJson(data);
          } catch (_) {
            progress = _fallback();
          }
          return _DetailBody(progress: progress);
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.progress});
  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    final total = progress.totalQuestions;
    final correct = progress.correctAnswers;
    final accuracy = total == 0 ? 0.0 : correct / total;

    final header = _Panel(
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: const Color(0xFFFFD166),
            child: Text(progress.avatar, style: const TextStyle(fontSize: 36)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(progress.childName,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.w900)),
                Text(
                  '${progress.childAge} years old',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 4,
                  children: [
                    _MiniStat(Icons.star_rounded, '${progress.points}',
                        'points', const Color(0xFFFFB703)),
                    _MiniStat(
                        Icons.local_fire_department_rounded,
                        '${progress.streak}',
                        'day streak',
                        const Color(0xFFFF715B)),
                    _MiniStat(Icons.quiz_rounded, '$total', 'tries',
                        const Color(0xFF3A86FF)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final accuracyCard = _Panel(
      title: 'Overall accuracy',
      child: Row(
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: CustomPaint(
              painter: _DonutPainter(
                fraction: accuracy,
                color: const Color(0xFF2ECC71),
                track: const Color(0xFFFFD8B0),
              ),
              child: Center(
                child: Text(
                  total == 0 ? '—' : '${(accuracy * 100).round()}%',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: total == 0
                ? const Text(
                    'No answers yet — the chart fills in once your child plays.',
                    style: TextStyle(color: Colors.black54))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Legend(const Color(0xFF2ECC71), '$correct correct'),
                      const SizedBox(height: 6),
                      _Legend(const Color(0xFFFFD8B0),
                          '${total - correct} needed another try'),
                    ],
                  ),
          ),
        ],
      ),
    );

    final subjects = _Panel(
      title: 'By learning world',
      child: Column(
        children: [
          for (final module in learningModules)
            _SubjectRow(
              module: module,
              answered: progress.moduleAnswered[module.id] ?? 0,
              correct: progress.moduleCorrect[module.id] ?? 0,
              completedActivities: worldCatalogs[module.id]!
                  .activities
                  .where((activity) =>
                      (progress.activityStars[activity.id] ?? 0) > 0)
                  .length,
              totalActivities: worldCatalogs[module.id]!.activities.length,
              stars: worldCatalogs[module.id]!.activities.fold<int>(
                    0,
                    (total, activity) =>
                        total + (progress.activityStars[activity.id] ?? 0),
                  ),
              totalStars: worldCatalogs[module.id]!.activities.length * 3,
            ),
        ],
      ),
    );

    final week = _Panel(
      title: 'Last 7 days',
      child: WeekChart(dailyStats: progress.dailyStats),
    );

    final tip = _Panel(
      color: const Color(0xFFE8F7F0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_rounded, color: Color(0xFF2E9E6B)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(_suggestion(progress),
                  style: const TextStyle(fontSize: 15, height: 1.35))),
        ],
      ),
    );

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 720;
      final left = Column(children: [
        header,
        const SizedBox(height: 14),
        accuracyCard,
        const SizedBox(height: 14),
        tip
      ]);
      final right =
          Column(children: [subjects, const SizedBox(height: 14), week]);
      return SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: left),
                      const SizedBox(width: 14),
                      Expanded(child: right),
                    ],
                  )
                : Column(children: [left, const SizedBox(height: 14), right]),
            const SizedBox(height: 10),
            const Text(
              'A try is each time an answer is dropped, including retries.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      );
    });
  }

  String _suggestion(UserProgress p) {
    if (p.totalQuestions < 5) {
      return 'Not much data yet. Encourage a few short rounds a day — '
          'this page will show strengths and what to practise next.';
    }
    LearningModule? weakest;
    var weakestRate = 2.0;
    LearningModule? strongest;
    var strongestRate = -1.0;
    for (final m in learningModules) {
      final answered = p.moduleAnswered[m.id] ?? 0;
      if (answered < 3) continue;
      final rate = (p.moduleCorrect[m.id] ?? 0) / answered;
      if (rate < weakestRate) {
        weakestRate = rate;
        weakest = m;
      }
      if (rate > strongestRate) {
        strongestRate = rate;
        strongest = m;
      }
    }
    final untried = learningModules
        .where((m) => (p.moduleAnswered[m.id] ?? 0) == 0)
        .toList();
    final parts = <String>[];
    if (strongest != null && strongestRate >= 0.7) {
      parts.add('${p.childName} is doing well in ${strongest.title} '
          '(${(strongestRate * 100).round()}% correct).');
    }
    if (weakest != null && weakestRate < 0.7 && weakest != strongest) {
      parts.add('${weakest.title} needs a little more practice '
          '(${(weakestRate * 100).round()}% correct) — try a few rounds together.');
    }
    if (untried.isNotEmpty) {
      parts.add('Not tried yet: ${untried.map((m) => m.title).join(', ')}.');
    }
    if (parts.isEmpty) {
      parts.add('Great all-round progress — keep the daily streak going!');
    }
    return parts.join(' ');
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.title, this.color});
  final Widget child;
  final String? title;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.icon, this.value, this.label, this.color);
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ],
      );
}

class _Legend extends StatelessWidget {
  const _Legend(this.color, this.text);
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Flexible(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      );
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.fraction,
    required this.color,
    required this.track,
  });
  final double fraction;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, base..color = track);
    if (fraction > 0) {
      canvas.drawArc(
        arcRect,
        -math.pi / 2,
        math.pi * 2 * fraction.clamp(0.0, 1.0),
        false,
        base..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.fraction != fraction || old.color != color;
}

class _SubjectRow extends StatelessWidget {
  const _SubjectRow({
    required this.module,
    required this.answered,
    required this.correct,
    required this.completedActivities,
    required this.totalActivities,
    required this.stars,
    required this.totalStars,
  });
  final LearningModule module;
  final int answered;
  final int correct;
  final int completedActivities;
  final int totalActivities;
  final int stars;
  final int totalStars;

  @override
  Widget build(BuildContext context) {
    final rate = answered == 0 ? 0.0 : correct / answered;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: module.illustrationAsset != null
                ? SvgPicture.asset(module.illustrationAsset!)
                : Icon(module.icon, color: module.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(module.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14)),
                    ),
                    Text(
                      answered == 0 ? 'Not tried' : '${(rate * 100).round()}%',
                      style: TextStyle(
                          fontWeight: FontWeight.w900, color: module.color),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: rate,
                    minHeight: 9,
                    color: module.color,
                    backgroundColor: module.color.withValues(alpha: 0.15),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$completedActivities / $totalActivities activities · '
                  '$stars / $totalStars stars · $answered tries',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WeekChart extends StatelessWidget {
  const WeekChart({required this.dailyStats, super.key});
  final Map<String, List<int>> dailyStats;

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String _key(DateTime d) => '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final days = [
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)),
    ];
    final values = [
      for (final d in days) dailyStats[_key(d)] ?? const [0, 0],
    ];
    final maxAnswered = values.fold<int>(1, (m, v) => math.max(m, v[0]));
    final any = values.any((v) => v[0] > 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 146,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < days.length; i++)
                Expanded(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 18,
                        child: Center(
                          child: Text(
                            values[i][0] == 0 ? '' : '${values[i][0]}',
                            maxLines: 1,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor: values[i][0] == 0
                                ? 0.04
                                : values[i][0] / maxAnswered,
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: 22,
                              decoration: BoxDecoration(
                                color: values[i][0] == 0
                                    ? Colors.black12
                                    : const Color(0xFFFFD8B0),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.bottomCenter,
                              child: values[i][0] == 0
                                  ? null
                                  : FractionallySizedBox(
                                      heightFactor: values[i][1] / values[i][0],
                                      widthFactor: 1,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2ECC71),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 18,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _dayNames[days[i].weekday - 1],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: i == days.length - 1
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 14,
          children: const [
            _Legend(Color(0xFF2ECC71), 'correct'),
            _Legend(Color(0xFFFFD8B0), 'needed another try'),
          ],
        ),
        if (!any)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Activity shows up here from now on, as your child plays.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
      ],
    );
  }
}
