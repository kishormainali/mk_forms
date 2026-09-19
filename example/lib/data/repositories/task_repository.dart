import 'package:injectable/injectable.dart';
import '../models/task_item.dart';

/// Repository interface for dynamic todo items.
abstract class TaskRepository {
  Future<List<TaskItem>> getTasks();
  Future<void> saveTasks(List<String> titles);
}

/// Implementation of [TaskRepository].
@LazySingleton(as: TaskRepository)
class TaskRepositoryImpl implements TaskRepository {
  final List<TaskItem> _tasks = [
    const TaskItem(id: '1', title: 'Design system tokens'),
    const TaskItem(id: '2', title: 'Write unit tests'),
  ];

  @override
  Future<List<TaskItem>> getTasks() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_tasks);
  }

  @override
  Future<void> saveTasks(List<String> titles) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _tasks.clear();
    for (int i = 0; i < titles.length; i++) {
      _tasks.add(TaskItem(id: '${i + 1}', title: titles[i]));
    }
  }
}
