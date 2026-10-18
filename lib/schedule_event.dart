class ScheduleEvent {
  final String title;
  final DateTime startTime;
  final DateTime? endTime;

  ScheduleEvent({
    required this.title,
    required this.startTime,
    this.endTime
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String()
    };
  }

  factory ScheduleEvent.fromJson(Map<String, dynamic> json) {
    final endTimeText = json['endTime'] as String?;

    return ScheduleEvent(
        title: json['title'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: endTimeText == null
          ? null
          : DateTime.parse(endTimeText)
    );
  }
}