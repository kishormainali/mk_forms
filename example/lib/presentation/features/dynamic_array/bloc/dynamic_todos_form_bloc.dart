import 'package:injectable/injectable.dart';
import 'package:mk_forms/mk_forms.dart';
import '../../../../data/repositories/task_repository.dart';

/// Form BLoC managing a dynamic array of task fields and their persistence.
@injectable
class DynamicTodosFormBloc extends MkFormBloc {
  DynamicTodosFormBloc(this._taskRepository)
      : super(
          controls: {
            'tasks': MkArrayBloc<MkFieldBloc<String>>([
              _createTaskField('Design system tokens'),
              _createTaskField('Write unit tests'),
            ]),
          },
        );

  final TaskRepository _taskRepository;

  MkArrayBloc<MkFieldBloc<String>> get tasksArray =>
      controls['tasks']! as MkArrayBloc<MkFieldBloc<String>>;

  static MkFieldBloc<String> _createTaskField([String initial = '']) {
    return MkFieldBloc<String>(
      initialValue: initial,
      validators: [
        MkValidators.required('Task description cannot be empty'),
        MkValidators.minLength(3, 'At least 3 characters required'),
      ],
    );
  }

  void addTask([String initial = '']) {
    tasksArray.add(_createTaskField(initial));
  }

  void removeTaskAt(int index) {
    if (tasksArray.length > 1) {
      tasksArray.removeAt(index);
    }
  }

  @override
  Future<void> onSubmit(Map<String, dynamic> values) async {
    final tasks = (values['tasks'] as List<dynamic>).cast<String>();
    await _taskRepository.saveTasks(tasks);
  }
}
