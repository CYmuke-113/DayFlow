class ScheduleEvent {
  final String title;
  final DateTime startTime;

  ScheduleEvent({
    required this.title,
    required this.startTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'startTime': startTime.toIso8601String(),
    };
  }

  factory ScheduleEvent.fromJson(Map<String, dynamic> json) {
    return ScheduleEvent(
        title: json['title'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
    );
  }
}