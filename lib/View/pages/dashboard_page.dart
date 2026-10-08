import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskfollow/View/pages/add_task_page.dart';
import 'package:taskfollow/View/pages/edit_task.dart';
import 'package:taskfollow/View/pages/login_page.dart';
import 'package:taskfollow/View/widgets/desktop_wrapper.dart';
import 'package:taskfollow/data/notifiers.dart';
import 'package:taskfollow/data/task.dart';
import 'package:taskfollow/services/notification_service.dart';

class DashboardPage extends StatefulWidget {
  final String userName;
  const DashboardPage({super.key, required this.userName});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _toggleTask(String id, bool currentValue) async {
    await FirebaseFirestore.instance.collection('tasks').doc(id).update({
      'isCompleted': !currentValue,
    });
  }

  void _updateTask(Task updatedTask) async {
    if (updatedTask.dueDate != null) {
      await NotificationService().scheduleTaskNotification(
        id: updatedTask.id.hashCode & 0x7FFFFFFF,
        title: updatedTask.title,
        body: updatedTask.description,
        scheduledTime: updatedTask.dueDate!,
      );
    } else {
      await NotificationService().cancelNotification(
        updatedTask.id.hashCode & 0x7FFFFFFF,
      );
    }

    await FirebaseFirestore.instance
        .collection('tasks')
        .doc(updatedTask.id)
        .update({
          'id': updatedTask.id,
          'title': updatedTask.title,
          'description': updatedTask.description,
          'isCompleted': updatedTask.isCompleted,
          'dueDate': updatedTask.dueDate != null
              ? Timestamp.fromDate(updatedTask.dueDate!)
              : null,
        });
  }

  void _deleteTask(String id) async {
    await NotificationService().cancelNotification(id.hashCode & 0x7FFFFFFF);
    await FirebaseFirestore.instance.collection('tasks').doc(id).delete();
  }

  Future<void> _handleLogout() async {
    final logout = await FirebaseAuth.instance.signOut();
    if (!mounted) {
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (route) => false,
    );
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
              _handleLogout();
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      body: DesktopWrapper(
        maxWidth: 850,
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('tasks')
              .where(
                'userId',
                isEqualTo: FirebaseAuth.instance.currentUser!.uid,
              )
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator.adaptive());
            } else if (snapshot.hasError) {
              return Center(child: Text('An error occurred!'));
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.task, size: 80, color: Colors.grey.shade400),
                    SizedBox(height: 20),
                    Text(
                      'No tasks yet!',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'Tap + to add your first task',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data();

                final task = Task.fromJson(doc.id, data);
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
                          builder: (context) => EditTask(task: task),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (task.description.isNotEmpty) ...[
                          Text(task.description),
                          SizedBox(height: 4),
                        ],
                        if (task.dueDate != null) ...[
                          Row(
                            children: [
                              Icon(
                                task.isOverdue
                                    ? Icons.error_outline
                                    : Icons.schedule,
                                size: 14,
                                color: task.isOverdue
                                    ? Colors.red
                                    : task.isDueToday
                                    ? Colors.orange
                                    : Colors.grey,
                              ),
                              SizedBox(width: 4),
                              Text(
                                _formatDate(task.dueDate!),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: task.isOverdue
                                      ? Colors.red
                                      : task.isDueToday
                                      ? Colors.orange
                                      : Colors.grey,
                                  fontWeight: task.isOverdue || task.isDueToday
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    leading: Checkbox(
                      value: task.isCompleted,
                      onChanged: (value) {
                        _toggleTask(task.id, task.isCompleted);
                      },
                    ),
                    trailing: IconButton(
                      onPressed: () => _deleteTask(task.id),
                      icon: Icon(Icons.delete_outline, color: Colors.red),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTaskPage()),
          );
        },
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: Icon(Icons.add),
      ),
    );
  }
}
