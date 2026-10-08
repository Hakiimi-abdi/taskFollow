import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String description;
  bool isCompleted;
  DateTime? dueDate;

  Task({
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    this.dueDate,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'isCompleted': isCompleted,
    'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
  };

  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  factory Task.fromJson(String id, Map<String, dynamic> json) {
    DateTime? parsedDueDate;
    if (json['dueDate'] != null) {
      if (json['dueDate'] is Timestamp) {
        parsedDueDate = (json['dueDate'] as Timestamp).toDate();
      } else if (json['dueDate'] is String) {
        parsedDueDate = DateTime.tryParse(json['dueDate']);
      }
    }

    return Task(
      id: id,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      isCompleted: json['isCompleted'] ?? false,
      dueDate: parsedDueDate,
    );
  }
}
