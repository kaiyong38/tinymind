import 'package:flutter_tts/flutter_tts.dart';

/// Reads short bits of text aloud (question prompts, "let's learn it"
/// facts, right/wrong feedback) so a 3-6 year old who can't read yet isn't
/// blocked by on-screen text. Uses the device's own text-to-speech voice —
/// no audio assets needed.
///
/// The voice is set up to sound bright and playful (higher pitch, a brisk
/// pace), and everything is passed through [spokenText] first so emoji are
/// spoken as words ("four balloons") instead of being read out one by one.
class NarrationService {
  NarrationService._();
  static final NarrationService instance = NarrationService._();

  final FlutterTts _tts = FlutterTts();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.5);
      await _tts.setVolume(1.0);
    } catch (_) {
      // If the platform has no TTS engine available, narration silently
      // becomes a no-op rather than crashing the app.
    }
  }

  Future<void> speak(String text) async {
    if (!_ready) await init();
    try {
      await _tts.stop();
      await _tts.speak(spokenText(text));
    } catch (_) {
      // No-op if TTS isn't available on this device.
    }
  }

  Future<void> stop() => _tts.stop();

  // ---------------------------------------------------------------------
  // Turning on-screen text into something that sounds natural aloud.
  // ---------------------------------------------------------------------

  /// Emoji we know how to say: singular name, and plural if it isn't just
  /// "+s". Anything not listed here is simply skipped (never read out as
  /// "red circle", "party popper", etc.).
  static const _emojiNames = <String, List<String>>{
    '🍎': ['apple', 'apples'],
    '⭐': ['star', 'stars'],
    '🎈': ['balloon', 'balloons'],
    '🐟': ['fish', 'fish'],
    '🔵': ['blue dot', 'blue dots'],
    '⚽': ['ball', 'balls'],
    '🐱': ['cat', 'cats'],
    '🐶': ['dog', 'dogs'],
    '☀': ['sun', 'suns'],
    '🦆': ['duck', 'ducks'],
    '🐧': ['penguin', 'penguins'],
    '🍇': ['grapes', 'grapes'],
    '🍊': ['orange', 'oranges'],
    '🦓': ['zebra', 'zebras'],
    '🍌': ['banana', 'bananas'],
  };

  static const _numberWords = [
    'zero', 'one', 'two', 'three', 'four', 'five',
    'six', 'seven', 'eight', 'nine', 'ten',
  ];

  static bool _isEmoji(int rune) =>
      (rune >= 0x1F000 && rune <= 0x1FAFF) ||
      (rune >= 0x2600 && rune <= 0x27BF) ||
      (rune >= 0x2B00 && rune <= 0x2BFF);

  /// Converts [text] for speech:
  ///  * a run of the same emoji becomes a count and a name — 🎈🎈🎈🎈 is
  ///    "four balloons", not "balloon, balloon, balloon, balloon";
  ///  * if the words just before already name the thing ("Count the fish
  ///    🐟🐟🐟🐟"), the emoji is skipped so we never say it twice — or
  ///    give away a count the child is meant to work out;
  ///  * other emoji and stray symbols are dropped, and "+", "=", "__" and
  ///    " - " are turned into words.
  static String spokenText(String text) {
    final runes = text.runes.toList();
    final out = StringBuffer();
    var i = 0;
    while (i < runes.length) {
      final rune = runes[i];
      if (_isEmoji(rune)) {
        // Gather this emoji plus any variation selector / joiner.
        var j = i + 1;
        while (j < runes.length && (runes[j] == 0xFE0F || runes[j] == 0x200D)) {
          j++;
        }
        final glyph = String.fromCharCode(rune);
        var count = 1;
        // Group identical emoji that follow directly.
        while (j < runes.length && runes[j] == rune) {
          count++;
          j++;
          while (j < runes.length &&
              (runes[j] == 0xFE0F || runes[j] == 0x200D)) {
            j++;
          }
        }
        final names = _emojiNames[glyph];
        if (names != null) {
          // Only look at the last few words: "Count the fish 🐟🐟" already
          // names the fish, but a balloon mentioned a whole clause ago
          // shouldn't stop the second group being counted out loud.
          final before = out.toString().toLowerCase();
          final recent =
              before.length > 20 ? before.substring(before.length - 20) : before;
          final alreadySaid = recent.contains(names[0].split(' ').last) ||
              recent.contains(names[1].split(' ').last);
          if (!alreadySaid) {
            final number = count <= 10 ? _numberWords[count] : '$count';
            final article = 'aeiou'.contains(names[0][0]) ? 'an' : 'a';
            out.write(count == 1
                ? ' $article ${names[0]} '
                : ' $number ${names[1]} ');
          }
        }
        i = j;
        continue;
      }
      if (rune == 0xFE0F || rune == 0x200D) {
        i++;
        continue;
      }
      out.writeCharCode(rune);
      i++;
    }
    return out
        .toString()
        .replaceAll(RegExp(r'_+'), ' blank ')
        .replaceAll('+', ' plus ')
        .replaceAll('=', ' equals ')
        .replaceAll(' - ', ', ')
        .replaceAll('…', '...')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(' .', '.')
        .replaceAll(' ,', ',')
        .replaceAll(' !', '!')
        .replaceAll(' ?', '?')
        .trim();
  }
}
