class Todo {
  final String title;
  bool isDone;
  final DateTime? deadline;

  Todo({
    required this.title,
    this.isDone = false,
    this.deadline,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'isDone': isDone,
      'dueDate': deadline?.toIso8601String(),
    };
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    final deadlineText = json['dueDate'] as String?;

    return Todo(
      title: json['title'] as String,
      isDone: json['isDone'] as bool,
      deadline: deadlineText == null
          ? null
          : DateTime.parse(deadlineText),
    );
  }
}