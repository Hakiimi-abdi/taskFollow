import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskfollow/View/pages/edit_task.dart';
import 'package:taskfollow/View/pages/login_page.dart';
import 'package:taskfollow/data/notifiers.dart';
import 'package:taskfollow/data/task.dart';

class DashboardPage extends StatefulWidget {
  final String userName;
  const DashboardPage({super.key, required this.userName});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Task> tasks = [
    Task(
      id: '1',
      title: 'Learn Flutter',
      description: 'Complete the bootcapm challenge',
      isCompleted: false,
    ),
    Task(
      id: '2',
      title: 'Build a project',
      description: 'Create a project',
      isCompleted: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? taskStringList = prefs.getStringList('tasks');
    if (taskStringList != null) {
      setState(() {
        tasks = taskStringList
            .map((task) => Task.fromJson(jsonDecode(task)))
            .toList();
      });
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = tasks.map((task) => jsonEncode(task.toJson())).toList();
    await prefs.setStringList('tasks', stringList);
  }

  void _addTaskDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add New Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                setState(() {
                  tasks.add(
                    Task(
                      id: DateTime.now().toString(),
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      isCompleted: false,
                    ),
                  );
                });
                _saveData();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _toggleTask(String id) {
    setState(() {
      final task = tasks.firstWhere((task) => task.id == id);
      task.isCompleted = !task.isCompleted;
    });
    _saveData();
  }

  void _updateTask(Task updatedTask) {
    setState(() {
      final index = tasks.indexWhere((task) => task.id == updatedTask.id);
      if (index != -1) {
        tasks[index] = updatedTask;
      }
    });
    _saveData();
  }

  void _deleteTask(String id) {
    setState(() {
      tasks.removeWhere((task) => task.id == id);
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.userName}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () async {
              isDarkModeNotifier.value = !isDarkModeNotifier.value;
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('themeMode', isDarkModeNotifier.value);
            },
            icon: ValueListenableBuilder(
              valueListenable: isDarkModeNotifier,
              builder: (context, isDarkMode, child) {
                return Icon(
                  isDarkMode
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                );
              },
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
                (route) => false,
              );
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: tasks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task, size: 80, color: Colors.grey.shade400),
                  SizedBox(height: 20),
                  Text(
                    'No tasks yet!',
                    style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
                  ),
                  Text(
                    'Tap + to add your first task',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Card(
                  elevation: 2,
                  margin: EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return EditTask(task: task);
                          },
                        ),
                      );
                      if (result == 'delete') {
                        _deleteTask(task.id);
                      } else if (result is Task) {
                        _updateTask(result);
                      }
                    },
                    title: Text(
                      task.title,
                      style: TextStyle(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isCompleted ? Colors.grey : null,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: task.description.isNotEmpty
                        ? Text(task.description)
                        : null,
                    leading: Checkbox(
                      value: task.isCompleted,
                      onChanged: (_) {
                        _toggleTask(task.id);
                      },
                    ),
                    trailing: IconButton(
                      onPressed: () {
                        _deleteTask(task.id);
                      },
                      icon: Icon(Icons.delete, color: Colors.red),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addTaskDialog();
        },
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: Icon(Icons.add),
      ),
    );
  }
}
