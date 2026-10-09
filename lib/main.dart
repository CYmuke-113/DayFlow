
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'todo.dart';
import 'schedule_event.dart';

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
  bool isLoadingTodos = true;

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

    setState(() {
      todos.add(Todo(title: result));
    });

    await saveTodos();
  }

  Future<void> saveTodos() async {
    final data = todos.map((todo) => todo.toJson()).toList();
    final jsonText = jsonEncode(data);

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

    final restoredTodos = data.map((item) {
      return Todo.fromJson(item as Map<String, dynamic>);
    }).toList();

    setState(() {
      todos.clear();
      todos.addAll(restoredTodos);
      isLoadingTodos = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSchedule = selectedTab == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedTab == 0 ? '日程' : '代办'),
      ),

      body: isLoadingTodos
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
              leading: isSchedule
                ? const Icon(Icons.event)
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
                  : null,
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
                            if (!isSchedule) {
                              await saveTodos();
                            }
                          },
                        ),
            ),
          );
        },
      ),

      floatingActionButton: isLoadingTodos
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