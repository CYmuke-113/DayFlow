
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'todo.dart';
import 'schedule_event.dart';
import 'settings_page.dart';

void main() {
  runApp(const DayFlowApp());
}

class DayFlowApp extends StatelessWidget {
  const DayFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DayFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedTab = 0;
  final prefs = SharedPreferencesAsync();
  bool isLoadingEvents = true, isLoadingTodos = true;

  final List<ScheduleEvent> events = [
    ScheduleEvent(
        title: '学习 Flutter',
        startTime: DateTime(2026, 10, 9, 14, 30)
    ),
  ];

  final List<Todo> todos = [
    Todo(title: '完成 Flutter Demo'),
    Todo(title: '阅读微北洋项目代码'),
  ];

  @override
  void initState() {
    super.initState();
    loadTodos();
    loadEvents();
  }

  Future<void> addEvent() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year, 1, 1),
      lastDate: DateTime(now.year + 5, 12, 31),
    );

    if (date == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (time == null) {
      return;
    }

    final startTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (!mounted) {
      return;
    }

    String input = '';

    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('新增日程'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '输入日程标题',
            ),
            onChanged: (value) {
              input = value;
            },
            onSubmitted: (value) {
              Navigator.pop(dialogContext, value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, input.trim());
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );

    if (!mounted || title == null || title.isEmpty) {
      return;
    }

    setState(() {
      events.add(
        ScheduleEvent(
          title: title,
          startTime: startTime,
        ),
      );
    });

    events.sort((a, b) {
      return a.startTime.compareTo(b.startTime);
    });

    await saveEvents();
  }

  Future<void> saveEvents() async {
    final data = <Map<String, dynamic>>[];
    for(final event in events) {
      data.add(event.toJson());
    }

    final jsonText = jsonEncode(data);

    await prefs.setString('events', jsonText);

    debugPrint("日程保存调用已完成");
  }

  Future<void> loadEvents() async {
    final jsonText = await prefs.getString('events');

    if(!mounted) {
      return;
    }

    if(jsonText == null) {
      setState( () {
        isLoadingEvents = false;
      });
      return;
    }

    final data = jsonDecode(jsonText) as List<dynamic>;

    final restoredEvents = <ScheduleEvent>[];
    for (final item in data) {
      restoredEvents.add(ScheduleEvent.fromJson(item as Map<String, dynamic>));
    }

    setState(() {
      events.clear();
      events.addAll(restoredEvents);
      isLoadingEvents = false;
    });
  }

  Future<void> addTodo() async {
    String input = '';

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('新增待办'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '输入待办内容',
            ),
            onChanged: (value) {
              input = value;
            },
            onSubmitted: (value) {
              Navigator.pop(dialogContext, value.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, input.trim());
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null || result.isEmpty) {
      return;
    }

    // 默认没有截止时间。
    DateTime? deadline;

    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5, 12, 31),
    );

    if (!mounted) {
      return;
    }

// 只有选择了日期，才继续选择时间。
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (!mounted) {
        return;
      }

      // 日期和时间都选好了，才设置截止时间。
      if (time != null) {
        deadline = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      }
    }

    setState(() {
      todos.add(
        Todo(
          title: result,
          deadline: deadline,
        ));
    });

    await saveTodos();
  }

  Future<void> saveTodos() async {
    final data = <Map<String, dynamic>>[];
    for (final todo in todos) {
      data.add(todo.toJson());
    }

    final jsonText = jsonEncode(data);

    debugPrint(data.toString());
    debugPrint(jsonText);

    await prefs.setString('todos', jsonText);

    debugPrint('待办保存调用已完成');
  }

  Future<void> loadTodos() async {
    final jsonText = await prefs.getString('todos');

    if (!mounted) {
      return;
    }

    if (jsonText == null) {
      setState(() {
        isLoadingTodos = false;
      });
      return;
    }

    final data = jsonDecode(jsonText) as List<dynamic>;

    final restoredTodos = <Todo>[];
    for (final item in data) {
      restoredTodos.add(Todo.fromJson(item as Map<String, dynamic>));
    }

    setState(() {
      todos.clear();
      todos.addAll(restoredTodos);
      isLoadingTodos = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSchedule = selectedTab == 0;
    final isLoading = isSchedule ? isLoadingEvents : isLoadingTodos;

    return Scaffold(
      appBar: AppBar(
        title: Text(isSchedule ? '日程' : '代办'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            tooltip: '设置',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                    builder: (context) {
                      return const SettingsPage();
                    }
                )
              );
            },
          )
        ],
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: isSchedule ? events.length : todos.length,
        itemBuilder: (context, index) {
          final title = isSchedule ? events[index].title : todos[index].title;
          return Card(
            child: ListTile(
              horizontalTitleGap: 4,
              leading: isSchedule
                ? const Icon(Icons.circle, size: 8)
                : Checkbox(
                  value: todos[index].isDone,
                  onChanged: (value) async {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      todos[index].isDone = value;
                    });
                    await saveTodos();
                  },
                ),
              title: Text(title),
              subtitle: isSchedule
                  ? Text(formatDateTime(events[index].startTime))
                  : todos[index].deadline == null
                    ? null
                    : Text('截止：${formatDateTime(todos[index].deadline!)}'),
              trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: '删除',
                          onPressed: () async {
                            setState(() {
                              if (isSchedule) {
                                events.removeAt(index);
                              } else {
                                todos.removeAt(index);
                              }
                            });
                            if (isSchedule) {
                              await saveEvents();
                            } else {
                              await saveTodos();
                            }
                          },
                        ),
            ),
          );
        },
      ),

      floatingActionButton: isLoading
          ? null
          : FloatingActionButton(
        onPressed: isSchedule ? addEvent : addTodo,
        child: const Icon(Icons.add),
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedTab,
        onDestinationSelected: (index) {
          setState(() {
            selectedTab = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month),
            label: '日程',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist),
            label: '待办',
          ),
        ],
      ),
    );
  }

  String formatDateTime(DateTime time) {
    final month = time.month.toString().padLeft(2, '0');
    final day = time.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '${time.year}-$month-$day $hour:$minute';
  }
}