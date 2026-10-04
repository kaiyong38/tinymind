import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilitySettings extends ChangeNotifier {
  static const _colorFriendlyModeKey = 'tinymind_color_friendly_mode';

  bool _colorFriendlyMode = false;

  bool get colorFriendlyMode => _colorFriendlyMode;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _colorFriendlyMode = preferences.getBool(_colorFriendlyModeKey) ?? false;
    notifyListeners();
  }

  Future<void> setColorFriendlyMode(bool enabled) async {
    if (_colorFriendlyMode == enabled) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_colorFriendlyModeKey, enabled);
    _colorFriendlyMode = enabled;
    notifyListeners();
  }
}

class AccessibilitySettingsScope
    extends InheritedNotifier<AccessibilitySettings> {
  const AccessibilitySettingsScope({
    required AccessibilitySettings settings,
    required super.child,
    super.key,
  }) : super(notifier: settings);

  static AccessibilitySettings of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AccessibilitySettingsScope>();
    assert(scope != null, 'AccessibilitySettingsScope is missing above context');
    return scope!.notifier!;
  }
}
