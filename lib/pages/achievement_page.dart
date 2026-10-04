import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../models/learning.dart';
import '../services/progress_store.dart';
import '../widgets/text_scale_limit.dart';

class AchievementPage extends StatelessWidget {
  const AchievementPage({required this.progress, super.key});
  final UserProgress progress;
  List<Achievement> get achievements => [
        Achievement(
            id: 'first',
            title: 'First steps',
            description: 'Answer your first question',
            icon: Icons.waving_hand,
            unlocked: progress.totalQuestions > 0),
        Achievement(
            id: 'days_played',
            title: 'Three-day explorer',
            description: 'Play on 3 different days',
            icon: Icons.calendar_month_rounded,
            unlocked: progress.daysLearned >= 3),
        Achievement(
            id: 'stars',
            title: 'Star learner',
            description: 'Collect 50 stars',
            icon: Icons.star,
            unlocked: progress.points >= 50),
        Achievement(
            id: 'super',
            title: 'Super learner',
            description: 'Answer 20 questions',
            icon: Icons.school,
            unlocked: progress.totalQuestions >= 20),
      ];
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Achievements')),
        body: TextScaleLimit(
          maxScale: 1.3,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 600 ? 4 : 2;
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: achievements.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: columns == 4 ? 0.95 : 0.88,
                ),
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  return Card(
                    margin: EdgeInsets.zero,
                    color: achievement.unlocked
                        ? const Color(0xFFFFE1ED)
                        : Colors.grey.shade200,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 29,
                            backgroundColor: achievement.unlocked
                                ? Colors.amber
                                : Colors.grey.shade300,
                            child: Icon(
                              achievement.icon,
                              size: 30,
                              color: achievement.unlocked
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Flexible(
                            child: SingleChildScrollView(
                              child: Text(
                                achievement.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Flexible(
                            child: SingleChildScrollView(
                              child: Text(
                                achievement.description,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Icon(
                            achievement.unlocked
                                ? Icons.check_circle
                                : Icons.lock_outline,
                            color: achievement.unlocked
                                ? Colors.green
                                : Colors.grey,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
}

class AvatarPage extends StatelessWidget {
  const AvatarPage({required this.store, super.key});
  final ProgressStore store;
  static const avatars = ['🧒', '👧', '🦊', '🐼', '🐸', '🦄', '🚀', '🌈'];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose your avatar')),
      body: TextScaleLimit(
        maxScale: 1.3,
        child: GridView.count(
          crossAxisCount: 4,
          padding: const EdgeInsets.all(24),
          children: avatars
              .map((avatar) => InkWell(
                    onTap: () async {
                      await store.setAvatar(avatar);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Center(
                        child:
                            Text(avatar, style: const TextStyle(fontSize: 44))),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
