import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/activities.dart';
import '../models/learning.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/parent_gate_service.dart';
import '../widgets/bouncy_tap.dart';
import 'auth_pages.dart';
import 'child_detail_page.dart';
import 'parent_settings_page.dart';
import 'privacy_policy_page.dart';

class AdminPage extends StatelessWidget {
  AdminPage({
    required this.parentUid,
    FirestoreService? firestore,
    AuthService? auth,
    ParentGateService? gateService,
    super.key,
  })  : firestore = firestore ?? FirestoreService(),
        auth = auth ?? AuthService(),
        gateService = gateService ?? ParentGateService.instance;
  final String parentUid;
  final FirestoreService firestore;
  final AuthService auth;
  final ParentGateService gateService;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Learning dashboard'),
          actions: [
            IconButton(
              tooltip: 'Settings',
              constraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              icon: const Icon(Icons.settings_rounded),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ParentSettingsPage(gateService: gateService),
                ),
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle_rounded),
              tooltip: 'Account',
              onSelected: (value) async {
                if (value == 'change_password') {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ChangePasswordPage(auth: auth),
                    ),
                  );
                } else if (value == 'sign_out') {
                  gateService.clearVerificationWindow();
                  await auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                } else if (value == 'privacy_policy') {
                  await openPrivacyPolicy(context);
                } else if (value == 'delete_account') {
                  await _deleteAccount(context, auth, gateService);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'change_password',
                  child: Text('Change password'),
                ),
                PopupMenuItem(
                  value: 'sign_out',
                  child: Text('Sign out'),
                ),
                PopupMenuItem(
                  value: 'privacy_policy',
                  child: Text('Privacy Policy'),
                ),
                PopupMenuItem(
                  value: 'delete_account',
                  child: Text(
                    'Delete account and all data',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
        body: StreamBuilder(
          stream: firestore.watchChildren(parentUid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unable to load children: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final children = snapshot.data!.docs;
            if (children.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No child profiles yet.\nSet up a learner to see progress here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              );
            }
            return LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 700 ? 2 : 1;
                final aspectRatio = columns == 2 ? 1.15 : 1.05;
                const padding = 20.0;
                const spacing = 16.0;
                final cardHeight =
                    (constraints.maxHeight - padding * 2).clamp(0.0, double.infinity);
                final widthToFitHeight =
                    cardHeight * aspectRatio * columns +
                        spacing * (columns - 1) +
                        padding * 2;
                final gridWidth =
                    widthToFitHeight < constraints.maxWidth
                        ? widthToFitHeight
                        : constraints.maxWidth;
                return Center(
                  child: SizedBox(
                    width: gridWidth,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(padding),
                      itemCount: children.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: aspectRatio,
                      ),
                      itemBuilder: (_, index) {
                        final doc = children[index];
                        final data = doc.data();
                        if (data['age'] == null ||
                            data['activityStars'] == null) {
                          firestore.backfillProfileFromProgress(
                              parentUid, doc.id);
                        }
                        return BouncyTap(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => ChildDetailPage(
                                parentUid: parentUid,
                                childId: doc.id,
                                summary: data,
                                firestore: firestore,
                              ),
                            ),
                          ),
                          child: _ChildProgressCard(data: data),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
}

Future<void> _deleteAccount(
  BuildContext context,
  AuthService auth,
  ParentGateService gateService,
) async {
  final passwordController = TextEditingController();
  final password = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Verify your password'),
      content: TextField(
        controller: passwordController,
        obscureText: true,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Password'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, passwordController.text),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
  passwordController.dispose();
  if (password == null || !context.mounted) return;

  try {
    await auth.reauthenticate(password);
  } on FirebaseAuthException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Password check failed.')),
      );
    }
    return;
  }
  if (!context.mounted) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete account and all data?'),
      content: const SingleChildScrollView(
        child: Text(
          'This permanently deletes your account, all learner profiles and '
          'their learning progress. This cannot be undone.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Delete everything'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await auth.deleteAccountAndData();
    gateService.clearVerificationWindow();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => LoginPage(auth: auth)),
        (_) => false,
      );
    }
  } on FirebaseAuthException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to delete account.')),
      );
    }
  } on FirebaseException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete all data: ${error.message}')),
      );
    }
  }
}

class _ChildProgressCard extends StatelessWidget {
  const _ChildProgressCard({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final name = data['name'] as String? ?? 'Little Learner';
    final avatar = data['avatar'] as String? ?? '🧒';
    final age = _number(data['age']);
    final points = _number(data['points']);
    final daysLearned = UserProgress.fromJson({
      'dailyStats': data['dailyStats'],
    }).daysLearned;
    final totalQuestions = _number(data['totalQuestions']);
    final correctAnswers = _number(data['correctAnswers']);
    final accuracy =
        totalQuestions == 0 ? 0.0 : correctAnswers / totalQuestions;
    final activityStars =
        Map<String, dynamic>.from(data['activityStars'] as Map? ?? {});
    final totalActivities = worldCatalogs.values.fold<int>(
      0,
      (sum, catalog) => sum + catalog.activities.length,
    );
    final completedActivities = worldCatalogs.values
        .expand((catalog) => catalog.activities)
        .where((activity) => _number(activityStars[activity.id]) > 0)
        .length;
    final progress =
        totalActivities == 0 ? 0.0 : completedActivities / totalActivities;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE1ED), Color(0xFFFFF9F4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(18),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFFFD166),
                    child: Text(avatar, style: const TextStyle(fontSize: 30)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            name,
                            maxLines: 1,
                            softWrap: false,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (age > 0)
                          Text(
                            '$age years old',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.child_care_rounded,
                    color: Color(0xFFFF6FA5),
                    size: 28,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      icon: Icons.star_rounded,
                      value: '$points',
                      label: 'Points',
                      color: const Color(0xFFFFB703),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Stat(
                      icon: Icons.calendar_month_rounded,
                      value: '$daysLearned',
                      label: 'Days played',
                      color: const Color(0xFF4ECDC4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _Stat(
                      icon: Icons.check_circle_rounded,
                      value: totalQuestions == 0
                          ? '—'
                          : '${(accuracy * 100).round()}%',
                      label: 'Correct',
                      color: const Color(0xFF4ECDC4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // A quick "which worlds has this child tried" row — the
              // simplest way to show more than a single overall bar without
              // needing a separate detail screen.
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final module in learningModules)
                    _WorldBadge(
                      module: module,
                      activitiesCompleted: worldCatalogs[module.id]!
                          .activities
                          .where((activity) =>
                              _number(activityStars[activity.id]) > 0)
                          .length,
                      totalActivities:
                          worldCatalogs[module.id]!.activities.length,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 9,
                        color: const Color(0xFFFF6FA5),
                        backgroundColor:
                            const Color(0xFFFF6FA5).withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Tap for charts & details ›',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFF6FA5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _number(Object? value) => value is num ? value.toInt() : 0;
}

/// A small pill showing how many activities a child has completed in a world.
class _WorldBadge extends StatelessWidget {
  const _WorldBadge({
    required this.module,
    required this.activitiesCompleted,
    required this.totalActivities,
  });
  final LearningModule module;
  final int activitiesCompleted;
  final int totalActivities;

  @override
  Widget build(BuildContext context) {
    final tried = activitiesCompleted > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tried
            ? module.color.withValues(alpha: 0.15)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(module.icon,
              size: 16, color: tried ? module.color : Colors.black38),
          const SizedBox(width: 5),
          Text(
            '$activitiesCompleted / $totalActivities',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: tried ? module.color : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 4),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
      ],
    );
  }
}
