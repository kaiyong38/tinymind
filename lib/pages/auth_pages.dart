import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinymind/app_info.dart';

import '../services/auth_service.dart';
import '../services/child_transfer.dart';
import '../services/firestore_service.dart';
import '../services/progress_store.dart';
import '../widgets/bouncy_tap.dart';
import '../widgets/emoji_glyph.dart';
import '../theme/tinymind_colors.dart';
import 'privacy_policy_page.dart';
import 'parent_gate_pages.dart';

/// Throws away every screen and starts again at a fresh [StartupGatePage].
/// Use it after the account changes so no page keeps using the old uid.
/// Works from any depth of the navigator stack.
Future<void> restartToStartup(
  BuildContext context, {
  ProgressStore? store,
  AuthService? auth,
  FirestoreService? firestore,
  String? message,
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final session = store ?? ProgressStore();
  await session.clearSelection();
  navigator.pushAndRemoveUntil(
    MaterialPageRoute<void>(
      builder: (_) => StartupGatePage(
        store: session,
        auth: auth,
        firestore: firestore,
      ),
    ),
    (route) => false,
  );
  if (message != null) {
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _BringChoice { bring, skip }

Future<_BringChoice?> _askBringChoice(BuildContext context) =>
    showDialog<_BringChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Bring this phone's children into your account?"),
        content: const SingleChildScrollView(
          child: Text(
            'Children saved on this phone can be copied into the account '
            'you are signing in to. Your account\'s own children are not '
            'changed.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _BringChoice.skip),
            child: const Text("Don't bring them"),
          ),
          FilledButton(
            autofocus: true,
            onPressed: () => Navigator.pop(context, _BringChoice.bring),
            child: const Text('Bring them'),
          ),
        ],
      ),
    );

Future<bool?> _confirmDeleteLocalChildren(BuildContext context) =>
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete this phone's children?"),
        content: const SingleChildScrollView(
          child: Text(
            'These children and their progress will be deleted and cannot '
            'be recovered. This only affects the children saved on this '
            'phone before you signed in. Your account\'s own children are '
            'not changed.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Go back'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete them'),
          ),
        ],
      ),
    );

/// Deletes the anonymous account's data while still signed in as it (the
/// rules allow that). Failures are ignored: leftover data is better than a
/// parent who cannot sign in. Remote steps time out because Firestore
/// writes never complete while offline; queued writes left behind fail on
/// permissions once the anonymous account is gone.
Future<void> _deleteAnonymousData(
  FirestoreService firestore,
  User anonymous,
  String oldUid,
  ProgressStore store,
) async {
  if (!anonymous.isAnonymous || anonymous.uid != oldUid) return;
  try {
    await firestore
        .deleteParentData(oldUid)
        .timeout(const Duration(seconds: 5));
  } catch (_) {}
  try {
    await store.removePendingProgress(oldUid);
  } catch (_) {}
  try {
    await anonymous.delete().timeout(const Duration(seconds: 5));
  } catch (_) {}
}

/// Signs in to an existing backup account. When this phone's anonymous
/// account has children, the parent chooses to bring them along (copied in
/// as new children) or delete them first. For an anonymous account [verify]
/// always runs first, before any dialog, so wrong details or an unverified
/// email never delete or copy anything. [onSignedIn] runs after sign-in,
/// before the app restarts. Errors are left for the caller to show.
Future<void> _switchAccountFromAnonymous({
  required BuildContext context,
  required AuthService auth,
  required FirestoreService firestore,
  required ProgressStore store,
  required Future<UserCredential> Function() signIn,
  Future<void> Function()? verify,
  Future<void> Function()? onSignedIn,
}) async {
  final current = auth.currentUser;
  final transfer = ChildTransfer(firestore: firestore, store: store);
  final oldUid = current?.uid;
  List<TransferableChild>? toBring;
  var deleteLocalChildren = false;
  if (current?.isAnonymous == true) {
    if (verify != null) {
      await verify();
      if (!context.mounted) return;
    }
    final childCount = await firestore.countChildren(current!.uid);
    if (!context.mounted) return;
    if (childCount > 0) {
      _BringChoice? choice;
      while (true) {
        choice = await _askBringChoice(context);
        if (!context.mounted) return;
        if (choice != _BringChoice.skip) break;
        if (await _confirmDeleteLocalChildren(context) == true) break;
        if (!context.mounted) return;
      }
      if (choice == null) return;
      if (choice == _BringChoice.bring) {
        toBring = await transfer.collect(current.uid);
      } else {
        deleteLocalChildren = true;
      }
    }
  }
  if (deleteLocalChildren &&
      current != null &&
      current.isAnonymous &&
      oldUid != null &&
      auth.currentUser?.uid == oldUid) {
    auth.isSwitchingAccount = true;
    try {
      await _deleteAnonymousData(firestore, current, oldUid, store);
      await signIn();
    } finally {
      auth.isSwitchingAccount = false;
    }
  } else {
    await signIn();
  }
  final newUid = auth.currentUser?.uid;
  if (toBring != null &&
      toBring.isNotEmpty &&
      oldUid != null &&
      newUid != null &&
      newUid != oldUid) {
    await transfer.copyInto(newUid, oldUid, toBring);
  }
  if (onSignedIn != null) await onSignedIn();
  if (context.mounted) {
    await restartToStartup(
      context,
      store: store,
      auth: auth,
      firestore: firestore,
      message: 'Welcome back! Your children are ready.',
    );
  }
}

class StartupGatePage extends StatefulWidget {
  const StartupGatePage({
    required this.store,
    this.auth,
    this.firestore,
    super.key,
  });

  final ProgressStore store;
  final AuthService? auth;
  final FirestoreService? firestore;

  @override
  State<StartupGatePage> createState() => _StartupGatePageState();
}

class _StartupGatePageState extends State<StartupGatePage> {
  late final AuthService _auth = widget.auth ?? AuthService();
  Timer? _retryTimer;
  bool _signingIn = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _retryTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_failed || _auth.currentUser == null) _signIn();
    });
    _signIn();
  }

  Future<void> _signIn() async {
    if (_signingIn || _auth.currentUser != null || _auth.isSwitchingAccount) {
      return;
    }
    setState(() {
      _signingIn = true;
      _failed = false;
    });
    try {
      await _auth.signInAnonymously();
      if (mounted) setState(() => _failed = false);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _auth.authStateChanges,
      builder: (context, snapshot) {
        final user = _auth.currentUser ?? snapshot.data;
        if (user != null) {
          return ChildPickerPage(
            key: ValueKey(user.uid),
            store: widget.store,
            parentUid: user.uid,
            auth: _auth,
            firestore: widget.firestore,
          );
        }
        if (!_signingIn && !_failed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _signIn();
          });
        }
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _failed
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'We could not get ready just yet. Please try again.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: _signingIn ? null : _signIn,
                            child: const Text('Retry'),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Getting TinyMind ready...'),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class WelcomePage extends StatelessWidget {
  WelcomePage({
    required this.store,
    AuthService? auth,
    super.key,
  }) : auth = auth ?? AuthService();

  final ProgressStore store;
  final AuthService auth;

  Future<void> _handleParentTap(BuildContext context) => openParentArea(context, auth: auth);

  Future<void> _handleChildTap(BuildContext context) async {
    if (auth.currentUser == null) return;
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChildPickerPage(
          store: store,
          parentUid: auth.currentUser!.uid,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape = constraints.maxWidth > constraints.maxHeight;
            final compact = landscape || constraints.maxHeight < 560;
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Padding(
                      padding: EdgeInsets.all(compact ? 12 : 20),
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (landscape)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const EmojiGlyph('🌈', 30),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Welcome to TinyMind',
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFC94F86),
                                  ),
                                ),
                                Text(
                                  'Who is learning today?',
                                  style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ],
                        )
                      else ...[
                        const EmojiGlyph('🌈', 34),
                        const SizedBox(height: 4),
                        const Text(
                          'Welcome to TinyMind',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFC94F86),
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Who is learning today?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ],
                      SizedBox(height: compact ? 16 : 20),
                      if (landscape)
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _RoleButton(
                                  icon: Icons.family_restroom_rounded,
                                  title: 'Parent',
                                  subtitle: 'Add learners, view progress',
                                  color: TinyMindColors.primary,
                                  compact: true,
                                  onPressed: () => _handleParentTap(context),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _RoleButton(
                                  icon: Icons.child_care_rounded,
                                  title: 'Child',
                                  subtitle: 'Choose your picture to play',
                                  color: TinyMindColors.mint,
                                  compact: true,
                                  onPressed: () => _handleChildTap(context),
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        _RoleButton(
                          icon: Icons.family_restroom_rounded,
                          title: 'Parent',
                          subtitle: 'Add learners, view progress',
                          color: TinyMindColors.primary,
                          compact: compact,
                          onPressed: () => _handleParentTap(context),
                        ),
                        SizedBox(height: compact ? 8 : 10),
                        _RoleButton(
                          icon: Icons.child_care_rounded,
                          title: 'Child',
                          subtitle: 'Choose your picture to play',
                          color: TinyMindColors.mint,
                          compact: compact,
                          onPressed: () => _handleChildTap(context),
                        ),
                      ],
                      SizedBox(height: compact ? 12 : 16),
                      const Text(
                        'Choose a picture and start playing!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onPressed,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: BouncyTap(
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 10 : 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: compact ? 20 : 24,
                  backgroundColor: color,
                  child: Icon(icon, color: Colors.white, size: compact ? 22 : 26),
                ),
                SizedBox(width: compact ? 10 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: compact ? 1 : 3),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: compact ? 12 : 14),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded,
                    color: color, size: compact ? 22 : 26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  LoginPage({
    super.key,
    AuthService? auth,
    FirestoreService? firestore,
    this.store,
  })  : auth = auth ?? AuthService(),
        firestore = firestore ?? FirestoreService();

  final AuthService auth;
  final FirestoreService firestore;
  final ProgressStore? store;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _rememberedEmailKey = 'tinymind_remembered_email';

  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  String? _success;
  bool _busy = false;
  bool _rememberMe = true;
  bool _emailNotVerified = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  Future<void> _loadRememberedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_rememberedEmailKey);
    if (savedEmail != null && mounted) {
      setState(() => _email.text = savedEmail);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
      _emailNotVerified = false;
    });
    try {
      await _switchAccountFromAnonymous(
        context: context,
        auth: widget.auth,
        firestore: widget.firestore,
        store: widget.store ?? ProgressStore(),
        // Check the password first so a typo never deletes anything.
        verify: () => widget.auth.verifyPassword(_email.text, _password.text),
        signIn: () => widget.auth.signIn(_email.text, _password.text),
        onSignedIn: () async {
          final prefs = await SharedPreferences.getInstance();
          if (_rememberMe) {
            await prefs.setString(_rememberedEmailKey, _email.text.trim());
          } else {
            await prefs.remove(_rememberedEmailKey);
          }
        },
      );
    } on EmailNotVerifiedException {
      if (mounted) {
        setState(() {
          _error = _emailNotVerifiedText;
          _emailNotVerified = true;
        });
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _error = _friendlyAuthError(error));
      }
    } on FirebaseException {
      if (mounted) {
        setState(() => _error =
            'We could not check this device yet. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The parent cannot sign in until the email is verified, so the link is
  /// sent from a throwaway sign-in instead of the current account.
  Future<void> _resendVerification() async {
    setState(() {
      _busy = true;
      _success = null;
    });
    try {
      await widget.auth.resendVerificationFor(_email.text, _password.text);
      if (mounted) {
        setState(() {
          _error = null;
          _emailNotVerified = false;
          _success = verificationLinkSentText;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = _verificationSendFailedText);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
      _emailNotVerified = false;
    });
    try {
      final credential = await widget.auth.pickGoogleCredential();
      if (credential == null || !mounted) return;
      await _switchAccountFromAnonymous(
        context: context,
        auth: widget.auth,
        firestore: widget.firestore,
        store: widget.store ?? ProgressStore(),
        signIn: () => widget.auth.signInWithCredential(credential),
      );
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _friendlyGoogleError(error));
    } catch (_) {
      if (mounted) setState(() => _error = _googleFailedText);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _ParentAuthScaffold(
        title: 'Welcome back',
        subtitle: 'Sign in to manage your TinyMind learner.',
        action: 'Log in',
        busy: _busy,
        error: _error,
        success: _success,
        errorAction: _emailNotVerified
            ? TextButton(
                onPressed: _busy ? null : _resendVerification,
                child: const Text('Send the link again'),
              )
            : null,
        fields: [_email, _password],
        hints: const ['Email address', 'Password'],
        onSubmit: _submit,
        footer: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CheckboxListTile(
              value: _rememberMe,
              onChanged: (value) =>
                  setState(() => _rememberMe = value ?? true),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: const Text('Remember my email on this device'),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ForgotPasswordPage(auth: widget.auth),
                ),
              ),
              child: const Text('Forgot password?'),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => RegisterPage(
                    auth: widget.auth,
                    firestore: widget.firestore,
                    store: widget.store,
                  ),
                ),
              ),
              child: const Text('Create a parent account'),
            ),
            TextButton(
              onPressed: () => openPrivacyPolicy(context),
              child: const Text('Privacy Policy'),
            ),
            _GoogleFooter(
              onPressed: _busy ? null : _continueWithGoogle,
            ),
          ],
        ),
      );
}

class RegisterPage extends StatefulWidget {
  RegisterPage({
    super.key,
    AuthService? auth,
    this.firestore,
    this.store,
  }) : auth = auth ?? AuthService();

  final AuthService auth;
  final FirestoreService? firestore;
  final ProgressStore? store;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _email = TextEditingController();
  final _confirmEmail = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _acceptedPrivacyPolicy = false;

  @override
  void dispose() {
    _email.dispose();
    _confirmEmail.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_acceptedPrivacyPolicy) {
      setState(() => _error = _agreePrivacyPolicyText);
      return;
    }
    if (_email.text.trim().isEmpty || _password.text.length < 6) {
      setState(() => _error = 'Use an email and a password of 6+ characters.');
      return;
    }
    if (_email.text.trim().toLowerCase() !=
        _confirmEmail.text.trim().toLowerCase()) {
      setState(() => _error = 'The two emails do not match.');
      return;
    }
    if (_password.text != _confirmPassword.text) {
      setState(() => _error = 'The passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.linkEmail(_email.text, _password.text);
      final email = _email.text.trim();
      var sent = false;
      try {
        await widget.auth.sendVerificationEmail();
        sent = true;
      } catch (_) {
        // The backup is saved; the link can be sent again from the menu.
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(
            sent
                ? 'Backup saved. We sent a verification link to $email. '
                    'Please open it to finish. Check your spam folder too.'
                : 'Backup saved. We could not send the verification link '
                    "yet. Use 'Verify my email' in the account menu.",
          ),
        ),
      );
      Navigator.pop(context, true);
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _error = _friendlyAuthError(error));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _continueWithGoogle() async {
    if (!_acceptedPrivacyPolicy) {
      setState(() => _error = _agreePrivacyPolicyText);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final credential = await widget.auth.pickGoogleCredential();
      if (credential == null || !mounted) return;
      final result = await widget.auth.linkGoogle(credential);
      if (!mounted) return;
      if (result.status == GoogleLinkStatus.linked) {
        Navigator.pop(context, true);
        return;
      }
      // This Google account already has its own backup: sign in to it.
      final backup = result.credential ?? credential;
      await _switchAccountFromAnonymous(
        context: context,
        auth: widget.auth,
        firestore: widget.firestore ?? FirestoreService(),
        store: widget.store ?? ProgressStore(),
        signIn: () => widget.auth.signInWithCredential(backup),
      );
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = _friendlyGoogleError(error));
    } catch (_) {
      if (mounted) setState(() => _error = _googleFailedText);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _ParentAuthScaffold(
        title: 'Back up my data',
        subtitle: 'Link an email to keep your children’s progress safe.',
        action: 'Back up my data',
        busy: _busy,
        error: _error,
        fields: [_email, _confirmEmail, _password, _confirmPassword],
        hints: const [
          'Email address',
          'Confirm email',
          'Password',
          'Confirm password',
        ],
        onSubmit: _submit,
        beforeSubmit: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              _registerEmailNote,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _acceptedPrivacyPolicy,
              onChanged: _busy
                  ? null
                  : (value) =>
                      setState(() => _acceptedPrivacyPolicy = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'I am a parent or guardian and I agree to the Privacy Policy',
              ),
            ),
            TextButton(
              onPressed: () => openPrivacyPolicy(context),
              child: const Text('Privacy Policy'),
            ),
          ],
        ),
        footer: _GoogleFooter(
          onPressed: _busy ? null : _continueWithGoogle,
        ),
      );
}

const _registerEmailNote = 'Please use a real email address, or you will '
    'not be able to reset your password. Check your spam folder for the '
    'verification link.';

const _agreePrivacyPolicyText = 'Please agree to the Privacy Policy first.';

const _emailNotVerifiedText = 'This email is not verified yet. Open the '
    'verification link we sent to this email, then try again.';

const verificationLinkSentText =
    'Verification link sent. Check your inbox and spam folder.';

const _verificationSendFailedText =
    'We could not send the link. Please try again later.';

const _googleFailedText =
    'We could not finish signing in with Google. Please try again.';

String _friendlyGoogleError(FirebaseAuthException error) => switch (error.code) {
      'account-exists-with-different-credential' || 'email-already-in-use' =>
        "This email already has an email backup. Use 'I already have a backup' "
            'with your email and password.',
      _ => _googleFailedText,
    };

/// The "or" divider and the secondary "Continue with Google" button shown at
/// the bottom of the email forms.
class _GoogleFooter extends StatelessWidget {
  const _GoogleFooter({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 18),
          const Row(
            children: [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.account_circle),
            label: const Text('Continue with Google'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      );
}

String _friendlyAuthError(FirebaseAuthException error) => switch (error.code) {
      'email-already-in-use' =>
        "This email already has a backup. Use 'I already have a backup' instead.",
      'weak-password' => 'Choose a stronger password with at least 6 characters.',
      'invalid-email' => 'Please check the email address and try again.',
      'requires-recent-login' =>
        'Please sign in again before changing this account.',
      'wrong-password' || 'invalid-credential' =>
        'That email and password do not match.',
      _ => 'We could not finish that. Please check your details and try again.',
    };

class ForgotPasswordPage extends StatefulWidget {
  ForgotPasswordPage({super.key, AuthService? auth})
      : auth = auth ?? AuthService();

  final AuthService auth;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _email = TextEditingController();
  String? _error;
  String? _success;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });
    try {
      await widget.auth.sendPasswordReset(_email.text);
      if (mounted) {
        setState(() => _success =
            "If that email has an account, we've sent a reset link — "
            'check your inbox (and spam folder).');
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _ParentAuthScaffold(
        title: 'Reset password',
        subtitle: 'We will send a secure reset link to your email.',
        action: 'Send reset link',
        fields: [_email],
        hints: const ['Email address'],
        error: _error,
        success: _success,
        busy: _busy,
        footer: const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "We'll email a reset link. Please check your Spam folder too.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              SizedBox(height: 4),
              Text(
                'Need help? Contact ${AppInfo.supportEmail}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
        onSubmit: _submit,
      );
}

class ChangePasswordPage extends StatefulWidget {
  ChangePasswordPage({super.key, AuthService? auth})
      : auth = auth ?? AuthService();

  final AuthService auth;

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_currentPassword.text.isEmpty || _newPassword.text.length < 6) {
      setState(() => _error =
          'Enter your current password and a new password of 6+ characters.');
      return;
    }
    if (_newPassword.text != _confirmPassword.text) {
      setState(() => _error = 'The new passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.auth.changePassword(
        currentPassword: _currentPassword.text,
        newPassword: _newPassword.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated.')),
        );
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _error = error.message ?? 'Unable to update password.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _ParentAuthScaffold(
        title: 'Change password',
        subtitle: 'Confirm your current password, then choose a new one.',
        action: 'Update password',
        busy: _busy,
        error: _error,
        fields: [_currentPassword, _newPassword, _confirmPassword],
        hints: const [
          'Current password',
          'New password',
          'Confirm new password',
        ],
        onSubmit: _submit,
      );
}

const childAvatarChoices = ['🧒', '👧', '🦊', '🐼', '🐸', '🦄', '🚀', '🌈'];
const childAgeChoices = [3, 4, 5, 6];

const nicknameErrorText =
    'Please enter a nickname of up to 20 characters with no spaces.';

class ChildProfilePage extends StatefulWidget {
  const ChildProfilePage({
    required this.store,
    required this.auth,
    this.firestore,
    super.key,
  });

  final ProgressStore store;
  final AuthService auth;
  final FirestoreService? firestore;

  @override
  State<ChildProfilePage> createState() => _ChildProfilePageState();
}

class _ChildProfilePageState extends State<ChildProfilePage> {
  final _name = TextEditingController();
  static const _avatars = childAvatarChoices;
  String _avatar = '🧒';
  int _age = 4;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!isValidNickname(_name.text)) {
      setState(() => _error = nicknameErrorText);
      return;
    }
    final parent = widget.auth.currentUser;
    if (parent == null) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => LoginPage(auth: widget.auth, store: widget.store),
        ),
      );
      if (mounted) setState(() {});
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Every save here is a NEW learner — always mint a fresh id rather
      // than reusing a cached one, otherwise a second child's profile
      // silently overwrites the first child's data under the same id.
      final childId =
          'child-${parent.uid}-${DateTime.now().microsecondsSinceEpoch}';
      final name = _name.text.trim();
      // A plain write that Firestore's local cache shows right away, so the
      // child appears in the picker even while offline.
      await (widget.firestore ?? FirestoreService()).createChildProfile(
        parent.uid,
        childId,
        name: name,
        avatar: _avatar,
        age: _age,
      );
      Future<void> saveProgress() async {
        widget.store.configureChild(parentUid: parent.uid, childId: childId);
        await widget.store.load();
        await widget.store.setChildProfile(
          name: _name.text,
          avatar: _avatar,
          age: _age,
        );
      }

      // Offline, the progress write is queued by the store; do not keep the
      // screen waiting for the network.
      final saving = saveProgress();
      unawaited(saving.then<void>((_) {}, onError: (Object _) {}));
      await saving.timeout(const Duration(seconds: 4), onTimeout: () {});
      if (mounted) Navigator.pop(context);
    } on FirebaseException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = widget.auth.currentUser != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Set up a learner')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  signedIn ? 'Add a new learner' : 'A grown-up goes first',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  signedIn
                      ? 'Choose an avatar and nickname for your child.'
                      : 'Please ask a parent to log in before setting up a child profile.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.black54),
                ),
                if (signedIn) ...[
                  const SizedBox(height: 24),
                  TextField(
                    controller: _name,
                    maxLength: 20,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(20),
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    ],
                    style: const TextStyle(fontSize: 18),
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Nickname',
                      helperText:
                          "Please use a nickname, not your child's real name.",
                      prefixIcon: Icon(Icons.person_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Choose an avatar',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _avatars.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      final avatar = _avatars[index];
                      final selected = avatar == _avatar;
                      return InkWell(
                        onTap: () => setState(() => _avatar = avatar),
                        borderRadius: BorderRadius.circular(18),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFFFFE1ED)
                                : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFFFF6FA5)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: EmojiGlyph(avatar, 40),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'How old is your child?',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'This picks the right level of questions — picture-matching '
                    'for younger learners, a little reading and adding for older ones.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: childAgeChoices.map((age) {
                      final selected = age == _age;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => setState(() => _age = age),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFFFE1ED)
                                    : Colors.black.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFFFF6FA5)
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                '$age',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: selected
                                      ? const Color(0xFFFF6FA5)
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: _busy ? null : _continue,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: Text(
                    _busy
                        ? 'Saving…'
                        : signedIn
                            ? 'Start learning'
                            : 'Parent login',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}

bool isValidNickname(String value) =>
    value.isNotEmpty && value.length <= 20 && !RegExp(r'\s').hasMatch(value);

class _ParentAuthScaffold extends StatelessWidget {
  const _ParentAuthScaffold({
    required this.title,
    required this.subtitle,
    required this.action,
    required this.fields,
    required this.hints,
    required this.onSubmit,
    this.error,
    this.errorAction,
    this.success,
    this.busy = false,
    this.beforeSubmit,
    this.footer,
  });

  final String title;
  final String subtitle;
  final String action;
  final List<TextEditingController> fields;
  final List<String> hints;
  final Future<void> Function() onSubmit;
  final String? error;

  /// Shown under [error], e.g. a button that fixes the problem.
  final Widget? errorAction;

  /// A confirmation message (shown in green, not red) — distinct from
  /// [error] so a successful "check your inbox" message never looks like
  /// a failure.
  final String? success;
  final bool busy;

  /// Shown between the text fields and the submit button, e.g. the
  /// Privacy Policy checkbox.
  final Widget? beforeSubmit;
  final Widget? footer;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    color: Color(0xFFFF6FA5),
                    size: 54,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, color: Colors.black54),
                  ),
                  const SizedBox(height: 28),
                  for (var i = 0; i < fields.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: TextField(
                        controller: fields[i],
                        obscureText:
                            hints[i].toLowerCase().contains('password'),
                        style: const TextStyle(fontSize: 18),
                        decoration: InputDecoration(
                          labelText: hints[i],
                          labelStyle: const TextStyle(fontSize: 17),
                          prefixIcon: Icon(
                            hints[i].toLowerCase().contains('email')
                                ? Icons.email_rounded
                                : Icons.lock_rounded,
                          ),
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                        ),
                      ),
                    ),
                  if (beforeSubmit != null) beforeSubmit!,
                  if (error != null)
                    Text(
                      error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                  if (error != null && errorAction != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: errorAction,
                    ),
                  if (success != null)
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            success!,
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: busy ? null : onSubmit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    child: Text(busy ? 'Please wait…' : action),
                  ),
                  if (footer != null) footer!,
                ],
              ),
            ),
          ),
        ),
      );
}
