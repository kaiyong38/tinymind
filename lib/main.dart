import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'models/learning.dart';
import 'models/activities.dart';
import 'models/parent_tip.dart';
import 'pages/achievement_page.dart';
import 'pages/auth_pages.dart';
import 'pages/parent_gate_pages.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/accessibility_settings.dart';
import 'services/background_music_service.dart';
import 'services/music_settings.dart';
import 'services/parent_gate_service.dart';
import 'services/narration_service.dart';
import 'services/progress_store.dart';
import 'theme/adaptive_metrics.dart';
import 'widgets/bouncy_tap.dart';
import 'widgets/drag_answer.dart';
import 'widgets/quiz_visuals.dart';
import 'theme/tinymind_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/emoji_glyph.dart';
import 'widgets/large_screen_scaler.dart';
import 'widgets/question_cue_card.dart';
import 'widgets/text_scale_limit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Baloo 2'], license);
  });
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // The app is designed landscape-first: wider cards side by side suit how
  // young children usually hold a tablet/phone with both hands, and it
  // matches the layout most benchmark kids' apps (Khan Academy Kids,
  // Endless Alphabet) use. Lock rotation so the layout below can assume a
  // wide, short canvas instead of handling both orientations.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const TinyMindApp());
}

class TinyMindApp extends StatefulWidget {
  const TinyMindApp({super.key});

  @override
  State<TinyMindApp> createState() => _TinyMindAppState();
}

class _TinyMindAppState extends State<TinyMindApp> with WidgetsBindingObserver {
  final ProgressStore _store = ProgressStore();
  final AccessibilitySettings _accessibilitySettings = AccessibilitySettings();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _accessibilitySettings.load();
    await BackgroundMusicService.instance.init();
    await NarrationService.instance.init();
    // Start the calm menu music as soon as app services are ready.
    await BackgroundMusicService.instance.play(MusicTrack.playtime);
    if (mounted) setState(() => _loading = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Fixes: switching to another app used to leave the music looping in
    // the background until TinyMind was force-closed. Pause the instant
    // the app stops being the visible/foreground one, and resume only
    // when it's genuinely back in front — never on a brief "inactive"
    // blip like a system dialog or notification shade.
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        BackgroundMusicService.instance.pauseForBackground();
        NarrationService.instance.stop();
      case AppLifecycleState.resumed:
        BackgroundMusicService.instance.resumeFromBackground();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    BackgroundMusicService.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AccessibilitySettingsScope(
      settings: _accessibilitySettings,
      child: MaterialApp(
        title: 'TinyMind',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        builder: (context, child) => LargeScreenScaler(
          child: TextScaleLimit(
            maxScale: 1.6,
            child: child!,
          ),
        ),
        home: _loading
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : _VoiceAvailabilityNotice(
                child: StartupGatePage(store: _store),
              ),
      ),
    );
  }
}

class _VoiceAvailabilityNotice extends StatefulWidget {
  const _VoiceAvailabilityNotice({required this.child});

  final Widget child;

  @override
  State<_VoiceAvailabilityNotice> createState() =>
      _VoiceAvailabilityNoticeState();
}

class _VoiceAvailabilityNoticeState extends State<_VoiceAvailabilityNotice> {
  static const _noticeShownKey = 'tinymind_voice_unavailable_notice_shown';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVoice());
  }

  Future<void> _checkVoice() async {
    if (NarrationService.instance.voiceAvailable) return;
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getBool(_noticeShownKey) == true || !mounted) return;
    await preferences.setBool(_noticeShownKey, true);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Voice not available'),
        content: const SingleChildScrollView(
          child: Text(
            'This device has no voice installed. Ask a parent to install '
            'Google Text-to-Speech, then restart TinyMind.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// The tabbed Play / Stars / Parents shell for a specific, already
/// loaded [store] — reached only after a learner has been chosen on the
/// [WelcomePage].
class TinyMindHomeShell extends StatefulWidget {
  const TinyMindHomeShell({
    required this.store,
    this.gateService,
    this.auth,
    this.firestore,
    super.key,
  });
  final ProgressStore store;
  final ParentGateService? gateService;
  final AuthService? auth;
  final FirestoreService? firestore;

  @override
  State<TinyMindHomeShell> createState() => _TinyMindHomeShellState();
}

class _TinyMindHomeShellState extends State<TinyMindHomeShell>
    with WidgetsBindingObserver {
  int _tabIndex = 0;
  final _music = BackgroundMusicService.instance;
  StreamSubscription? _selectedChildSubscription;

  ParentGateService get _gate =>
      widget.gateService ?? ParentGateService.instance;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.hidden) &&
        _tabIndex == 2) {
      setState(() => _tabIndex = 0);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedChildSubscription =
        widget.store.watchSelectedChild().listen((snapshot) async {
      if (snapshot.exists || snapshot.metadata.isFromCache || !mounted) return;
      final parentUid = widget.store.parentUid;
      if (parentUid == null) return;
      final messenger = ScaffoldMessenger.of(context);
      final auth = AuthService();
      await widget.store.clearCachedChildIfMatches(widget.store.childId ?? '');
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => ChildPickerPage(
            store: widget.store,
            parentUid: parentUid,
            auth: auth,
          ),
        ),
        (_) => false,
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text('That learner was removed. Choose another picture.'),
        ),
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _selectedChildSubscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleMusic() => _music.toggleMute();

  void _openLibrary(BuildContext callerContext, LearningModule module) {
    Navigator.of(callerContext)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => LibraryPage(world: module, store: widget.store),
          ),
        )
        .then((_) => setState(() {}));
  }

  Future<void> _openMenu() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _HomeMenuSheet(
        currentIndex: _tabIndex,
        musicSettings: _music.settingsNotifier,
        onToggleMusic: _toggleMusic,
        onVolumeChanged: (value) => _music.setVolume(value),
        onVolumeChangeEnd: (_) => _music.saveSettings(),
      ),
    );
    if (selected == null || !mounted) return;
    if (selected == _switchLearnerChoice) {
      _openChildPicker();
      return;
    }
    if (selected == 2 && _tabIndex != 2) {
      final unlocked = await _gate.unlock(context);
      if (!unlocked || !mounted) return;
    }
    setState(() => _tabIndex = selected);
  }

  void _openChildPicker() {
    final auth = widget.auth ?? AuthService();
    final parentUid = auth.currentUser?.uid;
    if (parentUid == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ChildPickerPage(
          store: widget.store,
          parentUid: parentUid,
          auth: auth,
          firestore: widget.firestore,
          gateService: widget.gateService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextScaleLimit(
        maxScale: 1.3,
        child: SafeArea(
          child: Stack(
            children: [
              IndexedStack(
                index: _tabIndex,
                children: [
                  HomePage(
                    store: widget.store,
                    onModuleTap: _openLibrary,
                  ),
                  // Other tabs keep clear of the floating menu button.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(78, 0, 12, 0),
                    child: ProgressPage(store: widget.store),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(78, 0, 12, 0),
                    child: ParentPage(
                      store: widget.store,
                      gateService: widget.gateService,
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 12,
                top: 4,
                child: _MenuButton(onTap: _openMenu),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The single always-visible "options" button: a big pink circle with a
/// white menu icon so it's easy to spot, sitting in its own gutter.
class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Menu',
      child: Material(
        color: TinyMindColors.primary,
        shape: const CircleBorder(
          side: BorderSide(color: Colors.white, width: 3),
        ),
        elevation: 6,
        shadowColor: TinyMindColors.primary.withValues(alpha: 0.6),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: const SizedBox(
            width: 52,
            height: 52,
            child: Center(
              child: Icon(Icons.menu_rounded, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}

/// Returned by [_HomeMenuSheet] for "Switch learner", which opens the child
/// picker instead of choosing a tab.
const _switchLearnerChoice = -1;

/// The bottom sheet opened by [_MenuButton].
class _HomeMenuSheet extends StatelessWidget {
  const _HomeMenuSheet({
    required this.currentIndex,
    required this.musicSettings,
    required this.onToggleMusic,
    required this.onVolumeChanged,
    required this.onVolumeChangeEnd,
  });

  final int currentIndex;
  final ValueListenable<MusicSettings> musicSettings;
  final VoidCallback onToggleMusic;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<double> onVolumeChangeEnd;

  @override
  Widget build(BuildContext context) {
    void closeMenu() => Navigator.of(context).pop();
    final maxHeight =
        (MediaQuery.sizeOf(context).height - 28).clamp(0.0, double.infinity);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: closeMenu,
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 720, maxHeight: maxHeight),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: closeMenu,
              child: Container(
                key: const Key('home-menu-card'),
                margin: const EdgeInsets.all(14),
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: SingleChildScrollView(
                  primary: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        key: const Key('home-menu-handle'),
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(builder: (context, constraints) {
                        // Navigation stays compact; volume controls get
                        // dedicated rows below. A label may wrap to two
                        // lines, so tiles in a row stretch to match.
                        final columns = constraints.maxWidth >= 480 ? 4 : 2;
                        const gap = 10.0;
                        final tileWidth =
                            (constraints.maxWidth - gap * (columns - 1)) /
                                columns;
                        final labelScaler = _MenuTile.scalerFor(
                          context,
                          labelWidth: tileWidth - 16,
                          labels: const [
                            'Play',
                            'Stars',
                            'Switch learner',
                            'Parents',
                          ],
                        );
                        final tiles = [
                          _MenuTile(
                            icon: Icons.home_rounded,
                            label: 'Play',
                            labelScaler: labelScaler,
                            color: TinyMindColors.primary,
                            selected: currentIndex == 0,
                            onTap: () => Navigator.of(context).pop(0),
                          ),
                          _MenuTile(
                            icon: Icons.emoji_events_rounded,
                            label: 'Stars',
                            labelScaler: labelScaler,
                            color: const Color(0xFFFFB703),
                            selected: currentIndex == 1,
                            onTap: () => Navigator.of(context).pop(1),
                          ),
                          _MenuTile(
                            icon: Icons.switch_account_rounded,
                            label: 'Switch learner',
                            labelScaler: labelScaler,
                            color: TinyMindColors.lavender,
                            selected: false,
                            onTap: () =>
                                Navigator.of(context).pop(_switchLearnerChoice),
                          ),
                          _MenuTile(
                            icon: Icons.family_restroom_rounded,
                            label: 'Parents',
                            labelScaler: labelScaler,
                            color: TinyMindColors.mint,
                            selected: currentIndex == 2,
                            onTap: () => Navigator.of(context).pop(2),
                          ),
                        ];
                        return Column(
                          children: [
                            for (var i = 0; i < tiles.length; i += columns) ...[
                              if (i > 0) const SizedBox(height: gap),
                              IntrinsicHeight(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (var j = i; j < i + columns; j++) ...[
                                      if (j > i) const SizedBox(width: gap),
                                      Expanded(child: tiles[j]),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        );
                      }),
                      const SizedBox(height: 12),
                      ValueListenableBuilder<MusicSettings>(
                        valueListenable: musicSettings,
                        builder: (context, settings, _) => _MusicVolumeRow(
                          settings: settings,
                          onToggleMute: onToggleMusic,
                          onVolumeChanged: onVolumeChanged,
                          onVolumeChangeEnd: onVolumeChangeEnd,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MusicVolumeRow extends StatelessWidget {
  const _MusicVolumeRow({
    required this.settings,
    required this.onToggleMute,
    required this.onVolumeChanged,
    required this.onVolumeChangeEnd,
  });

  final MusicSettings settings;
  final VoidCallback onToggleMute;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<double> onVolumeChangeEnd;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const SizedBox(
            width: 60,
            child: Text(
              'Music',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ),
          Semantics(
            button: true,
            label: settings.isMuted ? 'Unmute music' : 'Mute music',
            child: IconButton(
              onPressed: onToggleMute,
              tooltip: settings.isMuted ? 'Unmute music' : 'Mute music',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              icon: Icon(
                settings.isMuted
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
                size: 28,
              ),
            ),
          ),
          Expanded(
            child: Semantics(
              label: 'Music volume',
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 12,
                    disabledThumbRadius: 12,
                  ),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 24),
                  trackHeight: 6,
                ),
                child: Slider(
                  value: settings.volume,
                  min: 0,
                  max: 1,
                  onChanged: onVolumeChanged,
                  onChangeEnd: onVolumeChangeEnd,
                ),
              ),
            ),
          ),
        ],
      );
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.labelScaler,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  static const _labelStyle =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w900);

  /// The ambient text scale, shrunk just enough that the longest single
  /// word of any label fits [labelWidth]. Labels wrap between words, so
  /// only a word too wide on its own needs smaller text.
  static TextScaler scalerFor(
    BuildContext context, {
    required double labelWidth,
    required List<String> labels,
  }) {
    final scaler = MediaQuery.textScalerOf(context);
    final style = DefaultTextStyle.of(context).style.merge(_labelStyle);
    var widest = 0.0;
    for (final word in labels.expand((label) => label.split(' '))) {
      final painter = TextPainter(
        text: TextSpan(text: word, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }
    if (widest <= labelWidth || labelWidth <= 0) return scaler;
    // A little spare room, since letter spacing does not scale.
    final size = _labelStyle.fontSize!;
    final fit = labelWidth * 0.95 / widest;
    return TextScaler.linear(scaler.scale(size) / size * fit);
  }

  final IconData icon;
  final String label;
  final TextScaler labelScaler;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: selected ? 0.22 : 0.10),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.25),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textScaler: labelScaler,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
                  color: selected ? color : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    required this.store,
    required this.onModuleTap,
    super.key,
  });

  final ProgressStore store;
  final void Function(BuildContext, LearningModule) onModuleTap;

  @override
  Widget build(BuildContext context) {
    final progress = store.progress;
    return Column(
      children: [
        SizedBox(
          height: 52,
          child: Center(
            child: Text(
              'Learning worlds',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
          ),
        ),
        Expanded(
          child: _WorldCarousel(
            progress: progress,
            onModuleTap: (module) => onModuleTap(context, module),
          ),
        ),
      ],
    );
  }
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({required this.world, required this.store, super.key});

  final LearningModule world;
  final ProgressStore store;

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  @override
  void initState() {
    super.initState();
    BackgroundMusicService.instance.play(MusicTrack.forModule(widget.world.id));
    widget.store.addListener(_onProgressChanged);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onProgressChanged);
    BackgroundMusicService.instance.play(MusicTrack.playtime);
    super.dispose();
  }

  /// Keeps the stars up to date even when the child chains several activities
  /// with the "Next" button instead of coming back to this page in between.
  void _onProgressChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openActivity(Activity activity) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => QuizPage(activity: activity, store: widget.store),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final catalog = worldCatalogs[widget.world.id]!;
    final bestStars = widget.store.progress.activityStars;
    final finished = worldFinished(
      worldId: widget.world.id,
      age: widget.store.progress.childAge,
      bestStars: bestStars,
    );
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(widget.world.title,
            style: const TextStyle(fontWeight: FontWeight.w900)),
      ),
      body: TextScaleLimit(
        maxScale: 1.3,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = (constraints.maxWidth / 190).floor().clamp(4, 5);
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              children: [
                if (finished)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: EmojiText(
                      'You finished everything here! Replay your favorites ⭐',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                for (var sectionIndex = 0;
                    sectionIndex < catalog.sections.length;
                    sectionIndex++) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 14, bottom: 8),
                    child: Row(
                      children: [
                        EmojiGlyph(
                          catalog.sections[sectionIndex].emoji,
                          24,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            catalog.sections[sectionIndex].title,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: catalog.inSection(sectionIndex).length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.15,
                    ),
                    itemBuilder: (context, index) {
                      final activity = catalog.inSection(sectionIndex)[index];
                      final stars = bestStars[activity.id] ?? 0;
                      return _ActivityTile(
                        activity: activity,
                        number: catalog.activities.indexOf(activity) + 1,
                        stars: stars,
                        color: widget.world.color,
                        onTap: () => _openActivity(activity),
                      );
                    },
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.activity,
    required this.number,
    required this.stars,
    required this.color,
    required this.onTap,
  });

  final Activity activity;
  final int number;
  final int stars;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: EmojiGlyph(activity.emoji, 38),
                    ),
                  ),
                  Text(
                    activity.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (index) => Icon(
                        index < stars
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: const Color(0xFFFFB703),
                        size: 19,
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Semantics(
                  label: 'Activity $number',
                  excludeSemantics: true,
                  child: Container(
                    key: ValueKey('activity-number-${activity.id}'),
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$number',
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (activity.minAge > 3)
                Positioned(
                  top: 30,
                  right: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      child: Text(
                        '${activity.minAge}+',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One learning world at a time, swiped between — rather than a grid of
/// four competing for attention, closer to the "one big friendly tile"
/// feel of Khan Academy Kids' home screen.
///
/// [_phoneWorldViewport] / [_tabletWorldViewport] is the share of the screen
/// width taken by one page; the neighbours are cut off by the screen edges.
const double _phoneWorldViewport = 0.62;
const double _tabletWorldViewport = 0.5;
const double _tabletMinWidth = 900;
const double _sideCardScale = 0.82;
const double _sideCardOpacity = 0.65;

class _WorldCarousel extends StatefulWidget {
  const _WorldCarousel({required this.progress, required this.onModuleTap});

  final UserProgress progress;
  final void Function(LearningModule module) onModuleTap;

  @override
  State<_WorldCarousel> createState() => _WorldCarouselState();
}

class _WorldCarouselState extends State<_WorldCarousel>
    with SingleTickerProviderStateMixin {
  PageController _controller =
      PageController(viewportFraction: _phoneWorldViewport);
  double _fraction = _phoneWorldViewport;
  late final AnimationController _mascotController;
  late final Animation<double> _mascotFloat;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _mascotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
    _mascotFloat = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _mascotController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _mascotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final fraction =
        width >= _tabletMinWidth ? _tabletWorldViewport : _phoneWorldViewport;
    if (fraction != _fraction) {
      final old = _controller;
      _fraction = fraction;
      _controller = PageController(
        viewportFraction: fraction,
        initialPage: _page,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            key: ValueKey(_fraction),
            controller: _controller,
            pageSnapping: true,
            clipBehavior: Clip.hardEdge,
            itemCount: learningModules.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) {
              final module = learningModules[index];
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  var distance = (_page - index).abs().toDouble();
                  if (_controller.position.haveDimensions) {
                    distance =
                        ((_controller.page ?? _page.toDouble()) - index).abs();
                  }
                  distance = distance.clamp(0.0, 1.0);
                  final scale = 1 - (1 - _sideCardScale) * distance;
                  final opacity = 1 - (1 - _sideCardOpacity) * distance;
                  return Opacity(
                    opacity: opacity,
                    child: Transform.scale(scale: scale, child: child),
                  );
                },
                child: IgnorePointer(
                  ignoring: index != _page,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _LearningWorldCard(
                      module: module,
                      progress: widget.progress,
                      mascotFloat: _mascotFloat,
                      onTap: () => widget.onModuleTap(module),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < learningModules.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _page == i ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _page == i ? learningModules[i].color : Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.progress,
    required this.avatarAnimation,
    required this.onAvatarTap,
  });

  final UserProgress progress;
  final Animation<double> avatarAnimation;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 14, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF8FC6), Color(0xFF9C8CFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const EmojiGlyph('🌈', 27),
                    const SizedBox(width: 4),
                    const Text(
                      'TinyMind',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: EmojiText(
                    'Hi, ${progress.childName}! 👋',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
                const SizedBox(height: 13),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _HeaderChip(
                      icon: Icons.star_rounded,
                      text: '${progress.points}',
                    ),
                    _HeaderChip(
                      icon: Icons.calendar_month_rounded,
                      text: '${progress.daysLearned} days played',
                    ),
                  ],
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: avatarAnimation,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, -4 * avatarAnimation.value),
              child: child,
            ),
            child: Semantics(
              button: true,
              label: 'Change avatar',
              child: GestureDetector(
                onTap: onAvatarTap,
                child: Container(
                  width: 82,
                  height: 82,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD166),
                    shape: BoxShape.circle,
                  ),
                  child: EmojiGlyph(progress.avatar, 46),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 19),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                text,
                softWrap: true,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeStats extends StatelessWidget {
  const _HomeStats({required this.progress});

  final UserProgress progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HomeStat(
            icon: Icons.star_rounded,
            value: '${progress.points}',
            label: 'Points',
            color: const Color(0xFFFFB703),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HomeStat(
            icon: Icons.calendar_month_rounded,
            value: '${progress.daysLearned}',
            label: 'Days played',
            color: const Color(0xFF4ECDC4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _HomeStat(
            icon: Icons.check_circle_rounded,
            value: '${progress.correctAnswers}',
            label: 'Correct',
            color: const Color(0xFF00A896),
          ),
        ),
      ],
    );
  }
}

class _HomeStat extends StatelessWidget {
  const _HomeStat({
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LearningWorldCard extends StatelessWidget {
  const _LearningWorldCard({
    required this.module,
    required this.progress,
    required this.mascotFloat,
    required this.onTap,
  });

  final LearningModule module;
  final UserProgress progress;
  final Animation<double> mascotFloat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activities = worldCatalogs[module.id]!.activities;
    final earnedStars = activities.fold<int>(
      0,
      (total, activity) => total + (progress.activityStars[activity.id] ?? 0),
    );
    final totalStars = activities.length * 3;
    final completedActivities = activities
        .where((activity) => (progress.activityStars[activity.id] ?? 0) > 0)
        .length;
    final progressValue =
        activities.isEmpty ? 0.0 : completedActivities / activities.length;
    final decoration = switch (module.id) {
      'letters' => const ['A', 'B', 'C'],
      'numbers' => const ['1', '2', '3'],
      'shapes' => const ['◆', '●', '▲'],
      _ => const ['✿', '●', '✦'],
    };

    return BouncyTap(
      key: Key('module-${module.id}'),
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 280;
          final mascotSize = compact
              ? (constraints.maxWidth * 0.28).clamp(40.0, 64.0).toDouble()
              : (constraints.maxHeight * 0.58).clamp(96.0, 150.0).toDouble();
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: module.color,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: module.color.withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -8,
                  top: -30,
                  child: Text(
                    decoration[0],
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.10),
                      fontSize: 112,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Positioned(
                  right: 44,
                  bottom: -35,
                  child: Text(
                    decoration[1],
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.10),
                      fontSize: 100,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Positioned(
                  left: constraints.maxWidth * 0.34,
                  bottom: -16,
                  child: Text(
                    decoration[2],
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.08),
                      fontSize: 74,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Padding(
                  padding: compact
                      ? const EdgeInsets.all(8)
                      : const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: compact
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: mascotFloat,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(0, mascotFloat.value),
                                child: child,
                              ),
                              child: Container(
                                width: mascotSize,
                                height: mascotSize,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.94),
                                  shape: BoxShape.circle,
                                ),
                                child: module.illustrationAsset != null
                                    ? SvgPicture.asset(
                                        module.illustrationAsset!,
                                        fit: BoxFit.contain,
                                      )
                                    : Icon(
                                        module.icon,
                                        color: module.color,
                                        size: mascotSize * 0.6,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              module.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            EmojiText(
                              '⭐ $earnedStars / $totalStars',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              softWrap: false,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$completedActivities / ${activities.length} activities',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progressValue,
                                minHeight: 8,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.35),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            SizedBox(
                              width: constraints.maxWidth * 0.40,
                              child: Center(
                                child: AnimatedBuilder(
                                  animation: mascotFloat,
                                  builder: (context, child) =>
                                      Transform.translate(
                                    offset: Offset(0, mascotFloat.value),
                                    child: child,
                                  ),
                                  child: Container(
                                    width: mascotSize,
                                    height: mascotSize,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.94),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.10),
                                          blurRadius: 12,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: module.illustrationAsset != null
                                        ? SvgPicture.asset(
                                            module.illustrationAsset!,
                                            fit: BoxFit.contain,
                                          )
                                        : Icon(
                                            module.icon,
                                            color: module.color,
                                            size: mascotSize * 0.6,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    module.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      height: 1.05,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  EmojiText(
                                    '⭐ $earnedStars / $totalStars stars',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '$completedActivities / ${activities.length} activities',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: progressValue,
                                      minHeight: 10,
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.35),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class QuizPage extends StatefulWidget {
  const QuizPage({
    required this.activity,
    required this.store,
    this.narration,
    super.key,
  });
  final Activity activity;
  final ProgressStore store;
  final NarrationService? narration;

  @visibleForTesting
  static const leadInsForTesting = _QuizPageState._leadIns;

  @visibleForTesting
  static const praisesForTesting = _QuizPageState._praises;

  @visibleForTesting
  static const oopsiesForTesting = _QuizPageState._oopsies;

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  NarrationService get _narration =>
      widget.narration ?? NarrationService.instance;

  LearningModule get _world => learningModules.firstWhere(
        (world) => worldCatalogs[world.id]!
            .activities
            .any((activity) => activity.id == widget.activity.id),
      );

  late QuizQuestion _question;
  int _questionNumber = 1;
  int _score = 0;
  bool _answered = false;
  bool _questionAttempted = false;
  int? _selected;
  bool _teaching = false;

  @override
  void initState() {
    super.initState();
    _question = widget.activity.questions.first;
    _teaching = _question.teach != null;
    _narrate();
  }

  @override
  void dispose() {
    _narration.stop();
    super.dispose();
  }

  static const _leadIns = [
    'Ready?',
    'Your turn!',
    'Here we go!',
    "Let's see!",
    'Look closely!',
  ];
  static const _praises = [
    'Great job!',
    'You got it!',
    'Awesome!',
    'Well done!',
    'Fantastic!',
    "That's right!",
  ];
  static const _oopsies = [
    'Good try!',
    "Let's look again!",
    'Try another one!',
    'You can do it!',
  ];

  void _narrate() {
    if (_teaching) {
      _narration.speak(_question.teach!);
      return;
    }
    final lead = _leadIns[_questionNumber % _leadIns.length];
    final speechText =
        _question.spokenText == null ? null : '$lead ${_question.spokenText}';
    _narration.speak(
      '$lead ${_question.prompt}',
      spokenText: speechText,
    );
  }

  /// A short, kid-friendly description of the option that was tapped, so
  /// the feedback can say what they picked before explaining why it's not
  /// the one.
  String _describe(QuizOption option) {
    switch (_question.visual) {
      case AnswerVisual.picture:
        return "That's ${option.label}.";
      case AnswerVisual.colorSwatch:
        return "That's ${option.label.toLowerCase()}.";
      case AnswerVisual.shape:
      case AnswerVisual.shapeCorners:
      case AnswerVisual.shapeSides:
        return "That's a ${option.label}.";
      case AnswerVisual.colorPair:
        return "That's ${option.label.toLowerCase()}.";
      case AnswerVisual.letterPicture:
        return "That's the letter ${option.label}.";
      case AnswerVisual.numberDots:
        return 'That group has ${option.count ?? option.label}.';
      case AnswerVisual.text:
        return 'You picked ${option.label}.';
    }
  }

  Future<void> _answer(int index) async {
    if (_answered) return;
    final correct = index == _question.answerIndex;
    final firstAttempt = !_questionAttempted;
    setState(() {
      _answered = true;
      _questionAttempted = true;
      _selected = index;
      if (correct && firstAttempt) _score++;
    });
    final saving = widget.store.recordAnswer(
      _world.id,
      correct,
      completedQuestionId:
          correct ? '${widget.activity.id}_${_questionNumber + 1}' : null,
    );
    await _showFeedback(correct, _question.options[index]);
    await saving;
  }

  Future<void> _showFeedback(bool correct, QuizOption picked) async {
    final praise = _praises[_score % _praises.length];
    final oops = _oopsies[_questionNumber % _oopsies.length];
    final detail = correct
        ? (_question.teach ?? '')
        : '${_describe(picked)} ${_question.hint ?? 'Have another look!'}';
    final title = correct ? praise : oops;
    final last = _questionNumber == 3;
    final buttonLabel =
        correct ? (last ? 'Finish game 🎉' : 'Next game →') : 'Try again 💪';
    _narration.speak(
      correct
          ? '$title ${_question.spokenText ?? detail}'
          : '$title $detail Try again, you can do it!',
    );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black38,
      builder: (_) => _FeedbackDialog(
        correct: correct,
        title: title,
        message: correct ? detail : '$detail\nTry again, you can do it!',
        buttonLabel: buttonLabel,
        color: _world.color,
        mascot: _world.illustrationAsset,
      ),
    );
    if (!mounted) return;
    if (correct) {
      _next();
    } else {
      _retry();
    }
  }

  /// Wrong answer: let the child try the SAME question again — same
  /// options, no penalty beyond the attempt already recorded — rather
  /// than moving on as if they'd got it.
  void _retry() {
    setState(() {
      _answered = false;
      _selected = null;
    });
    _narrate();
  }

  void _beginQuestion() {
    setState(() => _teaching = false);
    _narrate();
  }

  Future<void> _next() async {
    if (_questionNumber == 3) {
      final stars = starsForScore(_score, 3);
      await widget.store.completeModule(_world.id);
      await widget.store.recordActivityResult(widget.activity.id, stars);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => ResultPage(
            world: _world,
            activity: widget.activity,
            score: _score,
            stars: stars,
            store: widget.store,
          ),
        ),
      );
      return;
    }
    setState(() {
      _questionNumber++;
      _answered = false;
      _questionAttempted = false;
      _selected = null;
      _question = widget.activity.questions[_questionNumber - 1];
      _teaching = _question.teach != null;
    });
    _narrate();
  }

  Widget _questionCard() => QuestionCueCard(
        question: _question,
        worldColor: _world.color,
        onReplay: _narrate,
        revealDifference: _answered,
      );

  Widget _answerArea() {
    return DragAnswerArea(
      question: _question,
      selectedIndex: _selected,
      answered: _answered,
      moduleColor: _world.color,
      onDrop: _answer,
      narration: _narration,
    );
  }

  /// The confirm button — "Try again" after a wrong pick, "Next game" /
  /// "Finish game" after a right one. The drag area itself answers the
  /// question on drop, so this button only ever appears once something
  /// has actually been dropped in the slot.
  Widget _confirmButton() {
    if (!_answered) return const SizedBox.shrink();
    final wrong = _selected != _question.answerIndex;
    return FilledButton(
      onPressed: wrong ? _retry : _next,
      style: FilledButton.styleFrom(
        backgroundColor: wrong ? const Color(0xFFFF8FAB) : _world.color,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: EmojiText(
        wrong
            ? 'Try again 💪'
            : _questionNumber == 3
                ? 'Finish game 🎉'
                : 'Next game →',
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Color.alphaBlend(_world.color.withValues(alpha: 0.10), Colors.white),
      appBar: AppBar(
        toolbarHeight: 48,
        backgroundColor: Color.alphaBlend(
            _world.color.withValues(alpha: 0.10), Colors.white),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_world.illustrationAsset != null) ...[
              SizedBox(
                width: 32,
                height: 32,
                child: SvgPicture.asset(_world.illustrationAsset!),
              ),
              const SizedBox(width: 8),
            ],
            EmojiText(
              '${widget.activity.emoji} ${widget.activity.title}',
              style: const TextStyle(fontWeight: FontWeight.w900),
              maxLines: 1,
              softWrap: false,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Center(
              child: EmojiText(
                '⭐ $_score',
                style:
                    const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                maxLines: 1,
                softWrap: false,
              ),
            ),
          ),
        ],
      ),
      body: TextScaleLimit(
        maxScale: 1.3,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _questionNumber / 3,
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(12),
                  color: _world.color,
                  backgroundColor: _world.color.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 8),
                Text(
                  'Game $_questionNumber of 3',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: _world.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 14),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: _teaching
                      ? _TeachCard(
                          module: _world,
                          question: _question,
                          onContinue: _beginQuestion,
                          onReplay: _narrate,
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide =
                                constraints.maxWidth > constraints.maxHeight;
                            if (isWide) {
                              final colorFriendlySwatches = _question.visual ==
                                      AnswerVisual.colorSwatch &&
                                  AccessibilitySettingsScope.of(context)
                                      .colorFriendlyMode;
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    flex: colorFriendlySwatches ? 4 : 5,
                                    child: _questionCard(),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    flex: colorFriendlySwatches ? 5 : 4,
                                    child: Column(
                                      children: [
                                        Expanded(child: _answerArea()),
                                        const SizedBox(height: 6),
                                        _confirmButton(),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                Expanded(flex: 3, child: _questionCard()),
                                const SizedBox(height: 12),
                                Expanded(flex: 5, child: _answerArea()),
                                const SizedBox(height: 8),
                                _confirmButton(),
                              ],
                            );
                          },
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

/// The pop-up shown after every answer: a big picture that says whether it
/// was right or wrong, a short explanation, and one button to carry on
/// ("Next game" after a right answer, "Try again" after a wrong one).
class _FeedbackDialog extends StatelessWidget {
  const _FeedbackDialog({
    required this.correct,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.color,
    required this.mascot,
  });

  final bool correct;
  final String title;
  final String message;
  final String buttonLabel;
  final Color color;
  final String? mascot;

  @override
  Widget build(BuildContext context) {
    final badgeColor =
        correct ? const Color(0xFF2ECC71) : const Color(0xFFFF9F43);
    final badge = TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1),
      duration: const Duration(milliseconds: 550),
      curve: Curves.elasticOut,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: SizedBox(
        width: 104,
        height: 104,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(8),
              child: mascot != null ? SvgPicture.asset(mascot!) : null,
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Icon(
                  correct ? Icons.check_rounded : Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  badge,
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EmojiText(
                          correct ? '$title 🎉' : '$title 🤔',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: badgeColor,
                          ),
                        ),
                        if (message.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            message,
                            style: const TextStyle(
                                fontSize: 16,
                                height: 1.3,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: correct ? color : badgeColor,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: Text(buttonLabel,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "let's learn it first" card shown before a question that has a
/// [QuizQuestion.teach] fact — teaches the concept with a big visual before
/// asking the child to apply it, instead of testing cold.
class _TeachCard extends StatelessWidget {
  const _TeachCard({
    required this.module,
    required this.question,
    required this.onContinue,
    required this.onReplay,
  });
  final LearningModule module;
  final QuizQuestion question;
  final VoidCallback onContinue;
  final VoidCallback onReplay;

  @override
  Widget build(BuildContext context) {
    final button = FilledButton(
      onPressed: onContinue,
      style: FilledButton.styleFrom(
        backgroundColor: module.color,
        minimumSize: const Size(180, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: const EmojiText(
        "Let's try it! 🎯",
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
      ),
    );
    final textCard = Semantics(
      button: true,
      label: 'Hear the question again',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onReplay,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: EmojiText(
                    question.teach ?? '',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800, height: 1.2),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 8),
                IgnorePointer(
                  child: Icon(
                    Icons.volume_up_rounded,
                    size: 26,
                    color: module.color.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > constraints.maxHeight;
      if (isWide) {
        // Landscape: the lesson (picture + words) on the left, the
        // "Let's try it!" confirm button on the right — nothing stacks
        // tall enough to push the button off the bottom of the screen.
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 6,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (module.illustrationAsset != null)
                        SizedBox(
                          width: 56,
                          height: 56,
                          child: SvgPicture.asset(module.illustrationAsset!),
                        ),
                      if (question.teachOption != null) ...[
                        const SizedBox(height: 4),
                        buildQuizVisual(
                            context, question.teachOption!, question.visual,
                            size: question.visual == AnswerVisual.colorSwatch
                                ? 60
                                : 42),
                      ],
                    ],
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: textCard),
                ],
              ),
            ),
            const SizedBox(width: 18),
            Expanded(flex: 4, child: Center(child: button)),
          ],
        );
      }
      // Portrait: plenty of height, so keep the stacked layout.
      return Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (module.illustrationAsset != null)
                  SizedBox(
                    width: 92,
                    height: 92,
                    child: SvgPicture.asset(module.illustrationAsset!),
                  ),
                const SizedBox(height: 14),
                if (question.teachOption != null) ...[
                  buildQuizVisual(
                      context, question.teachOption!, question.visual,
                      size: 68),
                  const SizedBox(height: 14),
                ],
                textCard,
                const SizedBox(height: 20),
                button,
              ],
            ),
          ),
        ),
      );
    });
  }
}

class _ConfettiOverlay extends StatefulWidget {
  const _ConfettiOverlay();

  @override
  State<_ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<_ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..forward();

  static const _colors = [
    TinyMindColors.primary,
    TinyMindColors.lavender,
    TinyMindColors.buttercream,
    TinyMindColors.mint,
  ];
  final List<double> _startX = List.generate(8, (i) => (i * 37) % 100 / 100);
  final List<double> _delay = List.generate(8, (i) => (i * 0.07) % 0.35);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            children: List.generate(_startX.length, (i) {
              final t = ((_controller.value - _delay[i]) / (1 - _delay[i]))
                  .clamp(0.0, 1.0);
              return Positioned(
                left: _startX[i] * size.width,
                top: t * size.height * 0.55,
                child: Opacity(
                  opacity: (1 - t).clamp(0.0, 1.0),
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _colors[i % _colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class ResultPage extends StatelessWidget {
  const ResultPage({
    required this.world,
    required this.activity,
    required this.score,
    required this.stars,
    required this.store,
    super.key,
  });
  final LearningModule world;
  final Activity activity;
  final int score;
  final int stars;
  final ProgressStore store;

  @override
  Widget build(BuildContext context) {
    final excellent = stars == 3;
    final sequentialId = nextActivityId(
      worldId: world.id,
      age: store.progress.childAge,
      currentId: activity.id,
    );
    final hasSuggestion = sequentialId != null;
    final nextId = nextActivityForResult(
      worldId: world.id,
      age: store.progress.childAge,
      currentId: activity.id,
    );
    final nextActivity = nextId == null ? null : activityById(nextId);
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      body: TextScaleLimit(
        maxScale: 1.3,
        child: Stack(
          children: [
            if (excellent) const _ConfettiOverlay(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final landscape =
                      constraints.maxWidth > constraints.maxHeight;
                  final metrics =
                      AdaptiveMetrics.fromConstraints(context, constraints);
                  final celebration = Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(metrics.size(12)),
                        decoration: BoxDecoration(
                          color: world.color.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          excellent ? Icons.celebration : Icons.auto_awesome,
                          size: metrics.size(48),
                          color: world.color,
                        ),
                      ),
                      SizedBox(height: metrics.size(8)),
                      EmojiText(
                        excellent ? 'Amazing work! 🎉' : 'Keep going! 💪',
                        style: TextStyle(
                          fontSize: metrics.size(23),
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: metrics.size(4)),
                      Text(
                        'You got $score out of 3 in ${activity.title}',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: metrics.size(15)),
                      ),
                      SizedBox(height: metrics.size(6)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          3,
                          (index) => Icon(
                            Icons.star,
                            size: metrics.size(25),
                            color: index < stars
                                ? const Color(0xFFFFB703)
                                : Colors.black12,
                          ),
                        ),
                      ),
                      SizedBox(height: metrics.size(4)),
                      Text(
                        'Best result: $stars ${stars == 1 ? 'star' : 'stars'}',
                        style: TextStyle(
                          color: world.color,
                          fontWeight: FontWeight.w800,
                          fontSize: metrics.size(14),
                        ),
                      ),
                    ],
                  );
                  final buttonHeight = math.max(48.0, metrics.size(46));
                  Widget oneLine(String label) => FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(label, maxLines: 1, softWrap: false),
                      );
                  final buttons = Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FilledButton(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                QuizPage(activity: activity, store: store),
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: world.color,
                          minimumSize: Size.fromHeight(buttonHeight),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: oneLine('Play again'),
                      ),
                      SizedBox(height: metrics.size(8)),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size.fromHeight(buttonHeight),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: oneLine('Back to library'),
                      ),
                      if (nextActivity != null) ...[
                        SizedBox(height: metrics.size(8)),
                        FilledButton.tonal(
                          onPressed: () =>
                              Navigator.of(context).pushReplacement(
                            MaterialPageRoute<void>(
                              builder: (_) => QuizPage(
                                activity: nextActivity,
                                store: store,
                              ),
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: Size.fromHeight(buttonHeight),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: oneLine('Next'),
                        ),
                      ],
                      if (!hasSuggestion) ...[
                        SizedBox(height: metrics.size(8)),
                        EmojiText(
                          'You finished everything here! Replay your favorites ⭐',
                          style: TextStyle(
                            fontSize: metrics.size(13),
                            height: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  );
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: Padding(
                        padding: EdgeInsets.all(metrics.size(16)),
                        child: Center(
                          child: landscape
                              ? Row(
                                  children: [
                                    Expanded(child: Center(child: celebration)),
                                    SizedBox(width: metrics.size(20)),
                                    SizedBox(
                                      width: metrics.size(190),
                                      child: buttons,
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Center(child: celebration),
                                    SizedBox(height: metrics.size(12)),
                                    SizedBox(
                                      width: metrics.size(240),
                                      child: buttons,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressPage extends StatefulWidget {
  const ProgressPage({required this.store, super.key});
  final ProgressStore store;

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _avatarController;

  @override
  void initState() {
    super.initState();
    _avatarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _avatarController.dispose();
    super.dispose();
  }

  void _openAvatarPicker() {
    Navigator.of(context)
        .push(
      MaterialPageRoute<void>(
        builder: (_) => AvatarPage(store: widget.store),
      ),
    )
        .then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.store.progress;
    final accuracy = progress.totalQuestions == 0
        ? 0
        : ((progress.correctAnswers / progress.totalQuestions) * 100).round();
    return TextScaleLimit(
      maxScale: 1.3,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        children: [
          _HomeHeader(
            progress: progress,
            avatarAnimation: _avatarController,
            onAvatarTap: _openAvatarPicker,
          ),
          const SizedBox(height: 14),
          _HomeStats(progress: progress),
          const SizedBox(height: 22),
          const Text('My little wins',
              style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          const EmojiText(
            'Every game makes your brain stronger! 💪',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFFFD166), Color(0xFFFFE9A6)]),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.white, size: 62),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${progress.points} points collected',
                          style: const TextStyle(
                              fontSize: 21, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 3),
                      Text(
                          '${progress.daysLearned} days played • $accuracy% correct',
                          style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const EmojiText(
            'Badge collection 🏅',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => AchievementPage(progress: progress))),
            icon: const Icon(Icons.emoji_events),
            label: const Text('See all achievements'),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 600 ? 4 : 2;
              final badges = [
                _BadgeData(
                  icon: Icons.waving_hand,
                  label: 'First steps',
                  earned: progress.totalQuestions > 0,
                ),
                _BadgeData(
                  icon: Icons.calendar_month_rounded,
                  label: 'Three-day explorer',
                  earned: progress.daysLearned >= 3,
                ),
                _BadgeData(
                  icon: Icons.star,
                  label: 'Star learner',
                  earned: progress.points >= 50,
                ),
                _BadgeData(
                  icon: Icons.school,
                  label: 'Super learner',
                  earned: progress.totalQuestions >= 20,
                ),
              ];
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: badges.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: columns == 4 ? 1.1 : 1.05,
                ),
                itemBuilder: (context, index) {
                  final badge = badges[index];
                  return _Badge(
                    icon: badge.icon,
                    label: badge.label,
                    earned: badge.earned,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _BadgeData {
  const _BadgeData({
    required this.icon,
    required this.label,
    required this.earned,
  });

  final IconData icon;
  final String label;
  final bool earned;
}

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.label, required this.earned});
  final IconData icon;
  final String label;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: earned ? const Color(0xFFFFE1ED) : Colors.grey.shade200,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 35,
              color: earned ? const Color(0xFFFF6FA5) : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: earned ? null : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ParentPage extends StatelessWidget {
  const ParentPage({
    required this.store,
    this.gateService,
    this.auth,
    this.firestore,
    super.key,
  });
  final ProgressStore store;
  final ParentGateService? gateService;
  final AuthService? auth;
  final FirestoreService? firestore;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('For parents',
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('A quick view of ${store.progress.childName}’s learning journey.'),
        const SizedBox(height: 22),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(children: [
                  Icon(Icons.insights, color: Color(0xFFFF6FA5)),
                  SizedBox(width: 10),
                  Text('Overview',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800))
                ]),
                const SizedBox(height: 18),
                _OverviewRow(
                    label: 'Activities completed',
                    value:
                        '${store.progress.activityStars.values.where((stars) => stars > 0).length}'),
                _OverviewRow(
                    label: 'Average accuracy',
                    value:
                        '${store.progress.totalQuestions == 0 ? 0 : (store.progress.correctAnswers / store.progress.totalQuestions * 100).round()}% correct'),
                _OverviewRow(
                    label: 'Days played',
                    value: '${store.progress.daysLearned}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          elevation: 0,
          color: const Color(0xFFE8F7EF),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              const Icon(Icons.lightbulb, color: Colors.green, size: 32),
              const SizedBox(width: 12),
              Expanded(child: Text(parentTipFor(store.progress.activityStars))),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.tonalIcon(
          onPressed: () => openParentArea(
            context,
            store: store,
            auth: auth,
            firestore: firestore,
            gateService: gateService,
            skipGate: true,
          ),
          icon: const Icon(Icons.admin_panel_settings),
          label: const Text('Open learning dashboard'),
        ),
      ],
    );
  }
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(child: Text(label)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ]),
    );
  }
}
