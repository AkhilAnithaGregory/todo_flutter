import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:todo_flutter/Screens/todo_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class EditTodoApp extends StatefulWidget {
  final String taskId;
  final String task;
  final String description;
  final String datePart;

  const EditTodoApp({
    required this.taskId,
    required this.task,
    required this.description,
    required this.datePart,
    super.key,
  });

  @override
  State<EditTodoApp> createState() => _EditTodoAppState();
}

class _EditTodoAppState extends State<EditTodoApp> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late String _loginToken;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _taskController.text = widget.task;
    _descriptionController.text = widget.description;
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loginToken = prefs.getString('loginToken') ?? '';
    });
  }

  Future<void> _updateTodo() async {
    setState(() {
      _isLoading = true;
    });
    final String url =
        'https://todo-mww8.onrender.com/api/todo/${widget.taskId}?date=${widget.datePart}';
    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': _loginToken,
      },
      body: jsonEncode({
        'task': _taskController.text,
        'isComplete': false.toString(),
        'description': _descriptionController.text,
      }),
    );

    if (response.statusCode == 200) {
      await _fetchUpdatedTodos();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Dashboard()),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update todo')),
      );
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchUpdatedTodos() async {
    const String url = 'https://todo-mww8.onrender.com/api/todos';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': _loginToken,
      },
    );

    if (response.statusCode == 200) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully Todo Fetched')),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to fetch updated todos')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Todo', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF9395D2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Dashboard()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextFormField(
              controller: _taskController,
              decoration: const InputDecoration(labelText: 'Task'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildUpdateTodoButton(),
                const SizedBox(width: 10),
                _buildCancelTodoButton()
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateTodoButton() {
    return Expanded(
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateTodo,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9395D2),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
        child: const Text('Update Todo'),
      ),
    );
  }

  Widget _buildCancelTodoButton() {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Dashboard()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9395D2),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
        child: const Text('Cancel'),
      ),
    );
  }
}
