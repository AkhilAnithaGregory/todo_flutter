import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'todo_dashboard.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const AddTodoApp());

class AddTodoApp extends StatelessWidget {
  const AddTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AddTodo(),
    );
  }
}

class AddTodo extends StatefulWidget {
  const AddTodo({super.key});

  @override
  State<AddTodo> createState() => _AddTodoState();
}

class _AddTodoState extends State<AddTodo> {
  final _formKey = GlobalKey<FormState>();
  Logger logger = Logger();
  final _titleController = TextEditingController();
  final _detailController = TextEditingController();
  bool _isLoading = false;
  String _loginToken = '';

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _loginToken = prefs.getString('loginToken') ?? '';
    });

    if (_loginToken.isNotEmpty) {
      logger.i('Token loaded: $_loginToken');
    } else {
      logger.e('No token found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ADD TODO',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF9395D2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildTitleField(),
              const SizedBox(height: 16),
              _buildDetailTextField(),
              const SizedBox(height: 30),
              Row(
                children: [
                  _buildAddTodoButton(),
                  const SizedBox(width: 10),
                  _buildCancelTodoButton()
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Title',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a title';
        }
        return null;
      },
    );
  }

  Widget _buildDetailTextField() {
    return TextFormField(
      controller: _detailController,
      decoration: const InputDecoration(
        labelText: 'Detail',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter some detail';
        }
        return null;
      },
    );
  }

  Widget _buildAddTodoButton() {
    return Expanded(
      child: ElevatedButton(
        onPressed: _isLoading ? null :_submitForm,
        child: const Text('Add Todo'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9395D2),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
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
        child: const Text('Cancel'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF9395D2),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      _createTodo();
    }
  }

  Future<void> _createTodo() async {
    final String title = _titleController.text;
    final String detail = _detailController.text;
    final String selectedDate =
        DateTime.now().toIso8601String().split('T').first;
    bool isComplete = false;
    const String url = 'https://todo-mww8.onrender.com/api/todo';

    if (_loginToken.isEmpty) {
      _showSnackBar('No token found');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': _loginToken,
        },
        body: jsonEncode(<String, dynamic>{
          'task': title,
          'description': detail,
          "isComplete": isComplete.toString(),
          "date": selectedDate,
        }),
      );
      logger.i('apiresponse : ${response.body}');
      if (response.statusCode == 201) {
        if (!mounted) return;
        _showSnackBar('Todo Added Successfully');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Dashboard()),
        );
      } else {
        if (!mounted) return;
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        final String errorMessage =
            responseBody['message'] ?? 'Failed to add todo.';
        _showSnackBar(errorMessage);
      }
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('An error occurred: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
