import 'dart:convert';

import 'package:frontend/core/constants/constants.dart';
import 'package:frontend/core/constants/utils.dart';
import 'package:frontend/features/home/repository/task_local_repository.dart';
import 'package:frontend/models/task_model.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class TaskRemoteRepository {
  final taskLocalRepository = TaskLocalRepository();

  Future<TaskModel> createTask({
    required String title,
    required String description,
    required String hexColor,
    required String token,
    required String uid,
    required DateTime dueAt,
  }) async {
    try {
      final res = await http.post(Uri.parse("${Constants.backendUri}/tasks"),
          headers: {
            'Content-Type': 'application/json',
            'x-auth-token': token,
          },
          body: jsonEncode(
            {
              'title': title,
              'description': description,
              'hexColor': hexColor,
              'dueAt': dueAt.toIso8601String(),
            },
          ));

      if (res.statusCode != 201) {
        throw jsonDecode(res.body)['error'];
      }

      return TaskModel.fromJson(res.body);
    } catch (e) {
      try {
        final taskModel = TaskModel(
          id: const Uuid().v6(),
          uid: uid,
          title: title,
          description: description,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          dueAt: dueAt,
          color: hexToRgb(hexColor),
          isSynced: 0,
        );
        await taskLocalRepository.insertTask(taskModel);
        return taskModel;
      } catch (e) {
        rethrow;
      }
    }
  }

  Future<List<TaskModel>> getTasks({required String token}) async {
    try {
      final res = await http.get(
        Uri.parse("${Constants.backendUri}/tasks"),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      if (res.statusCode != 200) {
        throw jsonDecode(res.body)['error'];
      }

      final listOfTasks = jsonDecode(res.body);
      List<TaskModel> tasksList = [];

      for (var elem in listOfTasks) {
        tasksList.add(TaskModel.fromMap(elem));
      }

      await taskLocalRepository.insertTasks(tasksList);

      return tasksList;
    } catch (e) {
      final tasks = await taskLocalRepository.getTasks();
      if (tasks.isNotEmpty) {
        return tasks;
      }
      rethrow;
    }
  }

  Future<bool> syncTasks({
    required String token,
    required List<TaskModel> tasks,
  }) async {
    try {
      final taskListInMap = [];
      for (final task in tasks) {
        taskListInMap.add(task.toMap());
      }
      final res = await http.post(
        Uri.parse("${Constants.backendUri}/tasks/sync"),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: jsonEncode(taskListInMap),
      );

      if (res.statusCode != 201) {
        throw jsonDecode(res.body)['error'];
      }

      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }
  Future<TaskModel> updateTask({
    required String token,
    required TaskModel task,
  }) async {
    try {
      final res = await http.put(
        Uri.parse("${Constants.backendUri}/tasks/${task.id}"),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
        body: jsonEncode({
          'title': task.title,
          'description': task.description,
          'hexColor': rgbToHex(task.color),
          'dueAt': task.dueAt.toIso8601String(),
        }),
      );

      if (res.statusCode != 200) {
        throw jsonDecode(res.body)['error'];
      }
      return TaskModel.fromJson(res.body);
    } catch (e) {
      // For now, we just rethrow. In a real app, you might handle offline updates.
      rethrow;
    }
  }

  Future<String> deleteTask({
    required String token,
    required String taskId,
  }) async {
    try {
      final res = await http.delete(
        Uri.parse("${Constants.backendUri}/tasks/$taskId"),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': token,
        },
      );

      if (res.statusCode != 200) {
        throw jsonDecode(res.body)['error'];
      }
      return jsonDecode(res.body)['id'];
    } catch (e) {
      // For now, we just rethrow. In a real app, you might handle offline deletes.
      rethrow;
    }
  }

}

