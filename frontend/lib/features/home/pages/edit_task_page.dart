import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/auth/cubit/auth_cubit.dart';
import 'package:frontend/features/home/cubit/tasks_cubit.dart';
import 'package:frontend/features/home/pages/home_page.dart';
import 'package:frontend/models/task_model.dart';
import 'package:intl/intl.dart';

class EditTaskPage extends StatefulWidget {
  final TaskModel task;

  static MaterialPageRoute route({required TaskModel task}) => MaterialPageRoute(
    builder: (context) => EditTaskPage(task: task),
  );

  const EditTaskPage({super.key, required this.task});

  @override
  State<EditTaskPage> createState() => _EditTaskPageState();
}

class _EditTaskPageState extends State<EditTaskPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  final _formKey = GlobalKey<FormState>();

  late DateTime _selectedDateTime;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController =
        TextEditingController(text: widget.task.description);
    _selectedDateTime = widget.task.dueAt;
    _selectedColor = widget.task.color;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateTask() {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthCubit>().state as AuthLoggedIn;

    final updatedTask = widget.task.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      dueAt: _selectedDateTime,
      color: _selectedColor,
    );

    context
        .read<TasksCubit>()
        .updateExistingTask(task: updatedTask, token: authState.user.token);
  }

  void _deleteTask() {
    final authState = context.read<AuthCubit>().state as AuthLoggedIn;
    context
        .read<TasksCubit>()
        .deleteExistingTask(task: widget.task, token: authState.user.token);
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null && context.mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Task',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.delete, color: Colors.red),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext ctx) {
                  return AlertDialog(
                    title: const Text('Please Confirm'),
                    content: const Text('Are you sure you want to delete this task?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(ctx).pop(); // Close the dialog first
                          _deleteTask();
                        },
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: BlocListener<TasksCubit, TasksState>(
        listener: (context, state) {
          if (state is GetTasksSuccess) { // <-- FIX: Listen for the correct state
            // After a successful update/delete, navigate home.
            Navigator.of(context).pushAndRemoveUntil(
              HomePage.route(),
                  (route) => false,
            );
          } else if (state is TasksError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.error)));
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                    controller: _titleController, label: "TITLE"),
                const SizedBox(height: 24),
                _buildTextField(
                  controller: _descriptionController,
                  label: "DESCRIPTION",
                  maxLines: 4,
                ),
                const SizedBox(height: 24),
                _buildDateTimePicker(context),
                const SizedBox(height: 24),
                const Text("COLOR",
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ColorPicker(
                  onColorChanged: (Color color) =>
                      setState(() => _selectedColor = color),
                  color: _selectedColor,
                  pickersEnabled: const {
                    ColorPickerType.wheel: true,
                    ColorPickerType.accent: false,
                    ColorPickerType.primary: false,
                  },
                  width: 44,
                  height: 44,
                  borderRadius: 22,
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _updateTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6A6AE3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'SAVE CHANGES',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("DUE DATE",
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDateTime(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM d, yyyy  -  h:mm a')
                      .format(_selectedDateTime),
                  style: const TextStyle(fontSize: 16),
                ),
                const Icon(CupertinoIcons.calendar, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
        required String label,
        int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
            const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return "$label cannot be empty";
            }
            return null;
          },
        ),
      ],
    );
  }
}