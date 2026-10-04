import 'dart:math';

class ParentGateQuestion {
  const ParentGateQuestion({
    required this.left,
    required this.operator,
    required this.right,
  });

  final int left;
  final String operator;
  final int right;

  int get answer => operator == '+' ? left + right : left * right;

  String get expression => '$left $operator $right';
}

ParentGateQuestion generateParentGateQuestion({Random? random}) {
  final source = random ?? Random();
  if (source.nextBool()) {
    final leftTens = source.nextInt(9) + 1;
    final leftOnes = source.nextInt(9) + 1;
    final rightTens = source.nextInt(9) + 1;
    final minRightOnes = 10 - leftOnes;
    final rightOnes = minRightOnes + source.nextInt(10 - minRightOnes);
    final left = leftTens * 10 + leftOnes;
    final right = rightTens * 10 + rightOnes;
    return ParentGateQuestion(left: left, operator: '+', right: right);
  }

  return ParentGateQuestion(
    left: source.nextInt(4) + 6,
    operator: '×',
    right: source.nextInt(4) + 6,
  );
}
