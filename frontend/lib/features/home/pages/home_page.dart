import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/auth/cubit/auth_cubit.dart';
import 'package:frontend/features/home/cubit/tasks_cubit.dart';
import 'package:frontend/features/home/pages/add_new_task_page.dart';
import 'package:frontend/features/home/pages/edit_task_page.dart';
import 'package:frontend/features/home/pages/profile_page.dart';
import 'package:frontend/models/task_model.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  static MaterialPageRoute route() => MaterialPageRoute(
    builder: (context) => const HomePage(),
  );
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // --- THIS IS THE FIX ---
    // We only fetch tasks if the cubit's state is initial (i.e., the app just started).
    // If we are coming back from the Add/Edit page, the cubit already has the correct,
    // up-to-date list, so we DON'T re-fetch and overwrite it.
    final tasksState = context.read<TasksCubit>().state;
    if (tasksState is TasksInitial) {
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthLoggedIn) {
        context.read<TasksCubit>().getAllTasks(token: authState.user.token);
      }
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _DateSelector(
            selectedDate: _selectedDate,
            onDateSelected: _onDateSelected,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BlocBuilder<TasksCubit, TasksState>(
              builder: (context, state) {
                if (state is TasksLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is TasksError) {
                  return Center(child: Text(state.error));
                }
                if (state is GetTasksSuccess) {
                  final tasksForSelectedDay = state.tasks
                      .where((task) =>
                  !task.isDeleted &&
                      DateUtils.isSameDay(task.dueAt, _selectedDate))
                      .toList();

                  if (tasksForSelectedDay.isEmpty) {
                    return const Center(
                      child: Text(
                        "No tasks for today!",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    itemCount: tasksForSelectedDay.length,
                    itemBuilder: (context, index) {
                      final task = tasksForSelectedDay[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(context, EditTaskPage.route(task: task));
                        },
                        child: _TaskCard(task: task),
                      );
                    },
                  );
                }
                return const Center(
                    child: Text("Welcome! Add a task to get started."));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, AddNewTaskPage.route()),
        backgroundColor: const Color(0xFF6A6AE3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  // The rest of the file (_buildAppBar, _DateSelector, _TaskCard) remains exactly the same.
  // No need to change them.
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    String? userName = (authState is AuthLoggedIn) ? authState.user.name : "User";

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      toolbarHeight: 80,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMMM d, yyyy').format(DateTime.now()),
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            "Hi, $userName",
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(CupertinoIcons.person_circle,
              color: Colors.black, size: 32),
          onPressed: () => Navigator.push(context, ProfilePage.route()),
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _DateSelector({required this.selectedDate, required this.onDateSelected});

  @override
  Widget build(BuildContext context) {
    final startOfWeek =
    selectedDate.subtract(Duration(days: selectedDate.weekday % 7));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(7, (index) {
          final date = startOfWeek.add(Duration(days: index));
          final isSelected = DateUtils.isSameDay(date, selectedDate);
          return GestureDetector(
            onTap: () => onDateSelected(date),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color:
                isSelected ? const Color(0xFF6A6AE3) : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('E').format(date).substring(0, 1),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Expanded(
                  child:
                  Container(width: 2, color: task.color.withOpacity(0.3)),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: task.color, width: 2),
                  ),
                ),
                Expanded(
                  child:
                  Container(width: 2, color: task.color.withOpacity(0.3)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: task.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.black54, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: task.color.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      DateFormat('h:mm a').format(task.dueAt),
                      style: TextStyle(
                        color: task.color.withRed(10),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}