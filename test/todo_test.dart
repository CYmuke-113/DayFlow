import 'dart:convert';

import 'package:dayflow/todo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('旧待办没有截止日期时仍可读取', () {
    final todo = Todo.fromJson({'title': '旧待办', 'isDone': false});

    expect(todo.deadline, isNull);
    expect(todo.title, '旧待办');
    expect(todo.isDone, isFalse);
  });

  test('截止日期和完成状态经过 JSON 保存后保持一致', () {
    final todo = Todo(
      title: '提交作业',
      isDone: true,
      deadline: DateTime(2026, 10, 20),
    );
    final restored = Todo.fromJson(
      jsonDecode(jsonEncode(todo.toJson())) as Map<String, dynamic>,
    );

    expect(restored.deadline, DateTime(2026, 10, 20));
    expect(restored.title, todo.title);
    expect(restored.isDone, isTrue);
  });

  test('未设置截止日期的待办保存后仍为空', () {
    final todo = Todo(title: '随时处理');

    expect(Todo.fromJson(todo.toJson()).deadline, isNull);
  });
}
