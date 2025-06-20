import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/features/auth/cubit/auth_cubit.dart';
import 'package:frontend/features/home/cubit/tasks_cubit.dart';
import 'package:frontend/features/home/pages/home_page.dart';
import 'package:intl/intl.dart';

class AddNewTaskPage extends StatefulWidget {
  static MaterialPageRoute route() => MaterialPageRoute(
    builder: (context) => const AddNewTaskPage(),
  );
  const AddNewTaskPage({super.key});

  @override
  State<AddNewTaskPage> createState() => _AddNewTaskPageState();
}

class _AddNewTaskPageState extends State<AddNewTaskPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Use one DateTime object for both date and time
  DateTime _selectedDateTime = DateTime.now();
  Color _selectedColor = const Color(0xFF6A6AE3); // Default to theme color

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Function to handle creating the task
  void _createNewTask() {
    // First, validate the form. If it's not valid, do nothing.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is AuthLoggedIn) {
      context.read<TasksCubit>().createNewTask(
        uid: authState.user.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        color: _selectedColor,
        token: authState.user.token,
        dueAt: _selectedDateTime,
      );
    }

  }

  // Function to show date and time pickers
  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
          'Create New Task',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: BlocConsumer<TasksCubit, TasksState>(
        // FIX: This new listener correctly detects when a task is successfully added.
        listener: (context, state) {
          if (state is TasksError) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.error)));
          } else if (state is GetTasksSuccess) {
            // Because this is the success state, we know the task was created.
            // We can now show a message and navigate.
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Task created successfully!")),
            );
            Navigator.of(context).pushAndRemoveUntil(
              HomePage.route(),
                  (route) => false,
            );
          }
        },
        // This ensures the listener only runs when needed.
        listenWhen: (previous, current) {
          // Fire the listener if we move from a loading state to a success state.
          return current is GetTasksSuccess && previous is TasksLoading;
        },
        builder: (context, state) {
          if (state is TasksLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // This SingleChildScrollView solves the RenderFlex overflow issue
          return SingleChildScrollView(
            child: Padding(
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
                      onPressed: _createNewTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A6AE3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'CREATE TASK',
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
          );
        },
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