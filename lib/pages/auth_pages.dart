import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tinymind/app_info.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/progress_store.dart';
import '../widgets/bouncy_tap.dart';
import '../widgets/emoji_glyph.dart';
import '../theme/tinymind_colors.dart';
import 'privacy_policy_page.dart';
import 'parent_gate_pages.dart';

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
      if (_failed) _signIn();
    });
    _signIn();
  }

  Future<void> _signIn() async {
    if (_signingIn || _auth.currentUser != null) return;
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
                                  title: 'Parent or teacher',
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
                          title: 'Parent or teacher',
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
  })  : auth = auth ?? AuthService(),
        firestore = firestore ?? FirestoreService();

  final AuthService auth;
  final FirestoreService firestore;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  static const _rememberedEmailKey = 'tinymind_remembered_email';

  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _rememberMe = true;

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
    });
    try {
      final current = widget.auth.currentUser;
      if (current?.isAnonymous == true) {
        final childCount = await widget.firestore.countChildren(current!.uid);
        if (!mounted) return;
        if (childCount > 0) {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Switch to your backup?'),
              content: const Text(
                'Children on this device will not be shown after signing in. '
                'They are not deleted.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Stay here'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Continue'),
                ),
              ],
            ),
          );
          if (confirmed != true) return;
        }
      }
      await widget.auth.signIn(_email.text, _password.text);
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString(_rememberedEmailKey, _email.text.trim());
      } else {
        await prefs.remove(_rememberedEmailKey);
      }
      if (mounted) Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) => _ParentAuthScaffold(
        title: 'Welcome back',
        subtitle: 'Sign in to manage your TinyMind learner.',
        action: 'Log in',
        busy: _busy,
        error: _error,
        fields: [_email, _password],
        hints: const ['Email address', 'Password'],
        onSubmit: _submit,
        footer: Column(
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
                  builder: (_) => RegisterPage(auth: widget.auth),
                ),
              ),
              child: const Text('Create a parent account'),
            ),
            TextButton(
              onPressed: () => openPrivacyPolicy(context),
              child: const Text('Privacy Policy'),
            ),
          ],
        ),
      );
}

class RegisterPage extends StatefulWidget {
  RegisterPage({super.key, AuthService? auth}) : auth = auth ?? AuthService();

  final AuthService auth;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _acceptedPrivacyPolicy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_acceptedPrivacyPolicy) {
      setState(() => _error =
          'Please agree to the Privacy Policy before linking an email.');
      return;
    }
    if (_email.text.trim().isEmpty || _password.text.length < 6) {
      setState(() => _error = 'Use an email and a password of 6+ characters.');
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
      if (mounted) Navigator.pop(context, true);
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _error = _friendlyAuthError(error));
      }
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
        fields: [_email, _password, _confirmPassword],
        hints: const ['Email address', 'Password', 'Confirm password'],
        onSubmit: _submit,
        footer: Column(
          children: [
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

class ChildProfilePage extends StatefulWidget {
  const ChildProfilePage({
    required this.store,
    required this.auth,
    super.key,
  });

  final ProgressStore store;
  final AuthService auth;

  @override
  State<ChildProfilePage> createState() => _ChildProfilePageState();
}

class _ChildProfilePageState extends State<ChildProfilePage> {
  final _name = TextEditingController();
  static const _avatars = ['🧒', '👧', '🦊', '🐼', '🐸', '🦄', '🚀', '🌈'];
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
      setState(() => _error =
          'Please enter a nickname of up to 20 characters with no spaces.');
      return;
    }
    final parent = widget.auth.currentUser;
    if (parent == null) {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => LoginPage(auth: widget.auth),
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
      widget.store.configureChild(parentUid: parent.uid, childId: childId);
      await widget.store.load();
      await widget.store.setChildProfile(
        name: _name.text,
        avatar: _avatar,
        age: _age,
      );
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
                      : 'Please ask a parent or teacher to log in before setting up a child profile.',
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
                    children: [3, 4, 5, 6].map((age) {
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
                            : 'Parent or teacher login',
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
    this.success,
    this.busy = false,
    this.footer,
  });

  final String title;
  final String subtitle;
  final String action;
  final List<TextEditingController> fields;
  final List<String> hints;
  final Future<void> Function() onSubmit;
  final String? error;

  /// A confirmation message (shown in green, not red) — distinct from
  /// [error] so a successful "check your inbox" message never looks like
  /// a failure.
  final String? success;
  final bool busy;
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
                  if (error != null)
                    Text(
                      error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
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
