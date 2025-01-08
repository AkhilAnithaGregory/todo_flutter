import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:todo_flutter/Screens/login_page.dart';
import 'add_todo.dart';
import 'edit_todo.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final Logger logger = Logger();
  String _loginToken = '';
  bool _isLoading = false;
  List<dynamic> _todoItems = [];
  DateTime? _selectedDate = DateTime.now();

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
      _fetchTodos();
    } else {
      logger.e('No token found');
    }
  }

  Future<void> _fetchTodos([String? date]) async {
    final String selectedDate =
        date ?? DateTime.now().toIso8601String().split('T').first;
    final String url =
        'https://todo-mww8.onrender.com/api/todo?date=$selectedDate';
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': _loginToken,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> todos = jsonDecode(response.body);
        setState(() {
          _todoItems = todos;
        });
      } else {
        logger.e('Failed to load todos: ${response.body}');
        setState(() {
          _todoItems = [];
        });
      }
    } catch (error) {
      logger.e('Error fetching todos: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
      _fetchTodos(_selectedDate?.toIso8601String().split('T').first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Todo App',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF9395D2),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_today,
              color: Colors.white,
            ),
            onPressed: () {
              _selectDate(context);
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            onPressed: () {
              _logout(context);
            },
          ),
        ],
      ),
      body: Center(
          child: _isLoading
              ? const CircularProgressIndicator()
              : _todoItems.isEmpty
                  ? const Center(child: Text('No Todo to show'))
                  : ListView.builder(
                      itemCount: _todoItems.length,
                      itemBuilder: (context, index) {
                        final todoItem = _todoItems[index];
                        final task = todoItem['task'] ?? 'Untitled';
                        final description =
                            todoItem['description'] ?? 'No description';
                        final isComplete = todoItem['isComplete'] ?? false;
                        final date = DateTime.parse(todoItem['date']);
                        final formattedDate =
                            "${date.year}-${date.month}-${date.day}";
                        final todoId = todoItem['_id'];

                        return Container(
                          margin: const EdgeInsets.all(8),
                          // margin: const EdgeInsets.only(bottom: 8), /* give only bottom margin */
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            title: Text('Task: $task'),
                            subtitle: Text(
                                'Detail: $description\nDate: $formattedDate'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isComplete
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    color: isComplete ? Colors.green : null,
                                  ),
                                  onPressed: () {
                                    _toggleTodoComplete(todoId, formattedDate,
                                        isComplete, index);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    _showDeleteConfirmationDialog(
                                        todoItem['_id']);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditTodoApp(
                                          taskId: todoItem['_id'] ?? "",
                                          task: todoItem['task'] ?? "untitled",
                                          description:
                                              todoItem['description'] ??
                                                  "No Description",
                                          datePart: todoItem['date'] ?? "",
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTodoApp(selectedDate: _selectedDate),
            ),
          );
        },
        backgroundColor: const Color(0xFF9395D2),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _toggleTodoComplete(
      String todoId, String date, bool isComplete, int index) async {
    final String url = 'https://todo-mww8.onrender.com/api/todo/$todoId';

    try {
      final response = await http.put(
        Uri.parse('$url?date=$date'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': _loginToken,
        },
        body: jsonEncode(<String, dynamic>{
          'isComplete': !isComplete,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _todoItems[index]['isComplete'] = !isComplete;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todo status updated')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update todo')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  void _showDeleteConfirmationDialog(String todoId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Todo'),
          content: const Text('Do you want to delete this todo?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteTodoItem(todoId);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTodoItem(String todoId) async {
    final String url = 'https://todo-mww8.onrender.com/api/todo/$todoId';

    try {
      final response = await http.delete(
        Uri.parse(url),
        headers: <String, String>{
          'Authorization': _loginToken,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _todoItems.removeWhere((item) => item['_id'] == todoId);
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todo deleted successfully')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete todo')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loginToken');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Successfully logged out')),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }
}
