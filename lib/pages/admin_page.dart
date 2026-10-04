import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/activities.dart';
import '../models/learning.dart';
import '../services/accessibility_settings.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/narration_service.dart';
import '../services/parent_gate_service.dart';
import '../widgets/bouncy_tap.dart';
import 'auth_pages.dart';
import 'child_detail_page.dart';
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
        body: Column(
          children: [
            const _VoiceStatusRow(),
            const _ColorFriendlyModeRow(),
            _GrownUpLockSection(service: gateService),
            Expanded(
              child: StreamBuilder(
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
                      return GridView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: children.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          // Shorter (taller-relative-to-width) than before: the
                          // card now also shows age, accuracy and a per-world
                          // row, so it needs more vertical room to avoid
                          // clipping its own content.
                          childAspectRatio: columns == 2 ? 1.15 : 1.05,
                        ),
                        itemBuilder: (_, index) {
                          final doc = children[index];
                          final data = doc.data();
                          if (data['age'] == null ||
                              data['activityStars'] == null) {
                            // Fire-and-forget: this child's profile predates the
                            // age/activity sync, so pull it from saved progress.
                            // The stream picks up the write automatically.
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
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      );
}

class _GrownUpLockSection extends StatefulWidget {
  const _GrownUpLockSection({required this.service});

  final ParentGateService service;

  @override
  State<_GrownUpLockSection> createState() => _GrownUpLockSectionState();
}

class _GrownUpLockSectionState extends State<_GrownUpLockSection> {
  late Future<ParentLockMethod?> _method;
  late Future<bool> _phoneSupported;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _method = widget.service.selectedMethod;
    _phoneSupported = widget.service.canUsePhoneUnlock;
  }

  Future<void> _showResult(String message) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _usePhone() async {
    try {
      final changed = await widget.service.usePhoneUnlock();
      if (!mounted) return;
      if (changed) {
        setState(_refresh);
      } else {
        await _showResult('Set up a phone screen lock before choosing this.');
      }
    } catch (error) {
      await _showResult('Could not change the grown-up lock: $error');
    }
  }

  Future<void> _usePin() async {
    try {
      final changed = await widget.service.usePin(context);
      if (!mounted || !changed) return;
      setState(_refresh);
    } catch (error) {
      await _showResult('Could not save the PIN: $error');
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Grown-up lock',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              FutureBuilder<ParentLockMethod?>(
                future: _method,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Current method: Could not load');
                  }
                  if (!snapshot.hasData) {
                    return const Text('Current method: Loading...');
                  }
                  final label = switch (snapshot.data) {
                    ParentLockMethod.phone => 'Phone unlock',
                    ParentLockMethod.pin => '4-digit PIN',
                    _ => 'Not set up',
                  };
                  return Text('Current method: $label');
                },
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  FutureBuilder<bool>(
                    future: _phoneSupported,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text(
                          'Phone unlock is unavailable: ${snapshot.error}',
                        );
                      }
                      return OutlinedButton.icon(
                        onPressed: snapshot.data == true ? _usePhone : null,
                        icon: const Icon(Icons.fingerprint_rounded),
                        label: const Text('Use phone unlock'),
                      );
                    },
                  ),
                  OutlinedButton.icon(
                    onPressed: _usePin,
                    icon: const Icon(Icons.dialpad_rounded),
                    label: const Text('Use a 4-digit PIN'),
                  ),
                  TextButton(
                    onPressed: _usePin,
                    child: const Text('Change PIN'),
                  ),
                ],
              ),
            ],
          ),
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
      content: const Text(
        'This permanently deletes your account, all learner profiles and '
        'their learning progress. This cannot be undone.',
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

class _VoiceStatusRow extends StatelessWidget {
  const _VoiceStatusRow();

  @override
  Widget build(BuildContext context) {
    final voiceAvailable = NarrationService.instance.voiceAvailable;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Icon(
            voiceAvailable ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            color: voiceAvailable ? Colors.green : Colors.redAccent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Voice: ${voiceAvailable ? 'Ready' : 'Not available'}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          OutlinedButton.icon(
            onPressed: voiceAvailable
                ? () => NarrationService.instance
                    .speak('This is TinyMind. Can you hear me?')
                : null,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Play test voice'),
          ),
        ],
      ),
    );
  }
}

class _ColorFriendlyModeRow extends StatefulWidget {
  const _ColorFriendlyModeRow();

  @override
  State<_ColorFriendlyModeRow> createState() => _ColorFriendlyModeRowState();
}

class _ColorFriendlyModeRowState extends State<_ColorFriendlyModeRow> {
  bool _saving = false;

  Future<void> _save(AccessibilitySettings settings, bool enabled) async {
    setState(() => _saving = true);
    try {
      await settings.setColorFriendlyMode(enabled);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save setting: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AccessibilitySettingsScope.of(context);
    return SwitchListTile(
      title: const Text('Color-friendly mode'),
      subtitle: const Text(
        'Adds patterns and names to colors for children '
        'who have trouble telling colors apart.',
      ),
      value: settings.colorFriendlyMode,
      onChanged: _saving ? null : (enabled) => _save(settings, enabled),
    );
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
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
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
        Icon(icon, color: color, size: 23),
        const SizedBox(width: 5),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        const SizedBox(width: 4),
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
