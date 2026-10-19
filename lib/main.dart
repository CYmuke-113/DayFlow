
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
    String input = '';
    DateTime? startTime, endTime;

    final result = await showDialog<String> (
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final invalidTimeRange = startTime != null
                  && endTime != null
                  && endTime!.isBefore(startTime!);
              return AlertDialog(
                title: const Text('新增日程'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: '输入日程内容'
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            input = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text('开始时间'),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.calendar_month),
                              label: Text(
                                startTime == null
                                    ? '未设置'
                                    : formatDateTime(startTime!)
                              ),
                              onPressed: () async {
                                final now = DateTime.now();

                                final date = await showDatePicker(
                                    context: context,
                                    initialDate: startTime == null
                                        || startTime!.isBefore(now)
                                        ? now
                                        : startTime,
                                    firstDate: now,
                                    lastDate: DateTime(
                                      now.year + 5,
                                      12,
                                      31
                                    )
                                );

                                if (!context.mounted || date == null) {
                                  return;
                                }

                                final time = await showTimePicker(
                                    context: context,
                                    initialTime: startTime == null
                                        ? TimeOfDay.fromDateTime(now)
                                        : TimeOfDay.fromDateTime(startTime!)
                                );

                                if (!context.mounted || time == null) {
                                  return;
                                }

                                setDialogState(() {
                                  startTime = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    time.hour,
                                    time.minute
                                  );
                                });
                              },
                            )
                          ),
                        ],
                      ),
                      if (startTime == null)
                        Text(
                          '开始时间为必填项！',
                          style: TextStyle(
                            color: Colors.red
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Text('结束时间（可选）'),
                      Row(
                        children: [
                          Expanded(
                              child: TextButton.icon(
                                icon: const Icon(Icons.calendar_month),
                                label: Text(
                                    endTime == null
                                        ? '未设置'
                                        : formatDateTime(endTime!)
                                ),
                                onPressed: () async {
                                  final now = DateTime.now();

                                  final date = await showDatePicker(
                                      context: context,
                                      initialDate: endTime == null
                                          || endTime!.isBefore(now)
                                          ? now
                                          : endTime,
                                      firstDate: now,
                                      lastDate: DateTime(
                                          now.year + 5,
                                          12,
                                          31
                                      )
                                  );

                                  if(!context.mounted || date == null) {
                                    return;
                                  }

                                  final time = await showTimePicker(
                                      context: context,
                                      initialTime: endTime == null
                                          ? TimeOfDay.fromDateTime(now)
                                          : TimeOfDay.fromDateTime(endTime!)
                                  );

                                  if(!context.mounted || time == null) {
                                    return;
                                  }

                                  setDialogState(() {
                                    endTime = DateTime(
                                        date.year,
                                        date.month,
                                        date.day,
                                        time.hour,
                                        time.minute
                                    );
                                  });
                                },
                              )
                          ),
                          if (endTime != null)
                            IconButton(
                              onPressed: () {
                                setDialogState(() {
                                  endTime = null;
                                });
                              },
                            icon: const Icon(Icons.close),
                            tooltip: '清除结束时间',
                            )
                        ]
                      ),
                      if(invalidTimeRange)
                        Text(
                            '开始时间不能晚于结束时间！',
                            style: TextStyle(
                              color: Colors.red
                            ),
                        )
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('取消'),
                  ),
                  FilledButton(
                      onPressed: input.trim() == ''
                          || startTime == null
                          || invalidTimeRange
                          ? null
                          : () {
                          Navigator.pop(context, input.trim());
                      },
                      child: const Text('添加'),
                  ),
                ],
              );
            },
          );
        }
    );

    if (!mounted ||  result == null) {
      return;
    }

    setState(() {
      events.add(
        ScheduleEvent(
          title: result,
          startTime: startTime!,
          endTime: endTime
        ),
      );
    });

    events.sort((a, b) {
      return a.startTime.compareTo(b.startTime);
    });

    await saveEvents();
  }

  Future<void> editEvent(ScheduleEvent event) async {
    String input = event.title;
    DateTime? startTime = event.startTime, endTime = event.endTime;

    final result = await showDialog<String> (
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              final invalidTimeRange = startTime != null
                  && endTime != null
                  && endTime!.isBefore(startTime!);
              return AlertDialog(
                title: const Text('编辑日程'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: input,
                        autofocus: true,
                        decoration: const InputDecoration(
                            hintText: '输入日程内容'
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            input = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text('开始时间'),
                      Row(
                        children: [
                          Expanded(
                              child: TextButton.icon(
                                icon: const Icon(Icons.calendar_month),
                                label: Text(
                                    startTime == null
                                        ? '未设置'
                                        : formatDateTime(startTime!)
                                ),
                                onPressed: () async {
                                  final now = DateTime.now();

                                  final date = await showDatePicker(
                                      context: context,
                                      initialDate: startTime == null
                                          || startTime!.isBefore(now)
                                          ? now
                                          : startTime,
                                      firstDate: now,
                                      lastDate: DateTime(
                                          now.year + 5,
                                          12,
                                          31
                                      )
                                  );

                                  if (!context.mounted || date == null) {
                                    return;
                                  }

                                  final time = await showTimePicker(
                                      context: context,
                                      initialTime: startTime == null
                                          ? TimeOfDay.fromDateTime(now)
                                          : TimeOfDay.fromDateTime(startTime!)
                                  );

                                  if (!context.mounted || time == null) {
                                    return;
                                  }

                                  setDialogState(() {
                                    startTime = DateTime(
                                        date.year,
                                        date.month,
                                        date.day,
                                        time.hour,
                                        time.minute
                                    );
                                  });
                                },
                              )
                          ),
                        ],
                      ),
                      if (startTime == null)
                        Text(
                          '开始时间为必填项！',
                          style: TextStyle(
                              color: Colors.red
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Text('结束时间（可选）'),
                      Row(
                          children: [
                            Expanded(
                                child: TextButton.icon(
                                  icon: const Icon(Icons.calendar_month),
                                  label: Text(
                                      endTime == null
                                          ? '未设置'
                                          : formatDateTime(endTime!)
                                  ),
                                  onPressed: () async {
                                    final now = DateTime.now();

                                    final date = await showDatePicker(
                                        context: context,
                                        initialDate: endTime == null
                                            || endTime!.isBefore(now)
                                            ? now
                                            : endTime,
                                        firstDate: now,
                                        lastDate: DateTime(
                                            now.year + 5,
                                            12,
                                            31
                                        )
                                    );

                                    if(!context.mounted || date == null) {
                                      return;
                                    }

                                    final time = await showTimePicker(
                                        context: context,
                                        initialTime: endTime == null
                                            ? TimeOfDay.fromDateTime(now)
                                            : TimeOfDay.fromDateTime(endTime!)
                                    );

                                    if(!context.mounted || time == null) {
                                      return;
                                    }

                                    setDialogState(() {
                                      endTime = DateTime(
                                          date.year,
                                          date.month,
                                          date.day,
                                          time.hour,
                                          time.minute
                                      );
                                    });
                                  },
                                )
                            ),
                            if (endTime != null)
                              IconButton(
                                onPressed: () {
                                  setDialogState(() {
                                    endTime = null;
                                  });
                                },
                                icon: const Icon(Icons.close),
                                tooltip: '清除结束时间',
                              )
                          ]
                      ),
                      if(invalidTimeRange)
                        Text(
                          '开始时间不能晚于结束时间！',
                          style: TextStyle(
                              color: Colors.red
                          ),
                        )
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('取消'),
                  ),
                  FilledButton(
                    onPressed: input.trim() == ''
                        || startTime == null
                        || invalidTimeRange
                        ? null
                        : () {
                      Navigator.pop(context, input.trim());
                    },
                    child: const Text('保存'),
                  ),
                ],
              );
            },
          );
        }
    );

    if (!mounted ||  result == null) {
      return;
    }

    final index = events.indexOf(event);

    if(index == -1) {
      return;
    }

    setState(() {
      events[index] = ScheduleEvent(
          title: result,
          startTime: startTime!,
          endTime: endTime
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
    DateTime? deadline;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('新增待办'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: '输入待办内容'
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            input = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text('截止时间（可选）'),
                      Row(
                        children: [
                          Expanded(
                              child: TextButton.icon(
                                  icon: const Icon(Icons.calendar_month),
                                  label: Text(
                                    deadline == null
                                        ? '未设置'
                                        : formatDateTime(deadline!)
                                  ),
                                  onPressed: () async {
                                    final now = DateTime.now();

                                    final date = await showDatePicker(
                                        context: context,
                                        initialDate: deadline == null
                                          || deadline!.isBefore(now)
                                          ? now
                                          :deadline,
                                        firstDate: now,
                                        lastDate: DateTime(
                                          now.year + 5,
                                          12,
                                          31
                                        )
                                    );

                                    if (!context.mounted || date == null) {
                                      return;
                                    }

                                    final time = await showTimePicker(
                                        context: context,
                                        initialTime: deadline == null
                                          ? TimeOfDay.fromDateTime(now)
                                          : TimeOfDay.fromDateTime(deadline!)
                                    );

                                    if (!context.mounted || time == null) {
                                      return;
                                    }

                                    setDialogState(() {
                                      deadline = DateTime(
                                        date.year,
                                        date.month,
                                        date.day,
                                        time.hour,
                                        time.minute
                                      );
                                    });
                                  },
                              ),
                          ),
                          if (deadline != null)
                            IconButton(
                              icon: const Icon(Icons.close),
                              tooltip: '清除截止时间',
                              onPressed: () {
                                setDialogState(() {
                                  deadline = null;
                                });
                              },
                            )
                        ],
                      )
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      child: const Text('取消'),
                  ),
                  FilledButton(
                      onPressed: input.trim() == ''
                        ? null
                        : () {
                            Navigator.pop(dialogContext, input.trim());
                      },
                      child: const Text('添加'),
                  ),
                ],
              );
            }
        );
      },
    );

    if (!mounted || result == null || result.isEmpty) {
      return;
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

  Future<void> editTodo(Todo todo) async {
    String input = todo.title;
    DateTime? deadline = todo.deadline;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('编辑待办'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        initialValue: input,
                        autofocus: true,
                        decoration: const InputDecoration(
                            hintText: '输入待办内容'
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            input = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text('截止时间（可选）'),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              icon: const Icon(Icons.calendar_month),
                              label: Text(
                                  deadline == null
                                      ? '未设置'
                                      : formatDateTime(deadline!)
                              ),
                              onPressed: () async {
                                final now = DateTime.now();

                                final date = await showDatePicker(
                                    context: context,
                                    initialDate: deadline == null
                                        || deadline!.isBefore(now)
                                        ? now
                                        :deadline,
                                    firstDate: now,
                                    lastDate: DateTime(
                                        now.year + 5,
                                        12,
                                        31
                                    )
                                );

                                if (!context.mounted || date == null) {
                                  return;
                                }

                                final time = await showTimePicker(
                                    context: context,
                                    initialTime: deadline == null
                                        ? TimeOfDay.fromDateTime(now)
                                        : TimeOfDay.fromDateTime(deadline!)
                                );

                                if (!context.mounted || time == null) {
                                  return;
                                }

                                setDialogState(() {
                                  deadline = DateTime(
                                      date.year,
                                      date.month,
                                      date.day,
                                      time.hour,
                                      time.minute
                                  );
                                });
                              },
                            ),
                          ),
                          if (deadline != null)
                            IconButton(
                              icon: const Icon(Icons.close),
                              tooltip: '清除截止时间',
                              onPressed: () {
                                setDialogState(() {
                                  deadline = null;
                                });
                              },
                            )
                        ],
                      )
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: const Text('取消'),
                  ),
                  FilledButton(
                    onPressed: input.trim() == ''
                        ? null
                        : () {
                      Navigator.pop(dialogContext, input.trim());
                    },
                    child: const Text('保存'),
                  ),
                ],
              );
            }
        );
      },
    );

    if (!mounted || result == null || result.isEmpty) {
      return;
    }

    final index = todos.indexOf(todo);

    if(index == -1) {
      return;
    }

    setState(() {
      todos[index] =  Todo(
        title: result,
        deadline: deadline,
        isDone: todo.isDone
      );
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
        title: Text(isSchedule ? '日程' : '待办'),
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
            clipBehavior: Clip.antiAlias,
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
              onTap: () async {
                if(isSchedule) {
                  await editEvent(events[index]);
                } else {
                  await editTodo(todos[index]);
                }
              },
              onLongPress: () async {
                final action = await showModalBottomSheet<String>(
                    context: context,
                    builder: (sheetContext) {
                      return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: 20),
                              ListTile(
                                title: const Text(
                                    '删除',
                                    style: TextStyle(color: Colors.red),
                                ),
                                onTap: () {
                                  Navigator.pop(sheetContext, 'delete');
                                },
                              ),
                              ListTile(
                                title: const Text(
                                    '取消',
                                    style: TextStyle(color: Colors.black),
                                ),
                                onTap: () {
                                  Navigator.pop(sheetContext);
                                },
                              )
                            ],
                          )
                      );
                    }
                );

                if(!context.mounted || action == null) {
                  return;
                }

                if(action == 'delete') {
                  final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) {
                        final String type = isSchedule ? '日程' : '待办';
                        return AlertDialog(
                          title: Text('确认删除'),
                          content: Text('确定要删除$type $title 吗？'),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext, false);
                                },
                                child: Text('取消')
                            ),
                            FilledButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext, true);
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text('删除')
                            ),
                          ],
                        );
                      }
                  );

                  if(!context.mounted || confirmed != true) {
                    return;
                  }

                  setState(() {
                    if(isSchedule) {
                      events.removeAt(index);
                    } else {
                      todos.removeAt(index);
                    }
                  });
                }

                if(isSchedule) {
                  await saveEvents();
                } else {
                  await saveTodos();
                }
              },
              title: Text(title),
              subtitle: isSchedule
                  ? Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '开始：${formatDateTime(events[index].startTime)}',
                          ),
                          if(events[index].endTime != null)
                            Text(
                              '结束：${formatDateTime(events[index].endTime!)}',
                            )
                        ],
                  )
                  : todos[index].deadline == null
                    ? null
                    : Text('截止：${formatDateTime(todos[index].deadline!)}'),
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