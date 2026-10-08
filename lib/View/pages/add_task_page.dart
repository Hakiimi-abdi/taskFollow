import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:taskfollow/services/notification_service.dart';
import 'package:taskfollow/View/widgets/resposive_wrapper.dart';

class AddTaskPage extends StatefulWidget {
  const AddTaskPage({super.key});

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDueDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _saveTask() async {
    if (_titleController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = await FirebaseFirestore.instance.collection('tasks').add({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'isCompleted': false,
        'userId': user.uid,
        'dueDate': _selectedDueDate != null
            ? Timestamp.fromDate(_selectedDueDate!)
            : null,
      });

      if (_selectedDueDate != null) {
        await NotificationService().scheduleTaskNotification(
          id: docRef.id.hashCode & 0x7FFFFFFF,
          title: _titleController.text.trim(),
          body: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : 'Your task is due now!',
          scheduledTime: _selectedDueDate!,
        );
      }
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Task'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ResposiveWrapper(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.description),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDueDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365 * 5),
                      ),
                    );
                    if (picked != null) {
                      if (!context.mounted) return;
                      final TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(
                          _selectedDueDate ?? DateTime.now(),
                        ),
                      );
                      setState(() {
                        _selectedDueDate = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          time?.hour ?? 12,
                          time?.minute ?? 0,
                        );
                      });
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Due Date (optional)',
                      prefixIcon: Icon(
                        Icons.calendar_today,
                        color: Colors.teal.shade700,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: _selectedDueDate != null
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () =>
                                  setState(() => _selectedDueDate = null),
                            )
                          : null,
                    ),
                    child: Text(
                      _selectedDueDate == null
                          ? 'No due date'
                          : _formatDate(_selectedDueDate!),
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDueDate == null
                            ? Colors.grey
                            : Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveTask,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save Task'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
