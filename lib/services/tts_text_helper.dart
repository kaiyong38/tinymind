/// Converts on-screen learning text into concise, natural TTS input.
class TtsTextHelper {
  TtsTextHelper._();

  static const _numberWords = <int, String>{
    0: 'zero',
    1: 'one',
    2: 'two',
    3: 'three',
    4: 'four',
    5: 'five',
    6: 'six',
    7: 'seven',
    8: 'eight',
    9: 'nine',
    10: 'ten',
    11: 'eleven',
    12: 'twelve',
    13: 'thirteen',
    14: 'fourteen',
    15: 'fifteen',
    16: 'sixteen',
    17: 'seventeen',
    18: 'eighteen',
    19: 'nineteen',
    20: 'twenty',
  };

  static const _objects = <int, List<String>>{
    0x1F388: ['balloon', 'balloons'],
    0x1F34E: ['apple', 'apples'],
    0x2B50: ['star', 'stars'],
    0x1F986: ['duck', 'ducks'],
    0x1F697: ['car', 'cars'],
    0x1F41F: ['fish', 'fish'],
    0x1F338: ['flower', 'flowers'],
    0x1F36A: ['cookie', 'cookies'],
    0x1F41E: ['ladybug', 'ladybugs'],
    0x1F9F8: ['teddy bear', 'teddy bears'],
  };

  static const _phoneticSpellings = <String, String>{
    'Aaa': 'ah',
    'Buh': 'buh',
    'Cuh': 'kuh',
    'Duh': 'duh',
    'Eh': 'eh',
    'Fff': 'fuh',
    'Guh': 'guh',
    'Huh': 'huh',
    'Ih': 'ih',
    'Juh': 'juh',
    'Kuh': 'kuh',
    'Lll': 'luh',
    'Mmm': 'muh',
    'Nnn': 'nuh',
    'Ah': 'ah',
    'Puh': 'puh',
    'Kwuh': 'kwuh',
    'Rrr': 'ruh',
    'Sss': 'suh',
    'Tuh': 'tuh',
    'Uh': 'uh',
    'Vvv': 'vuh',
    'Wuh': 'wuh',
    'Yuh': 'yuh',
    'Zzz': 'zuh',
  };

  /// Removes visual-only symbols while preserving counted objects and math.
  static String clean(String text) {
    final countQuestion = _countQuestion(text);
    if (countQuestion != null) return countQuestion;

    final withoutEmoji = text
        .split('\n')
        .map(_removeDecorativeSymbols)
        .where(
            (line) => line.isNotEmpty && !RegExp(r'^[+\-= ]+$').hasMatch(line))
        .join('. ');

    var result = withoutEmoji;
    for (final entry in _phoneticSpellings.entries) {
      result = result.replaceAll(
        RegExp('\\b${RegExp.escape(entry.key)}\\b', caseSensitive: false),
        entry.value,
      );
    }
    result = result
        .replaceAllMapped(RegExp(r'\b\d+\b'), (match) {
          final number = int.parse(match[0]!);
          return _numberWords[number] ?? match[0]!;
        })
        .replaceAll('+', ' plus ')
        .replaceAll('−', ' minus ')
        .replaceAll('-', ' minus ')
        .replaceAll('=', ' equals ')
        .replaceAll(RegExp(r'\bequals\s*\?'), 'equals what?')
        .replaceAll(RegExp(r'\bplus\s+equals\b'), 'equals')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAllMapped(
          RegExp(r'\s+([,.!?])'),
          (match) => match[1]!,
        )
        .replaceAllMapped(
          RegExp(r'([,.!?])(?=\S)'),
          (match) => '${match[1]} ',
        )
        .trim();
    return result;
  }

  static String? _countQuestion(String text) {
    final lines = text.split('\n');
    if (lines.length < 2) return null;
    final question = RegExp(
      r'^How many ([a-z ]+)\?$',
      caseSensitive: false,
    ).firstMatch(lines.last.trim());
    if (question == null) return null;

    final emojiCounts = <int, int>{};
    for (final rune in lines.take(lines.length - 1).join().runes) {
      if (_isEmoji(rune) && _objects.containsKey(rune)) {
        emojiCounts.update(rune, (count) => count + 1, ifAbsent: () => 1);
      } else if (!_isDecoration(rune) && !_isWhitespace(rune)) {
        return null;
      }
    }
    if (emojiCounts.length != 1) return null;

    final entry = emojiCounts.entries.single;
    final count = entry.value;
    final object = _objects[entry.key]!;
    final noun = count == 1 ? object[0] : object[1];
    return '${_numberWords[count] ?? count} $noun';
  }

  static String _removeDecorativeSymbols(String line) {
    final buffer = StringBuffer();
    for (final rune in line.runes) {
      if (!_isDecoration(rune)) buffer.writeCharCode(rune);
    }
    return buffer
        .toString()
        .replaceAll(RegExp(r'_+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static bool _isWhitespace(int rune) =>
      rune == 0x20 || (rune >= 0x09 && rune <= 0x0D);

  static bool _isEmoji(int rune) =>
      (rune >= 0x1F000 && rune <= 0x1FAFF) ||
      (rune >= 0x2600 && rune <= 0x27BF) ||
      (rune >= 0x2B00 && rune <= 0x2BFF) ||
      (rune >= 0x2300 && rune <= 0x23FF);

  static bool _isDecoration(int rune) =>
      _isEmoji(rune) ||
      rune == 0x200D ||
      rune == 0xFE0E ||
      rune == 0xFE0F ||
      rune == 0x20E3 ||
      (rune >= 0x2190 && rune <= 0x21FF) ||
      (rune >= 0x25A0 && rune <= 0x25FF);
}
