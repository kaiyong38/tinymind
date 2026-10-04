import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tinymind/models/parent_gate_question.dart';

void main() {
  test('generated questions have correct answers and require real arithmetic',
      () {
    final random = Random(42);
    var additionCount = 0;
    var multiplicationCount = 0;

    for (var i = 0; i < 200; i++) {
      final question = generateParentGateQuestion(random: random);

      if (question.operator == '+') {
        additionCount++;
        expect(question.left, inInclusiveRange(10, 99));
        expect(question.right, inInclusiveRange(10, 99));
        expect(
            question.left % 10 + question.right % 10, greaterThanOrEqualTo(10));
        expect(question.answer, question.left + question.right);
        expect(question.answer, lessThan(200));
      } else {
        multiplicationCount++;
        expect(question.operator, '×');
        expect(question.left, inInclusiveRange(6, 9));
        expect(question.right, inInclusiveRange(6, 9));
        expect(question.answer, question.left * question.right);
      }

      expect(question.answer, greaterThanOrEqualTo(10));
      expect(question.answer.toString().length, lessThanOrEqualTo(3));
    }

    expect(additionCount, greaterThan(0));
    expect(multiplicationCount, greaterThan(0));
  });
}
