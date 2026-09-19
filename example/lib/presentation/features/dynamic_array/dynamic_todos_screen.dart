import 'dart:async';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:mk_forms/mk_forms.dart';
import '../../../core/di/injection.dart';
import 'bloc/dynamic_todos_form_bloc.dart';

/// Screen demonstrating dynamic array forms powered by [DynamicTodosFormBloc].
@RoutePage()
class DynamicTodosScreen extends StatefulWidget {
  const DynamicTodosScreen({
    super.key,
    DynamicTodosFormBloc? formBloc,
  }) : _formBloc = formBloc;

  final DynamicTodosFormBloc? _formBloc;

  @override
  State<DynamicTodosScreen> createState() => _DynamicTodosScreenState();
}

class _DynamicTodosScreenState extends State<DynamicTodosScreen> {
  late final DynamicTodosFormBloc _formBloc;

  @override
  void initState() {
    super.initState();
    _formBloc = widget._formBloc ?? getIt<DynamicTodosFormBloc>();
  }

  @override
  void dispose() {
    unawaited(_formBloc.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tasksArray = _formBloc.tasksArray;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Array Controls'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Task',
            onPressed: () => _formBloc.addTask(),
          ),
        ],
      ),
      body: MkFormScope(
        formBloc: _formBloc,
        child: MkFormListener(
          formBloc: _formBloc,
          onSuccess: (context, response) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Saved ${tasksArray.length} tasks!'),
                backgroundColor: Colors.green,
              ),
            );
          },
          child: StreamBuilder<MkArrayState<MkFieldBloc<String>>>(
            stream: tasksArray.stream,
            initialData: tasksArray.state,
            builder: (context, snapshot) {
              final tasksState = snapshot.data!;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    elevation: 0,
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Dynamic Forms with MkArrayBloc:\n'
                        '• Dynamically append and remove form controls.\n'
                        '• All items inherit reactive validation lifecycle.\n'
                        '• Form submission automatically aggregates values into a List.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (tasksState.controls.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('No tasks yet. Tap "+" above to add one.'),
                      ),
                    ),
                  for (int i = 0; i < tasksState.controls.length; i++)
                    Card(
                      key: ValueKey(tasksState.controls[i]),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              child: Text(
                                '${i + 1}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: MkTextField(
                                fieldBloc: tasksState.controls[i],
                                decoration: InputDecoration(
                                  labelText: 'Task #${i + 1}',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              color: Colors.red.shade400,
                              onPressed: () => _formBloc.removeTaskAt(i),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => _formBloc.submit(),
                    child: const Text('Save All Tasks'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _formBloc.addTask(),
                    child: const Text('Add Another Task'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
