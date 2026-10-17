import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/activities.dart';
import '../models/learning.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/parent_gate_service.dart';
import '../services/progress_store.dart';
import '../widgets/bouncy_tap.dart';
import '../widgets/emoji_glyph.dart';
import 'auth_pages.dart';
import 'child_detail_page.dart';
import 'parent_settings_page.dart';
import 'privacy_policy_page.dart';

enum _VerifyEmailChoice { send, check, verified }

const emailVerifiedAutomaticallyText = 'Your email is verified. Thank you!';

/// Checks whether the phone can reach the internet. Tests replace it, since
/// they cannot make real lookups.
@visibleForTesting
Future<bool> Function() checkInternetConnection = _lookUpInternet;

Future<bool> _lookUpInternet() async {
  try {
    final result = await InternetAddress.lookup('google.com')
        .timeout(const Duration(seconds: 3));
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}

class AdminPage extends StatefulWidget {
  AdminPage({
    FirestoreService? firestore,
    AuthService? auth,
    ParentGateService? gateService,
    this.store,
    super.key,
  })  : firestore = firestore ?? FirestoreService(),
        auth = auth ?? AuthService(),
        gateService = gateService ?? ParentGateService.instance;
  final FirestoreService firestore;
  final AuthService auth;
  final ParentGateService gateService;
  final ProgressStore? store;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with WidgetsBindingObserver {
  FirestoreService get firestore => widget.firestore;
  AuthService get auth => widget.auth;
  ParentGateService get gateService => widget.gateService;

  Stream<QuerySnapshot<Map<String, dynamic>>>? _childrenStream;
  String? _streamUid;
  int _attempt = 0;

  Stream<QuerySnapshot<Map<String, dynamic>>> _streamFor(String uid) {
    if (_childrenStream == null || _streamUid != uid) {
      _streamUid = uid;
      _childrenStream = firestore.watchChildren(uid);
    }
    return _childrenStream!;
  }

  void _retry() => setState(() {
        _childrenStream = null;
        _attempt++;
      });

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The parent may have opened the verification link in another app.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_needsEmailVerification) return;
    auth.refreshEmailVerified().then((_) {
      if (mounted) setState(() {});
    }, onError: (_) {});
  }

  Future<void> _push(Widget page) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => page),
    );
    // Linking an email keeps the uid, so only refresh.
    if (mounted) setState(() {});
  }

  Future<void> _openSettings() => _push(
        ParentSettingsPage(
          gateService: gateService,
          auth: auth,
          store: widget.store,
          firestore: firestore,
        ),
      );

  bool get _needsEmailVerification =>
      auth.hasEmailBackup && !auth.isEmailVerified;

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _verifyEmail() async {
    final choice = await showDialog<_VerifyEmailChoice>(
      context: context,
      builder: (dialogContext) => _EmailVerifiedWatcher(
        auth: auth,
        onVerified: () =>
            Navigator.pop(dialogContext, _VerifyEmailChoice.verified),
        child: AlertDialog(
          title: const Text('Verify my email'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We will send a verification link to '
                  '${auth.currentUser?.email ?? 'your email'}.',
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, _VerifyEmailChoice.check),
                  child: const Text('I have verified it'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, _VerifyEmailChoice.send),
              child: const Text('Send link'),
            ),
          ],
        ),
      ),
    );
    if (choice == _VerifyEmailChoice.verified) {
      _showMessage(emailVerifiedAutomaticallyText);
      if (mounted) setState(() {});
    } else if (choice == _VerifyEmailChoice.send) {
      try {
        await auth.sendVerificationEmail();
        _showMessage(verificationLinkSentText);
      } catch (_) {
        _showMessage('We could not send the link. Please try again later.');
      }
    } else if (choice == _VerifyEmailChoice.check) {
      bool verified;
      try {
        verified = await auth.refreshEmailVerified();
      } catch (_) {
        verified = false;
      }
      _showMessage(
        verified
            ? 'Email verified. Thank you!'
            : 'Not verified yet. Please open the link in the email.',
      );
      if (mounted) setState(() {});
    }
  }

  /// Signing out of an unverified email account would lock the parent out,
  /// because LoginPage refuses unverified emails.
  Future<void> _askToVerifyBeforeSignOut() async {
    var verified = false;
    final verifyNow = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _EmailVerifiedWatcher(
        auth: auth,
        onVerified: () {
          verified = true;
          Navigator.pop(dialogContext);
        },
        child: AlertDialog(
          content: const Text(
            'Please verify your email first. Otherwise you will not be able '
            'to sign back in.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('OK'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Verify now'),
            ),
          ],
        ),
      ),
    );
    if (verified) {
      _showMessage(emailVerifiedAutomaticallyText);
      if (mounted) setState(() {});
    } else if (verifyNow == true && mounted) {
      await _verifyEmail();
    }
  }

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
              onPressed: _openSettings,
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle_rounded),
              tooltip: 'Account',
              onSelected: (value) async {
                if (value == 'change_password') {
                  await _push(ChangePasswordPage(auth: auth));
                } else if (value == 'sign_in_backup') {
                  await _push(
                    LoginPage(
                      auth: auth,
                      firestore: firestore,
                      store: widget.store,
                    ),
                  );
                } else if (value == 'verify_email') {
                  await _verifyEmail();
                } else if (value == 'sign_out') {
                  // Signing back in needs the internet, so do not sign out
                  // while offline.
                  if (!await checkInternetConnection()) {
                    _showMessage(
                      'Please connect to the internet before signing out.',
                    );
                    return;
                  }
                  if (!context.mounted) return;
                  if (_needsEmailVerification) {
                    // The link may have been opened since the page loaded.
                    bool verified;
                    try {
                      verified = await auth.refreshEmailVerified();
                    } catch (_) {
                      verified = false;
                    }
                    if (!context.mounted) return;
                    if (!verified) {
                      await _askToVerifyBeforeSignOut();
                      return;
                    }
                  }
                  final shouldSignOut = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('Sign out?'),
                      content: const Text(
                        'This phone will start fresh. You can sign back in '
                        'with the same account to get your children back.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(dialogContext, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              Navigator.pop(dialogContext, true),
                          child: const Text('Sign out'),
                        ),
                      ],
                    ),
                  );
                  if (shouldSignOut != true) return;
                  await auth.signOut();
                  if (context.mounted) {
                    await restartToStartup(
                      context,
                      store: widget.store,
                      auth: auth,
                      firestore: firestore,
                    );
                  }
                } else if (value == 'privacy_policy') {
                  await openPrivacyPolicy(context);
                } else if (value == 'delete_account') {
                  await _deleteAccount(
                    context,
                    auth,
                    gateService,
                    store: widget.store,
                    firestore: firestore,
                  );
                  if (mounted) setState(() {});
                }
              },
              itemBuilder: (context) => [
                if (auth.hasEmailBackup)
                  const PopupMenuItem(
                    value: 'change_password',
                    child: Text('Change password'),
                  ),
                if (_needsEmailVerification)
                  const PopupMenuItem(
                    value: 'verify_email',
                    child: Text('Verify my email'),
                  ),
                if (auth.isAnonymous)
                  const PopupMenuItem(
                    value: 'sign_in_backup',
                    child: Text('I already have a backup (sign in)'),
                  ),
                if (!auth.isAnonymous)
                  const PopupMenuItem(
                    value: 'sign_out',
                    child: Text('Sign out'),
                  ),
                const PopupMenuItem(
                  value: 'privacy_policy',
                  child: Text('Privacy Policy'),
                ),
                const PopupMenuItem(
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
            _AnonymousBackupBanner(auth: auth, onOpenSettings: _openSettings),
            Expanded(
              child: StreamBuilder<User?>(
                stream: auth.userChanges,
                builder: (context, authSnapshot) {
                  final uid = auth.currentUser?.uid;
                  if (uid == null) return _retryState();
                  return StreamBuilder(
                    key: ValueKey('$uid-$_attempt'),
                    stream: _streamFor(uid),
                    builder: (context, snapshot) {
            if (snapshot.hasError) return _retryState();
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
                          firestore.backfillProfileFromProgress(uid, doc.id);
                        }
                        return BouncyTap(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => ChildDetailPage(
                                parentUid: uid,
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
                  );
                },
              ),
            ),
          ],
        ),
      );

  Widget _retryState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Could not load children. Please try again.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _retry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}

/// Checks every 3 seconds, and when the app comes back to the front, whether
/// the parent has opened the verification link, and calls [onVerified] once
/// they have. The timer stops when the dialog closes.
class _EmailVerifiedWatcher extends StatefulWidget {
  const _EmailVerifiedWatcher({
    required this.auth,
    required this.onVerified,
    required this.child,
  });

  final AuthService auth;
  final VoidCallback onVerified;
  final Widget child;

  @override
  State<_EmailVerifiedWatcher> createState() => _EmailVerifiedWatcherState();
}

class _EmailVerifiedWatcherState extends State<_EmailVerifiedWatcher>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _checking = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _check());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    if (_checking || _done) return;
    _checking = true;
    bool verified;
    try {
      verified = await widget.auth.refreshEmailVerified();
    } catch (_) {
      verified = false;
    }
    _checking = false;
    if (!verified || _done || !mounted) return;
    _done = true;
    _timer?.cancel();
    widget.onVerified();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AnonymousBackupBanner extends StatefulWidget {
  const _AnonymousBackupBanner({
    required this.auth,
    required this.onOpenSettings,
  });

  final AuthService auth;

  /// Opens the settings page and refreshes the dashboard afterwards.
  final Future<void> Function() onOpenSettings;

  @override
  State<_AnonymousBackupBanner> createState() => _AnonymousBackupBannerState();
}

class _AnonymousBackupBannerState extends State<_AnonymousBackupBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) => StreamBuilder(
        stream: widget.auth.userChanges,
        builder: (context, snapshot) {
          final user = widget.auth.currentUser ?? snapshot.data;
          if (_dismissed || user?.isAnonymous != true) {
            return const SizedBox.shrink();
          }
          return Material(
            color: const Color(0xFFFFF0C2),
            child: ListTile(
              dense: true,
              title: const Text(
                'Your data is only on this phone. Tap to back up.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: widget.onOpenSettings,
              trailing: IconButton(
                tooltip: 'Dismiss backup reminder',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => setState(() => _dismissed = true),
              ),
            ),
          );
        },
      );
}

Future<void> _deleteAccount(
  BuildContext context,
  AuthService auth,
  ParentGateService gateService, {
  ProgressStore? store,
  FirestoreService? firestore,
}) async {
  if (auth.hasGoogleBackup && auth.hasEmailBackup) {
    // Google first; the password is the fallback.
    while (true) {
      try {
        await auth.reauthenticateWithGoogle();
        break;
      } catch (_) {}
      if (!context.mounted) return;
      final choice = await showGoogleFallbackDialog(context);
      if (!context.mounted) return;
      if (choice == GoogleFallbackChoice.tryGoogleAgain) continue;
      if (choice != GoogleFallbackChoice.usePassword) return;
      if (!await _reauthenticateWithPassword(context, auth)) return;
      break;
    }
  } else if (auth.hasEmailBackup) {
    if (!await _reauthenticateWithPassword(context, auth)) return;
  } else if (auth.hasGoogleBackup) {
    try {
      await auth.reauthenticateWithGoogle();
    } catch (error) {
      if (context.mounted) {
        final cancelled =
            error is FirebaseAuthException && error.code == 'cancelled';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              cancelled
                  ? 'Google sign-in was cancelled.'
                  : 'Google sign-in check failed. Please try again.',
            ),
          ),
        );
      }
      return;
    }
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
    if (context.mounted) {
      await restartToStartup(
        context,
        store: store,
        auth: auth,
        firestore: firestore,
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

/// Asks for the account password and re-authenticates with it. Returns
/// false when the parent cancels or the password is wrong.
Future<bool> _reauthenticateWithPassword(
  BuildContext context,
  AuthService auth,
) async {
  final password = await showDialog<String>(
    context: context,
    builder: (_) => const _VerifyPasswordDialog(),
  );
  if (password == null || !context.mounted) return false;

  try {
    await auth.reauthenticate(password);
    return true;
  } on FirebaseAuthException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Password check failed.')),
      );
    }
    return false;
  }
}

/// Owns its text controller, so the controller lives until the dialog has
/// finished closing.
class _VerifyPasswordDialog extends StatefulWidget {
  const _VerifyPasswordDialog();

  @override
  State<_VerifyPasswordDialog> createState() => _VerifyPasswordDialogState();
}

class _VerifyPasswordDialogState extends State<_VerifyPasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        scrollable: true,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        titlePadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
        title: const Text(
          'Verify your password',
          style: TextStyle(fontSize: 20),
        ),
        content: TextField(
          controller: _controller,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            isDense: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _controller.text),
            child: const Text('Continue'),
          ),
        ],
      );
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
      (int total, catalog) => total + catalog.activities.length,
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
                    child: EmojiGlyph(avatar, 30),
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
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
