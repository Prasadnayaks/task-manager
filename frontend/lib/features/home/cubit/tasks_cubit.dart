import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/constants/utils.dart';
import 'package:frontend/features/home/repository/task_local_repository.dart';
import 'package:frontend/features/home/repository/task_remote_repository.dart';
import 'package:frontend/models/task_model.dart';
import 'package:uuid/uuid.dart'; // Make sure Uuid is imported

part 'tasks_state.dart';

class TasksCubit extends Cubit<TasksState> {
  TasksCubit() : super(TasksInitial());
  final taskRemoteRepository = TaskRemoteRepository();
  final taskLocalRepository = TaskLocalRepository();

  List<TaskModel> _tasks = [];

  Future<void> getAllTasks({required String token}) async {
    try {
      emit(TasksLoading());
      _tasks = await taskRemoteRepository.getTasks(token: token);
      emit(GetTasksSuccess(List.from(_tasks)));
    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  // --- CORRECTED METHODS ---

  Future<void> createNewTask({
    required String title,
    required String description,
    required Color color,
    required String token,
    required String uid,
    required DateTime dueAt,
  }) async {
    try {
      emit(TasksLoading());
      final newTask = TaskModel(
        id: const Uuid().v6(),
        uid: uid,
        title: title,
        description: description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        dueAt: dueAt,
        color: color,
        isSynced: 0,
        isDeleted: false,
      );

      _tasks.add(newTask);
      await taskLocalRepository.insertTask(newTask);

      // Emit ONE state that contains the new list. This will trigger
      // both the HomePage rebuild and the AddNewTaskPage listener.
      emit(GetTasksSuccess(List.from(_tasks)));

      // Sync in background
      final syncedTask = await taskRemoteRepository.createTask(
          uid: uid, title: title, description: description, hexColor: rgbToHex(color), token: token, dueAt: dueAt);
      await taskLocalRepository.updateTask(syncedTask.copyWith(isSynced: 1));

    } catch (e) {
      emit(TasksError(e.toString()));
    }
  }

  Future<void> updateExistingTask({
    required TaskModel task,
    required String token,
  }) async {
    try {
      final offlineTask = task.copyWith(isSynced: 0, updatedAt: DateTime.now());
      final index = _tasks.indexWhere((t) => t.id == task.id);

      if (index != -1) {
        await taskLocalRepository.updateTask(offlineTask);
        _tasks[index] = offlineTask;
        emit(GetTasksSuccess(List.from(_tasks)));
      }

      final syncedTask = await taskRemoteRepository.updateTask(token: token, task: offlineTask);
      await taskLocalRepository.updateTask(syncedTask.copyWith(isSynced: 1));
      _tasks[index] = syncedTask.copyWith(isSynced: 1);
      emit(GetTasksSuccess(List.from(_tasks)));
    } catch (e) {
      print("Remote update failed, will sync later: $e");
    }
  }

  Future<void> deleteExistingTask({
    required TaskModel task,
    required String token,
  }) async {
    try {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        final deletedOfflineTask = task.copyWith(isDeleted: true, isSynced: 0);
        await taskLocalRepository.updateTask(deletedOfflineTask);
        _tasks.removeAt(index);
        emit(GetTasksSuccess(List.from(_tasks)));
      }

      await taskRemoteRepository.deleteTask(token: token, taskId: task.id);
      await taskLocalRepository.deleteTask(task.id);
    } catch (e) {
      print("Remote delete failed, will sync later: $e");
    }
  }

  // syncTasks remains the same...
  Future<void> syncTasks(String token) async {
    // get all unsynced tasks from our sqlite db
    final unsyncedTasks = await taskLocalRepository.getUnsyncedTasks();
    if (unsyncedTasks.isEmpty) {
      return;
    }

    // talk to our postgresql db to add the new task
    final isSynced = await taskRemoteRepository.syncTasks(
        token: token, tasks: unsyncedTasks);
    // change the tasks that were added to the db from 0 to 1
    if (isSynced) {
      print("synced done");
      for (final task in unsyncedTasks) {
        taskLocalRepository.updateRowValue(task.id, 1);
      }
    }
  }
}