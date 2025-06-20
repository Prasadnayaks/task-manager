part of 'tasks_cubit.dart';

sealed class TasksState {
  const TasksState();
}

final class TasksInitial extends TasksState {}

final class TasksLoading extends TasksState {}

final class TasksError extends TasksState {
  final String error;
  TasksError(this.error);
}

// This is now the ONLY success state we need.
// It holds the data and signals a successful operation.
final class GetTasksSuccess extends TasksState {
  final List<TaskModel> tasks;
  const GetTasksSuccess(this.tasks);
}